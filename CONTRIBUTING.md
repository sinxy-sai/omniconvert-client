# 贡献指南 / Contributing to OmniConvert Client

感谢你为 OmniConvert 贡献代码、文档或测试。Contributions of all sizes are welcome — bug reports, local tooling, platform fixes, tests and docs.

请先阅读 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告，不要创建公开 issue。本仓库采用 Apache-2.0，提交贡献即表示同意按同一许可证授权。

## 仓库边界

| 仓库 | 职责 |
| --- | --- |
| `omniconvert-client`（本仓库，公开） | Flutter 界面、任务编排、纯 Dart 本地图片/PDF 引擎、客户端更新逻辑 |
| `omniconvert-site`（公开） | 静态官网、`/app/` Web 构建产物、下载与发布清单 |
| `omniconvert-backend`（私有） | 需要上传的文档转换（MOBI/DOCX → PDF）、将来的官方 OCR、账号与配额 |

因此：

- 不要在本仓库提交官方 OCR/账号的后端实现或凭据。
- 不要声称官方 OCR 已可用；当前 OCR 只在页面上显示「暂未开放」。
- 站点发布数据不要在本仓库维护。
- iOS/macOS 目录存在，但 iOS 仅做无签名编译检查，macOS 未做签名/公证与正式安装验证；文档中不要写成「已发布」。

## 开发环境

| 组件 | 版本 / 要求 |
| --- | --- |
| Flutter | **3.47.7**（stable，CI 固定此版本） |
| Dart | **3.13.5** |
| Python | **3.12**（仅用于 `tool/generate_registry.py`；只用标准库，无第三方依赖） |
| Node.js | **22**（可选，仅浏览器端到端冒烟 `tool/e2e/web_smoke.js` 需要） |
| Windows 桌面 | Visual Studio **Desktop development with C++** 工作负载 + Windows SDK；并需开启系统「开发者模式」（Flutter 插件需要符号链接权限） |
| Android | Android SDK + JDK 17（CI 使用 temurin 17） |
| Linux 桌面 | Flutter 官方要求的 GTK/CMake 工具链（clang、cmake、ninja-build、pkg-config、libgtk-3-dev） |
| macOS / iOS | 只能在 macOS + Xcode 上构建；iOS 真机安装需要自己的签名配置 |

**不需要任何原生工具链**：0.1.4 起运行时没有任何原生库，本地图片/PDF 引擎是纯 Dart；`pubspec.yaml` 里只有 Dart/Flutter 依赖（`image`、`pdf`、`sqlite3`、`http`、`crypto` 等），也没有跨语言绑定生成步骤。安装 Flutter SDK 后 `flutter pub get` 即可。

本仓库的 `.toolchains/` 仅供本机开发，已被 Git 忽略；CI 会独立安装固定版本的 Flutter SDK。本地找不到 `flutter` 时，`tool/verify_platforms.ps1` 会尝试使用 `.toolchains/flutter/bin/flutter.bat`。运维凭据保存在 Git 忽略的本地目录中，**不应提交到公开仓库**。

## 初始化

```powershell
flutter pub get
```

生成物（`lib/core/tools/tool_registry.g.dart`、`docs/capabilities.md` 等）已随仓库提交，正常拉取代码后无需额外生成步骤。

## 必跑检查

提交 PR 前至少运行：

```powershell
flutter analyze
flutter test
python tool/generate_registry.py --check
```

- `flutter analyze` 当前是 **0 issue**；新增告警不允许合并。
- `flutter test` 当前 **117 项全部通过**；PR 里请写明测试数量与结果。
- `python tool/generate_registry.py --check` 校验四处生成物与 `tool/registry.json` 一致。改了注册表却忘记重新生成，这项会失败。

改动涉及前端/Web 渲染或引擎行为时，另外执行：

```powershell
flutter build web --release --base-href /app/
node tool/e2e/web_smoke.js --dir build/web --out .work/e2e   # 可选，需 Playwright
```

