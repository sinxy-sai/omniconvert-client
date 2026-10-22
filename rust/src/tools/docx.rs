use std::collections::BTreeMap;
use std::io::Write;
use std::time::Duration;

use tempfile::tempdir;

use super::external::{ConverterInfo, ConverterKind};
use super::process::{ProcessSpec, ensure_output, run_process};
use super::{
    CancellationToken, ToolError, ToolErrorCode, ToolOperation, ToolProgress, ToolRequest,
};

pub struct DocxToPdf {
    pub converter: ConverterInfo,
    pub timeout: Duration,
}

impl DocxToPdf {
    pub fn new(converter: ConverterInfo) -> Result<Self, ToolError> {
        if converter.kind != ConverterKind::LibreOffice {
            return Err(ToolError::new(
                ToolErrorCode::InvalidInput,
                "DOCX conversion requires a LibreOffice converter",
                false,
            ));
        }
        Ok(Self {
            converter,
            timeout: Duration::from_secs(120),
        })
    }
}

impl ToolOperation for DocxToPdf {
    fn id(&self) -> &'static str {
        "docx_to_pdf"
    }
    fn accepts_input_extension(&self, extension: &str) -> bool {
        extension == "docx"
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
            return Err(invalid("DOCX converter does not accept options"));
        }
        let staging = tempdir().map_err(|error| internal(error.to_string()))?;
        let staged_input = staging.path().join("input.docx");
        std::fs::copy(&request.input_path, &staged_input)
            .map_err(|error| internal(format!("Cannot stage DOCX input: {error}")))?;
        let spec = ProcessSpec {
            program: self.converter.path.clone(),
            args: vec![
                "--headless".into(),
                "--convert-to".into(),
                "pdf".into(),
                "--outdir".into(),
                staging.path().to_string_lossy().into_owned(),
                staged_input.to_string_lossy().into_owned(),
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
        let result_path = staging.path().join("input").with_extension("pdf");
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
