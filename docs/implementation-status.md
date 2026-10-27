# OmniConvert 实施状态

更新：2026-10-27。

## 已实现

- 六平台 Flutter 工程骨架；访客可进入首页、任务、工具和设置。
- Rust 本地核心及 Flutter/Rust 生成绑定；Windows 上的 Dart→Rust 健康检查通过。
- 任务状态机、最近任务和失败/中断任务重试入口。
- SQLite 任务持久化；启动时将遗留的运行中任务标记为已中断。Web 使用 SQLite WASM 和 IndexedDB。
- 六目标 GitHub Actions 构建配置、本地验证脚本和第三方 WASM 许可声明。

## 已验证

- Windows 开发机：`flutter analyze`、`flutter test`（13 项）、`cargo test`、`cargo build`、`tool/verify_platforms.ps1 -Target web` 通过。
- Flutter Web 在 `/app/` 路径构建成功；无界面 Edge 加载时无页面错误，SQLite WASM 请求返回 200，IndexedDB 数据库创建成功。
- SQLite 测试覆盖创建/更新、排序、结构化错误、幂等键唯一性和重启恢复。
- GitHub Actions [运行 39471597280](https://github.com/sinxy-sai/omniconvert-client/actions/runs/39471597280) 全部通过：Windows、Linux、Android、Web、macOS 构建及 iOS 无签名编译检查；各作业的产物上传也通过。Android CI 修复提交为 `5aec27e`。
- 本地工具第一阶段已实现：Rust 工具契约、输入大小和像素限制、取消、临时文件原子发布、PNG→JPEG、图片压缩和单图→PDF；Dart/Rust 图片工具绑定、原生工具页与任务执行服务已接入，跨语言冒烟测试通过。
- 图片压缩和图片转 PDF 现在接受 PNG、JPEG 和 WebP 输入；PNG → JPEG 仍只接受 PNG 输入。任务记录页已接入真实的持久化任务仓库。
- Windows 原生图片处理在选择器路径不可直接访问时，会将已读取的输入字节落到临时文件后交给 Rust 核心，并在任务结束后清理临时文件；Web 端继续以内存字节处理。
- 桌面文档适配器已实现检测与安全进程边界：LibreOffice DOCX→PDF、Calibre MOBI→PDF，包含版本记录、超时、取消、输出校验和代表性 PDF 测试；第三方转换器仍由用户自行安装。
- 任务执行已支持运行中取消、迟到结果保护；任务页显示持久化历史和错误详情，不再提供无法恢复原始输入的伪重试按钮。

## 待验证和待做

## 跨仓库职责边界

- 客户端仓库负责 Flutter 界面、任务编排和本地图片处理；Rust 核心只处理本地文件，不能替代服务端 OCR。
- 官网仓库负责静态页面、`/app/` Web 构建产物和发布清单，不承载转换或 OCR 业务逻辑。
- backend 仓库负责需要上传同意的 OCR、账号、配额和异步队列。当前 backend 的识别提交接口返回 `202 queued`，而客户端仍按同步结果协议处理；在这项协议统一前，不应把官方 OCR 标记为已可用。

安装包与发布方案已接入 CI：Windows 生成 NSIS 安装器和 ZIP；macOS 生成 DMG 和 ZIP，且 universal 命名要求双架构；Linux 生成 AppImage、DEB 和 tar.gz；Android split-per-ABI 产出 arm64 APK，正式 tag 构建要求发布签名密钥。Release job 生成 `SHA256SUMS.txt`，官网下载页优先显示安装器及其他格式。真实 tag 发布、macOS Developer ID 签名与公证、各平台安装行为及官网线上清单仍待验证。

- Windows 桌面调试构建未完成：本机缺少 Flutter 所需的 Visual Studio C++ 工作负载；Flutter Windows 构建产物下载曾因 TLS 握手中断。Android SDK 本机未安装。
- 原生发行包的 Rust 库已在 Windows、Linux、macOS 和 Android release workflow 中加入构建/打包步骤；各平台实际安装和启动仍需在对应 runner 或设备上验收。
- DOCX/MOBI 适配器仍未接入 Flutter 工具页；官网发布流程及 OCR 服务属于后续计划。官网 `/app/` 的静态 Web 版本元数据已同步到客户端 0.1.2。

客户端基础计划的六平台 CI 构建检查已通过，正式安装包发布仍未执行；现有域名和服务器未改动。官网筹备页仍保留在本地 `ops/holding-page/` 和现有服务器上，含原有ICP备案与公安备案页脚；它已从客户端仓库的当前跟踪文件中移除，后续纳入独立官网仓库。
