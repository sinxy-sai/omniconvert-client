<div align="center">

# OmniConvert

**图片、PDF、电子书与文档转换，一个工作台就够了。**

从图片格式转换、压缩到电子书和文档转 PDF，OmniConvert 把常用文件工具集中到一个清爽的跨平台工作台。图片工具直接在设备上运行，文档转换按需使用在线服务，让学习、研究和日常办公中的文件处理更顺手。

<a href="https://github.com/sinxy-sai/omniconvert-client/releases"><img src="https://img.shields.io/github/v/release/sinxy-sai/omniconvert-client?style=flat-square&label=release" alt="Latest release"></a>
<a href="https://github.com/sinxy-sai/omniconvert-client/actions"><img src="https://img.shields.io/github/actions/workflow/status/sinxy-sai/omniconvert-client/client.yml?style=flat-square&label=CI" alt="CI status"></a>
<a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter 3.47.7"></a>
<a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart&logoColor=white&style=flat-square" alt="Dart 3.13.5"></a>
<a href="LICENSE"><img src="https://img.shields.io/github/license/sinxy-sai/omniconvert-client?style=flat-square" alt="Apache License 2.0"></a>
<a href="https://github.com/sinxy-sai/omniconvert-client/stargazers"><img src="https://img.shields.io/github/stars/sinxy-sai/omniconvert-client?style=flat-square&logo=github" alt="GitHub stars"></a>

**简体中文**

</div>

<p align="center">
  <img src="https://socialify.git.ci/sinxy-sai/omniconvert-client/image?description=1&font=Jost&forks=1&issues=1&language=1&logo=https%3A%2F%2Fraw.githubusercontent.com%2Fsinxy-sai%2Fomniconvert-client%2Fmain%2Fweb%2Ficons%2FIcon-512.png&name=1&owner=1&pattern=Plus&pulls=1&stargazers=1&theme=Light" alt="OmniConvert project preview" width="640">
</p>

<p align="center">
  <a href="#快速开始">🚀 快速开始</a> ·
  <a href="#关键特性">✨ 特性</a> ·
  <a href="#支持的工具与格式">🧰 工具</a> ·
  <a href="#平台矩阵">💻 平台</a> ·
  <a href="docs/README.md">📚 文档</a>
</p>

## ✨ 项目简介

OmniConvert 是一个面向学生、研究者和日常办公场景的跨平台文件转换工作台。它把最常用的图片和 PDF 操作留在本机，让文件少一次上传、转换少一次等待；对 MOBI、EPUB 和 DOCX 等需要服务端能力的格式，则提供清晰、可控的在线转换路径。

**选择 OmniConvert 的理由：**

- **少上传**：图片转换、压缩和图片转 PDF 默认在本机完成。
- **更顺手**：转换、任务记录、取消、重试和更新检查集中在一个应用里。
- **跨平台**：同一套 Flutter 客户端覆盖 Web、Windows、Linux、Android、macOS 和 iOS 工程。
- **可验证**：更新下载强制使用 HTTPS，并校验 SHA-256；工具参数由统一注册表管理。

| 项目 | 说明 |
| --- | --- |
| **当前版本** | `0.1.5`，以 GitHub Releases 为准 |
| **本机引擎** | 纯 Dart，基于 `package:image` 与 `package:pdf` |
| **在线转换** | MOBI / AZW / AZW3 / EPUB / DOCX → PDF |
| **数据边界** | 本机工具不上传文件；在线工具处理完成后即用即删 |
| **许可证** | [Apache License 2.0](LICENSE) |

## 关键特性

