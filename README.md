# OmniConvert

OmniConvert 是面向学生和研究者的本地优先文件与公式工具。本仓库包含 Flutter 客户端、Rust 本地核心和公开的设计规格，采用 [Apache-2.0](LICENSE) 许可证。

**当前状态：客户端 0.1.3**（`pubspec.yaml` 为 `0.1.3+3`，最新 tag 为 `v0.1.3`）。首页、工具、任务和设置导航可运行；图片 → JPEG（仅 PNG 输入）、图片压缩和单图 → PDF（支持 PNG、JPEG 和 WebP 输入）已接入本地处理。DOCX / MOBI → PDF 通过服务器转换接口处理，需要联网。公式识别仍依赖用户明确配置的 OCR 服务；官方 OCR 服务和账号服务属于独立的私有后端边界，当前未标记为可用。

> 版本线与发布状态以 `pubspec.yaml`、git tag 和 GitHub Release 为准。真实 tag 发布产物、macOS 签名与公证、各平台安装验收仍在验证中，详见 [实施状态](docs/implementation-status.md)。

## 关键特性

- **本地优先**：图片 → JPEG、图片压缩、单图 → PDF 由 Rust 核心在本机完成，Web 端在浏览器内存中完成；文件不会因为打开工具而自动上传。
- **边界明确**：只有 DOCX / MOBI → PDF 通过服务器转换接口上传文件；官方 OCR 暂缓，自建 OCR provider 由用户显式配置。
- **任务可恢复**：任务状态机、SQLite 持久化、运行中取消，启动时把遗留的“处理中”任务标记为“已中断”并由用户决定是否重试。
- **跨平台工程**：Web/PWA、Windows、Linux、Android 已配置构建与打包；macOS 有构建配置但未发布验证；iOS 仅做无签名编译检查。
- **可控更新**：客户端读取发布清单、校验下载内容，Android 安装交给系统安装器确认，不承诺静默安装。

## 支持的工具与格式

| 工具 | 输入 | 输出 | 执行位置 |
| --- | --- | --- | --- |
| 图片 → JPEG（`png_to_jpeg`） | PNG | JPEG（质量 1–100） | 本机 Rust 核心 / 浏览器内存 |
| 图片压缩（`compress_image`） | PNG、JPEG、WebP | JPEG | 本机 Rust 核心 / 浏览器内存 |
| 单图 → PDF（`image_to_pdf`） | PNG、JPEG、WebP | PDF（A4，自动方向） | 本机 Rust 核心 / 浏览器内存 |
| DOCX → PDF（`docx_to_pdf`） | DOCX | PDF | 服务器转换接口（需联网并上传文件） |
| MOBI → PDF（`mobi_to_pdf`） | MOBI | PDF | 服务器转换接口（需联网并上传文件） |
| 手写公式 → LaTeX | 图片 | LaTeX | 用户配置的 `ocr-provider-v1` 服务（官方 OCR 暂缓） |

补充说明：

- Web 端图片工具在当前页面内存中处理，结果由浏览器下载；原生端由 Rust 核心处理并在任务结束后清理临时文件。
- DOCX / MOBI 转换依赖私有后端服务，客户端只负责上传与结果保存；服务端实现不在本仓库，正式发布前仍需端到端验证。
- 桌面外部转换器（LibreOffice、Calibre）的检测、版本记录与进程安全边界见 [桌面外部转换器](docs/docs/external-converters.md)；当前工具页按服务器转换路径接入。
- 公式识别协议见 [自建公式识别 Provider](docs/docs/self-hosted-provider.md)。官方 OCR、账号与配额属于私有后端，当前未开放。

## 平台矩阵

| 平台 | 状态 | 构建与验证 | 说明 |
| --- | --- | --- | --- |
| Web / PWA | 可用 | CI 构建，官网 `/app/` 发布 | 使用 SQLite WASM + IndexedDB；不加载原生动态库；官网发布清单当前为 `0.1.2` |
| Windows x64 | 构建与打包配置完成，待发布验证 | CI 未签名调试产物；NSIS 安装器 + ZIP 打包脚本 | 需 Visual Studio C++ 工作负载与 Windows SDK |
| Linux x64 | 构建与打包配置完成，待发布验证 | CI 未签名调试产物；AppImage、DEB、tar.gz | 需 GTK/CMake 工具链 |
| Android arm64 | 构建与打包配置完成，待发布验证 | split-per-ABI；正式 tag 构建需发布签名密钥 | 未做真机安装验收 |
| macOS universal | 构建配置存在，未验证 | CI 构建 DMG/ZIP，未签名、未公证 | 正式发布方案待验证 |
| iOS arm64 | 仅无签名编译检查 | `flutter build ios --no-codesign` | 目录存在，未发布、未验证 |

> “构建与打包配置完成”只表示 CI 与脚本已就绪，不代表已有正式安装包。安装包与下载状态以 GitHub Release 和官网发布清单为准。

## 快速开始

### 开发环境

- Flutter **3.47.7**，Dart **3.13.5**。
- Rust stable；本地验证版本为 **1.99.1**。
- Windows 桌面构建需要 Visual Studio 的 **Desktop development with C++** 工作负载及 Windows SDK。
- Windows 上使用 Flutter 插件还需启用系统“开发者模式”，以便创建插件符号链接。
- Android 构建需要 Android SDK；Linux 桌面构建需要 Flutter 官方列出的 GTK/CMake 工具链。
- macOS 和 iOS 构建只能在 macOS 与 Xcode 环境中执行。iOS 真机安装需要开发者自己的签名配置。

