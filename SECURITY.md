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
- 该操作中文件应在本地处理还是上传到服务器（DOCX/MOBI 转换与 OCR 会联网）。
- 是否已公开或已告知第三方；是否希望匿名或致谢。

## 重点范围

- **Rust 本地核心**：图片/PDF 解析、尺寸与内存限制、临时文件与原子发布、越界与 panic 处理。
- **原生文件处理**：文件选择器路径回退、临时文件清理、输出路径处理。
- **Web 端**：SQLite WASM / IndexedDB 本地数据、浏览器内存中的图片处理、下载结果。
- **更新与发布**：`latest.json` 解析、下载来源与完整性、SHA-256 校验、Android 安装器交接（不得绕过系统确认）。
- **OCR provider**：`ocr-provider-v1` 的 HTTPS 要求（仅显式标记的本地开发地址允许 HTTP）、凭据存储、错误信息中不得回显令牌或完整本地路径。
- **服务器转换边界**：DOCX/MOBI → PDF 会上传文件；若发现未在用户操作下上传、上传范围超出说明或错误地回显服务端凭据，请报告。
- **CI 与供应链**：Release workflow 的权限、签名密钥使用、制品与 `SHA256SUMS.txt` 的可信度、依赖来源。

## 不在范围内

- 私有后端服务端的实现与部署（请勿在公开渠道测试）。
- LibreOffice、Calibre 等第三方转换器自身的漏洞（请报告给上游；客户端适配层的问题仍在范围内）。
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
- 隐私边界：本仓库 [README.md](README.md) 的“隐私边界”一节
- OCR 协议：[docs/docs/self-hosted-provider.md](docs/docs/self-hosted-provider.md)
- 实施状态：[docs/implementation-status.md](docs/implementation-status.md)
