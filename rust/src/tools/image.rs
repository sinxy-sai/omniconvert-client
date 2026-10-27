use std::collections::BTreeMap;
use std::io::{Cursor, Write};

use exif::{In, Tag};
use image::codecs::jpeg::JpegEncoder;
use image::{DynamicImage, GenericImageView, ImageFormat, Rgb, RgbImage};
use lopdf::{dictionary, Document, Object, Stream};

use super::{
    CancellationToken, ToolError, ToolErrorCode, ToolOperation, ToolProgress, ToolRequest,
};

const MAX_WIDTH_OR_HEIGHT: u32 = 8192;
const MAX_PIXELS: u64 = 32_000_000;

pub struct PngToJpeg;
pub struct ImageToPdf;
pub struct CompressImage;

impl ToolOperation for PngToJpeg {
    fn id(&self) -> &'static str {
        "png_to_jpeg"
    }
    fn accepts_input_extension(&self, extension: &str) -> bool {
        matches!(extension, "png" | "jpg" | "jpeg" | "webp")
    }
    fn accepts_output_extension(&self, extension: &str) -> bool {
        matches!(extension, "jpg" | "jpeg")
    }

    fn execute(
        &self,
        request: &ToolRequest,
        input: &[u8],
        output: &mut dyn Write,
        progress: &mut dyn FnMut(ToolProgress),
        cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError> {
        check_options(request, &["quality", "background", "max_pixels"])?;
        let quality = quality(request)?;
        let background = background(request)?;
        let image = decode_image(request, input, input_format(request)?)?;
        encode_jpeg(image, output, quality, background, progress, cancel)
    }
}

impl ToolOperation for CompressImage {
    fn id(&self) -> &'static str {
        "compress_image"
    }
    fn accepts_input_extension(&self, extension: &str) -> bool {
        matches!(extension, "png" | "jpg" | "jpeg" | "webp")
    }
    fn accepts_output_extension(&self, extension: &str) -> bool {
        matches!(extension, "jpg" | "jpeg")
    }

    fn execute(
        &self,
        request: &ToolRequest,
        input: &[u8],
        output: &mut dyn Write,
        progress: &mut dyn FnMut(ToolProgress),
        cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError> {
        check_options(
            request,
            &["quality", "max_dimension", "background", "max_pixels"],
        )?;
        let quality = quality(request)?;
        let background = background(request)?;
        let format = input_format(request)?;
        let mut image = decode_image(request, input, format)?;
        if let Some(raw) = request.options.get("max_dimension") {
            let maximum = parse_u32(raw, 1, MAX_WIDTH_OR_HEIGHT, "max_dimension")?;
            if image.width().max(image.height()) > maximum {
                image = image.resize(maximum, maximum, ::image::imageops::FilterType::Lanczos3);
            }
        }
        encode_jpeg(image, output, quality, background, progress, cancel)
    }
}

