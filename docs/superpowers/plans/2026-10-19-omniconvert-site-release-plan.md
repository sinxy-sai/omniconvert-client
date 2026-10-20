# OmniConvert Website and Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the OmniConvert website, documentation, release manifest, platform downloads, Android APK update flow, and PWA entry at `https://www.sinxysai.site/`.

**Architecture:** The site is a static build deployed behind the existing HTTPS server. Release artifacts are immutable files with SHA-256 hashes. The Flutter client reads a version manifest over HTTPS; Android downloads the APK and delegates installation to the system installer.

**Tech Stack:** Astro static output, Markdown documentation, Nginx, GitHub Actions, JSON release manifest, and Flutter Web.

**Spec:** `docs/superpowers/specs/2026-10-19-omniconvert-design.md`

## Global Constraints

- Canonical website is `https://www.sinxysai.site/`.
- Required paths are `/`, `/download/`, `/releases/`, `/docs/`, and `/app/`.
- Download pages must show platform, architecture, version, size, SHA-256, and release notes.
- Android updates use a signed APK and user-confirmed system installation; no silent update promise.
- iOS phase one uses PWA; do not advertise public native IPA installation.

### Task 1: Build the static website shell

**Files:**
- Create: `site/package.json`
- Create: `site/astro.config.mjs`
- Create: `site/src/pages/index.astro`
- Create: `site/src/pages/download.astro`
- Create: `site/src/pages/releases.astro`
- Create: `site/src/pages/docs/index.astro`
- Create: `site/src/pages/privacy.astro`
- Create: `site/src/lib/releases.ts`
- Create: `site/src/styles/site.css`
- Create: `site/public/robots.txt`
- Create: `site/README.md`

- [ ] **Step 1: Configure Astro for static output.** Pin dependencies in `site/package-lock.json`; no Node server is required at runtime.
- [ ] **Step 2: Write the homepage and privacy page.** Explain local-first processing, formula-to-LaTeX, supported platforms, open-source client, Web/PWA entry, upload consent, official file retention, self-hosted provider boundaries, and deletion controls without claiming unsupported features.
- [ ] **Step 3: Add download, release, and documentation templates.** Templates must consume release metadata rather than hardcoding stale links.
- [ ] **Step 4: Add responsive styles and accessible navigation.** Verify keyboard navigation, contrast, headings, and mobile layout.
- [ ] **Step 5: Run the site build and link checker.** Expected: static output builds without broken internal links.
- [ ] **Step 6: Commit.** Commit as `feat: add OmniConvert website shell`.

### Task 2: Define release manifest and artifact verification

**Files:**
- Create: `site/public/releases/latest.json`
- Create: `site/tools/generate_manifest.py`
- Create: `site/tools/verify_artifacts.py`
- Create: `site/tests/test_manifest.py`
- Modify: `site/src/pages/download.astro`

**Interfaces:**
- Manifest fields: `platform`, `arch`, `version`, `minimumSupportedVersion`, `downloadUrl`, `size`, `sha256`, `signature`, `releaseNotes`.
- `generate_manifest.py` emits deterministic JSON sorted by platform and architecture.
- `verify_artifacts.py` exits non-zero if a declared file, size, or SHA-256 does not match.

- [ ] **Step 1: Write manifest and verification tests.** Cover missing field, duplicate platform/architecture pair, invalid URL scheme, hash mismatch, and deterministic output.
- [ ] **Step 2: Run `python -m pytest site/tests/test_manifest.py -v`.** Expected: failures before implementation.
- [ ] **Step 3: Implement generation and verification.** Accept artifact paths as arguments; never download arbitrary URLs during verification.
- [ ] **Step 4: Render the download page from the manifest.** Show unavailable platforms clearly and link the PWA for iOS users.
- [ ] **Step 5: Run tests and a sample manifest generation.** Expected: PASS.
- [ ] **Step 6: Commit.** Commit as `feat: add verified release manifest tooling`.

### Task 3: Add PWA shell and Android update contract

**Files:**
- Create: `site/src/pages/app.astro`
- Create: `site/public/app/manifest.webmanifest`
- Create: `site/public/app/service-worker.js`
- Create: `site/docs/android-updates.md`
- Modify: `site/src/pages/download.astro`

- [ ] **Step 1: Add the PWA manifest and service worker.** Cache only the static shell and versioned assets; do not cache user files or OCR results.
- [ ] **Step 2: Document Android update behavior.** Explain browser download, unknown-source permission, signature continuity, checksum verification, and user confirmation.
- [ ] **Step 3: Add a release-check contract test fixture.** Verify the client-facing manifest can distinguish update available, current, minimum-version blocked, and invalid-manifest states.
- [ ] **Step 4: Run the static build and inspect the PWA manifest.** Expected: valid icons, start URL `/app/`, HTTPS scope, and no private API keys.
- [ ] **Step 5: Commit.** Commit as `feat: add PWA and Android release flow`.

### Task 4: Add deployment and release CI

**Files:**
- Create: `.github/workflows/site.yml`
- Create: `site/deploy/nginx-omniconvert.conf.example`
- Create: `site/deploy/README.md`

- [ ] **Step 1: Add CI.** Build the site, run link and manifest checks, and publish a versioned artifact.
- [ ] **Step 2: Add deployment documentation.** Describe static files, `/app/`, `latest.json`, cache headers, HTTPS-only redirects, and atomic release directory switching.
- [ ] **Step 3: Add cache rules.** Immutable artifacts use versioned URLs; `latest.json` and release pages use short revalidation.
- [ ] **Step 4: Run CI locally where possible and validate the generated Nginx configuration syntax on the deployment server.** Expected: no broken route or certificate assumption.
- [ ] **Step 5: Commit.** Commit as `ci: publish OmniConvert website artifacts`.

### Task 5: Connect client version checks to release metadata

**Files:**
- Create: `lib/core/updates/release_manifest.dart`
- Create: `lib/core/updates/update_checker.dart`
- Create: `lib/core/updates/android_installer.dart`
- Create: `test/core/updates/update_checker_test.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

**Interfaces:**
- `UpdateChecker.check(currentVersion, platform, arch)` returns `current`, `available`, `required`, or `invalidManifest`.
- `AndroidInstaller.installVerifiedApk(path, expectedSha256)` verifies the file, then invokes the Android system installer with user confirmation.

- [ ] **Step 1: Write update tests.** Cover current version, newer version, minimum-version block, wrong platform, invalid HTTPS URL, hash mismatch, and cancelled download.
- [ ] **Step 2: Run targeted tests and verify they fail.** Expected: missing manifest parser and update checker.
- [ ] **Step 3: Implement manifest parsing and update comparison.** Reject unknown architectures and non-HTTPS artifact URLs.
- [ ] **Step 4: Implement Android download and installation handoff.** Save to app-private storage, verify SHA-256 and package signature continuity, and use a content URI with Android's package installer; never request silent installation.
- [ ] **Step 5: Add settings UI.** Show installed version, last check, release notes, download progress, and actionable verification errors.
- [ ] **Step 6: Run unit tests and install an upgrade over a signed older APK on a test device or emulator.** Expected: data preserved and system confirmation shown.
- [ ] **Step 7: Commit.** Commit as `feat: add client update checks and Android installer handoff`.

