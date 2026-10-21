pub mod docx;
mod errors;
pub mod external;
pub mod image;
pub mod mobi;
pub mod process;
mod types;

pub use errors::{ToolError, ToolErrorCode};
pub use types::{CancellationToken, ToolProgress, ToolRequest, ToolResult};

use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{Read, Write};

const MAX_INPUT_BYTES: u64 = 64 * 1024 * 1024;

pub trait ToolOperation {
    fn id(&self) -> &'static str;
    fn accepts_input_extension(&self, extension: &str) -> bool;
    fn accepts_output_extension(&self, extension: &str) -> bool;

    fn execute(
        &self,
        request: &ToolRequest,
        input: &[u8],
        output: &mut dyn Write,
        progress: &mut dyn FnMut(ToolProgress),
        cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError>;
}

pub struct ToolRunner<O: ToolOperation> {
    operation: O,
    cancel: CancellationToken,
}

impl<O: ToolOperation> ToolRunner<O> {
    pub fn new(operation: O) -> Self {
        Self {
            operation,
            cancel: CancellationToken::default(),
        }
    }

    pub fn cancellation_token(&self) -> CancellationToken {
        self.cancel.clone()
    }

    pub fn run(
        &self,
        request: ToolRequest,
        mut progress_sink: impl FnMut(ToolProgress),
    ) -> Result<ToolResult, ToolError> {
        self.check_cancelled()?;
        self.validate_request(&request)?;
        progress_sink(ToolProgress {
            stage: "validating".into(),
            completed: 1,
            total: 1,
        });

        let input_file = File::open(&request.input_path).map_err(|error| {
            if error.kind() == std::io::ErrorKind::NotFound {
                ToolError::new(
                    ToolErrorCode::MissingInput,
                    "Input file does not exist",
                    false,
                )
            } else {
                ToolError::new(
                    ToolErrorCode::InvalidInput,
                    format!("Cannot open input: {error}"),
                    false,
                )
            }
        })?;
        let input_meta = input_file.metadata().map_err(|error| {
            ToolError::new(
                ToolErrorCode::InvalidInput,
                format!("Cannot inspect input: {error}"),
                false,
            )
        })?;
        if !input_meta.is_file() {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "Input is not a regular file",
                false,
            ));
        }
        if input_meta.len() > request.max_bytes {
            return Err(ToolError::new(
                ToolErrorCode::InputTooLarge,
                "Input exceeds the size limit",
                false,
            ));
        }
        let mut input = Vec::new();
        input_file
            .take(request.max_bytes + 1)
            .read_to_end(&mut input)
            .map_err(|error| {
                ToolError::new(
                    ToolErrorCode::InvalidInput,
                    format!("Cannot read input: {error}"),
                    false,
                )
            })?;
        if input.len() as u64 > request.max_bytes {
            return Err(ToolError::new(
                ToolErrorCode::InputTooLarge,
                "Input exceeds the size limit",
                false,
            ));
        }
        self.check_cancelled()?;

        let parent = request.output_path.parent().ok_or_else(|| {
            ToolError::new(
                ToolErrorCode::InvalidInput,
                "Output directory is missing",
                false,
            )
        })?;
        if !parent.is_dir() {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "Output directory does not exist",
                false,
            ));
        }
        if fs::symlink_metadata(&request.output_path).is_ok() {
            return Err(ToolError::new(
                ToolErrorCode::OutputExists,
                "Output already exists",
                false,
            ));
        }
        let mut staged = tempfile::Builder::new()
            .prefix(".omniconvert-")
            .tempfile_in(parent)
            .map_err(|error| {
                ToolError::new(
                    ToolErrorCode::Internal,
                    format!("Cannot stage output: {error}"),
                    true,
                )
            })?;

        let metadata = self.operation.execute(
            &request,
            &input,
            staged.as_file_mut(),
            &mut progress_sink,
            &self.cancel,
        )?;
        self.check_cancelled()?;
        staged.as_file_mut().flush().map_err(|error| {
            ToolError::new(
                ToolErrorCode::Internal,
                format!("Cannot flush output: {error}"),
                true,
            )
        })?;
        staged.as_file().sync_all().map_err(|error| {
            ToolError::new(
                ToolErrorCode::Internal,
                format!("Cannot sync output: {error}"),
                true,
            )
        })?;
        let output_bytes = staged
            .as_file()
            .metadata()
            .map_err(|error| {
                ToolError::new(
                    ToolErrorCode::Internal,
                    format!("Cannot inspect output: {error}"),
                    true,
                )
            })?
            .len();
        if output_bytes == 0 {
            return Err(ToolError::new(
                ToolErrorCode::ConverterFailed,
                "Processor produced an empty output",
                true,
            ));
        }
        self.check_cancelled()?;

        staged
            .persist_noclobber(&request.output_path)
            .map_err(|error| {
                if error.error.kind() == std::io::ErrorKind::AlreadyExists {
                    ToolError::new(ToolErrorCode::OutputExists, "Output already exists", false)
                } else {
                    ToolError::new(
                        ToolErrorCode::Internal,
                        format!("Cannot publish output: {}", error.error),
                        true,
                    )
                }
            })?;
        progress_sink(ToolProgress {
            stage: "completed".into(),
            completed: 1,
            total: 1,
        });
        Ok(ToolResult {
            output_path: request.output_path,
            input_bytes: input.len() as u64,
            output_bytes,
            metadata,
        })
    }

    fn validate_request(&self, request: &ToolRequest) -> Result<(), ToolError> {
        if request.tool_id != self.operation.id() {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "Tool ID does not match the processor",
                false,
            ));
        }
        if !request.input_path.is_absolute() || !request.output_path.is_absolute() {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "File paths must be absolute",
                false,
            ));
        }
        if request.max_bytes == 0 || request.max_bytes > MAX_INPUT_BYTES {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "Invalid input size limit",
                false,
            ));
        }
        let input_extension = extension(&request.input_path);
        let output_extension = extension(&request.output_path);
        if !self.operation.accepts_input_extension(&input_extension)
            || !self.operation.accepts_output_extension(&output_extension)
        {
            return Err(ToolError::new(
                ToolErrorCode::UnsupportedFormat,
                "Unsupported input or output format",
                false,
            ));
        }
        Ok(())
    }

    fn check_cancelled(&self) -> Result<(), ToolError> {
        if self.cancel.is_cancelled() {
            Err(ToolError::new(
                ToolErrorCode::Cancelled,
                "Operation cancelled",
                true,
            ))
        } else {
            Ok(())
        }
    }
}

fn extension(path: &std::path::Path) -> String {
    path.extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_ascii_lowercase()
}