impl ToolOperation for ImageToPdf {
    fn id(&self) -> &'static str {
        "image_to_pdf"
    }
    fn accepts_input_extension(&self, extension: &str) -> bool {
        matches!(extension, "png" | "jpg" | "jpeg" | "webp")
    }
    fn accepts_output_extension(&self, extension: &str) -> bool {
        extension == "pdf"
    }

    fn execute(
        &self,
        request: &ToolRequest,
        input: &[u8],
        output: &mut dyn Write,
        progress: &mut dyn FnMut(ToolProgress),
        cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError> {
        check_options(
            request,
            &[
                "page_size",
                "orientation",
                "margin_pt",
                "fit",
                "background",
                "max_pixels",
            ],
        )?;
        let background = background(request)?;
        let image = decode_image(request, input, input_format(request)?)?;
        if cancel.is_cancelled() {
            return Err(cancelled());
        }
        let (width, height) = image.dimensions();
        let rgb = flatten(image, background);
        let (mut page_width, mut page_height) = match request
            .options
            .get("page_size")
            .map(String::as_str)
            .unwrap_or("a4")
        {
            "a4" => (595.28_f32, 841.89_f32),
            "letter" => (612.0_f32, 792.0_f32),
            _ => return Err(invalid("Unsupported PDF page size")),
        };
        let landscape = match request
            .options
            .get("orientation")
            .map(String::as_str)
            .unwrap_or("auto")
        {
            "auto" => width > height,
            "landscape" => true,
            "portrait" => false,
            _ => return Err(invalid("Unsupported PDF orientation")),
        };
        if landscape {
            std::mem::swap(&mut page_width, &mut page_height);
        }
        let margin = match request.options.get("margin_pt") {
            Some(value) => value
                .parse::<f32>()
                .map_err(|_| invalid("Invalid PDF margin"))?,
            None => 24.0,
        };
        if !margin.is_finite() || margin < 0.0 || margin * 2.0 >= page_width.min(page_height) {
            return Err(invalid("PDF margin leaves no printable area"));
        }
        let fit = request
            .options
            .get("fit")
            .map(String::as_str)
            .unwrap_or("contain");
        let content_width = page_width - margin * 2.0;
        let content_height = page_height - margin * 2.0;
        let scale_x = content_width / width as f32;
        let scale_y = content_height / height as f32;
        let scale = match fit {
            "contain" => scale_x.min(scale_y),
            "cover" => scale_x.max(scale_y),
            _ => return Err(invalid("Unsupported PDF fit mode")),
        };
        let draw_width = width as f32 * scale;
        let draw_height = height as f32 * scale;
        let draw_x = (page_width - draw_width) / 2.0;
        let draw_y = (page_height - draw_height) / 2.0;

        let mut document = Document::with_version("1.5");
        let pages_id = document.new_object_id();
        let mut image_stream = Stream::new(
            dictionary! {
                "Type" => "XObject", "Subtype" => "Image",
                "Width" => width as i64, "Height" => height as i64,
                "ColorSpace" => "DeviceRGB", "BitsPerComponent" => 8,
            },
            rgb.into_raw(),
        );
        image_stream
            .compress()
            .map_err(|error| internal(format!("Cannot compress PDF image: {error}")))?;
        let image_id = document.add_object(image_stream);
        let resources_id =
            document.add_object(dictionary! { "XObject" => dictionary! { "Im0" => image_id } });
        let content = format!(
            "q {margin:.3} {margin:.3} {content_width:.3} {content_height:.3} re W n {draw_width:.3} 0 0 {draw_height:.3} {draw_x:.3} {draw_y:.3} cm /Im0 Do Q"
        );
        let content_id = document.add_object(Stream::new(dictionary! {}, content.into_bytes()));
        let page_id = document.add_object(dictionary! {
            "Type" => "Page", "Parent" => pages_id,
            "MediaBox" => vec![Object::Integer(0), Object::Integer(0), Object::Real(page_width), Object::Real(page_height)],
            "Resources" => resources_id, "Contents" => content_id,
        });
        document.objects.insert(
            pages_id,
            Object::Dictionary(dictionary! {
                "Type" => "Pages", "Kids" => vec![Object::Reference(page_id)], "Count" => 1,
            }),
        );
        let catalog_id =
            document.add_object(dictionary! { "Type" => "Catalog", "Pages" => pages_id });
        document.trailer.set("Root", catalog_id);
        let mut writer = output;
        document
            .save_to(&mut writer)
            .map_err(|error| internal(format!("Cannot write PDF: {error}")))?;
        progress(ToolProgress {
            stage: "encoding".into(),
            completed: 1,
            total: 1,
        });
        let mut metadata = dimensions(width, height);
        metadata.insert("pages".into(), "1".into());
        Ok(metadata)
    }
}

fn input_format(request: &ToolRequest) -> Result<ImageFormat, ToolError> {
    match request
        .input_path
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_ascii_lowercase()
        .as_str()
    {
        "png" => Ok(ImageFormat::Png),
        "jpg" | "jpeg" => Ok(ImageFormat::Jpeg),
        "webp" => Ok(ImageFormat::WebP),
        _ => Err(invalid("Unsupported image format")),
    }
}

fn decode_image(
    request: &ToolRequest,
    input: &[u8],
    format: ImageFormat,
) -> Result<DynamicImage, ToolError> {
    let reader = ::image::ImageReader::with_format(Cursor::new(input), format);
    let (width, height) = reader
        .into_dimensions()
        .map_err(|error| invalid(format!("Cannot read image dimensions: {error}")))?;
    let max_pixels = match request.options.get("max_pixels") {
        Some(value) => parse_u64(value, 1, MAX_PIXELS, "max_pixels")?,
        None => MAX_PIXELS,
    };
    if width == 0
        || height == 0
        || width > MAX_WIDTH_OR_HEIGHT
        || height > MAX_WIDTH_OR_HEIGHT
        || u64::from(width) * u64::from(height) > max_pixels
    {
        return Err(ToolError::new(
            ToolErrorCode::InputTooLarge,
            "Image dimensions exceed the limit",
            false,
        ));
    }
    let image = ::image::load_from_memory_with_format(input, format)
        .map_err(|error| invalid(format!("Cannot decode image: {error}")))?;
    let orientation = if format == ImageFormat::Jpeg {
        exif_orientation(input)
    } else {
        1
    };
    Ok(apply_orientation(image, orientation))
}

