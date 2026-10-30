# OmniConvert 实施状态

更新：2026-10-30（对应 `0.1.4`）。

本文只写**已经验证过**的事实。每条结论后面标注证据类型：`analyze` / `test` / `browser-e2e` / `curl` / `ci`。未经运行验证的一律放在「待验证」里。

## 架构现状（0.1.4 起）

```
tools/registry.json        单一事实源：工具、格式、参数、上限
        │  tool/generate_registry.py
        ├─────────────▶ lib/core/tools/tool_registry.g.dart   （客户端 UI + 引擎默认值）
        ├─────────────▶ OmniConvert-site/src/lib/capabilities.generated.json （官网能力表）
        └─────────────▶ OmniConvert-backend/app/conversion/capabilities_generated.py
                                     （服务端可转换格式，测试断言与 CONVERTERS 一致）

ToolRunner（lib/core/tools/tool_runner.dart）
  └── DartToolRunner（所有平台同一份实现，package:image + package:pdf）
        ├── 本地图片工具：png_to_jpeg / jpg_to_png / compress_image / image_to_pdf
        └── BackendConversionRunner（HTTP）：mobi_to_pdf / docx_to_pdf
```

**0.1.4 移除了 Rust 内核**（`rust/`、`lib/src/rust/`、`flutter_rust_bridge.yaml`）。原因：同一份能力曾在 Rust、Web 纯 Dart、UI 目录、后端四处分别实现，导致 png↔jpg 长期只有单向、Web 端与桌面端行为不一致、每加一个格式要改四处。现在本地引擎只有一份纯 Dart 实现，所有平台跑同一段代码，测试也只需要一套。代价是 mobi/docx 仍依赖服务端（这两种格式本来就需要 Calibre / LibreOffice）。

## 工具清单（与 registry 一致）

| 工具 | 输入 | 输出 | 引擎 | 参数 |
|---|---|---|---|---|
| png_to_jpeg | png | jpg | 本机 | JPEG 质量 1–100（默认 90） |
| jpg_to_png | jpg / jpeg | png | 本机 | 无 |
| compress_image | png / jpg / jpeg | **保持原格式** | 本机 | 压缩档位 / 画质 |
| image_to_pdf | png / jpg / jpeg | pdf | 本机 | 版面：整页铺满 / A4 留白 |
| mobi_to_pdf | mobi / azw / azw3 / epub | pdf | 服务器 | 无 |
| docx_to_pdf | docx | pdf | 服务器 | 无 |

单次输入上限 50 MB（`registry.json` 的 `maxInputBytes`）；图片像素上限 1 亿（压缩会按比例缩小而不是直接失败）。

公式识别（OCR）按产品决定**本阶段不开放**：首页与工具页显示「暂未开放」，不提供入口。

## 已验证

- `flutter analyze` —— **0 issue**。（analyze）
- `flutter test` —— **117 项全部通过**。（test）
- `flutter build web --release --base-href /app/` 成功。（build）
- 浏览器端**真实点击**验证（Playwright + Chromium + Edge，选择文件 → 开始处理 → 下载结果 → 校验文件头）：
  - png_to_jpeg：`red.jpg` 2364 B，magic `FF D8 FF` ✅
  - jpg_to_png：`blue.png` 1949 B，magic `89 50 4E 47` ✅
  - compress_image（PNG 输入）：`red.png` 737 B（输入 788 B），**格式保持 PNG** ✅
  - compress_image（JPEG 输入）：`blue.jpg` 9013 B，magic `FF D8 FF` ✅
  - image_to_pdf：`red.pdf` 1355 B，magic `%PDF-` ✅
  （browser-e2e）
- 服务端转换（curl 直连线上 API）：真实 mobi → 200 / 12772 B / `%PDF-`；真实 docx → 200 / 33370 B / `%PDF-`。（curl）
- 更新链路：清单 `https://www.sinxysai.site/releases/latest.json` 可读（200），客户端支持检查版本、应用内下载、**流式 SHA-256 校验**、校验失败自动删除、交给系统安装包打开。

## 0.1.4 修复的关键缺陷

- **Web 端所有本地工具失效**：`dart_tool_runner.dart` 无条件创建 `ReceivePort` 并通过 `listen` 接收进度，而 dart2js 不支持 `ReceivePort.listen`，浏览器里每次点「开始处理」都抛 `UnsupportedError`，7 个工具全部报「处理没有完成」。现在 Web 不建端口，进度阶段由结果返回后补发。
- **压缩会把 PNG 变成 JPEG**：压缩现在按输入魔数判断格式，PNG 仍输出 PNG（走 zlib 级别），透明通道不再被白色背景替换。
- **切换工具后输入文件与输出名不联动**：切换工具会重置选中文件、输出名与参数；扩展名由工具决定（PNG → JPEG 不会残留 `.png`）。
- **更新包下载必然失败**：GitHub Release 资产 URL 一定 302 跳转到 CDN，旧代码 `followRedirects = false` 直接失败。现在手动跟随最多 5 跳、每一跳都必须 HTTPS。
- **更新下载器是死代码**：`UpdateDownloader` 只有测试引用，设置页只能「复制下载地址」。现在设置页可一键下载、校验、打开安装包（Android 走原生安装器，Web 打开下载页）。

## 待验证

- **Windows 本机构建**：当前开发机未开启「开发者模式」，Flutter 插件需要符号链接权限，`flutter build windows` 在本机被拒。Windows 产物由 CI（`windows-latest`）构建，需在发版后下载安装包做一次人工启动验收。
- **服务端工具在浏览器内的完整链路**：本地验证时 `/app/` 与 `/api/` 不同源，浏览器受同源策略限制会失败；线上两者同源，需在部署后于 `https://www.sinxsai.site/app/` 复测 mobi/docx 两项。
- **macOS**：无设备，未做安装与启动验收；产物由 CI 构建（未签名/未公证）。
- **Android**：未在真机安装验收。

## 跨仓库职责边界

- 客户端仓库：Flutter 界面、任务编排、本地图片引擎、更新检查与下载。
- 官网仓库：静态页面、`/app/` Web 构建产物、发布清单（`public/releases/latest.json`），不承载转换逻辑。
- backend 仓库：文档转换 API（LibreOffice / Calibre）、能力清单、健康检查与部署流水线；OCR 相关代码保留但线上关闭（`OCR_ENABLED=0`）。

## 已知限制

- 大文件走服务端转换时，客户端把整个文件读进内存再 multipart 上传，50 MB 输入会占用约两倍内存；后续应改为流式上传。
- 转换服务暂无 CORS 头，只适用于与官网同源的浏览器场景；桌面端不受影响。
- 任务历史可查看但暂不支持「重跑」或「打开产物所在目录」的一键入口。