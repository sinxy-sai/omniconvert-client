# Cross-Platform Installers and Release Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 发布用户可以直接安装的 OmniConvert 客户端，并为每个平台提供符合系统习惯的安装或分发格式。

**Architecture:** Flutter 继续负责跨平台应用构建；各平台使用原生或成熟打包工具生成最终分发物。Release workflow 同时上传安装包和可选便携包，官网默认展示安装包，更新清单记录实际文件名、哈希和安装方式。

**Tech Stack:** Flutter 3.47.7、GitHub Actions、Windows NSIS、macOS `hdiutil`/DMG、Linux AppImage 与 DEB、GitHub Releases、Astro 官网下载页。

**Spec:** `docs/superpowers/specs/2026-10-19-omniconvert-design.md` 第 6.6 节和第 8 节。

## Global Constraints

- Release 资产只包含客户端可下载文件，不上传 contributor 头像或临时生成文件。
- Windows 安装程序必须创建开始菜单入口、桌面快捷方式和卸载入口。
- 官网默认展示安装程序；便携 ZIP 作为明确标注的备用下载。
- macOS 使用 DMG 中的 `.app` 和 `/Applications` 快捷入口供用户拖拽安装。未签名构建只能作为测试版；公开推荐下载须完成 Developer ID 签名、公证与 staple。
- Linux 提供 AppImage 和 DEB。AppImage 是可执行便携包，不保证自动生成桌面或应用菜单图标；DEB 安装后须提供应用菜单入口，桌面快捷方式取决于桌面环境和用户选择。
- 每个发布资产必须有 HTTPS 下载地址、文件大小和 SHA-256。
- 发布前必须验证资产名称、版本号、架构和清单内容一致。

---

## Reference implementation: allreal-config

`C:\Users\liubingliang\Desktop\MGI\allreal-config` 当前只有 Windows amd64 和 macOS arm64 两条 Release 工作流，没有 Linux 构建或安装包。

| 平台 | allreal-config 实际做法 | 用户安装体验 |
| --- | --- | --- |
| Windows amd64 | Wails 生成 EXE；NSIS 生成 setup EXE；另发便携 ZIP | 安装向导写入 Program Files、开始菜单、桌面快捷方式和卸载入口 |
| macOS arm64 | Go/Wails 生成 `.app`；`hdiutil` 打包 DMG，内置 Applications 入口；可按凭据签名、公证和 staple | 打开 DMG 后把 App 拖入 Applications；可从 Launchpad 或 Applications 启动 |
| Linux | 没有发布工作流 | 无现成安装体验可复用 |

OmniConvert 沿用 Flutter 应用，不迁移到 Wails。macOS 参考它的 DMG 布局与签名流程；Linux 需要独立设计。当前 OmniConvert Release 的 macOS ZIP 以及 Linux tar.gz 都是便携归档，不是安装程序。`universal` 文件名只有在实际检查包含 arm64 与 x86_64 两种架构后才能使用。

---

### Task 1: Define release asset metadata and download preference

**Files:**
- Modify: `docs/superpowers/specs/2026-10-19-omniconvert-design.md` release section
- Modify: `docs/superpowers/plans/2026-10-19-omniconvert-site-release-plan.md`
- Test: `tests/release_manifest_test.dart` or the existing manifest validation suite

**Interfaces:**
- Produces platform asset IDs and preferred download order consumed by the release workflow and website manifest.

- [ ] **Step 1: Add the asset matrix to the design specification**

Document these exact asset IDs:

```text
windows-installer: OmniConvert-{version}-windows-x64-setup.exe
windows-portable: OmniConvert-{version}-windows-x64.zip
macos-dmg: OmniConvert-{version}-macos-universal.dmg
linux-appimage: OmniConvert-{version}-linux-x64.AppImage
linux-deb: OmniConvert-{version}-linux-x64.deb
android: OmniConvert-{version}-android-arm64.apk
```

- [ ] **Step 2: Define website preference rules**

The download page selects `windows-installer`, `macos-dmg`, and `linux-appimage` as the primary button. It exposes ZIP and DEB under an “其他格式” link when those assets exist.

- [ ] **Step 3: Add manifest validation cases**

Validate that every desktop asset has a platform, architecture, version, HTTPS URL, non-negative size, and 64-character lowercase SHA-256.

- [ ] **Step 4: Run the manifest tests**

Run: `flutter test` and the existing release manifest verification command.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-10-19-omniconvert-design.md docs/superpowers/plans/2026-10-19-omniconvert-site-release-plan.md tests
git commit -m "docs: define platform installer asset matrix"
```

### Task 2: Build the Windows installer

**Files:**
- Modify: `.github/workflows/release.yml`
- Create: `ops/windows/installer.nsi`
- Create: `ops/windows/package.ps1`
- Test: `ops/windows/package.ps1` in a Windows runner

**Interfaces:**
- Consumes the output of `flutter build windows --release`.
- Produces `OmniConvert-{version}-windows-x64-setup.exe` and the existing portable ZIP.

- [ ] **Step 1: Add the NSIS script**

Install the executable under `$PROGRAMFILES64\OmniConvert`, write uninstall metadata, create `$DESKTOP\OmniConvert.lnk`, create a Start Menu shortcut, and optionally launch the app on the finish page.

- [ ] **Step 2: Add the packaging script**

The script checks for `makensis`, passes the release version, packages the Flutter Windows Release directory, and fails if the installer or portable ZIP is missing.

- [ ] **Step 3: Add the Windows workflow steps**

Run Flutter build, create the portable ZIP, invoke NSIS, and upload both artifacts with stable names.

- [ ] **Step 4: Verify installer contents**

On a Windows runner, assert that the installer exists, has the expected version in its filename, and that the portable ZIP remains available.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/release.yml ops/windows
git commit -m "ci: publish Windows installer and portable package"
```

