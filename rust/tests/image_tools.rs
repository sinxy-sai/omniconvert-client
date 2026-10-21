use std::io::Cursor;
use std::path::Path;

use image::{DynamicImage, GenericImageView, ImageFormat, Rgba, RgbaImage};
use omniconvert_core::tools::image::{CompressImage, ImageToPdf, PngToJpeg};
use omniconvert_core::tools::{ToolErrorCode, ToolRequest, ToolRunner};

fn save_png(path: &Path, image: RgbaImage) {
    DynamicImage::ImageRgba8(image)
        .save_with_format(path, ImageFormat::Png)
        .unwrap();
}

fn request(tool_id: &str, input: &Path, output: &Path, options: &[(&str, &str)]) -> ToolRequest {
    ToolRequest {
        tool_id: tool_id.into(),
        input_path: input.into(),
        output_path: output.into(),
        options: options
            .iter()
            .map(|(key, value)| ((*key).into(), (*value).into()))
            .collect(),
        max_bytes: 2 * 1024 * 1024,
    }
}

fn jpeg_with_orientation(image: DynamicImage, orientation: u16) -> Vec<u8> {
    let mut cursor = Cursor::new(Vec::new());
    image.write_to(&mut cursor, ImageFormat::Jpeg).unwrap();
    let bytes = cursor.into_inner();
    let mut exif = b"Exif\0\0II\x2a\0\x08\0\0\0\x01\0\x12\x01\x03\0\x01\0\0\0".to_vec();
    exif.extend_from_slice(&orientation.to_le_bytes());
    exif.extend_from_slice(&[0, 0, 0, 0, 0, 0]);
    let segment_length = (exif.len() + 2) as u16;
    let mut with_exif = vec![0xff, 0xd8, 0xff, 0xe1];
    with_exif.extend_from_slice(&segment_length.to_be_bytes());
    with_exif.extend_from_slice(&exif);
    with_exif.extend_from_slice(&bytes[2..]);
    with_exif
}

#[test]
fn png_to_jpeg_flattens_transparency_on_white() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("transparent.png");
    let output = dir.path().join("flattened.jpg");
    let mut pixels = RgbaImage::new(2, 1);
    pixels.put_pixel(0, 0, Rgba([255, 0, 0, 0]));
    pixels.put_pixel(1, 0, Rgba([0, 0, 255, 255]));
    save_png(&input, pixels);

    let result = ToolRunner::new(PngToJpeg)
        .run(
            request("png_to_jpeg", &input, &output, &[("quality", "95")]),
            |_| {},
        )
        .unwrap();

    let decoded = image::open(&output).unwrap().to_rgb8();
    assert_eq!(decoded.dimensions(), (2, 1));
    let white = decoded.get_pixel(0, 0).0;
    assert!(white.iter().all(|channel| *channel > 220));
    assert_eq!(result.metadata.get("width").map(String::as_str), Some("2"));
    assert_eq!(result.metadata.get("height").map(String::as_str), Some("1"));
}

#[test]
fn rejects_corrupt_image_bytes() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("invalid.png");
    let output = dir.path().join("invalid.jpg");
    std::fs::write(&input, b"not a png").unwrap();

    let error = ToolRunner::new(PngToJpeg)
        .run(request("png_to_jpeg", &input, &output, &[]), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::InvalidInput);
    assert!(!output.exists());
}

#[test]
fn rejects_dimensions_above_the_configured_pixel_limit() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("wide.png");
    let output = dir.path().join("wide.jpg");
    save_png(&input, RgbaImage::new(3, 2));

    let error = ToolRunner::new(PngToJpeg)
        .run(
            request("png_to_jpeg", &input, &output, &[("max_pixels", "4")]),
            |_| {},
        )
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::InputTooLarge);
    assert!(!output.exists());
}

#[test]
fn compression_applies_jpeg_exif_orientation_and_resizes() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("rotated.jpg");
    let output = dir.path().join("compressed.jpg");
    let pixels = RgbaImage::from_pixel(4, 2, Rgba([20, 100, 220, 255]));
    std::fs::write(
        &input,
        jpeg_with_orientation(DynamicImage::ImageRgba8(pixels), 6),
    )
    .unwrap();

    ToolRunner::new(CompressImage)
        .run(
            request(
                "compress_image",
                &input,
                &output,
                &[("quality", "80"), ("max_dimension", "2")],
            ),
            |_| {},
        )
        .unwrap();

    assert_eq!(image::open(output).unwrap().dimensions(), (1, 2));
}

#[test]
fn lower_jpeg_quality_reduces_output_size_for_a_patterned_image() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("pattern.png");
    let low = dir.path().join("low.jpg");
    let high = dir.path().join("high.jpg");
    let mut pixels = RgbaImage::new(64, 64);
    for y in 0..64 {
        for x in 0..64 {
            pixels.put_pixel(
                x,
                y,
                Rgba([
                    ((x * 17 + y * 13) % 256) as u8,
                    ((x * y) % 256) as u8,
                    ((x * 9) % 256) as u8,
                    255,
                ]),
            );
        }
    }
    save_png(&input, pixels);

    let low_result = ToolRunner::new(CompressImage)
        .run(
            request("compress_image", &input, &low, &[("quality", "25")]),
            |_| {},
        )
        .unwrap();
    let high_result = ToolRunner::new(CompressImage)
        .run(
            request("compress_image", &input, &high, &[("quality", "95")]),
            |_| {},
        )
        .unwrap();

    assert!(low_result.output_bytes < high_result.output_bytes);
    assert_eq!(image::open(low).unwrap().dimensions(), (64, 64));
}

#[test]
fn image_to_pdf_creates_one_landscape_a4_page() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("figure.png");
    let output = dir.path().join("figure.pdf");
    save_png(
        &input,
        RgbaImage::from_pixel(8, 4, Rgba([90, 120, 150, 255])),
    );

    ToolRunner::new(ImageToPdf)
        .run(
            request(
                "image_to_pdf",
                &input,
                &output,
                &[
                    ("page_size", "a4"),
                    ("orientation", "landscape"),
                    ("margin_pt", "24"),
                    ("fit", "contain"),
                ],
            ),
            |_| {},
        )
        .unwrap();

    let document = lopdf::Document::load(&output).unwrap();
    assert_eq!(document.get_pages().len(), 1);
    let page = document
        .get_object(*document.get_pages().values().next().unwrap())
        .unwrap();
    let box_values = page
        .as_dict()
        .unwrap()
        .get(b"MediaBox")
        .unwrap()
        .as_array()
        .unwrap();
    assert_eq!(box_values.len(), 4);
    assert_eq!(box_values[2].as_float().unwrap().round() as i32, 842);
    assert_eq!(box_values[3].as_float().unwrap().round() as i32, 595);
}

#[test]
fn invalid_quality_option_is_rejected_without_output() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("figure.png");
    let output = dir.path().join("figure.jpg");
    save_png(&input, RgbaImage::new(2, 2));

    let error = ToolRunner::new(PngToJpeg)
        .run(
            request("png_to_jpeg", &input, &output, &[("quality", "0")]),
            |_| {},
        )
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::InvalidInput);
    assert!(!output.exists());
}
