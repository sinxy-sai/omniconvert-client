# OmniConvert 实施状态

更新：2026-10-21。

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
- 桌面文档适配器已实现检测与安全进程边界：LibreOffice DOCX→PDF、Calibre MOBI→PDF，包含版本记录、超时、取消、输出校验和代表性 PDF 测试；第三方转换器仍由用户自行安装。
- 任务执行已支持运行中取消、迟到结果保护和同一任务记录上的失败重试；取消不会被迟到的成功结果覆盖。

## 待验证和待做

- Windows 桌面调试构建未完成：本机缺少 Flutter 所需的 Visual Studio C++ 工作负载；Flutter Windows 构建产物下载曾因 TLS 握手中断。Android SDK 本机未安装。
- 原生发行包中 Rust 库的自动编译和打包尚未接入；当前跨语言健康检查从开发构建目录加载动态库。
- DOCX/MOBI 适配器尚未接入 Flutter 工具页；浏览器本地图片实现、官网发布流程及 OCR 服务属于后续计划。

客户端基础计划的六平台 CI 构建检查已通过，正式安装包发布仍未执行；现有域名和服务器未改动。官网筹备页仍保留在本地 `ops/holding-page/` 和现有服务器上，含原有ICP备案与公安备案页脚；它已从客户端仓库的当前跟踪文件中移除，后续纳入独立官网仓库。