`web_smoke.js` 在真实浏览器里对每个本机工具走完「选文件 → 开始处理 → 下载 → 校验文件头」，并断言压缩后格式与输入一致。历史上有两类缺陷只能被它抓住：Web 文件选择器的类型错误，以及 PNG 被悄悄重新编码成 JPEG。

## 新增一个工具的真实路径

工具能力的唯一事实源是 `tool/registry.json`，**不要**在 UI 或引擎里硬编码清单、默认值或扩展名。

1. **改注册表**：在 `tool/registry.json` 的 `tools` 数组里加一项，字段包括 `id`（稳定标识，任务历史会持久化它，不要改名）、`name`/`summary`（中英）、`category`、`engine`（`local` 或 `server`）、`inputExtensions`（小写、不带点）、`outputExtension`（或用 `same` 表示保持输入格式）、`options`（`integer` / `enum` / `boolean` / `string`）。
2. **重新生成**：`python tool/generate_registry.py`。它会写出 Dart 侧的工具定义（含参数默认值与取值范围）、官网能力表、后端 capabilities 与 `docs/capabilities.md`。生成物一起提交。
3. **实现执行分支**，二选一：
   - **本机工具** → 在 `lib/core/tools/dart_tool_runner.dart` 里实现：把 tool id 加进 `kDartImageToolIds`，并在 `_runImageJob` 的 `switch` 中加分支。要求：解码失败/损坏输入返回 `InvalidInput` 而不是抛异常穿过 isolate 边界；遵守 `kMaxInputBytes` 与 `kMaxImagePixels`；重活保持在 isolate 内（`compute`）；参数从注册表解析（`_resolveOptions`），不在引擎里写死。
   - **服务器工具** → 在 `lib/core/tools/backend_conversion_runner.dart` 对接 `POST {baseUrl}/conversions/pdf`：沿用 `multipart/form-data`、`Accept: application/pdf`、`x-error-code` 归一化与「返回内容必须是有效 PDF」的校验；新的上传范围必须同步写进 README 的隐私边界。
4. **信号与文案**：所有失败只能抛 `ToolRunException(ToolRunFailure(code, message))`，`code` 必须是 `ToolErrorCode` 里已有的 6 个之一，`message` 是可直接展示的中文；确实需要新错误码时，同时更新 `tool_error.dart`、UI 的 switch 和 `test/core/tools/tool_error_test.dart`。
5. **补测试**：契约测试（注册表里每个工具都要能被 runner 接住）、引擎行为测试（`test/core/tools/dart_tool_runner_test.dart`）、需要上传的工具用假 `http.Client` 覆盖状态码与错误头，页面层加一条 widget 测试。
6. **跑检查**：`flutter analyze`、`flutter test`、`python tool/generate_registry.py --check`、`flutter build web --release --base-href /app/`；涉及 Web 行为再跑一次 `node tool/e2e/web_smoke.js`。

## 平台构建

```powershell
flutter build windows
flutter build linux
flutter build macos
flutter build apk
flutter build ios --no-codesign
flutter build web --release --base-href /app/
```

每条命令只在相应平台及工具链齐备时运行；Apple 平台构建必须在 macOS + Xcode 上执行（macOS 产物由 release workflow 构建，iOS 只在本地做无签名编译检查）。Windows 本机若报符号链接权限错误，先在系统设置里开启「开发者模式」。

一键验证脚本（只跑 analyze + test + 当前平台构建，不涉及原生构建）：

- Windows：`./tool/verify_platforms.ps1`（`-Target windows|android|web`，`-SkipChecks` 可跳过 analyze/test）。
- Linux/macOS：`bash tool/verify_platforms.sh`（Linux 上 `linux|android|web`，macOS 上 `macos|ios-check`）。

CI 产物只是无签名构建（Web、Windows、Linux 为 release，Android 为 debug APK）；正式安装包、签名与发布流程见 `.github/workflows/release.yml`。

## 代码结构

