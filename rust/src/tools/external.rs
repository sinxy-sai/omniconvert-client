use std::path::{Path, PathBuf};
use std::time::Duration;

use super::process::{ProcessSpec, run_process};
use super::{CancellationToken, ToolError, ToolErrorCode};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConverterKind {
    LibreOffice,
    Calibre,
}

impl ConverterKind {
    pub fn display_name(self) -> &'static str {
        match self {
            Self::LibreOffice => "LibreOffice",
            Self::Calibre => "Calibre",
        }
    }

    fn version_args(self) -> &'static [&'static str] {
        match self {
            Self::LibreOffice => &["--version"],
            Self::Calibre => &["--version"],
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConverterInfo {
    pub kind: ConverterKind,
    pub path: PathBuf,
    pub version: String,
}

#[derive(Debug, Clone, Copy)]
pub struct ExternalConverter;

impl ExternalConverter {
    pub fn detect(kind: ConverterKind) -> Result<ConverterInfo, ToolError> {
        let candidates: &[&str] = match kind {
            ConverterKind::LibreOffice => {
                if cfg!(windows) {
                    &["soffice.exe", "libreoffice.exe"]
                } else {
                    &["soffice", "libreoffice"]
                }
            }
            ConverterKind::Calibre => {
                if cfg!(windows) {
                    &["ebook-convert.exe"]
                } else {
                    &["ebook-convert"]
                }
            }
        };
        Self::detect_candidates(kind, candidates)
    }

    pub fn detect_path(
        kind: ConverterKind,
        path: impl AsRef<Path>,
    ) -> Result<ConverterInfo, ToolError> {
        let path = path.as_ref().to_path_buf();
        let output = run_process(&ProcessSpec {
            program: path.clone(),
            args: kind
                .version_args()
                .iter()
                .map(|arg| (*arg).into())
                .collect(),
            timeout: Duration::from_secs(5),
            cancel: CancellationToken::default(),
        })
        .map_err(|error| missing_dependency(kind, &path, error.message))?;
        if output.status_code != Some(0) {
            return Err(ToolError::new(
                ToolErrorCode::DependencyMissing,
                format!("{} did not return a usable version", kind.display_name()),
                false,
            ));
        }
        let version = output.stdout.trim().to_owned();
        if version.is_empty() {
            return Err(ToolError::new(
                ToolErrorCode::DependencyMissing,
                format!("{} returned no version information", kind.display_name()),
                false,
            ));
        }
        Ok(ConverterInfo {
            kind,
            path,
            version,
        })
    }

    fn detect_candidates(
        kind: ConverterKind,
        candidates: &[&str],
    ) -> Result<ConverterInfo, ToolError> {
        for candidate in candidates {
            if let Ok(info) = Self::detect_path(kind, candidate) {
                return Ok(info);
            }
        }
        Err(ToolError::new(
            ToolErrorCode::DependencyMissing,
            format!(
                "{} is not installed or not available on PATH",
                kind.display_name()
            ),
            false,
        ))
    }
}

fn missing_dependency(kind: ConverterKind, path: &Path, detail: String) -> ToolError {
    ToolError::new(
        ToolErrorCode::DependencyMissing,
        format!(
            "{} is unavailable at {}: {detail}",
            kind.display_name(),
            path.display()
        ),
        false,
    )
}
