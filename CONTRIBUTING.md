# 贡献指南 / Contributing to OmniConvert Client

感谢你为 OmniConvert 贡献代码、文档或测试。Contributions of all sizes are welcome — bug reports, local tooling, platform fixes, tests and docs.

请先阅读 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告，不要创建公开 issue。本仓库采用 Apache-2.0，提交贡献即表示同意按同一许可证授权。

## 仓库边界

| 仓库 | 职责 |
| --- | --- |
| `omniconvert-client`（本仓库，公开） | Flutter 界面、任务编排、本地图片处理、Rust 核心、客户端更新逻辑 |
| `omniconvert-site`（公开） | 静态官网、`/app/` Web 构建产物、下载与发布清单 |
| `omniconvert-backend`（私有） | 需要上传同意的 OCR、文档转换、账号、配额与异步队列 |

因此：

- 不要在本仓库提交官方 OCR/账号的后端实现或凭据。
- 不要声称官方 OCR 已可用；当前 OCR 只支持用户显式配置的 `ocr-provider-v1` 服务。
- 站点发布数据不要在本仓库维护。
- iOS/macOS 目录存在，但 iOS 仅做无签名编译检查，macOS 未做签名/公证与正式安装验证；文档中不要写成“已发布”。

## 开发环境

| 组件 | 版本 / 要求 |
| --- | --- |
| Flutter | **3.47.7**（stable） |
| Dart | **3.13.5** |
| Rust | stable；本地验证版本 **1.99.1** |
| flutter_rust_bridge_codegen | **2.13.0**（与 `flutter_rust_bridge` 运行时一致） |
| Windows 桌面 | Visual Studio **Desktop development with C++** 工作负载 + Windows SDK |
| Windows 插件 | 启用系统“开发者模式”（创建插件符号链接需要） |
| Android | Android SDK + JDK 17（CI 使用 temurin 17） |
| Linux 桌面 | Flutter 官方要求的 GTK/CMake 工具链（clang、cmake、ninja-build、pkg-config、libgtk-3-dev） |
| macOS / iOS | 只能在 macOS + Xcode 上构建；iOS 真机安装需要自己的签名配置 |

本仓库的 `.toolchains/` 仅供本机开发，已被 Git 忽略；CI 会独立安装固定版本的 Flutter SDK。本地找不到 `flutter` 时，`tool/verify_platforms.ps1` 会尝试使用 `.toolchains/flutter/bin/flutter.bat`。运维凭据保存在 Git 忽略的本地目录中，**不应提交到公开仓库**。

## 初始化

```powershell
flutter pub get
cargo build --manifest-path rust/Cargo.toml
```

Rust/Dart 绑定由 `flutter_rust_bridge_codegen` 生成；修改 `rust/src/api.rs` 后，在仓库根目录运行：

```powershell
flutter_rust_bridge_codegen generate
```

`flutter_rust_bridge.yaml` 控制代码生成。请一并提交生成后的 `lib/src/rust/*` 与 `rust/src/frb_generated.rs`。

## 必跑检查

提交 PR 前至少运行：

```powershell
flutter analyze
flutter test
cargo test --manifest-path rust/Cargo.toml
cargo build --manifest-path rust/Cargo.toml
flutter test test/bridge_smoke_test.dart   # 需先 cargo build
```

`flutter test test/bridge_smoke_test.dart` 是 Dart→Rust 跨语言健康检查；Web 客户端不加载原生动态库，因此 Web 相关改动请另外执行：

```powershell
flutter build web --release --base-href /app/
```

## 平台构建

```powershell
flutter build windows
flutter build linux
flutter build macos
flutter build apk
flutter build ios --no-codesign
flutter build web --release --base-href /app/
```

每条命令只在相应平台及工具链齐备时运行；Apple 平台构建由 CI 在 macOS runner 上检查。

一键验证脚本：

