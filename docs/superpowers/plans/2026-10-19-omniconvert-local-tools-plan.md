# OmniConvert Local Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver deterministic local image tools and guarded desktop document conversion adapters with observable progress, cancellation, cleanup, and meaningful errors.

**Architecture:** A Rust `ToolRunner` owns validation, temporary directories, subprocess limits, atomic output, and progress events. Flutter invokes tools through the task engine. Image operations are in-process; DOCX/MOBI adapters invoke explicitly detected external converters and never silently bundle them.

**Tech Stack:** Rust, Flutter FFI, Rust `image` crate for raster decoding/encoding, `lopdf` for PDF writing, LibreOffice for DOCX conversion, Calibre command-line tools for MOBI conversion, and platform subprocess APIs. Pin and record the checked license versions before release.

**Spec:** `docs/superpowers/specs/2026-10-19-omniconvert-design.md`

## Global Constraints

- Local tools do not upload files and require no account.
- Outputs are written to a temporary path and atomically moved only after validation.
- File size, type, output directory, CPU time, memory, and temporary disk use are bounded.
- External converters are detected and reported; they are not silently assumed or bundled.
- Conversion-library and model licenses must be recorded before distribution.

### Task 1: Define Rust tool contracts and structured errors

**Files:**
- Create: `rust/src/tools/mod.rs`
- Create: `rust/src/tools/types.rs`
- Create: `rust/src/tools/errors.rs`
- Create: `rust/tests/tool_contracts.rs`

**Interfaces:**
- `ToolRequest { tool_id, input_path, output_path, options, max_bytes }`.
- `ToolProgress { stage, completed, total }`.
- `ToolError { code, message, retryable, details }`.
- `ToolRunner::run(request, progress_sink) -> Result<ToolResult, ToolError>`.

- [ ] **Step 1: Write contract tests.** Cover unsupported extension, input-size limit, missing input, output collision, cancellation, and atomic-output behavior.
- [ ] **Step 2: Run `cargo test --manifest-path rust/Cargo.toml --test tool_contracts`.** Expected: failures because the contracts do not exist.
- [ ] **Step 3: Implement typed requests, results, progress, and errors.** Error codes must distinguish invalid input, dependency missing, converter failed, timeout, cancelled, quota, and internal failure.
- [ ] **Step 4: Implement temp-directory lifecycle and atomic move.** Cleanup must run on success, failure, cancellation, and panic-safe drop paths.
- [ ] **Step 5: Run tests and Clippy.** Expected: PASS with `cargo clippy -- -D warnings`.
- [ ] **Step 6: Commit.** Commit as `feat: define local tool contracts`.

### Task 2: Implement image conversion and compression

**Files:**
- Create: `rust/src/tools/image.rs`
- Create: `rust/tests/image_tools.rs`
- Modify: `rust/src/tools/mod.rs`
- Modify: `lib/features/tools/presentation/tools_page.dart`

**Interfaces:**
- Rust functions `png_to_jpeg`, `image_to_pdf`, and `compress_image` consume `ToolRequest` and return `ToolResult`.
- Flutter tool cards expose input selection, output options, progress, cancel, and result location.

- [ ] **Step 1: Write failing image tests.** Use generated fixtures for transparency, EXIF orientation, oversized dimensions, invalid bytes, and quality settings.
- [ ] **Step 2: Run the tests and verify failure.** Expected: missing tool implementations.
- [ ] **Step 3: Implement PNG→JPEG.** Define alpha handling explicitly, preserve orientation after decode, and report the output dimensions and byte size.
- [ ] **Step 4: Implement image→PDF.** Support a single image with page size, orientation, margin, and fit options; reject unsupported color or corrupt input with typed errors.
- [ ] **Step 5: Implement compression.** Allow target quality and optional maximum dimension; never overwrite the source by default.
- [ ] **Step 6: Connect Flutter tool cards to task creation.** Disable submit when validation fails and show whether execution is local.
- [ ] **Step 7: Run Rust and Flutter tests.** Expected: PASS.
- [ ] **Step 8: Commit.** Commit as `feat: add local image tools`.