- **一份引擎，所有平台**：本地图片/PDF 处理只有一份纯 Dart 实现（`lib/core/tools/dart_tool_runner.dart`，基于 `package:image` + `package:pdf`）。Web、Windows、Linux、macOS、Android、iOS 执行同一段代码，同一输入得到同一输出，测试也只需要一套。项目运行时没有原生动态库，也没有代码生成/绑定步骤：`flutter pub get` 之后即可直接分析、测试、构建与打包。
- **重活不进 UI 线程**：CPU 密集的解码与编码通过 `compute` 放进后台 isolate，界面不卡；Web 上 dart2js 不支持 `ReceivePort.listen`，因此不建端口、在主 isolate 直接执行，进度阶段在结果返回后补发。
- **边界明确**：只有 MOBI / DOCX → PDF 会把文件上传到服务器，其余工具全程留在本机；文件不会因为打开工具页而自动上传。
- **任务可恢复**：任务状态机（等待中 → 处理中 → 已完成 / 失败 / 已取消）、SQLite 持久化、运行中协作式取消；启动时把遗留的「处理中」任务标记为「已中断」，由用户决定是否重试。
- **错误可读**：所有失败路径（图片引擎、服务器转换、更新下载）统一收敛为 6 个稳定错误码，界面只按其渲染一句可直接展示的中文提示。
- **可控更新**：客户端读取发布清单，校验版本后下载，手动跟随最多 5 跳重定向且每一跳必须是 HTTPS，全程流式计算并**强制**比对 SHA-256；校验失败立即删除文件。Android 交给原生安装器确认，不承诺静默安装。
- **跨平台工程**：Web/PWA、Windows、Linux、Android 已配置构建与打包；macOS 有构建配置但未签名、未公证；iOS 仅做无签名编译检查。

## 支持的工具与格式

工具清单的唯一事实源是 [`tool/registry.json`](tool/registry.json)，下方表格与它保持一致：

| 工具 | 输入 | 输出 | 参数 | 处理位置 |
| --- | --- | --- | --- | --- |
| 图片 → JPEG（`png_to_jpeg`） | PNG | JPEG | JPEG 质量 1–100（默认 90）；透明底自动合成白色背景 | 本机，纯 Dart 引擎 |
| JPEG → PNG（`jpg_to_png`） | JPG、JPEG | PNG（无损） | 无 | 本机，纯 Dart 引擎 |
| 图片压缩（`compress_image`） | PNG、JPG、JPEG | **保持输入格式**（PNG 仍输出 PNG，JPEG 仍输出 JPEG） | 压缩档位 `high` / `balanced` / `small`（默认 `balanced`）+ 画质 1–100（默认 80） | 本机，纯 Dart 引擎 |
| 图片 → PDF（`image_to_pdf`） | PNG、JPG、JPEG | 单页 PDF | 版面 `fit`（页面等于图片尺寸，整页铺满）或 `a4`（A4 + 等比留白，不裁切），默认 `fit` | 本机，纯 Dart 引擎 |
| MOBI → PDF（`mobi_to_pdf`） | MOBI、AZW、AZW3、EPUB | PDF | 无 | 服务器转换服务（需联网并上传文件） |
| DOCX → PDF（`docx_to_pdf`） | DOCX | PDF | 无 | 服务器转换服务（需联网并上传文件） |

补充说明：

- **输入上限**：单次输入 50 MB（`registry.json` 的 `maxInputBytes` = 52,428,800 字节）；图片像素上限 1 亿（`maxImagePixels` = 100,000,000）。压缩工具在超过像素上限时按比例缩小而不是失败（用户要的就是更小的文件），其余图片工具会提示先缩小尺寸。
- **参数不写死在界面里**：默认值、取值范围、枚举项都从 `tool/registry.json` 生成到 `lib/core/tools/tool_registry.g.dart`；改参数只改注册表并重新生成，不需要动 UI 和引擎。
- **服务器转换**：客户端 `POST https://www.sinxysai.site/api/v1/conversions/pdf`（`lib/core/tools/backend_conversion_runner.dart`），可用 `--dart-define=OMNICONVERT_API_BASE_URL=<地址>` 覆盖；返回内容会校验是否为有效 PDF，文件在服务端即用即删。服务端实现不在本仓库。
- **公式识别（OCR）暂未开放**：首页与工具页只显示「暂未开放」，不提供可用入口。自建 `ocr-provider-v1` 服务的协议与安全要求见 [自建公式识别 Provider](docs/docs/self-hosted-provider.md)，当前不接入官方识别。
- 桌面外部转换器（LibreOffice、Calibre）的检测、版本记录与进程安全边界见 [桌面外部转换器](docs/docs/external-converters.md)；工具页当前统一走服务器转换路径。

## 平台矩阵

