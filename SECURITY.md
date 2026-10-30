# 安全策略 / Security Policy

## 支持范围

| 版本 | 是否支持 | 说明 |
| --- | --- | --- |
| `0.1.4`（最新 tag） | ✅ | 当前维护版本 |
| `0.1.3`、`0.1.2`、`0.1.0` | ⚠️ | 仅在最新版本仍受影响时考虑修复，不单独发布安全更新 |
| 未发布的分支 / 旧提交 | ❌ | 不提供安全支持 |
| 私有 `omniconvert-backend` | ❌ | 不在本公开仓库范围内 |

## 如何报告漏洞

**请不要创建公开 issue、PR 或 discussion。**

优先使用 GitHub 的私密漏洞报告入口：

<https://github.com/sinxy-sai/omniconvert-client/security/advisories/new>

（仓库 **Security** 标签页 → **Report a vulnerability**。）

如果该入口不可用，请通过维护者 GitHub 账号 [@sinxy-sai](https://github.com/sinxy-sai) 的公开资料所列方式私下联系，并在标题中注明 `SECURITY`。

报告中请**不要**附带真实用户文件、个人文档、OCR 服务凭据或签名密钥；请使用最小化、可脱敏的样例复现。

## 报告建议包含

- 受影响的版本、平台与安装方式（Web / Windows / Linux / Android / 直接运行 debug 构建）。
- 复现步骤、最小样例文件与预期/实际行为。
- 影响评估：例如任意文件读写、路径穿越、越界/崩溃、临时文件残留、更新包校验绕过、凭据泄露、上传边界不符合预期。
- 该操作中文件应在本地处理还是上传到服务器（只有 MOBI / DOCX → PDF 会联网并把文件上传到转换服务；官方 OCR 未开放，本机图片工具全程不联网）。
- 是否已公开或已告知第三方；是否希望匿名或致谢。

## 重点范围

- **本机图片/PDF 引擎（纯 Dart）**：`lib/core/tools/dart_tool_runner.dart` 是唯一实现，所有平台跑同一段代码（Web、Windows、Linux、macOS、Android、iOS），运行时没有任何原生动态库。关注点：
  - **输入上限**：单次输入 50 MB（`registry.json` 的 `maxInputBytes`）、图片像素上限 1 亿（`maxImagePixels`）；绕过上限导致内存耗尽属于范围内。
  - **恶意/损坏输入**：解码器在畸形数据上抛出的异常必须在隔离区内被捕获并映射为可读的 `InvalidInput` 错误，不得崩溃、不得把 `RemoteError`/堆栈穿透到界面。
  - **沙箱内处理**：CPU 密集工作在 `compute` 隔离区执行；Web 因 dart2js 不支持 `ReceivePort.listen` 而在主 isolate 执行，此处不得引入阻塞式无限循环。
  - **输出写入**：原生端默认写到系统临时目录下的 `OmniConvert/` 子目录，用户指定路径时写到给定路径；需防路径穿越、覆盖非预期文件与失败后半成品残留。
- **原生文件处理**：文件选择器路径回退、临时文件清理、输出路径处理。
- **Web 端**：SQLite WASM / IndexedDB 本地数据、浏览器内存中的图片处理、下载结果。
- **更新与发布**：`releases/latest.json` 解析、下载来源与完整性、Android 安装器交接（不得绕过系统确认）。以下三项是硬约束，偏离即视为漏洞：
  - 更新包下载地址与应用清单地址都必须是 **HTTPS**，手动跟随重定向时**每一跳**都必须校验 scheme，且跳数不得超过 5；
  - 下载过程必须**流式**计算并与清单比对 **SHA-256**，不匹配要删除已落盘文件（半成品绝不能进安装器）；
  - 清单里的 `sha256` 不是 64 位十六进制、或下载文件名不可用时，必须直接拒绝下载。
- **服务器转换边界**：MOBI / DOCX → PDF 会通过 `POST /api/v1/conversions/pdf` 上传文件（默认 `https://www.sinxysai.site/api/v1`，可用 `--dart-define=OMNICONVERT_API_BASE_URL=` 覆盖），服务端在转换后即用即删。若发现未在用户操作下上传、上传范围超出说明（例如本机工具也发了请求）、上传文件被留存，或错误地回显服务端凭据，请报告。
- **OCR provider**：官方 OCR 当前未开放，页面只显示「暂未开放」。`ocr-provider-v1` 相关配置的安全要求仍然适用：HTTPS 要求（仅显式标记的本地开发地址允许 HTTP）、凭据存储、错误信息中不得回显令牌或完整本地路径。
- **CI 与供应链**：Release workflow 的权限、签名密钥使用、制品与 `SHA256SUMS.txt` 的可信度、依赖来源。

## 不在范围内

- 私有后端服务端的实现与部署（请勿在公开渠道测试）。
- 转换服务缺少 CORS 头导致的浏览器同源限制：这是已知限制（浏览器侧只在与官网同源的场景可用），不作为漏洞处理；但若发现该限制可被绕过并造成实际影响，请报告。
- LibreOffice、Calibre 等第三方转换器自身的漏洞（请报告给上游；服务端/适配层的问题仍在范围内）。
- 已知未验证项：macOS Developer ID 签名与公证、iOS 发布、各平台正式安装行为；这些属于发布前验收，不作为安全漏洞处理（但若可导致任意代码执行等实际影响，请报告）。
- 需要物理接触设备、社会工程、垃圾邮件或单纯流量型 DoS。
- 只是“使用了调试构建/未签名 CI 产物”这类已知状态。

## 处理流程

1. 维护者在收到报告后争取 **7 天内**给出初步响应（个人维护项目，请理解响应时间可能波动）。
2. 与报告者确认影响范围；必要时先在私有分支修复并在本地/CI 验证。
3. 修复进入新版本后，与报告者协调披露时间；经同意可在 CHANGELOG 或 Release Notes 中致谢。
4. 本项目不提供漏洞赏金（no bug bounty），但会认真对待每一份报告。

## 安全港

我们支持善意的安全研究。只要研究行为限于**你自己的环境**、使用你自己的文件、不破坏数据、不侵犯他人隐私、不中断服务、不进行未授权访问，并按本策略私下报告，我们不会就此采取法律行动。请给维护者合理的修复时间，避免公开尚未修复的细节。

## 相关文档

- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)
- 行为准则：[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- 隐私边界：本仓库 [README.md](README.md) 的“隐私边界”与“已知限制”两节
- 执行层与更新链路：[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- OCR 协议：[docs/docs/self-hosted-provider.md](docs/docs/self-hosted-provider.md)
- 实施状态：[docs/implementation-status.md](docs/implementation-status.md)
