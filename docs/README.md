# 文档索引 / Documentation index

本目录保存 OmniConvert 客户端的架构说明、能力清单、实施状态和设计规格。新增或调整文档时请同步本索引。

## 面向使用者与贡献者

| 文档 | 内容 |
| --- | --- |
| [../README.md](../README.md) | 项目简介、关键特性、工具与格式（6 个工具）、平台矩阵、快速开始、目录结构、隐私边界、已知限制 |
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | 开发环境、必跑检查、新增一个工具的完整路径、平台构建、提交与 PR 规范、发布流程 |
| [../CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) | 行为准则（Contributor Covenant 2.1） |
| [../SECURITY.md](../SECURITY.md) | 漏洞私下报告渠道、重点范围（纯 Dart 引擎、更新校验、上传边界）与处理流程 |
| [../CHANGELOG.md](../CHANGELOG.md) | 版本变更记录 |

## 架构与能力

| 文档 | 内容 |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 三仓职责边界、`tool/registry.json` 唯一事实源、执行层与错误模型、任务持久化、更新推送、部署与测试分层 |
| [capabilities.md](capabilities.md) | 支持的工具与格式（**由 `tool/registry.json` 自动生成，勿手改**） |
| [implementation-status.md](implementation-status.md) | 当前已实现、已验证与待验证事项（跨仓库边界的权威状态说明） |

工具清单的唯一事实源是 `tool/registry.json`（含每个工具的输入/输出格式、参数、默认值与 50 MB / 1 亿像素上限）。改完注册表后运行 `python tool/generate_registry.py` 重新生成 `lib/core/tools/tool_registry.g.dart`、官网站点与后端 capabilities 以及本文目录下的 `capabilities.md`。

## 使用说明

| 文档 | 内容 |
| --- | --- |
| [docs/external-converters.md](docs/external-converters.md) | 桌面外部转换器（LibreOffice DOCX→PDF、Calibre MOBI→PDF）的依赖、进程安全与限制 |
| [docs/self-hosted-provider.md](docs/self-hosted-provider.md) | 自建 `ocr-provider-v1` 公式识别服务的协议与安全要求（官方 OCR 当前未开放） |

## 设计规格与计划

这些文档记录 2026-10 的设计决策与实施顺序，**属于历史记录，不代表当前架构**：其中描述的原生处理核心、跨语言绑定与原生编译链已在 0.1.4 移除，本地图片/PDF 引擎改为一份纯 Dart 实现。当前状态一律以 [ARCHITECTURE.md](ARCHITECTURE.md) 与 [implementation-status.md](implementation-status.md) 为准。

| 文档 | 内容 |
| --- | --- |
| [superpowers/specs/2026-10-19-omniconvert-design.md](superpowers/specs/2026-10-19-omniconvert-design.md) | 产品与系统设计规格（本地优先、隐私边界、发布原则） |
| [superpowers/plans/2026-10-19-omniconvert-roadmap.md](superpowers/plans/2026-10-19-omniconvert-roadmap.md) | 总体实施路线图 |
| [superpowers/plans/2026-10-19-omniconvert-client-foundation-plan.md](superpowers/plans/2026-10-19-omniconvert-client-foundation-plan.md) | 客户端基础工程与任务/导航计划 |
| [superpowers/plans/2026-10-19-omniconvert-local-tools-plan.md](superpowers/plans/2026-10-19-omniconvert-local-tools-plan.md) | 本地图片/文档工具计划 |
| [superpowers/plans/2026-10-19-omniconvert-ocr-service-plan.md](superpowers/plans/2026-10-19-omniconvert-ocr-service-plan.md) | OCR 服务与 provider 计划（官方 OCR 当前未开放） |
| [superpowers/plans/2026-10-19-omniconvert-site-release-plan.md](superpowers/plans/2026-10-19-omniconvert-site-release-plan.md) | 官网与发布计划（官网已迁至独立仓库） |
| [superpowers/plans/2026-10-27-cross-platform-installers-and-release-packaging.md](superpowers/plans/2026-10-27-cross-platform-installers-and-release-packaging.md) | 跨平台安装包与发布打包计划 |

## 写作约定

- 中文为主，关键结论可中英双语；版本号、链接、哈希必须可核对。
- 明确区分「已实现 / 已验证 / 待验证」，不要声称未实现的功能。
- 当前技术事实：本地图片/PDF 引擎是一份纯 Dart 实现（`lib/core/tools/dart_tool_runner.dart`，`package:image` + `package:pdf`），所有平台同一段代码；运行时无原生库，构建不需要额外原生编译链。文档里不要再出现旧架构描述。
- 官方 OCR 标注为暂缓/未开放；iOS 与 macOS 标注未发布、未验证，macOS 未签名未公证；MOBI/DOCX 转换需要上传文件，必须在隐私说明中写清楚。
- 能力清单与参数只从 `tool/registry.json` 派生，不要在文档里另写一份格式表。
- 跨仓库职责边界（client / site / backend）以 `implementation-status.md` 为准。