# OmniConvert 架构说明

本文描述三仓（client / site / backend）的职责边界、数据流、能力清单唯一事实源的约束，以及 0.1.4 起的执行层与更新链路。改代码前请先读本文；与本文冲突的实现视为需要修复的偏差。

## 1. 仓库边界

| 仓库 | 可见性 | 职责 | 明确不做 |
|---|---|---|---|
| `omniconvert-client` | 公开 | Flutter UI、任务编排、本机图片/PDF 处理、更新检查与下载 | 不承载账号/配额/官方 OCR；不实现文档格式的权威转换 |
| `omniconvert-site` | 公开 | 静态官网、`/app/` Web 产物托管、发布清单展示 | 不含业务逻辑；不直连数据库 |
| `omniconvert-backend` | 私有 | 需要上传的文档转换（MOBI/AZW/AZW3/EPUB、DOCX → PDF）、将来的账号与 OCR | 不实现本机图片处理 |

## 2. 唯一事实源：`tool/registry.json`

**能力清单只能有一个来源。** 历史上同一份能力被维护在四处（原生核心、Web 专用 Dart 实现、UI 目录、后端 capabilities），格式、上限、错误码各说各话，是"有时能用有时不能用"的根因。

```
OmniConvert-client/tool/registry.json          ← 唯一的编辑入口
        │  python tool/generate_registry.py
        ├─▶ lib/core/tools/tool_registry.g.dart                       Flutter
        ├─▶ ../OmniConvert-site/src/lib/capabilities.generated.json   官网
        ├─▶ ../OmniConvert-backend/app/conversion/capabilities_generated.py  API
        └─▶ docs/capabilities.md                                     文档
```

约束：

- 上述四个产物**都是生成文件，禁止手改**。
- CI 的 `registry` job 会跑 `python tool/generate_registry.py --check`，本仓库内的生成物与注册表不一致即失败；该 job 是所有后续 job 的前置。`--check` 只校验本仓库拥有的两份产物（Dart 定义与 `docs/capabilities.md`），因为 CI 只检出本仓库；在含兄弟仓库的完整工作区里用 `--check-cross-repo` 才会连官网站点与后端的产物一起校验。
- 新增一个格式/工具 = 改 `registry.json` + 在对应引擎里实现，不涉及其它清单。

### 注册表字段

```jsonc
{
  "registryVersion": 1,
  "limits": {
    "maxInputBytes": 52428800,     // 单文件 50 MiB
    "maxImagePixels": 100000000    // 1 亿像素
  },
  "categories": [ { "id": "convert | compress", "name": { "zh": "...", "en": "..." } } ],
  "tools": [{
    "id": "compress_image",        // 稳定标识，任务历史会持久化它，不要改名
    "name": { "zh": "...", "en": "..." },
    "summary": { "zh": "...", "en": "..." },
    "category": "convert",
    "engine": "local | server",    // local = 本机进程内完成；server = 需要上传
    "inputExtensions": ["png"],    // 小写、不带点
    "outputExtension": "jpg",      // 或 "same" 表示保留输入格式
    "options": [ /* integer | enum | boolean | string，含 default/min/max/values */ ]
  }]
}
```

### 当前 6 个工具（0.1.4）

| id | 输入 | 输出 | 参数 | engine |
|---|---|---|---|---|
| `png_to_jpeg` | png | jpg | `quality` 1–100（默认 90） | local |
| `jpg_to_png` | jpg / jpeg | png | 无 | local |
| `compress_image` | png / jpg / jpeg | `same`（保持原格式） | `preset` high/balanced/small、`quality` 1–100 | local |
| `image_to_pdf` | png / jpg / jpeg | pdf | `layout` fit/a4 | local |
| `mobi_to_pdf` | mobi / azw / azw3 / epub | pdf | 无 | server |
| `docx_to_pdf` | docx | pdf | 无 | server |

