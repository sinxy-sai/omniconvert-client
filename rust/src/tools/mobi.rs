use std::collections::BTreeMap;
use std::io::Write;
use std::time::Duration;

use tempfile::tempdir;

use super::external::{ConverterInfo, ConverterKind};
use super::process::{ProcessSpec, ensure_output, run_process};
use super::{
    CancellationToken, ToolError, ToolErrorCode, ToolOperation, ToolProgress, ToolRequest,
};

pub struct MobiToPdf {
    pub converter: ConverterInfo,
    pub timeout: Duration,
}

impl MobiToPdf {
    pub fn new(converter: ConverterInfo) -> Result<Self, ToolError> {
        if converter.kind != ConverterKind::Calibre {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "MOBI conversion requires a Calibre converter",
                false,
            ));
        }
        Ok(Self {
            converter,
            timeout: Duration::from_secs(120),
        })
    }
}

impl ToolOperation for MobiToPdf {
    fn id(&self) -> &'static str {
        "mobi_to_pdf"
    }
    fn accepts_input_extension(&self, extension: &str) -> bool {
        matches!(extension, "mobi" | "azw" | "azw3")
    }
    fn accepts_output_extension(&self, extension: &str) -> bool {
        extension == "pdf"
    }

    fn execute(
        &self,
        request: &ToolRequest,
        _input: &[u8],
        output: &mut dyn Write,
        progress: &mut dyn FnMut(ToolProgress),
        cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError> {
        if cancel.is_cancelled() {
            return Err(cancelled());
        }
        if !request.options.is_empty() {
            return Err(invalid("MOBI converter does not accept options"));
        }
        let staging = tempdir().map_err(|error| internal(error.to_string()))?;
        let staged_input = staging.path().join("input.mobi");
        std::fs::copy(&request.input_path, &staged_input)
            .map_err(|error| internal(format!("Cannot stage MOBI input: {error}")))?;
        let result_path = staging.path().join("result.pdf");
        let spec = ProcessSpec {
            program: self.converter.path.clone(),
            args: vec![
                staged_input.to_string_lossy().into_owned(),
                result_path.to_string_lossy().into_owned(),
            ],
            timeout: self.timeout,
            cancel: cancel.clone(),
        };
        progress(ToolProgress {
            stage: "converting".into(),
            completed: 0,
            total: 1,
        });
        run_process(&spec)?;
        if cancel.is_cancelled() {
            return Err(cancelled());
        }
        let bytes = ensure_output(&result_path)?;
        output
            .write_all(&bytes)
            .map_err(|error| internal(error.to_string()))?;
        progress(ToolProgress {
            stage: "converted".into(),
            completed: 1,
            total: 1,
        });
        Ok(BTreeMap::from([
            ("converter".into(), self.converter.version.clone()),
            ("format".into(), "pdf".into()),
        ]))
    }
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
