# OmniConvert Implementation Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this roadmap task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build OmniConvert as a low-cost, production-quality cross-platform file and handwritten-math tool with an open client and replaceable OCR providers.

**Architecture:** The work is split into four independently testable plans: client foundation, local processing, website/release delivery, and OCR/account services. The Flutter client owns UI and orchestration; Rust owns local processing; the website publishes downloads and documentation; the private backend owns official OCR and quotas.

**Tech Stack:** Flutter/Dart, Rust with `flutter_rust_bridge`, Astro static output, Python/FastAPI, Docker, PostgreSQL, and a CPU-capable small OCR model.

**Spec:** `docs/superpowers/specs/2026-10-19-omniconvert-design.md`

## Global Constraints

- Application name: `OmniConvert`.
- Website: `https://www.sinxysai.site/`.
- Local tools require no account and default to no upload.
- Official OCR requires login and uses free quotas; payment is out of scope.
- Android distributes APK from the website; iOS public native distribution is out of scope for phase one and uses PWA.
- Public client and local core use Apache-2.0; official backend remains private.
- Do not add GPU, paid CDN, object storage, SMS, or payment as phase-one dependencies.
- macOS and iOS builds run only on macOS CI; Windows/Linux remain the primary development environments.

## Plan order

1. `2026-10-19-omniconvert-client-foundation-plan.md` — repository layout, task model, Flutter/Rust bridge, CI matrix.
2. `2026-10-19-omniconvert-local-tools-plan.md` — local image tools, document adapters, history, and failure recovery.
3. `2026-10-19-omniconvert-site-release-plan.md` — website, downloads, release manifest, APK update flow, and PWA shell.
4. `2026-10-19-omniconvert-ocr-service-plan.md` — provider protocol, private CPU OCR service, accounts, quotas, and security.

Each plan ends with an independently testable deliverable. Do not start a later plan until its predecessor's tests and documented acceptance checks pass.

