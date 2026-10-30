# 变更记录 / Changelog

本文件记录 OmniConvert 客户端（`omniconvert-client`）的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

版本事实以 `pubspec.yaml` 与 git tag 为准。本仓库的 tag 为 `v0.1.0`、`v0.1.2`、`v0.1.3`、`v0.1.4`；**不存在 `v0.1.1`**，版本号从 `0.1.0` 直接跳到 `0.1.2`。真实发布产物、签名/公证与各平台安装验收状态见 [实施状态](docs/implementation-status.md)。

## [0.1.4] - 2026-10-30

### 修复 / Fixed

- **Web 端全部本地工具失效**（P0）：本地引擎无条件创建 `ReceivePort` 并 `listen` 接收阶段进度，而 dart2js 不支持 `ReceivePort.listen`，浏览器里每次运行都抛 `UnsupportedError`，PNG→JPEG、JPG→PNG、图片压缩、图片→PDF 全部报「处理没有完成」。Web 上不再创建端口，阶段进度在结果返回后补发。
- **图片压缩会把 PNG 静默变成 JPEG**：压缩按输入文件魔数判断格式，PNG 输入仍输出 PNG（走 zlib 级别），透明通道不再被白色背景替换。
- **切换工具后状态串味**：切换工具会重置已选文件、输出文件名与参数；输出扩展名由工具定义决定，不再出现「压缩 PNG 却给出 `.jpg`」。
- **更新包永远下载失败**：GitHub Release 资产 URL 必然 302 到 CDN，旧实现 `followRedirects = false` 直接抛错。现在手动跟随最多 5 跳，每一跳都要求 HTTPS。
- Web 选文件时 `reader.result` 的类型兜底（`NativeUint8List` 不是 `ByteBuffer`）。

### 新增 / Added

- **一键更新**：设置页支持「检查更新 → 下载（显示进度）→ 校验 SHA-256 → 打开安装包」。Android 交给原生安装器，桌面端用系统默认方式打开，Web 打开下载页。校验失败会删除已下载文件。
- `jpg_to_png`（JPEG → PNG）工具，补齐 png↔jpg 双向。
- 单一事实源 `tool/registry.json` + `tool/generate_registry.py`：客户端 UI、官网能力表与后端 capabilities 全部由它生成，新增格式只需要改一处。
- 工具页重做：拖拽/选择文件、参数控件由注册表生成、处理阶段进度、结果卡片（尺寸、用时、保存位置、下载/打开所在目录）、失败原因可操作（换文件/重试）。

### 变更 / Changed

- **移除 Rust 内核**（`rust/`、`lib/src/rust/`、`flutter_rust_bridge.yaml`）。本地图片工具改为一份纯 Dart 实现（`package:image` + `package:pdf`），所有平台执行同一段代码，Web 与桌面端不再出现行为差异。
- 界面按设计系统重做：统一设计 token（颜色、间距、圆角、字号）、图标集、暗色模式、空状态与骨架屏。
- 公式识别（OCR）明确标注「暂未开放」，不再提供不可用的入口。

### 验证

- `flutter analyze` 0 issue；`flutter test` 117 项通过。
- 浏览器真机点击验证（Chromium/Edge）：4 个本地工具（PNG→JPEG、JPEG→PNG、图片压缩、图片→PDF，其中压缩覆盖 PNG/JPEG 两种输入，共 5 个用例）全部「选文件 → 运行 → 下载 → 校验文件头」通过，压缩后 PNG 仍是 PNG。

## [Unreleased]

### 文档 / Documentation