| 平台 | 状态 | 构建与验证 | 说明 |
| --- | --- | --- | --- |
| Web / PWA | 可用 | CI 构建 `flutter build web --release --base-href /app/`，官网 `/app/` 发布 | 使用 SQLite WASM + IndexedDB 保存任务；纯 Dart 引擎在页面内存中处理，不加载任何原生库 |
| Windows x64 | 构建与打包配置完成，待发布验证 | CI 在 `windows-latest` 上构建 release 产物并打 ZIP；NSIS 安装器脚本在 `ops/windows/` | 本机构建需开启 Windows「开发者模式」（Flutter 插件需要符号链接权限） |
| Linux x64 | 构建与打包配置完成，待发布验证 | CI `ubuntu-latest` 构建 release；AppImage、DEB、tar.gz 脚本在 `ops/linux/` | 需 GTK/CMake 工具链（clang、cmake、ninja-build、pkg-config、libgtk-3-dev） |
| Android arm64 | 构建与打包配置完成，待发布验证 | CI 构建 debug APK；正式 tag 构建需发布签名密钥 | 未做真机安装验收 |
| macOS universal | 构建配置存在，未验证 | 仅 release workflow（tag 发布）在 `macos-latest` 构建 `flutter build macos --release` 并打 DMG/ZIP，**未签名、未公证**；PR CI 不构建 macOS | 无设备做安装与启动验收 |
| iOS arm64 | 仅无签名编译检查 | 本地手动 `flutter build ios --no-codesign`，CI 无 iOS job | 目录存在，未发布、未验证 |

> 「构建与打包配置完成」只表示 CI 与脚本已就绪，不代表已有正式安装包。安装包与下载状态以 GitHub Release 和官网发布清单为准。

## 快速开始

### 开发环境

- Flutter **3.47.7**（stable），Dart **3.13.5**。
- Python **3.12**：仅用于 `tool/generate_registry.py`（只用标准库，无第三方依赖）。
- Node.js **22**（可选）：仅浏览器端到端冒烟 `tool/e2e/web_smoke.js` 需要，且依赖 Playwright。
- Windows 桌面构建需要 Visual Studio 的 **Desktop development with C++** 工作负载与 Windows SDK，并需在系统设置里开启「开发者模式」（Flutter 插件依赖符号链接）。
- Linux 桌面构建需要 Flutter 官方列出的 GTK/CMake 工具链；Android 构建需要 Android SDK 与 JDK 17。
- macOS / iOS 构建只能在 macOS + Xcode 环境中执行，iOS 真机安装需要开发者自己的签名配置。
- **不需要任何原生工具链**：安装 Flutter SDK 后即可分析、测试、构建；没有原生库、没有绑定生成步骤，`pubspec.yaml` 里只有 Dart/Flutter 依赖。

本仓库的 `.toolchains/` 仅供本机开发，已被 Git 忽略；CI 会独立安装固定版本的 Flutter SDK。运维凭据保存在 Git 忽略的本地目录中，不应提交到公开仓库。

### 初始化

```powershell
flutter pub get
```

### 本地验证

```powershell
flutter analyze                            # 0 issue
flutter test                               # 117 项通过
python tool/generate_registry.py --check   # 本仓库生成物必须与 tool/registry.json 一致
flutter build web --release --base-href /app/
```

- 修改 `tool/registry.json` 后必须重新生成代码与文档：

  ```powershell
  python tool/generate_registry.py
  ```

  它会写出 `lib/core/tools/tool_registry.g.dart`、`docs/capabilities.md`（以及官网站点与后端的 capabilities 生成物）。生成物都随仓库提交，禁止手改；CI 的 `registry` job 会跑 `--check`（只校验本仓库内的 Dart 定义与 `docs/capabilities.md`），不一致即失败。在含兄弟仓库的完整工作区里用 `--check-cross-repo`，会额外校验官网站点与后端的生成物。
- 浏览器端到端冒烟（可选，需要 Playwright 与 Chromium/Edge）：

  ```powershell
  node tool/e2e/web_smoke.js --dir build/web --out .work/e2e
  ```

  它在真实浏览器里走完「选文件 → 开始处理 → 下载 → 校验文件头」，并断言压缩后格式不变。
- 最近任务保存在应用数据目录的 SQLite 数据库中；Web 使用 IndexedDB 承载 SQLite WASM 文件系统。Web 二进制来源和校验值见 [第三方声明](THIRD_PARTY_NOTICES.md)。启动时，原来处于「处理中」的任务会改为「已中断」，由用户决定是否重试。

