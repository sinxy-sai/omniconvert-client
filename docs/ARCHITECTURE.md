# OmniConvert 架构说明

本文描述三仓（client / site / backend）的职责边界、数据流与"能力清单唯一事实源"的约束。改代码前请先读本文；与本文冲突的实现视为需要修复的偏差。

## 1. 仓库边界

| 仓库 | 可见性 | 职责 | 明确不做 |
|---|---|---|---|
| `omniconvert-client` | 公开 | Flutter UI、任务编排、本机图片处理、更新检查 | 不承载账号/配额/OCR；不实现文档格式的权威转换 |
| `omniconvert-site` | 公开 | 静态官网、`/app/` Web 产物托管数据、发布清单展示 | 不含业务逻辑；不直连数据库 |
| `omniconvert-backend` | 私有 | 需要上传的文档转换（DOCX/MOBI/AZW/AZW3/EPUB → PDF）、将来的账号与 OCR | 不实现本机图片处理 |

## 2. 唯一事实源：`tool/registry.json`

**能力清单只能有一个来源。** 历史上同一份能力被维护在四处（Rust、Web Dart、UI 目录、后端 capabilities），格式、上限、错误码各说各话，是"有时能用有时不能用"的根因。

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
- CI 的 `registry` job 会跑 `python tool/generate_registry.py --check`，生成物与注册表不一致即失败。
- 新增一个格式/工具 = 改 `registry.json` + 在对应引擎里实现，不涉及其它清单。

### 注册表字段

```jsonc
{
  "id": "compress_image",          // 稳定标识，任务历史会持久化它，不要改名
  "name": { "zh": "...", "en": "..." },
  "summary": { "zh": "...", "en": "..." },
  "category": "convert | compress",
  "engine": "local | server",      // local = 本机/浏览器内完成；server = 需要上传
  "inputExtensions": ["png"],      // 小写、不带点
  "outputExtension": "jpg",        // 或 "same" 表示保留输入格式
  "options": [ /* integer | enum | boolean | string */ ]
}
```

## 3. 执行层：一条代码路径覆盖所有平台

```
ToolRequest ──▶ ToolRunner
                 ├── DartToolRunner          package:image + package:pdf
                 │    Web / Windows / Linux / Android 共用
                 └── BackendConversionRunner HTTP multipart → /api/v1/conversions/pdf
```

设计决策与理由：

- **图片处理不再依赖 Rust 原生核心。** 旧架构里 Rust 只实现 3 个工具、Web 的 Dart 实现 4 个，两边能力不对齐；而原生核心带来的构建依赖（frb 绑定、`omniconvert_core.dll`、NDK/MSVC）是 Windows 端"所有工具都失败"的直接来源，也让本机无法编译 Windows 版本。统一为纯 Dart 后：构建依赖归零，行为在三端一致，测试只需一套。
- 原生平台把重活放进 `compute()` isolate，避免阻塞 UI；Web 端在主 isolate 执行并回报进度。
- 引擎选择由注册表的 `engine` 字段决定，不在 UI 里判断。

## 4. 错误模型

所有 runner 只能抛 `ToolRunException(ToolRunFailure(code, message))`，`message` 必须是可直接展示的中文。

| code | 含义 | UI 表现 |
|---|---|---|
| `InvalidInput` | 文件损坏 / 不是声明的格式 | 提示换文件 |
| `InputTooLarge` | 超过 `kMaxInputBytes` | 提示上限 |
| `UnsupportedTool` | 当前平台无该工具 | 隐藏入口（正常不该出现） |
| `Cancelled` | 用户取消 | 不报错，回到可重跑状态 |
| `ConverterUnavailable` | 服务端转换器不可用（503） | 提示稍后重试 |
| `NetworkError` | 网络/超时 | 提示检查网络 |

## 5. 任务与持久化

`ToolExecutionService` 负责状态机（queued → running → succeeded/failed/cancelled）与持久化。启动时把遗留的 `running` 任务标记为已中断。Web 用 SQLite WASM + IndexedDB，原生用 SQLite 文件。

## 6. 更新推送

- 客户端读取发布清单（`latest.json`），比较版本。
- 下载后**必须**校验清单里的 `sha256`，不匹配即删除文件并报错。
- Android 交给系统安装器，不承诺静默安装。
- 清单由 release 工作流生成并 dispatch 给站点仓库，站点与客户端读同一份数据，避免"能下载"和"看起来能下载"不一致。

## 7. 部署

| 目标 | 方式 | 验证 |
|---|---|---|
| 官网 + Web 客户端 | site CI `rsync dist/` → `/var/www/omniconvert`（含 `/app/`） | 备份 → 部署 → 6 个路径 200 冒烟，失败自动回滚 |
| 后端 API | backend CI rsync 源码 → VPS 上 `docker compose build` → `up -d` | `/healthz` 轮询 + capabilities + 真实 docx→PDF，失败回滚上一镜像 tag |

后端镜像在 VPS 本机构建（约 2.5GB，含 LibreOffice/Calibre/中文字体），不经 CI 跨国传输。

## 8. 测试分层

1. **单元**：`flutter test` / `pytest` —— 纯逻辑、引擎正确性（含"压缩必须保留格式"这类回归）。
2. **端到端**：`tool/e2e/web_smoke.js` —— 真实浏览器里选文件→处理→下载→校验文件头，覆盖全部本机工具。
3. **部署冒烟**：CI 在部署后打生产接口。

任何一层红都不允许合并到 `main`。