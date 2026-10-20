# OmniConvert OCR Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide a private, CPU-capable official handwritten-math OCR service with a replaceable public Provider protocol, email accounts, free quotas, security limits, and automatic temporary-file cleanup.

**Architecture:** A versioned HTTP API accepts one image per idempotent request, places work in a PostgreSQL-backed lease queue, runs a small model in a resource-limited worker, and returns editable LaTeX. The public client only depends on the Provider contract; the model, account, quota, and operational code stay private.

**Tech Stack:** Python 3, FastAPI, SQLAlchemy, PostgreSQL, Argon2id, SMTP, Docker, structured logging, and a CPU-capable OCR model whose license permits the intended use.

**Spec:** `docs/superpowers/specs/2026-10-19-omniconvert-design.md`

## Global Constraints

- Official OCR is free-quota only in phase one; no payment or subscription implementation.
- The service runs on existing Linux infrastructure and must be CPU-capable.
- Uploaded originals are deleted within one hour after completion and no later than 24 hours after task creation.
- Logs must not contain image content, file bodies, access tokens, or complete local paths.
- Retries with the same idempotency key must not double-charge quota.
- No official registration without a configured SMTP channel.

### Task 1: Specify and test the public Provider protocol

**Files:**
- Create: `protocol/ocr-provider-v1.openapi.yaml`
- Create: `protocol/examples/recognize-request.json`
- Create: `protocol/examples/recognize-response.json`
- Create: `protocol/tests/provider_contract_test.py`
- Create: `docs/docs/self-hosted-provider.md`

**Interfaces:**
- `GET /v1/capabilities` returns protocol version and supported modes.
- `POST /v1/recognize` accepts one image, mode, idempotency key, and timeout.
- Response contains `requestId`, `latex`, `modelVersion`, warnings, and structured error fields.

- [ ] **Step 1: Write contract tests.** Cover valid response, malformed image, unsupported mode, timeout, duplicate idempotency key, and provider unavailable.
- [ ] **Step 2: Run the contract test and verify it fails.** Expected: no server or fixture implementation.
- [ ] **Step 3: Write the OpenAPI document and examples.** Include max request size, HTTPS expectation, authentication extension point, and error codes.
- [ ] **Step 4: Implement a deterministic mock provider for client integration tests.** It returns fixture LaTeX and never stores images.
- [ ] **Step 5: Run contract tests and validate the OpenAPI document.** Expected: PASS.
- [ ] **Step 6: Commit.** Commit as `feat: define OCR provider protocol v1`.