### 平台构建

```powershell
flutter build windows
flutter build linux
flutter build macos
flutter build apk
flutter build ios --no-codesign
flutter build web --release --base-href /app/
```

每条命令只在相应平台及工具链齐备时运行。Apple 平台构建必须在 macOS + Xcode 上执行：macOS 产物由 release workflow 构建，iOS 只在本地做无签名编译检查。CI 构建 Web 时会额外加 `--no-wasm-dry-run`：`package:image` 4.5.4 有两个文件（`exif/ifd_directory.dart`）在 wasm dry-run 报告中报错，JS 构建本身正常，升级该依赖后可以去掉这个 flag。

一键验证脚本：

- Windows：`./tool/verify_platforms.ps1`（`-Target windows|android|web`，`-SkipChecks` 可跳过 analyze/test）。
- Linux/macOS：`bash tool/verify_platforms.sh`（Linux 上 `linux|android|web`，macOS 上 `macos|ios-check`）。

脚本只做一件事：先跑 `flutter analyze` + `flutter test`，再构建当前平台（不涉及任何原生构建）。GitHub Actions 在 Web、Windows、Linux、Android 上分别编译，产物名采用 `OmniConvert-{version}-{platform}-{arch}`。CI 产物是无签名的调试/预览构建；安装包打包脚本（NSIS、AppImage/DEB、DMG/ZIP）已在 release workflow 中接入，但真实 tag 发布、签名、公证与安装验收仍在进行中。

## 目录结构

```text
.
├── lib/
│   ├── main.dart                     # 入口
│   ├── app/                          # 应用外壳：路由、导航、主题与设计 token、通用控件
│   ├── core/
│   │   ├── tools/                    # 工具运行时：注册表定义、纯 Dart 引擎、服务端转换、错误码
│   │   │   ├── tool_registry.g.dart  # 由 registry.json 生成，勿手改
│   │   │   ├── tool_runner.dart      # ToolRequest/Result、ToolRunner、CancellableToolRunner
│   │   │   ├── dart_tool_runner.dart # 纯 Dart 图片/PDF 引擎，全平台同一份实现
│   │   │   ├── backend_conversion_runner.dart  # HTTP 服务器转换客户端
│   │   │   ├── tool_execution_service.dart     # 任务编排、进度、取消
│   │   │   ├── tool_error.dart       # 6 个稳定错误码与中文文案
│   │   │   └── tool_io*.dart / file_picker*.dart  # 平台文件读写与选择（条件导入）
│   │   ├── updates/                  # 检查更新 → 下载 → 校验 → 打开安装包
│   │   │   ├── update_service.dart   # 读 releases/latest.json，按平台/架构选目标
│   │   │   ├── update_downloader.dart# 手动跟随 ≤5 跳 HTTPS 重定向 + 流式 SHA-256
│   │   │   ├── update_opener*.dart   # Web/桌面分流
│   │   │   └── android_installer.dart# 原生 MethodChannel 安装器交接
│   │   ├── tasks/                    # 任务模型、状态机、SQLite 仓库（Web 走 WASM + IndexedDB）
│   │   ├── storage/                  # 数据库初始化
│   │   └── ocr/                      # 自建 ocr-provider-v1 设置与 HTTP provider（官方 OCR 未开放）
│   └── features/                     # 页面：home / tools / tasks / settings / formula
├── tool/
│   ├── registry.json                 # 工具能力唯一事实源
│   ├── generate_registry.py          # 生成 Dart/站点/后端/文档四处产物（含 --check）
│   ├── verify_platforms.ps1 / .sh    # analyze + test + 当前平台构建
│   └── e2e/web_smoke.js              # 浏览器端到端冒烟（Playwright）
├── test/                             # Flutter/Dart 测试（工具契约、引擎、任务、更新、页面）
├── docs/                             # 架构、能力、实施状态与设计规格（索引见 docs/README.md）
├── ops/                              # NSIS、AppImage/DEB、DMG 打包脚本
├── protocol/                         # ocr-provider-v1 OpenAPI、mock provider 与契约测试
├── web/                              # Web 资源（index.html、manifest、sqlite3.wasm）
├── windows/ linux/ macos/ android/ ios/   # 平台工程
├── .toolchains/                      # 本地 Flutter/工具链（Git 忽略，不提交）
└── .github/workflows/                # client.yml（registry/analyze/test/web-e2e/四平台构建）与 release.yml（标签发布）
```