### Task 3: Add DOCX and MOBI adapter detection

**Files:**
- Create: `rust/src/tools/external.rs`
- Create: `rust/src/tools/docx.rs`
- Create: `rust/src/tools/mobi.rs`
- Create: `rust/src/tools/process.rs`
- Create: `rust/tests/external_tools.rs`
- Create: `docs/docs/external-converters.md`

**Interfaces:**
- `ExternalConverter::detect() -> Result<ConverterInfo, ToolError>`.
- `docx_to_pdf(request, converter_info)` and `mobi_to_pdf(request, converter_info)` return the same `ToolResult` as image tools.

- [ ] **Step 1: Write detection tests with fake executable paths.** Verify missing dependency, executable version capture, non-zero exit, timeout, and successful output validation.
- [ ] **Step 2: Run tests and verify failure.** Expected: missing detector and adapters.
- [ ] **Step 3: Implement detection with allowlisted executable names and no shell interpolation.** Capture version text for diagnostics.
- [ ] **Step 4: Implement DOCX and MOBI subprocess execution.** Use argument arrays, a restricted temp directory, timeout, output existence check, and cleanup.
- [ ] **Step 5: Add representative fixture tests.** Keep fixtures small and license-safe; validate page count or output readability rather than pixel equality.
- [ ] **Step 6: Document installation, supported input range, DRM limitations, and converter licenses.** Do not claim universal MOBI compatibility.
- [ ] **Step 7: Run Rust tests and a manual conversion smoke test on each available desktop platform.** Expected: typed missing-dependency messages when tools are absent.
- [ ] **Step 8: Commit.** Commit as `feat: add desktop document conversion adapters`.

### Task 4: Add cancellation, retries, and history integration

**Files:**
- Modify: `rust/src/tools/mod.rs`
- Modify: `lib/core/tasks/task_repository.dart`
- Modify: `lib/features/home/presentation/home_page.dart`
- Create: `test/features/tasks/task_retry_test.dart`

- [ ] **Step 1: Write tests.** Verify cancellation terminates the operation, failed tasks can be explicitly retried, and a successful retry does not duplicate history entries.
- [ ] **Step 2: Implement cancellation tokens and task event forwarding.** Do not mark a task succeeded after cancellation has been accepted.
- [ ] **Step 3: Add retry UI and result reveal.** Show actionable error code and converter installation guidance where applicable.
- [ ] **Step 4: Run targeted tests, full tests, and host smoke conversion.** Expected: PASS.
- [ ] **Step 5: Commit.** Commit as `feat: integrate local tools with task history`.

### Task 5: Add browser-local image tools

**Files:**
- Create: `lib/core/tools/tool_runner.dart`
- Create: `lib/core/tools/native_tool_runner.dart`
- Create: `lib/core/tools/web_image_tool_runner.dart`
- Create: `test/core/tools/web_image_tool_runner_test.dart`
- Modify: `lib/features/tools/presentation/tools_page.dart`
- Modify: `pubspec.yaml`

**Interfaces:**
- `ToolRunner.run(request, onProgress)` returns the same task result shape on native and Web.
- `WebImageToolRunner` supports PNG→JPEG, single-image PNG/JPEG→PDF, and image compression; it never sends input bytes to a server.

- [ ] **Step 1: Add browser tests.** Cover alpha flattening, output MIME type, PDF page count, maximum input size, and invalid image bytes. Run with `flutter test --platform chrome` and verify the tests fail before implementation.
- [ ] **Step 2: Implement browser-safe decoding and encoding.** Use pinned pure-Dart image and PDF packages; keep bytes in browser memory and release object URLs after download.
- [ ] **Step 3: Add conditional platform selection.** Native targets use `NativeToolRunner`; Web uses `WebImageToolRunner`. No Web build may import or initialize the Rust FFI library.
- [ ] **Step 4: Run browser tests, `flutter build web --base-href /app/`, and a manual offline image-conversion smoke test.** Expected: local image output with no network request carrying file bytes.
- [ ] **Step 5: Commit.** Commit as `feat: add browser-local image tools`.