### Task 3: Package macOS and Linux distributions

**Files:**
- Modify: `.github/workflows/release.yml`
- Create: `ops/macos/package-dmg.sh`
- Create: `ops/linux/package-appimage.sh`
- Create: `ops/linux/package-deb.sh`
- Test: macOS and Linux release jobs

**Interfaces:**
- Consumes Flutter macOS and Linux release bundles.
- Produces DMG, AppImage, DEB, and retains the portable Linux archive where practical.

- [ ] **Step 1: Validate the macOS architecture and bundle**

Run `lipo -archs` against `OmniConvert.app/Contents/MacOS/OmniConvert` and native Rust libraries. If any required binary lacks one of the architectures, publish architecture-specific filenames instead of `macos-universal`. Confirm `Info.plist`, app icon, bundle ID, and executable path before packaging.

- [ ] **Step 2: Create the macOS DMG**

Stage `OmniConvert.app` and a symlink to `/Applications` in a temporary directory. Use `hdiutil` to create a writable DMG, set a clear Finder icon layout, then convert to a compressed read-only DMG. Name the asset according to the verified architecture. After mounting, confirm the `.app` and Applications entry are both visible and that drag-to-Applications works.

- [ ] **Step 3: Sign and notarize the macOS public release**

With protected Apple secrets, sign every nested executable and framework, sign the app with hardened runtime, verify with `codesign --verify --deep --strict`, submit the DMG to `notarytool`, and staple the ticket. If credentials are unavailable, publish only a clearly marked unsigned test artifact and do not select it as the recommended public download.

- [ ] **Step 4: Create the Linux AppImage**

Build an AppDir containing the Flutter bundle, executable launcher, `.desktop` entry, and icon; run `appimagetool`; fail if the executable AppImage is not produced. On a clean Linux desktop, verify that granting execute permission and launching it works. Label it as a portable app; do not promise that merely running it creates a desktop shortcut.

- [ ] **Step 5: Create the Linux DEB**

Build a Debian package with `/opt/omniconvert/` application files, a launcher under `/usr/bin/omniconvert`, an icon under `/usr/share/icons/hicolor/`, and a `.desktop` file under `/usr/share/applications/`. Include dependencies needed by the Flutter Linux bundle. On a clean Ubuntu VM, verify install, launch from the app menu, and clean removal via `apt`.

- [ ] **Step 6: Wire the workflow and upload assets**

Add package steps to the macOS and Linux jobs and upload the resulting files to the release job.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/release.yml ops/macos ops/linux
git commit -m "ci: publish macOS DMG and Linux packages"
```

### Task 4: Update the website release manifest and download page

**Files:**
- Modify: `src/pages/download.astro` in `omniconvert-site`
- Modify: `src/lib/releases.ts` in `omniconvert-site`
- Modify: `public/releases/latest.json` in `omniconvert-site`
- Test: site build and release manifest verification

**Interfaces:**
- Consumes GitHub Release assets by exact suffix.
- Produces a primary install button and secondary format links for each desktop platform.

- [ ] **Step 1: Map each platform to its primary installer asset**

Use setup EXE for Windows, signed/notarized DMG for macOS, DEB for supported Debian/Ubuntu systems, AppImage for other supported Linux desktops, and APK for Android. An unsigned DMG must be clearly marked for testing and must not be the recommended public download. Do not show the Web app as a downloadable desktop artifact.

- [ ] **Step 2: Display alternate formats**

Show portable ZIP, AppImage, and DEB only when GitHub reports those assets. Label them with the platform and format so users do not confuse portable files with installers. Explain that Linux AppImage may require setting executable permission and does not automatically create a desktop icon.

- [ ] **Step 3: Preserve system recommendation and manual selection**

Continue highlighting the detected system while keeping all platform cards visible and independently selectable.

- [ ] **Step 4: Run the site checks**

Run: `npm ci`, `npm run build`, and `python tools/verify_artifacts.py dist/releases/latest.json`.

- [ ] **Step 5: Commit**

```bash
git add src/pages/download.astro src/lib/releases.ts public/releases/latest.json
git commit -m "feat: prefer native installers on download page"
```

### Task 5: Publish and verify a tagged release

**Files:**
- Modify: `.github/workflows/release.yml`
- Verify: GitHub Release assets and website download page

- [ ] **Step 1: Run platform jobs on a release candidate tag**

Confirm Windows installer, macOS DMG, Linux AppImage/DEB, Android APK, and optional portable files are all uploaded.

- [ ] **Step 2: Verify checksums and manifest**

Compare every manifest SHA-256 and file size with the corresponding GitHub Release asset.

- [ ] **Step 3: Verify installation behavior**

On Windows, install the setup EXE and confirm the desktop shortcut, Start Menu shortcut, launch behavior, and uninstall entry. On macOS, mount the DMG, drag the app to Applications, verify launch, and check signature/notarization for a public release. On Linux, launch the AppImage after granting execute permission, then install and remove the DEB in a clean Ubuntu VM and confirm the application menu entry.

- [ ] **Step 4: Verify website links**

Open `/download/`, confirm the recommended button points to the installer for the current system, and confirm alternate formats remain available.

- [ ] **Step 5: Record the release result**

Update `docs/implementation-status.md` with the release URL, asset list, checksums verification result, and any unsigned-build notices.