### Task 2: Implement official API, accounts, and sessions

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/app/main.py`
- Create: `backend/app/auth/routes.py`
- Create: `backend/app/auth/passwords.py`
- Create: `backend/app/auth/sessions.py`
- Create: `backend/app/auth/mail.py`
- Create: `backend/migrations/001_accounts.sql`
- Create: `backend/tests/test_auth_api.py`
- Create: `backend/.env.example`
- Create: `backend/docs/auth.md`

**Interfaces:**
- `POST /v1/auth/register`, `POST /v1/auth/login`, `POST /v1/auth/logout`, and password-reset endpoints.
- Passwords are Argon2id hashes; sessions are short-lived access tokens plus revocable refresh tokens.

- [ ] **Step 1: Write API tests.** Cover duplicate email, weak password, wrong password, expired session, revoked refresh token, and SMTP-disabled registration.
- [ ] **Step 2: Run tests and verify failure.** Expected: missing routes and migrations.
- [ ] **Step 3: Implement the account schema and Argon2id password handling.** Normalize email addresses and never log credentials or reset tokens.
- [ ] **Step 4: Implement SMTP-gated verification and password reset.** Reset links are single-use and expire within one hour.
- [ ] **Step 5: Run tests and a manual HTTPS-only request smoke test.** Expected: PASS.
- [ ] **Step 6: Commit.** Commit as `feat: add OCR service accounts`.

### Task 3: Implement quota, idempotency, and the lease queue

**Files:**
- Create: `backend/migrations/002_ocr_tasks.sql`
- Create: `backend/app/ocr/queue.py`
- Create: `backend/app/ocr/quota.py`
- Create: `backend/tests/test_quota_and_queue.py`

**Interfaces:**
- `POST /v1/recognitions` creates or returns a task by `(user_id, idempotency_key)`.
- `GET /v1/recognitions/{requestId}` returns queued, running, succeeded, failed, or expired state.
- Quota functions `reserve`, `release_on_server_failure`, and `commit_on_success` are transactionally safe.

- [ ] **Step 1: Write concurrency tests.** Submit the same idempotency key concurrently and verify one task and one quota result; verify server failure releases quota.
- [ ] **Step 2: Implement PostgreSQL task rows with lease owner, lease expiry, attempt count, and cleanup deadline.** Add indexes for queued tasks and expiry.
- [ ] **Step 3: Implement quota transactions.** Only a successful valid result commits usage; duplicate completion is harmless.
- [ ] **Step 4: Implement queue polling with lease renewal and bounded attempts.** Expired leases are reclaimable; tasks exceeding attempts become failed with a retryable flag only when safe.
- [ ] **Step 5: Run concurrency and migration tests.** Expected: PASS.
- [ ] **Step 6: Commit.** Commit as `feat: add OCR quota and task queue`.

### Task 4: Integrate the small CPU OCR model and cleanup worker

**Files:**
- Create: `backend/app/ocr/model_adapter.py`
- Create: `backend/app/ocr/worker.py`
- Create: `backend/app/ocr/cleanup.py`
- Create: `backend/evals/fixtures/README.md`
- Create: `backend/evals/run_eval.py`
- Create: `backend/tests/test_ocr_worker.py`

- [ ] **Step 1: Record model source, version, license, input normalization, and CPU memory/latency budget.** Reject any model whose terms do not permit the intended distribution and service use.
- [ ] **Step 2: Add evaluation fixtures.** Include fractions, superscripts/subscripts, roots, matrices, multi-line formulas, low-quality photos, and non-math negatives; keep source rights documented.
- [ ] **Step 3: Write worker tests.** Cover valid inference, corrupt input, model timeout, memory limit, result schema, and cleanup deadline.
- [ ] **Step 4: Implement preprocessing and inference.** Normalize orientation and bounds, cap pixels, run under worker resource limits, and return LaTeX plus model version.
- [ ] **Step 5: Implement cleanup.** Delete originals after completion within one hour and all unfinished task files after 24 hours; record counts and failures without file contents.
- [ ] **Step 6: Run evaluation and publish measured limits.** Do not mark the official provider ready until the sample set meets the agreed quality and latency thresholds.
- [ ] **Step 7: Commit.** Commit as `feat: add CPU OCR worker and cleanup`.

### Task 5: Harden deployment and monitoring

**Files:**
- Create: `backend/Dockerfile`
- Create: `backend/docker-compose.production.yml`
- Create: `backend/deploy/healthcheck.sh`
- Create: `backend/deploy/backup.sh`
- Create: `backend/docs/operations.md`
- Create: `backend/tests/test_security_smoke.py`

- [ ] **Step 1: Add security smoke tests.** Verify request-size limits, MIME/content validation, rate limits, authorization, HTTPS redirect behavior, log redaction, and path traversal rejection.
- [ ] **Step 2: Containerize API, worker, and database connectivity.** Run API and worker as non-root users with CPU, memory, disk, and filesystem limits.
- [ ] **Step 3: Add health, metrics, and structured logs.** Include queue depth, latency, failure count, cleanup failures, disk usage, and model version; exclude sensitive payloads.
- [ ] **Step 4: Add encrypted database backup and restore instructions.** Test restore on a clean environment before enabling public OCR.
- [ ] **Step 5: Deploy to a staging path on the existing server.** Verify API, worker, SMTP gating, cleanup, and quota behavior under a bounded load test.
- [ ] **Step 6: Commit.** Commit as `ops: harden OmniConvert OCR deployment`.

### Task 6: Connect client OCR providers and formula workflow

**Files:**
- Create: `lib/core/ocr/ocr_provider.dart`
- Create: `lib/core/ocr/official_ocr_provider.dart`
- Create: `lib/core/ocr/custom_ocr_provider.dart`
- Create: `lib/features/formula/presentation/formula_page.dart`
- Create: `test/core/ocr/provider_contract_test.dart`
- Create: `test/features/formula/formula_page_test.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

**Interfaces:**
- `OcrProvider.recognize(image, mode, idempotencyKey)` returns LaTeX, model version, warnings, and a structured error.
- Official and custom providers implement the same interface and support a configurable timeout.

- [ ] **Step 1: Write provider contract tests against the deterministic mock server.** Cover capability discovery, valid LaTeX, timeout, malformed response, and server error.
- [ ] **Step 2: Run tests and verify failure.** Expected: missing provider implementations.
- [ ] **Step 3: Implement official and custom providers.** Store credentials in secure platform storage, show the destination host, require HTTPS except for explicitly enabled local development, and never log image bytes or tokens.
- [ ] **Step 4: Add formula page.** Include image selection/crop, upload consent, provider choice, editable LaTeX, rendered preview, copy, and retry.
- [ ] **Step 5: Run provider, widget, and browser tests.** Expected: both providers meet the same contract; cloud outage does not disable local tools.
- [ ] **Step 6: Commit.** Commit as `feat: connect replaceable OCR providers`.

