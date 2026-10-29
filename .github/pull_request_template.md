## 变更说明 / Summary

<!-- 这个 PR 做了什么？为什么需要？关联的 issue 是什么？ -->

## 关联 issue / Related issue

<!-- 如 Fixes #123；没有则写“无” -->

## 变更类型 / Type of change

- [ ] 缺陷修复（fix）
- [ ] 新功能（feat）
- [ ] 重构或性能（refactor / perf）
- [ ] 文档（docs）
- [ ] 测试（test）
- [ ] CI / 构建（ci）

## 影响平台 / Affected platforms

- [ ] Web / PWA
- [ ] Windows
- [ ] Linux
- [ ] Android
- [ ] macOS（未发布验证）
- [ ] iOS（仅构建检查）
- [ ] 跨平台 / 不涉及平台代码

## 验证 / Verification

<!-- 勾选并填写实际结果，不要只写“已测试” -->

- [ ] `flutter analyze` → 结果：
- [ ] `flutter test` → 结果：<!-- 例如 13 项通过 -->
- [ ] `cargo test --manifest-path rust/Cargo.toml` → 结果：
- [ ] `cargo build --manifest-path rust/Cargo.toml` → 结果：
- [ ] 修改 `rust/src/api.rs` 后已运行 `flutter_rust_bridge_codegen generate` 并提交生成文件
- [ ] 涉及 Web：`flutter build web --release --base-href /app/` → 结果：
- [ ] 涉及平台构建：`tool/verify_platforms.ps1` / `tool/verify_platforms.sh` → 结果：
- [ ] 涉及 UI：附截图（说明平台与窗口尺寸）

## 截图 / Screenshots

<!-- UI 改动请附前后对比；没有可删除本节 -->

## 检查清单 / Checklist

- [ ] 一个 PR 只解决一个问题，改动范围清晰。
- [ ] 未提交 `build/`、`.dart_tool/`、`rust/target/`、`.toolchains/`、`ops/ssh/` 或任何密钥。
- [ ] 未修改与本 PR 无关的站点发布数据（官网仓库负责）。
- [ ] 行为变化已同步更新 `docs/implementation-status.md` 与相关文档。
- [ ] 未夸大尚未验证的能力（官方 OCR、iOS/macOS 发布、正式安装包）。
- [ ] 新增依赖/资源已确认许可证兼容，必要时更新 `THIRD_PARTY_NOTICES.md`。
- [ ] 涉及文件上传（DOCX/MOBI、OCR provider）时，隐私边界说明已更新且用户可感知。

## 备注 / Notes

<!-- 需要维护者特别关注的地方，例如跨平台差异、未验证项、发布影响 -->
