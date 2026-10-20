# OmniConvert

OmniConvert 是面向学生和研究者的本地优先文件与公式工具。本仓库包含 Flutter 客户端、Rust 本地核心和公开的设计规格，采用 [Apache-2.0](LICENSE) 许可证。

**当前状态：客户端基础阶段。** 首页、工具、任务和设置导航可运行；转换、压缩与公式识别尚未开放。界面中的工具卡片会标明“规划中”。本地工具设计为访客可用，官方 OCR 服务和账号服务以后在私有后端实现。

## 开发环境

- Flutter **3.47.7**，Dart **3.13.5**。
- Rust stable；本地验证版本为 **1.99.1**。
- Windows 桌面构建需要 Visual Studio 的 **Desktop development with C++** 工作负载及 Windows SDK。
- Windows 上使用 Flutter 插件还需启用系统“开发者模式”，以便创建插件符号链接。
- Android 构建需要 Android SDK；Linux 桌面构建需要 Flutter 官方列出的 GTK/CMake 工具链。
- macOS 和 iOS 构建只能在 macOS 与 Xcode 环境中执行。iOS 真机安装需要开发者自己的签名配置。

本仓库的 `.toolchains/` 仅供本机开发，已被 Git 忽略；CI 会独立安装固定版本的 Flutter SDK。运维凭据保存在 Git 忽略的本地目录中，不应提交到公开仓库。

## 本地验证

```powershell
flutter pub get
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

`flutter_rust_bridge.yaml` 控制代码生成。跨语言健康检查需先执行 `cargo build`，再运行指定测试；Web 客户端不加载原生动态库。原生安装包的 Rust 库打包方式将在平台构建阶段验证。

最近任务保存在应用数据目录的 SQLite 数据库中；Web 使用 IndexedDB 承载 SQLite WASM 文件系统。Web 二进制来源和校验值见 [第三方声明](THIRD_PARTY_NOTICES.md)。启动时，原来处于“处理中”的任务会改为“已中断”，由用户决定是否重试。

平台构建命令：`flutter build windows`、`flutter build linux`、`flutter build macos`、`flutter build apk`、`flutter build ios --no-codesign`、`flutter build web`。每条命令只在相应平台及工具链齐备时运行。Apple 平台构建由 macOS CI 检查。

一键验证脚本：Windows 用 `./tool/verify_platforms.ps1`，Linux/macOS 用 `bash tool/verify_platforms.sh`。脚本先检查 Flutter、Rust 和跨语言测试，再构建当前平台。Windows 也可运行 `./tool/verify_platforms.ps1 -Target web` 验证 Web；Linux 可指定 `android` 或 `web`。GitHub Actions 在六个目标上分别编译，产物名采用 `OmniConvert-{version}-{platform}-{arch}`。CI 产物只是无签名的调试预览，正式安装包、哈希和发布流程将在后续发布阶段实现。

设计与实施顺序见 [实施路线图](docs/superpowers/plans/2026-10-19-omniconvert-roadmap.md)。本仓库对应公开客户端 `omniconvert-client`；官网源代码将放在独立的公开仓库 `omniconvert-site`，官方服务端放在私有仓库 `omniconvert-backend`。
