use std::path::PathBuf;
use std::time::Duration;

use omniconvert_core::tools::docx::DocxToPdf;
use omniconvert_core::tools::external::{ConverterKind, ExternalConverter};
use omniconvert_core::tools::mobi::MobiToPdf;
use omniconvert_core::tools::process::{ProcessSpec, ensure_output, run_process};
use omniconvert_core::tools::{CancellationToken, ToolErrorCode, ToolRequest, ToolRunner};
use std::collections::BTreeMap;

fn helper() -> PathBuf {
    PathBuf::from(env!("CARGO_BIN_EXE_process_helper"))
}

#[test]
fn detects_converter_and_captures_version() {
    let info = ExternalConverter::detect_path(ConverterKind::LibreOffice, helper()).unwrap();
    assert_eq!(info.version, "process-helper 1.0");
}

#[test]
fn reports_missing_dependency() {
    let error = ExternalConverter::detect_path(
        ConverterKind::Calibre,
        PathBuf::from("definitely-missing-converter"),
    )
    .unwrap_err();
    assert_eq!(error.code, ToolErrorCode::DependencyMissing);
}

#[test]
fn reports_non_zero_exit_with_stderr_or_exit_code() {
    let error = run_process(&ProcessSpec {
        program: helper(),
        args: vec!["--fail".into()],
        timeout: Duration::from_secs(1),
        cancel: CancellationToken::default(),
    })
    .unwrap_err();
    assert_eq!(error.code, ToolErrorCode::ConverterFailed);
    assert!(error.message.contains("exit code 7"));
}

#[test]
fn terminates_a_converter_that_exceeds_timeout() {
    let error = run_process(&ProcessSpec {
        program: helper(),
        args: vec!["--sleep".into()],
        timeout: Duration::from_millis(50),
        cancel: CancellationToken::default(),
    })
    .unwrap_err();
    assert_eq!(error.code, ToolErrorCode::Timeout);
}

#[test]
fn validates_converter_output_is_present_and_non_empty() {
    let dir = tempfile::tempdir().unwrap();
    let output = dir.path().join("output.pdf");
    std::fs::write(&output, b"pdf").unwrap();
    assert_eq!(
        ensure_output(&output).unwrap_err().code,
        ToolErrorCode::ConverterFailed
    );
    std::fs::write(&output, b"").unwrap();
    assert_eq!(
        ensure_output(&output).unwrap_err().code,
        ToolErrorCode::ConverterFailed
    );
}

#[test]
fn cancellation_terminates_a_running_converter() {
    let cancel = CancellationToken::default();
    let cancelling = cancel.clone();
    std::thread::spawn(move || {
        std::thread::sleep(Duration::from_millis(50));
        cancelling.cancel();
    });
    let error = run_process(&ProcessSpec {
        program: helper(),
        args: vec!["--sleep".into()],
        timeout: Duration::from_secs(1),
        cancel,
    })
    .unwrap_err();
    assert_eq!(error.code, ToolErrorCode::Cancelled);
}

fn request(tool_id: &str, input: PathBuf, output: PathBuf) -> ToolRequest {
    ToolRequest {
        tool_id: tool_id.into(),
        input_path: input,
        output_path: output,
        options: BTreeMap::new(),
        max_bytes: 1024,
    }
}

#[test]
fn docx_adapter_publishes_a_readable_pdf() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("paper.docx");
    let output = dir.path().join("paper.pdf");
    std::fs::write(&input, b"fixture").unwrap();
    let converter = ExternalConverter::detect_path(ConverterKind::LibreOffice, helper()).unwrap();
    let operation = DocxToPdf::new(converter).unwrap();
    let result = ToolRunner::new(operation)
        .run(request("docx_to_pdf", input, output.clone()), |_| {})
        .unwrap();
    assert_eq!(result.metadata["converter"], "process-helper 1.0");
    assert_eq!(lopdf::Document::load(&output).unwrap().get_pages().len(), 1);
}

#[test]
fn mobi_adapter_publishes_a_readable_pdf() {
    let dir = tempfile::tempdir().unwrap();
    let input = dir.path().join("book.mobi");
    let output = dir.path().join("book.pdf");
    std::fs::write(&input, b"fixture").unwrap();
    let converter = ExternalConverter::detect_path(ConverterKind::Calibre, helper()).unwrap();
    let operation = MobiToPdf::new(converter).unwrap();
    ToolRunner::new(operation)
        .run(request("mobi_to_pdf", input, output.clone()), |_| {})
        .unwrap();
    assert_eq!(lopdf::Document::load(&output).unwrap().get_pages().len(), 1);
}