## 隐私边界

| 场景 | 文件去向 | 说明 |
| --- | --- | --- |
| PNG → JPEG / JPEG → PNG / 图片压缩 / 图片 → PDF | 留在本机 | 纯 Dart 引擎在进程内处理；Web 端结果在页面内存中生成、由浏览器下载；原生端结果写到系统临时目录下的 `OmniConvert/` 子目录（用户指定路径时写到该路径） |
| MOBI / DOCX → PDF | 上传到服务器 | 发送到 `https://www.sinxysai.site/api/v1/conversions/pdf` 转换，服务端即用即删；敏感文件请改用本机工具，或不要上传 |
| 公式识别（OCR） | — | 当前未开放，页面无可用入口；自建 provider 的地址与凭据由用户自行管理 |
| 更新检查 | 只读取发布清单 | 仅请求 `https://www.sinxysai.site/releases/latest.json`；安装包下载全程 HTTPS 并强制校验 SHA-256，校验失败删除文件；Android 安装需用户在系统安装器中确认 |

- 不要把他人的文档、OCR 凭据或签名密钥粘贴到 issue/PR；本地绝对路径也可能包含个人信息，报告问题前请脱敏。
- 隐私说明的权威页面是官网 `/privacy/`；本仓库只描述客户端行为。

## 已知限制

- **Windows 本机构建需要开启「开发者模式」**：Flutter 插件需要符号链接权限，未开启时 `flutter build windows` 会失败。Windows 产物由 CI 在 `windows-latest` 上构建，仍需下载安装包做一次人工启动验收。
- **macOS 产物未签名、未公证**：CI 只产出 DMG/ZIP，没做 Developer ID 签名与公证，也没有设备做过安装与启动验收。iOS 仅做无签名编译检查，未发布。
- **转换服务没有 CORS 头**：浏览器只能在与官网同源的场景（`https://www.sinxsysai.site/app/`）调用服务器转换，本地 `flutter run` 的 Web 调试、或把 `/app/` 独立部署到别的域上，MOBI/DOCX 两项会因同源策略失败；桌面端不受影响。
- **大文件服务端转换占内存**：客户端先把整个文件读进内存再做 multipart 上传，50 MB 输入约需两倍内存，后续应改成流式上传。
- **公式识别未开放**：官方 OCR 属于私有后端范围，本阶段不提供入口。

## 文档

文档索引见 [docs/README.md](docs/README.md)。常用的几篇：

- [架构说明](docs/ARCHITECTURE.md)：三仓边界、`tool/registry.json` 唯一事实源、执行层、错误模型、更新链路、测试分层。
- [支持的能力](docs/capabilities.md)：由注册表自动生成的工具表。
- [实施状态](docs/implementation-status.md)：已实现 / 已验证 / 待验证，以及跨仓库边界。
- [实施路线图](docs/superpowers/plans/2026-10-19-omniconvert-roadmap.md)：历史设计与实施顺序记录，**不代表当前架构**。

## 贡献

欢迎提交 issue 与 PR。开始前请阅读：

- [CONTRIBUTING.md](CONTRIBUTING.md)：开发环境、新增工具的完整路径、必跑检查、平台构建、提交与发布流程。
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)：行为准则。
- [SECURITY.md](SECURITY.md)：安全漏洞请私下报告，不要创建公开 issue。

## 许可证

Copyright 2026 sinxy-sai（https://github.com/sinxy-sai）。

本项目采用 [Apache License 2.0](LICENSE) 许可证：你可以在遵守该许可证的前提下使用、修改与分发本项目。版权归属与项目名称声明见 [NOTICE](NOTICE)。第三方组件与 WASM 二进制声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。提交贡献即表示同意按同一许可证授权。

本仓库对应公开客户端 `omniconvert-client`；官网源代码放在独立的公开仓库 `omniconvert-site`，官方服务端放在私有仓库 `omniconvert-backend`。变更记录见 [CHANGELOG.md](CHANGELOG.md)。