本仓库的 `.toolchains/` 仅供本机开发，已被 Git 忽略；CI 会独立安装固定版本的 Flutter SDK。运维凭据保存在 Git 忽略的本地目录中，不应提交到公开仓库。

### 初始化

```powershell
flutter pub get
cargo build --manifest-path rust/Cargo.toml
```

### 本地验证

```powershell
flutter analyze
flutter test
cargo test --manifest-path rust/Cargo.toml
cargo build --manifest-path rust/Cargo.toml
flutter test test/bridge_smoke_test.dart
flutter build web
```

Rust/Dart 绑定由 `flutter_rust_bridge_codegen` **2.13.0** 生成。修改 `rust/src/api.rs` 后，在仓库根目录运行：

```powershell
flutter_rust_bridge_codegen generate
```

`flutter_rust_bridge.yaml` 控制代码生成。跨语言健康检查需先执行 `cargo build`，再运行指定测试；Web 客户端不加载原生动态库。原生安装包的 Rust 库打包方式已在 release workflow 中接入，仍需在各平台实际验收。

最近任务保存在应用数据目录的 SQLite 数据库中；Web 使用 IndexedDB 承载 SQLite WASM 文件系统。Web 二进制来源和校验值见 [第三方声明](THIRD_PARTY_NOTICES.md)。启动时，原来处于“处理中”的任务会改为“已中断”，由用户决定是否重试。

### 平台构建

```powershell
flutter build windows
flutter build linux
flutter build macos
flutter build apk
flutter build ios --no-codesign
flutter build web --release --base-href /app/
```

每条命令只在相应平台及工具链齐备时运行。Apple 平台构建由 macOS CI 检查。

一键验证脚本：Windows 用 `./tool/verify_platforms.ps1`，Linux/macOS 用 `bash tool/verify_platforms.sh`。脚本先检查 Flutter、Rust 和跨语言测试，再构建当前平台。Windows 也可运行 `./tool/verify_platforms.ps1 -Target web` 验证 Web；Linux 可指定 `android` 或 `web`。GitHub Actions 在六个目标上分别编译，产物名采用 `OmniConvert-{version}-{platform}-{arch}`。CI 产物是无签名的调试预览；安装包打包脚本（NSIS、AppImage/DEB、DMG/ZIP）已在 release workflow 中接入，但真实 tag 发布、签名、公证与安装验收仍在进行中。

## 目录结构

```text
.
├── lib/                    # Flutter 应用：app / core / features / src/rust 生成绑定
├── rust/                   # Rust 本地核心：图片工具、文档适配器、进程边界
│   ├── src/api.rs          # 跨语言入口（修改后需重新生成绑定）
│   ├── src/tools/          # image / docx / mobi / process / errors
│   └── tests/              # Rust 集成测试
├── test/                   # Flutter/Dart 测试（含跨语言冒烟测试）
├── tool/                   # verify_platforms.ps1 / verify_platforms.sh
├── ops/                    # Windows NSIS、Linux AppImage/DEB、macOS DMG 打包脚本
├── protocol/               # ocr-provider-v1 OpenAPI、mock provider 与契约测试
├── docs/                   # 实施状态、设计规格与说明（索引见 docs/README.md）
├── web/ android/ windows/ linux/ macos/ ios/   # 平台工程与 Web 资源
├── .toolchains/            # 本地 Flutter/工具链（Git 忽略，不提交）
└── .github/workflows/      # client.yml（六平台构建）与 release.yml（标签发布）
```

## 隐私边界

| 场景 | 文件去向 | 说明 |
| --- | --- | --- |
| 图片 → JPEG / 图片压缩 / 单图 → PDF | 留在本机 | 原生端由 Rust 核心处理；Web 端在页面内存中处理，结果由浏览器下载 |
| DOCX / MOBI → PDF | 上传到服务器 | 发送到 `https://www.sinxysai.site/api/v1/conversions/pdf` 转换；敏感文件请改用本机工具 |
| 公式识别 | 发送到用户配置的服务 | 官方 OCR 暂缓；自建 provider 的地址与凭据由用户自行管理 |
| 更新检查 | 只读取发布清单 | 下载内容会按清单校验；Android 安装需用户在系统安装器中确认 |

- 不要把他人的文档、OCR 凭据或签名密钥粘贴到 issue/PR；本地绝对路径也可能包含个人信息，报告问题前请脱敏。
- 隐私说明的权威页面是官网 `/privacy/`；本仓库只描述客户端行为。

## 文档

文档索引见 [docs/README.md](docs/README.md)：实施状态（含跨仓库边界）、外部转换器、自建 OCR provider、设计规格与实施计划。

设计与实施顺序见 [实施路线图](docs/superpowers/plans/2026-10-19-omniconvert-roadmap.md)。

## 贡献

欢迎提交 issue 与 PR。开始前请阅读：

- [CONTRIBUTING.md](CONTRIBUTING.md)：开发环境、工具链、测试命令、代码生成、平台构建、提交与发布流程。
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)：行为准则。
- [SECURITY.md](SECURITY.md)：安全漏洞请私下报告，不要创建公开 issue。

## 许可证

本项目采用 [Apache-2.0](LICENSE) 许可证。第三方组件与 WASM 二进制声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。提交贡献即表示同意按同一许可证授权。

本仓库对应公开客户端 `omniconvert-client`；官网源代码放在独立的公开仓库 `omniconvert-site`，官方服务端放在私有仓库 `omniconvert-backend`。变更记录见 [CHANGELOG.md](CHANGELOG.md)。
