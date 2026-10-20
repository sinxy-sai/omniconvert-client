# OmniConvert Client Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the open OmniConvert client foundation with a shared task model, Flutter UI shell, Rust bridge, local persistence, and cross-platform CI checks.

**Architecture:** Flutter owns navigation, settings, task presentation, and platform adapters. A Rust library exposes deterministic local operations through a narrow FFI boundary. The client stores task metadata locally and treats interrupted work as retryable rather than silently continuing it.

**Tech Stack:** Flutter/Dart, Rust with `flutter_rust_bridge`, SQLite, GitHub Actions, and platform-native package builders.

**Spec:** `docs/superpowers/specs/2026-10-19-omniconvert-design.md`

## Global Constraints

- Application name is `OmniConvert`; local tools work without login.
- Supported build targets are Windows, Linux, macOS, Android, iOS, and Web; Apple builds run on macOS.
- The public client and local core are Apache-2.0.
- No backend or payment dependency is required to launch the local client.
- Web must not call native Rust FFI directly; it uses a browser-safe implementation boundary.

### Task 1: Establish the client repository layout

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app/app.dart`
- Create: `lib/app/router.dart`
- Create: `lib/features/home/presentation/home_page.dart`
- Create: `lib/features/settings/presentation/settings_page.dart`
- Create: `lib/features/tools/presentation/tools_page.dart`
- Create: `lib/features/tasks/presentation/tasks_page.dart`
- Create: `rust/Cargo.toml`
- Create: `rust/src/lib.rs`
- Create: `LICENSE`
- Create: `README.md`

**Interfaces:**
- Produces a Flutter application with routes `/`, `/tasks`, `/tools`, and `/settings`.
- Produces a Rust library crate with a stable package name and a placeholder `health_check() -> String` bridge method.

- [ ] **Step 1: Add the Flutter project metadata and app entry point.** Set the display name to `OmniConvert`. Commit `pubspec.lock` and pin the Flutter SDK in CI to the version used to create the project. Keep dependencies limited to routing, persistence, and the FFI bridge.
- [ ] **Step 2: Add the Rust crate and bridge health method.** Make `health_check()` return a constant string and expose it through generated bindings so a smoke test can call it.
- [ ] **Step 3: Build the navigation shell.** Render the recent-task home page, tools page placeholder, and settings page without requiring an account or network.
- [ ] **Step 4: Add the Apache-2.0 license and developer setup instructions.** Document Windows/Linux setup and state that macOS/iOS builds require macOS and Xcode.
- [ ] **Step 5: Run the smoke checks.** Run `flutter analyze`, `flutter test`, `cargo test --manifest-path rust/Cargo.toml`, and a debug build for the local host platform. Expected: all commands pass.
- [ ] **Step 6: Commit.** Commit as `chore: create OmniConvert client foundation`.

### Task 2: Implement the shared task model and state machine

**Files:**
- Create: `lib/core/tasks/task.dart`
- Create: `lib/core/tasks/task_status.dart`
- Create: `lib/core/tasks/task_repository.dart`
- Create: `test/core/tasks/task_state_machine_test.dart`
- Modify: `lib/features/home/presentation/home_page.dart`

**Interfaces:**
- `TaskStatus` exposes `queued`, `running`, `succeeded`, `failed`, `cancelled`, and `interrupted`.
- `TaskRepository.create`, `TaskRepository.update`, `TaskRepository.listRecent`, and `TaskRepository.markInterrupted` are asynchronous Dart methods.

- [ ] **Step 1: Write failing transition tests.** Cover valid `queued → running → succeeded`, `running → failed`, explicit `failed → queued`, `running → cancelled`, and restart-time `running → interrupted`; reject all other transitions.
- [ ] **Step 2: Run `flutter test test/core/tasks/task_state_machine_test.dart -v`.** Expected: failures because the model and transition guard do not exist.
- [ ] **Step 3: Implement immutable task records.** Include `taskId`, `toolId`, `executionMode`, `status`, `progress`, timestamps, input metadata, output metadata, and structured error fields. Do not store raw file contents in the record.
- [ ] **Step 4: Implement the transition guard and repository interface.** Ensure retries create a new attempt timestamp but preserve the same task identity and idempotency key.
- [ ] **Step 5: Connect the home page to repository data.** Show recent tasks, status labels, retry action for failed/interrupted tasks, and an empty state.
- [ ] **Step 6: Run the targeted and full Flutter tests.** Expected: PASS.
- [ ] **Step 7: Commit.** Commit as `feat: add task model and state machine`.

### Task 3: Add SQLite persistence and restart recovery

**Files:**
- Create: `lib/core/storage/database.dart`
- Create: `lib/core/tasks/sqlite_task_repository.dart`
- Create: `test/core/tasks/sqlite_task_repository_test.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- `SqliteTaskRepository` implements `TaskRepository`.
- `markInterrupted()` updates only tasks persisted as `running` when the application last exited.

- [ ] **Step 1: Write repository tests.** Verify create/update/list ordering, structured error persistence, idempotency-key uniqueness, and restart recovery.
- [ ] **Step 2: Run the targeted test and verify it fails.** Expected: missing database implementation errors.
- [ ] **Step 3: Create the SQLite schema.** Use a migration version, indexed `updated_at`, and a unique idempotency key. Store paths and metadata, never binary file contents.
- [ ] **Step 4: Implement repository methods and startup recovery.** Run recovery before rendering the home route.
- [ ] **Step 5: Run targeted tests and `flutter analyze`.** Expected: PASS with no analyzer errors.
- [ ] **Step 6: Commit.** Commit as `feat: persist tasks locally`.

### Task 4: Add platform CI and build verification

**Files:**
- Create: `.github/workflows/client.yml`
- Create: `tool/verify_platforms.ps1`
- Create: `tool/verify_platforms.sh`
- Modify: `README.md`

**Interfaces:**
- CI jobs are named `windows`, `linux`, `android`, `web`, `macos`, and `ios-check`.
- `ios-check` runs an unsigned compile check; it does not require production signing secrets.

- [ ] **Step 1: Add workflow checks.** Windows builds Windows, Ubuntu builds Linux/Android/Web, and macOS builds macOS plus `flutter build ios --no-codesign`.
- [ ] **Step 2: Add local verification scripts.** Scripts run analyze, unit tests, Rust tests, and the host-appropriate build; they fail on the first unsuccessful command.
- [ ] **Step 3: Add artifact naming rules.** Use `OmniConvert-{version}-{platform}-{arch}` and publish hashes only in later release jobs.
- [ ] **Step 4: Run the local script on the available host.** Expected: host checks pass; unavailable Apple targets are reported as CI-only, not as false failures.
- [ ] **Step 5: Commit.** Commit as `ci: verify OmniConvert platform builds`.