- 新增 `CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、`SECURITY.md`、本 `CHANGELOG.md` 与 `.editorconfig`。
- 新增 `.github/ISSUE_TEMPLATE/`（bug / feature 表单）、`.github/pull_request_template.md` 与模板配置。
- 补强 `README.md`：项目简介、关键特性、支持工具与格式、平台矩阵、快速开始、目录结构、隐私边界、贡献入口与许可证段落；版本描述与 `pubspec.yaml`（`0.1.3+3`）及 tag `v0.1.3` 对齐。
- 新增 `docs/README.md` 作为仓库文档索引。

本次改动未修改业务代码、CI 工作流、发布数据或依赖。

## [0.1.3] - 2026-10-28

### 新增 / Added

- 完成非 OCR 工具闭环（`b9163d2`）：图片压缩与单图 → PDF 支持 PNG、JPEG、WebP 输入；DOCX / MOBI → PDF 接入服务器转换接口并出现在工具页；任务页展示持久化历史与结构化错误；Windows 原生图片处理在路径不可直接访问时回退到临时文件；改进 Rust 跨语言初始化。
- 为 0.1.3 准备发布流程（`4b48b3c`）：更新 `pubspec.yaml` 版本并调整 release workflow。

### 修复 / Fixed

- Android release 构建改为在 Rust workspace 内执行 `cargo ndk`（`12cb569`）。

### 变更 / Changed

- `pubspec.yaml` 版本提升至 `0.1.3+3`。
- PNG → JPEG 仍只接受 PNG 输入；WebP 支持范围限于图片压缩与单图 → PDF。

### 说明

`v0.1.3` 的正式安装包发布、macOS Developer ID 签名与公证、各平台安装与启动行为仍需在对应环境验收；CI 产物为无签名构建。官方 OCR 仍未开放，公式识别仅支持用户自行配置的 `ocr-provider-v1` 服务。

## [0.1.2] - 2026-10-27

### 新增 / Added

- 跨平台安装包打包（`77504cf`）：Windows 生成 NSIS 安装器与 ZIP，Linux 生成 AppImage、DEB 与 tar.gz，macOS 生成 DMG 与 ZIP；Release job 生成 `SHA256SUMS.txt`。
- 记录跨平台安装器与发布打包计划（`604375d`）。

### 变更 / Changed

- Release 说明中的贡献者头像不再作为发布资产上传（`e653998`）。
- 版本提升至 `0.1.2`（`171d86f`）。

### 修复 / Fixed

- 修复导航与文件工作流（#25，`33ff8f7`）。
- 发布打包在 CI runner 上的兼容性问题（`8d0e675`）、Linux 包应用图标（`f27b9bc`）、NSIS 可执行文件调用（`616bd8d`）。

## [0.1.1] - 未发布

仓库中不存在 `v0.1.1` tag，也没有对应的版本提交；`pubspec.yaml` 从 `0.1.0` 直接升级到 `0.1.2`。为避免伪造发布记录，本文件不列 `0.1.1` 条目。

## [0.1.0] - 2026-10-27

首个公开客户端版本（tag `v0.1.0`）。

### 新增 / Added

- Flutter 六平台工程骨架（Web、Windows、Linux、Android、macOS、iOS）与首页、工具、任务、设置导航。
- 任务模型、状态机、SQLite 持久化、运行中取消与启动时中断恢复。
- Rust 本地核心及 Flutter/Rust 生成绑定；PNG → JPEG、图片压缩、单图 → PDF。
- 浏览器本地图片工具与工具页接入；Web 使用 SQLite WASM + IndexedDB。
- 客户端更新检查、可取消下载、Android 安装器交接与设置页发布状态。
- `ocr-provider-v1` 协议、确定性 mock provider、可替换/自定义 OCR provider 与公式识别流程（官方 OCR 未开放）。
- 六目标 GitHub Actions 构建、标签发布工作流、本地验证脚本与第三方 WASM 许可声明。
- 设计规格、实施路线图与实施状态文档。

### 已知限制

- Windows 桌面构建需要 Visual Studio C++ 工作负载与 Windows SDK；Android 构建需要 Android SDK。
- 官方 OCR 与账号服务属于私有后端边界，当时未开放。
- DOCX/MOBI 桌面转换适配器已实现，但当时尚未接入 Flutter 工具页（0.1.3 起改走服务器转换接口）。
- 真实 tag 发布、macOS 签名与公证、各平台安装行为仍待验证。