- Windows：`./tool/verify_platforms.ps1`（`-Target windows|android|web`，`-SkipChecks` 可跳过 analyze/test）。
- Linux/macOS：`bash tool/verify_platforms.sh`（`linux|android|web` 在 Linux，`macos|ios-check` 在 macOS）。

脚本先检查 Flutter、Rust 和跨语言测试，再构建当前平台。CI 产物只是无签名的调试预览；正式安装包、签名与发布流程见 `.github/workflows/release.yml`。

## 代码结构

```text
lib/                 Flutter 应用（app / core / features / src/rust 生成绑定）
rust/src/api.rs      跨语言入口
rust/src/tools/      本地工具（image、docx、mobi、process、errors）
rust/tests/          Rust 集成测试
test/                Flutter/Dart 测试
tool/                平台验证脚本
ops/                 NSIS / AppImage / DEB / DMG 打包脚本
protocol/            ocr-provider-v1 OpenAPI 与 mock provider
docs/                实施状态、设计规格与说明（索引见 docs/README.md）
```

新增本地工具的一般路径：Rust 侧定义请求/结果契约与错误码 → `rust/src/api.rs` 暴露入口 → 重新生成绑定 → Dart `ToolRunner` 接入 → 工具页与任务服务 → Rust + Dart 测试。图片工具必须在本地完成；DOCX/MOBI 的服务器转换路径属于客户端与私有后端的协议边界，改动需格外谨慎并把上传范围写清楚。

## 提交规范

- 从 `main` 创建分支：`feat/…`、`fix/…`、`docs/…`、`test/…`、`ci/…`。
- 一个 PR 聚焦一个改动；提交信息建议使用 Conventional Commits（`feat:`、`fix:`、`docs:`、`test:`、`ci:`、`chore:`）。
- 不要提交 `build/`、`.dart_tool/`、`rust/target/`、`.toolchains/`、`ops/ssh/` 或任何密钥。
- 修改行为时同步更新 `docs/implementation-status.md`；涉及隐私边界时同时更新 README 与相关文档。

## PR 检查清单

- [ ] `flutter analyze` 通过。
- [ ] `flutter test` 通过，并在 PR 中写明测试数量/结果。
- [ ] `cargo test --manifest-path rust/Cargo.toml` 通过。
- [ ] 修改 `rust/src/api.rs` 时已重新生成绑定并提交生成文件。
- [ ] 涉及 UI 的改动附截图；涉及平台行为的改动说明已测试的平台。
- [ ] 未夸大未验证能力（官方 OCR、iOS/macOS 发布状态、正式安装包）。
- [ ] 未提交密钥、真实用户文件或构建产物。
- [ ] 新增依赖/资源时确认许可证兼容，必要时更新 `THIRD_PARTY_NOTICES.md`。

## 发布流程（维护者）

1. 更新 `pubspec.yaml` 的 `version`，同步 README 与 `docs/implementation-status.md` 的版本描述。
2. 打 tag `vX.Y.Z`；`release.yml` 会校验 tag 与 `pubspec.yaml` 版本一致。
3. CI 构建：Android arm64 APK（需 `ANDROID_KEYSTORE_BASE64` 等签名密钥）、Windows NSIS + ZIP、Linux AppImage/DEB/tar.gz、macOS DMG/ZIP，Release job 生成 `SHA256SUMS.txt`。
4. 配置 `SITE_REPO_TOKEN` 时自动触发官网 `repository_dispatch`；否则手动触发站点重建。
5. 核对 GitHub Release 资产、哈希和官网清单后再宣布发布。

真实 tag 发布、macOS Developer ID 签名与公证、各平台安装行为仍需在对应 runner/设备上验收；在这些验证完成前，不要在文档中写“已发布/已验证”。

## 安全与联系方式

- 安全漏洞：见 [SECURITY.md](SECURITY.md)（私密报告，不要开公开 issue）。
- 行为准则事项：见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
- 一般问题与建议：GitHub Issues（使用模板）。