fn exif_orientation(bytes: &[u8]) -> u32 {
    exif::Reader::new()
        .read_from_container(&mut Cursor::new(bytes))
        .ok()
        .and_then(|data| {
            data.get_field(Tag::Orientation, In::PRIMARY)
                .and_then(|field| field.value.get_uint(0))
        })
        .unwrap_or(1)
}

fn apply_orientation(image: DynamicImage, orientation: u32) -> DynamicImage {
    match orientation {
        2 => image.fliph(),
        3 => image.rotate180(),
        4 => image.flipv(),
        5 => image.rotate90().fliph(),
        6 => image.rotate90(),
        7 => image.rotate270().fliph(),
        8 => image.rotate270(),
        _ => image,
    }
}

fn encode_jpeg(
    image: DynamicImage,
    output: &mut dyn Write,
    quality: u8,
    background: [u8; 3],
    progress: &mut dyn FnMut(ToolProgress),
    cancel: &CancellationToken,
) -> Result<BTreeMap<String, String>, ToolError> {
    if cancel.is_cancelled() {
        return Err(cancelled());
    }
    let rgb = flatten(image, background);
    let (width, height) = rgb.dimensions();
    JpegEncoder::new_with_quality(output, quality)
        .encode(
            rgb.as_raw(),
            width,
            height,
            ::image::ExtendedColorType::Rgb8,
        )
        .map_err(|error| internal(format!("Cannot encode JPEG: {error}")))?;
    progress(ToolProgress {
        stage: "encoding".into(),
        completed: 1,
        total: 1,
    });
    Ok(dimensions(width, height))
}

fn flatten(image: DynamicImage, background: [u8; 3]) -> RgbImage {
    let rgba = image.to_rgba8();
    let mut rgb = RgbImage::new(rgba.width(), rgba.height());
    for (x, y, pixel) in rgba.enumerate_pixels() {
        let alpha = u32::from(pixel[3]);
        let result = std::array::from_fn(|channel| {
            ((u32::from(pixel[channel]) * alpha
                + u32::from(background[channel]) * (255 - alpha)
                + 127)
                / 255) as u8
        });
        rgb.put_pixel(x, y, Rgb(result));
    }
    rgb
}

fn dimensions(width: u32, height: u32) -> BTreeMap<String, String> {
    BTreeMap::from([
        ("width".into(), width.to_string()),
        ("height".into(), height.to_string()),
    ])
}

fn quality(request: &ToolRequest) -> Result<u8, ToolError> {
    match request.options.get("quality") {
        Some(value) => parse_u32(value, 1, 100, "quality").map(|value| value as u8),
        None => Ok(85),
    }
}

fn background(request: &ToolRequest) -> Result<[u8; 3], ToolError> {
    let value = request
        .options
        .get("background")
        .map(String::as_str)
        .unwrap_or("FFFFFF");
    let digits = value.strip_prefix('#').unwrap_or(value);
    if digits.len() != 6 || !digits.is_ascii() {
        return Err(invalid("Background must be a six-digit RGB color"));
    }
    let mut result = [0; 3];
    for (index, channel) in result.iter_mut().enumerate() {
        *channel = u8::from_str_radix(&digits[index * 2..index * 2 + 2], 16)
            .map_err(|_| invalid("Background must be a six-digit RGB color"))?;
    }
    Ok(result)
}

fn parse_u32(value: &str, minimum: u32, maximum: u32, name: &str) -> Result<u32, ToolError> {
    let parsed = value
        .parse::<u32>()
        .map_err(|_| invalid(format!("Invalid {name}")))?;
    if parsed < minimum || parsed > maximum {
        Err(invalid(format!("Invalid {name}")))
    } else {
        Ok(parsed)
    }
}

fn parse_u64(value: &str, minimum: u64, maximum: u64, name: &str) -> Result<u64, ToolError> {
    let parsed = value
        .parse::<u64>()
        .map_err(|_| invalid(format!("Invalid {name}")))?;
    if parsed < minimum || parsed > maximum {
        Err(invalid(format!("Invalid {name}")))
    } else {
        Ok(parsed)
    }
}

fn check_options(request: &ToolRequest, allowed: &[&str]) -> Result<(), ToolError> {
    if let Some(key) = request
        .options
        .keys()
        .find(|key| !allowed.contains(&key.as_str()))
    {
        return Err(invalid(format!("Unsupported option: {key}")));
    }
    Ok(())
}

fn invalid(message: impl Into<String>) -> ToolError {
    ToolError::new(ToolErrorCode::InvalidInput, message, false)
}

fn internal(message: impl Into<String>) -> ToolError {
    ToolError::new(ToolErrorCode::Internal, message, true)
}

fn cancelled() -> ToolError {
    ToolError::new(ToolErrorCode::Cancelled, "Operation cancelled", true)
}
