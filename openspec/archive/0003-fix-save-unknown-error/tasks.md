# Tasks: 修复保存图片未知错误

- [ ] 1. 在 `openspec/changes/0003-fix-save-unknown-error/` 下补齐相关需求文档（proposal, design, spec）。
- [ ] 2. 修改 `ViewController.swift`，确保 `performSave` 方法内的 `UIImageWriteToSavedPhotosAlbum` 运行在主线程上。
- [ ] 3. 修改 `ViewController.swift` 的完成回调 `image(_:didFinishSavingWithError:contextInfo:)`，确保其中的 UI 操作在主线程运行（虽然系统文档称其由 `UIImageWriteToSavedPhotosAlbum` 回调通常为主线程，但明确一下更为稳妥）。
- [ ] 4. 进行效果验证（检查代码修改的合理性）。
- [ ] 5. 将修复同步到 `openspec/specs/` 中。
- [ ] 6. 归档本次变更到 `openspec/archive/0003-fix-save-unknown-error`。
