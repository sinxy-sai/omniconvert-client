# 变更记录 / Changelog

本文件记录 OmniConvert 客户端（`omniconvert-client`）的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

版本事实以 `pubspec.yaml` 与 git tag 为准。本仓库的 tag 为 `v0.1.0`、`v0.1.2`、`v0.1.3`；**不存在 `v0.1.1`**，版本号从 `0.1.0` 直接跳到 `0.1.2`。真实发布产物、签名/公证与各平台安装验收状态见 [实施状态](docs/implementation-status.md)。

## [Unreleased] - 2026-10-28

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
