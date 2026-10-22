use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, Instant};

use super::{CancellationToken, ToolError, ToolErrorCode};

const POLL_INTERVAL: Duration = Duration::from_millis(25);
const MAX_LOG_BYTES: u64 = 1024 * 1024;
const MAX_CONVERTED_BYTES: u64 = 128 * 1024 * 1024;

#[derive(Debug, Clone)]
pub struct ProcessSpec {
    pub program: PathBuf,
    pub args: Vec<String>,
    pub timeout: Duration,
    pub cancel: CancellationToken,
}

#[derive(Debug, Clone)]
pub struct ProcessOutput {
    pub status_code: Option<i32>,
    pub stdout: String,
    pub stderr: String,
}

pub fn run_process(spec: &ProcessSpec) -> Result<ProcessOutput, ToolError> {
    let mut stdout = tempfile::tempfile().map_err(|error| internal(error.to_string()))?;
    let mut stderr = tempfile::tempfile().map_err(|error| internal(error.to_string()))?;
    let mut command = Command::new(&spec.program);
    command
        .args(&spec.args)
        .stdin(Stdio::null())
        .stdout(Stdio::from(
            stdout
                .try_clone()
                .map_err(|error| internal(error.to_string()))?,
        ))
        .stderr(Stdio::from(
            stderr
                .try_clone()
                .map_err(|error| internal(error.to_string()))?,
        ));
    command.configure_process_group();
    let mut child = command.spawn().map_err(|error| {
        ToolError::new(
            ToolErrorCode::DependencyMissing,
            format!("Cannot start {}: {error}", spec.program.display()),
            false,
        )
    })?;
    let started = Instant::now();
    loop {
        if spec.cancel.is_cancelled() {
            terminate(&mut child);
            return Err(ToolError::new(
                ToolErrorCode::Cancelled,
                "Operation cancelled",
                true,
            ));
        }
        if stdout
            .metadata()
            .map_err(|error| internal(error.to_string()))?
            .len()
            > MAX_LOG_BYTES
            || stderr
                .metadata()
                .map_err(|error| internal(error.to_string()))?
                .len()
                > MAX_LOG_BYTES
        {
            terminate(&mut child);
            return Err(ToolError::new(
                ToolErrorCode::ConverterFailed,
                "Converter log output exceeds the limit",
                false,
            ));
        }
        match child
            .try_wait()
            .map_err(|error| internal(error.to_string()))?
        {
            Some(status) => {
                stdout
                    .seek(SeekFrom::Start(0))
                    .map_err(|error| internal(error.to_string()))?;
                stderr
                    .seek(SeekFrom::Start(0))
                    .map_err(|error| internal(error.to_string()))?;
                let mut stdout_bytes = Vec::new();
                let mut stderr_bytes = Vec::new();
                stdout
                    .take(MAX_LOG_BYTES + 1)
                    .read_to_end(&mut stdout_bytes)
                    .map_err(|error| internal(error.to_string()))?;
                stderr
                    .take(MAX_LOG_BYTES + 1)
                    .read_to_end(&mut stderr_bytes)
                    .map_err(|error| internal(error.to_string()))?;
                let result = ProcessOutput {
                    status_code: status.code(),
                    stdout: String::from_utf8_lossy(&stdout_bytes).trim().to_owned(),
                    stderr: String::from_utf8_lossy(&stderr_bytes).trim().to_owned(),
                };
                if !status.success() {
                    return Err(ToolError::new(
                        ToolErrorCode::ConverterFailed,
                        process_error_message(&spec.program, &result),
                        true,
                    ));
                }
                return Ok(result);
            }
            None if started.elapsed() >= spec.timeout => {
                terminate(&mut child);
                return Err(ToolError::new(
                    ToolErrorCode::Timeout,
                    format!(
                        "{} exceeded the conversion time limit",
                        spec.program.display()
                    ),
                    true,
                ));
            }
            None => thread::sleep(POLL_INTERVAL),
        }
    }
}

fn terminate(child: &mut std::process::Child) {
    #[cfg(windows)]
    {
        let _ = child.kill();
        let _ = Command::new("taskkill")
            .args(["/PID", &child.id().to_string(), "/T", "/F"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
    #[cfg(unix)]
    {
        let pid = -(child.id() as i32);
        unsafe {
            libc::kill(pid, libc::SIGKILL);
        }
    }
    let _ = child.kill();
    let _ = child.wait();
}

pub fn ensure_output(path: &Path) -> Result<Vec<u8>, ToolError> {
    let size = std::fs::metadata(path)
        .map_err(|error| {
            ToolError::new(
                ToolErrorCode::ConverterFailed,
                format!("Converter did not produce an output: {error}"),
                true,
            )
        })?
        .len();
    if size > MAX_CONVERTED_BYTES {
        return Err(ToolError::new(
            ToolErrorCode::InputTooLarge,
            "Converted output exceeds the size limit",
            false,
        ));
    }
    let file = std::fs::File::open(path).map_err(|error| {
        ToolError::new(
            ToolErrorCode::ConverterFailed,
            format!("Converter did not produce a readable output: {error}"),
            true,
        )
    })?;
    let mut bytes = Vec::new();
    file.take(MAX_CONVERTED_BYTES + 1)
        .read_to_end(&mut bytes)
        .map_err(|error| {
            ToolError::new(
                ToolErrorCode::ConverterFailed,
                format!("Cannot read converter output: {error}"),
                true,
            )
        })?;
    if bytes.len() as u64 > MAX_CONVERTED_BYTES {
        return Err(ToolError::new(
            ToolErrorCode::InputTooLarge,
            "Converted output exceeds the size limit",
            false,
        ));
    }
    if bytes.is_empty() {
        return Err(ToolError::new(
            ToolErrorCode::ConverterFailed,
            "Converter produced an empty output",
            true,
        ));
    }
    let pdf = lopdf::Document::load_mem(&bytes).map_err(|error| {
        ToolError::new(
            ToolErrorCode::ConverterFailed,
            format!("Converter output is not a readable PDF: {error}"),
            false,
        )
    })?;
    if pdf.get_pages().is_empty() {
        return Err(ToolError::new(
            ToolErrorCode::ConverterFailed,
            "Converter output contains no PDF pages",
            false,
        ));
    }
    Ok(bytes)
}

trait CommandProcessGroup {
    fn configure_process_group(&mut self);
}

#[cfg(unix)]
impl CommandProcessGroup for Command {
    fn configure_process_group(&mut self) {
        use std::os::unix::process::CommandExt;
        unsafe {
            self.pre_exec(|| {
                if libc::setpgid(0, 0) == 0 {
                    Ok(())
                } else {
                    Err(std::io::Error::last_os_error())
                }
            });
        }
    }
}

#[cfg(windows)]
impl CommandProcessGroup for Command {
    fn configure_process_group(&mut self) {}
}

fn process_error_message(program: &Path, output: &ProcessOutput) -> String {
    let detail = if output.stderr.is_empty() {
        output.stdout.as_str()
    } else {
        output.stderr.as_str()
    };
    match output.status_code {
        Some(code) if !detail.is_empty() => format!(
            "{} failed with exit code {code}: {detail}",
            program.display()
        ),
        Some(code) => format!("{} failed with exit code {code}", program.display()),
        None if !detail.is_empty() => format!("{} failed: {detail}", program.display()),
        None => format!("{} failed", program.display()),
    }
}

fn internal(message: String) -> ToolError {
    ToolError::new(ToolErrorCode::Internal, message, true)
}