公式识别（OCR）不在注册表里：官方 OCR 未开放，页面显示「暂未开放」，`lib/core/ocr/` 只保留自建 `ocr-provider-v1` 的配置与 HTTP provider 实现。

## 3. 执行层：一条代码路径覆盖所有平台

```
ToolRequest ──▶ ToolRunner（lib/core/tools/tool_runner.dart）
                 └── DartToolRunner（所有平台同一份实现）
                      ├── 本机图片/PDF：package:image + package:pdf
                      └── 服务端文档：BackendConversionRunner
                            HTTP multipart → POST {baseUrl}/conversions/pdf
```

设计决策与理由：

- **本机能力只有一份实现。** 旧的混合架构里，原生核心只实现 3 个工具、Web 专用 Dart 实现另外 4 个，两边能力不对齐（png↔jpg 长期只有单向、Web 压缩只能输出 JPEG、PDF 会被裁切）；而原生核心带来的构建依赖（绑定代码生成、随包动态库、跨平台 NDK/MSVC 工具链）本身就是 Windows 端"所有工具都失败"的直接来源，也让本机无法编译 Windows 版本。统一为纯 Dart 后：构建依赖归零，行为在所有平台一致，测试只需一套。
- **引擎选择由注册表的 `engine` 字段决定**，不在 UI 里判断。`DartToolRunner` 读 `toolDefinitionFor(toolId)`：`isLocal == false` 直接转交 `BackendConversionRunner`，本地工具走本机分支。
- **重活进隔离区。** 原生平台通过 `compute` 把解码/编码放进后台 isolate，UI 线程只做编排；Web 上 dart2js 不支持 `ReceivePort.listen`，因此**不创建端口、不传 `SendPort`**，在主 isolate 直接执行，编码阶段的进度在结果返回后由 runner 补发（`decoding → encoding → completed` 的阶段顺序保持不变）。违反这条限制会让 Web 端每个本机工具都抛 `UnsupportedError`（0.1.4 修的就是这个）。
- **取消是协作式的。** `CancellableToolRunner.cancel()` 只置标志位，runner 在阶段边界（解码前、解码后、写盘前）检查并抛 `Cancelled`；已经在 isolate 里的 CPU 计算不会被抢占，但标志置位后不会写出任何文件。
- **格式化输出由工具定义决定**：输出扩展名来自 `outputExtension`（`same` 时跟随输入格式），压缩是否保持 PNG 由**输入魔数**判断（PNG 走 zlib 级别，JPEG 走质量参数），不靠扩展名猜。
- **选项解析只在引擎侧一处**：`_resolveOptions()` 用注册表补默认值、把 integer 夹到 `min`/`max`、丢弃注册表未声明的 enum 值；用户实际动过的那个控件优先于未动的兄弟默认值。

## 4. 错误模型

所有 runner 只能抛 `ToolRunException(ToolRunFailure(code, message))`（`lib/core/tools/tool_error.dart`），`message` 必须是可直接展示的中文。

| code | 含义 | UI 表现 |
|---|---|---|
| `InvalidInput` | 文件损坏 / 不是声明的格式 / 服务端判定输入无效 | 提示换文件 |
| `InputTooLarge` | 超过 `kMaxInputBytes` 或 `kMaxImagePixels`（HTTP 413） | 提示上限 |
| `UnsupportedTool` | 未知 id 或当前平台无该工具（HTTP 415） | 隐藏入口（正常不该出现） |
| `Cancelled` | 用户取消 | 不报错，回到可重跑状态 |
| `ConverterUnavailable` | 服务端转换器不可用（5xx、408/429/504、超时） | 提示稍后重试 |
| `NetworkError` | 网络 / DNS / TLS / 超时前的传输失败 | 提示检查网络 |

服务端返回的 `x-error-code` 会先被归一化到上述 6 个码（`canonicalToolErrorCode`），未知码再按 HTTP 状态兜底。服务端说明文字会做安全截断：超过 200 字符或疑似堆栈/JSON 时直接丢弃，避免把后端内部细节回显到界面。

