pub fn health_check() -> String {
    "omniconvert-core-ok".to_owned()
}

use std::collections::HashMap;
use std::path::PathBuf;

use crate::tools::image::{CompressImage, ImageToPdf, PngToJpeg};
use crate::tools::{ToolError, ToolErrorCode, ToolRequest, ToolResult, ToolRunner};

pub struct ImageToolOutcome {
    pub success: bool,
    pub output_path: String,
    pub input_bytes: u64,
    pub output_bytes: u64,
    pub width: u32,
    pub height: u32,
    pub error_code: String,
    pub error_message: String,
}

pub fn run_image_tool(
    tool_id: String,
    input_path: String,
    output_path: String,
    options: HashMap<String, String>,
    max_bytes: u64,
) -> ImageToolOutcome {
    let request = ToolRequest {
        tool_id: tool_id.clone(),
        input_path: PathBuf::from(input_path),
        output_path: PathBuf::from(output_path),
        options: options.into_iter().collect(),
        max_bytes,
    };
    let result = match tool_id.as_str() {
        "png_to_jpeg" => ToolRunner::new(PngToJpeg).run(request, |_| {}),
        "image_to_pdf" => ToolRunner::new(ImageToPdf).run(request, |_| {}),
        "compress_image" => ToolRunner::new(CompressImage).run(request, |_| {}),
        _ => Err(ToolError::new(
            ToolErrorCode::InvalidInput,
            "Unknown image tool",
            false,
        )),
    };
    match result {
        Ok(result) => successful_image_outcome(result),
        Err(error) => ImageToolOutcome {
            success: false,
            output_path: String::new(),
            input_bytes: 0,
            output_bytes: 0,
            width: 0,
            height: 0,
            error_code: format!("{:?}", error.code),
            error_message: error.message,
        },
    }
}

fn successful_image_outcome(result: ToolResult) -> ImageToolOutcome {
    let width = result
        .metadata
        .get("width")
        .and_then(|value| value.parse().ok())
        .unwrap_or(0);
    let height = result
        .metadata
        .get("height")
        .and_then(|value| value.parse().ok())
        .unwrap_or(0);
    ImageToolOutcome {
        success: true,
        output_path: result.output_path.to_string_lossy().into_owned(),
        input_bytes: result.input_bytes,
        output_bytes: result.output_bytes,
        width,
        height,
        error_code: String::new(),
        error_message: String::new(),
    }
}
