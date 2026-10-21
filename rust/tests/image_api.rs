use std::collections::HashMap;

use image::{DynamicImage, ImageFormat, Rgba, RgbaImage};
use omniconvert_core::api::run_image_tool;

#[test]
fn image_api_returns_output_metadata_and_typed_failure() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("pixel.png");
    let output = dir.path().join("pixel.jpg");
    DynamicImage::ImageRgba8(RgbaImage::from_pixel(2, 1, Rgba([10, 20, 30, 255])))
        .save_with_format(&input, ImageFormat::Png)
        .unwrap();

    let success = run_image_tool(
        "png_to_jpeg".into(),
        input.to_string_lossy().into_owned(),
        output.to_string_lossy().into_owned(),
        HashMap::new(),
        1024 * 1024,
    );
    assert!(success.success);
    assert_eq!(success.width, 2);
    assert_eq!(success.height, 1);
    assert!(success.output_bytes > 0);
    assert!(output.exists());

    let failure = run_image_tool(
        "png_to_jpeg".into(),
        dir.path().join("missing.png").to_string_lossy().into_owned(),
        dir.path().join("missing.jpg").to_string_lossy().into_owned(),
        HashMap::new(),
        1024 * 1024,
    );
    assert!(!failure.success);
    assert_eq!(failure.error_code, "MissingInput");
}