## 5. 任务与持久化

`ToolExecutionService` 负责状态机与持久化：

```
queued ──▶ running ──▶ succeeded / failed / cancelled / interrupted
              ▲                              │
              └──── 用户重试（queued）◀──────┘
```

启动时把遗留的 `running` 任务标记为 `interrupted`（「已中断」），由用户决定是否重试，不静默续跑。Web 用 SQLite WASM + IndexedDB（`web/sqlite3.wasm`，来源与校验值见 `THIRD_PARTY_NOTICES.md`），原生端用 SQLite 文件（`path_provider` 的应用数据目录）。

## 6. 更新链路

```
检查 ─▶ 下载 ─▶ 校验 ─▶ 打开
```

- **检查**：`UpdateService` 读取 `https://www.sinxysai.site/releases/latest.json`，先按平台/架构选出目标产物再进行版本比较——Web 为 `(web, all)`；Android 通过 MethodChannel `site.sinxysai.omniconvert/updates` 的 `deviceArch` 取 ABI（`arm64-v8a` / `armeabi-v7a` / `x86_64`）；Windows/Linux 为 `x64`；macOS 为 `universal`。
- **下载**（`update_downloader.dart`）：GitHub Release 资产 URL 必然 302 到 CDN，所以**手动跟随重定向**，上限 5 跳，**每一跳都要求 HTTPS**，最终必须 200；边下边算 SHA-256，不把整个安装包读进内存；支持取消。
- **校验**：清单里的 `sha256` 必须是 64 位十六进制，否则直接拒绝下载；下载完成后比对摘要，不匹配就**删除已落盘文件**并报错——半成品绝不能进安装器。
- **打开**：`update_opener*.dart` 按平台分流——Web 打开官网下载页（Web 没有本地安装包），桌面端用系统默认方式打开已校验文件，Android 走原生 `installVerifiedApk`（`android_installer.dart`）交给系统安装器，**不承诺静默安装**。
- 清单由 release 工作流生成并 dispatch 给站点仓库，站点与客户端读同一份数据，避免"能下载"和"看起来能下载"不一致。

## 7. 部署

| 目标 | 方式 | 验证 |
|---|---|---|
| 官网 + Web 客户端 | site CI `rsync dist/` → `/var/www/omniconvert`（含 `/app/`） | 备份 → 部署 → 6 个路径 200 冒烟，失败自动回滚 |
| 后端 API | backend CI rsync 源码 → VPS 上 `docker compose build` → `up -d` | `/healthz` 轮询 + capabilities + 真实 docx→PDF，失败回滚上一镜像 tag |

后端镜像在 VPS 本机构建（约 2.5GB，含 LibreOffice/Calibre/中文字体），不经 CI 跨国传输。转换服务**没有 CORS 头**，因此浏览器侧只在与官网同源（`https://www.sinxysai.site/app/`）时可用；桌面端不受影响。

## 8. 测试分层

1. **注册表一致性**：`python tool/generate_registry.py --check` —— 本仓库内的生成物与 `tool/registry.json` 不一致即红（`--check-cross-repo` 额外覆盖兄弟仓库产物）。这是 CI 的第一个 job。
2. **单元**：`flutter analyze`（0 issue）+ `flutter test`（117 项）—— 纯逻辑、引擎正确性（含"压缩必须保留格式"这类回归）、工具契约、错误码、更新下载的重定向与摘要校验、任务状态机、页面 widget。
3. **端到端**：`tool/e2e/web_smoke.js` —— 真实浏览器里选文件→处理→下载→校验文件头，覆盖全部本机工具；CI 的 `web-e2e` job 跑它并上传产物。
4. **部署冒烟**：CI 在部署后打生产接口。

任何一层红都不允许合并到 `main`。