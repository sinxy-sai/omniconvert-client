use std::collections::BTreeMap;
use std::io::Write;
use std::path::{Path, PathBuf};

use omniconvert_core::tools::{
    CancellationToken, ToolError, ToolErrorCode, ToolOperation, ToolProgress, ToolRequest,
    ToolRunner,
};

struct CopyOperation;

impl ToolOperation for CopyOperation {
    fn id(&self) -> &'static str {
        "test_copy"
    }

    fn accepts_input_extension(&self, extension: &str) -> bool {
        extension == "png"
    }

    fn accepts_output_extension(&self, extension: &str) -> bool {
        extension == "bin"
    }

    fn execute(
        &self,
        _request: &ToolRequest,
        input: &[u8],
        output: &mut dyn Write,
        progress: &mut dyn FnMut(ToolProgress),
        _cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError> {
        output.write_all(input).unwrap();
        progress(ToolProgress {
            stage: "processing".into(),
            completed: 1,
            total: 1,
        });
        Ok(BTreeMap::new())
    }
}

struct FailingOperation;

impl ToolOperation for FailingOperation {
    fn id(&self) -> &'static str {
        "test_copy"
    }

    fn accepts_input_extension(&self, extension: &str) -> bool {
        extension == "png"
    }

    fn accepts_output_extension(&self, extension: &str) -> bool {
        extension == "bin"
    }

    fn execute(
        &self,
        _request: &ToolRequest,
        _input: &[u8],
        output: &mut dyn Write,
        _progress: &mut dyn FnMut(ToolProgress),
        _cancel: &CancellationToken,
    ) -> Result<BTreeMap<String, String>, ToolError> {
        output.write_all(b"incomplete").unwrap();
        Err(ToolError::new(
            ToolErrorCode::ConverterFailed,
            "Simulated processing failure",
            true,
        ))
    }
}

fn request(input_path: &Path, output_path: &Path, max_bytes: u64) -> ToolRequest {
    ToolRequest {
        tool_id: "test_copy".into(),
        input_path: input_path.to_path_buf(),
        output_path: output_path.to_path_buf(),
        options: BTreeMap::new(),
        max_bytes,
    }
}

fn output_names(directory: &Path) -> Vec<PathBuf> {
    std::fs::read_dir(directory)
        .unwrap()
        .map(|entry| entry.unwrap().path())
        .collect()
}

#[test]
fn rejects_unsupported_input_extension() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("input.txt");
    std::fs::write(&input, b"data").unwrap();
    let output = dir.path().join("output.bin");

    let error = ToolRunner::new(CopyOperation)
        .run(request(&input, &output, 100), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::UnsupportedFormat);
    assert!(!output.exists());
}

#[test]
fn reports_missing_input_without_creating_output() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("missing.png");
    let output = dir.path().join("output.bin");

    let error = ToolRunner::new(CopyOperation)
        .run(request(&input, &output, 100), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::MissingInput);
    assert!(output_names(dir.path()).is_empty());
}

#[test]
fn rejects_input_exceeding_request_limit() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("input.png");
    std::fs::write(&input, b"12345").unwrap();
    let output = dir.path().join("output.bin");

    let error = ToolRunner::new(CopyOperation)
        .run(request(&input, &output, 4), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::InputTooLarge);
    assert_eq!(output_names(dir.path()), vec![input]);
}

#[test]
fn never_replaces_an_existing_output() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("input.png");
    let output = dir.path().join("output.bin");
    std::fs::write(&input, b"new").unwrap();
    std::fs::write(&output, b"original").unwrap();

    let error = ToolRunner::new(CopyOperation)
        .run(request(&input, &output, 100), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::OutputExists);
    assert_eq!(std::fs::read(output).unwrap(), b"original");
}

#[test]
fn cancellation_leaves_no_partial_output() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("input.png");
    let output = dir.path().join("output.bin");
    std::fs::write(&input, b"data").unwrap();
    let runner = ToolRunner::new(CopyOperation);
    runner.cancellation_token().cancel();

    let error = runner
        .run(request(&input, &output, 100), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::Cancelled);
    assert_eq!(output_names(dir.path()), vec![input]);
}

#[test]
fn successful_run_publishes_only_the_complete_output() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("input.png");
    let output = dir.path().join("output.bin");
    std::fs::write(&input, b"complete-data").unwrap();
    let mut stages = Vec::new();

    let result = ToolRunner::new(CopyOperation)
        .run(request(&input, &output, 100), |event| {
            stages.push(event.stage)
        })
        .unwrap();

    assert_eq!(std::fs::read(&output).unwrap(), b"complete-data");
    assert_eq!(result.output_path, output);
    assert_eq!(result.output_bytes, 13);
    assert_eq!(output_names(dir.path()).len(), 2);
    assert!(stages.contains(&"processing".to_string()));
}

#[test]
fn failed_run_cleans_staged_output() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("input.png");
    let output = dir.path().join("output.bin");
    std::fs::write(&input, b"data").unwrap();

    let error = ToolRunner::new(FailingOperation)
        .run(request(&input, &output, 100), |_| {})
        .unwrap_err();

    assert_eq!(error.code, ToolErrorCode::ConverterFailed);
    assert_eq!(output_names(dir.path()), vec![input]);
}
