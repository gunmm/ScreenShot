# 任务拆解：xcconfig 集成

- [ ] 1. 在项目根目录（或 LongScreenShot/ 下）新建 `PMConfig.xcconfig` 文件，写入初始变量 `APP_VERSION=1.0.1` 和 `APP_BUILD_NUMBER=1`。
- [ ] 2. 使用 xcodeproj 脚本或直接通过 Xcode 命令行集成（我们将通过 Ruby 脚本 `fix_project.py` 或者 python 脚本自动修改 `project.pbxproj`，或者手动解析替换 pbxproj 文件）使 `LongScreenShot`、`ScreenCapture` 和 `ScreenCaptureSetupUI` 的 Debug 和 Release Configuration 使用 `PMConfig.xcconfig`。
- [ ] 3. 更新 Target 的 Build Settings，将 `MARKETING_VERSION` 设置为 `$(APP_VERSION)`，将 `CURRENT_PROJECT_VERSION` 设置为 `$(APP_BUILD_NUMBER)`。
- [ ] 4. 验证项目的 Info.plist 是否不再硬编码版本号（若有）。
- [ ] 5. 使用 `xcodebuild -showBuildSettings` 验证各个 target 的版本号输出正确。