```text
lib/app/                应用外壳、路由、主题与设计 token、通用控件
lib/core/tools/         工具运行时：注册表生成物、纯 Dart 引擎、服务端转换客户端、任务编排、错误码
lib/core/updates/       检查更新、下载、SHA-256 校验、打开安装包 / Android 原生安装器
lib/core/tasks/         任务模型、状态机、SQLite 仓库（Web 走 WASM + IndexedDB）
lib/core/storage/       数据库初始化
lib/core/ocr/           自建 ocr-provider-v1 设置与 HTTP provider（官方 OCR 未开放）
lib/features/           页面：home / tools / tasks / settings / formula
tool/                   registry.json、generate_registry.py、verify_platforms.*、e2e/web_smoke.js
test/                   Flutter/Dart 测试
ops/                    NSIS / AppImage / DEB / DMG 打包脚本
protocol/               ocr-provider-v1 OpenAPI 与 mock provider
docs/                   架构、能力、实施状态、设计规格（索引见 docs/README.md）
web/ windows/ linux/ macos/ android/ ios/   平台工程与 Web 资源
```

## 提交规范

- 从 `main` 创建分支：`feat/…`、`fix/…`、`docs/…`、`test/…`、`ci/…`。
- 一个 PR 聚焦一个改动；提交信息建议使用 Conventional Commits（`feat:`、`fix:`、`docs:`、`test:`、`ci:`、`chore:`）。
- 不要提交 `build/`、`.dart_tool/`、`.toolchains/`、`ops/ssh/` 或任何密钥。
- 修改行为时同步更新 `docs/implementation-status.md`；涉及隐私边界时同时更新 README 与相关文档；改动工具清单时先改 `tool/registry.json` 再重新生成。

## PR 检查清单

- [ ] `flutter analyze` 通过（0 issue）。
- [ ] `flutter test` 通过，并在 PR 中写明测试数量/结果。
- [ ] 改了 `tool/registry.json` 时已跑 `python tool/generate_registry.py` 并提交全部生成物；`--check` 通过。
- [ ] 新增/修改本机工具时，损坏输入返回 `InvalidInput` 而不是崩溃，且未被 isolate 内的异常穿透成 `RemoteError`。
- [ ] 新增/修改服务端工具时，上传范围已写进 README 隐私边界，且错误码/中文文案可直接展示。
- [ ] 涉及 UI 的改动附截图；涉及平台行为的改动说明已测试的平台。
- [ ] 涉及 Web 的改动已 `flutter build web --release --base-href /app/`，条件允许时跑过 `tool/e2e/web_smoke.js`。
- [ ] 未夸大未验证能力（官方 OCR、iOS/macOS 发布状态、macOS 签名与公证、正式安装包）。
- [ ] 未提交密钥、真实用户文件或构建产物。
- [ ] 新增依赖/资源时确认许可证兼容，必要时更新 `THIRD_PARTY_NOTICES.md`。

## 发布流程（维护者）

1. 更新 `pubspec.yaml` 的 `version`，同步 README、`docs/implementation-status.md` 与 `CHANGELOG.md` 的版本描述。
2. 打 tag `vX.Y.Z`；`release.yml` 会校验 tag 与 `pubspec.yaml` 版本一致。
3. CI 构建：Android APK（需 `ANDROID_KEYSTORE_BASE64` 等签名密钥）、Windows NSIS + ZIP、Linux AppImage/DEB/tar.gz、macOS DMG/ZIP，Release job 生成 `SHA256SUMS.txt`。
4. 配置 `SITE_REPO_TOKEN` 时自动触发官网 `repository_dispatch`；否则手动触发站点重建。
5. 核对 GitHub Release 资产、哈希、`releases/latest.json` 清单后再宣布发布——客户端的更新检查直接读这份清单。

真实 tag 发布、macOS Developer ID 签名与公证、各平台安装行为仍需在对应 runner/设备上验收；在这些验证完成前，不要在文档中写「已发布/已验证」。

## 安全与联系方式

- 安全漏洞：见 [SECURITY.md](SECURITY.md)（私密报告，不要开公开 issue）。
- 行为准则事项：见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
- 一般问题与建议：GitHub Issues（使用模板）。