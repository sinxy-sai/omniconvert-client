# 文档索引 / Documentation index

本目录保存 OmniConvert 客户端的实施状态、设计规格和说明文档。新增或调整文档时请同步本索引。

## 面向使用者与贡献者

| 文档 | 内容 |
| --- | --- |
| [../README.md](../README.md) | 项目简介、能力与格式、平台矩阵、快速开始、目录结构、隐私边界与许可证 |
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | 开发环境、工具链、测试与平台构建、代码生成、提交与 PR 规范、发布流程 |
| [../CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) | 行为准则（Contributor Covenant 2.1） |
| [../SECURITY.md](../SECURITY.md) | 漏洞私下报告渠道、范围与处理流程 |
| [../CHANGELOG.md](../CHANGELOG.md) | 版本变更记录 |
| [implementation-status.md](implementation-status.md) | 当前已实现、已验证与待验证事项（跨仓库边界的权威状态说明） |

## 使用说明

| 文档 | 内容 |
| --- | --- |
| [docs/external-converters.md](docs/external-converters.md) | 桌面外部转换器（LibreOffice DOCX→PDF、Calibre MOBI→PDF）的依赖、进程安全与限制 |
| [docs/self-hosted-provider.md](docs/self-hosted-provider.md) | 自建 `ocr-provider-v1` 公式识别服务的协议与安全要求 |

## 设计规格与计划

这些文档记录了设计决策与实施顺序，部分内容是历史计划，**不代表当前已全部实现**；当前状态以 [implementation-status.md](implementation-status.md) 为准。

| 文档 | 内容 |
| --- | --- |
| [superpowers/specs/2026-10-19-omniconvert-design.md](superpowers/specs/2026-10-19-omniconvert-design.md) | 产品与系统设计规格（本地优先、隐私边界、OCR provider、发布原则） |
| [superpowers/plans/2026-10-19-omniconvert-roadmap.md](superpowers/plans/2026-10-19-omniconvert-roadmap.md) | 总体实施路线图 |
| [superpowers/plans/2026-10-19-omniconvert-client-foundation-plan.md](superpowers/plans/2026-10-19-omniconvert-client-foundation-plan.md) | 客户端基础工程与任务/导航计划 |
| [superpowers/plans/2026-10-19-omniconvert-local-tools-plan.md](superpowers/plans/2026-10-19-omniconvert-local-tools-plan.md) | 本地图片/文档工具计划 |
| [superpowers/plans/2026-10-19-omniconvert-ocr-service-plan.md](superpowers/plans/2026-10-19-omniconvert-ocr-service-plan.md) | OCR 服务与 provider 计划（官方 OCR 当前未开放） |
| [superpowers/plans/2026-10-19-omniconvert-site-release-plan.md](superpowers/plans/2026-10-19-omniconvert-site-release-plan.md) | 官网与发布计划（官网已迁至独立仓库） |
| [superpowers/plans/2026-10-27-cross-platform-installers-and-release-packaging.md](superpowers/plans/2026-10-27-cross-platform-installers-and-release-packaging.md) | 跨平台安装包与发布打包计划 |

## 写作约定

- 中文为主，关键结论可中英双语；版本号、链接、哈希必须可核对。
- 明确区分“已实现 / 已验证 / 待验证”，不要声称未实现的功能。
- 官方 OCR 标注为暂缓；iOS 与 macOS 标注未发布、未验证；DOCX/MOBI 转换需要上传文件，必须在隐私说明中写清楚。
- 跨仓库职责边界（client / site / backend）以 `implementation-status.md` 为准。
