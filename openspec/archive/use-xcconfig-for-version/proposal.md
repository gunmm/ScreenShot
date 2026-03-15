# 提案：使用 PMConfig.xcconfig 统一管理版本号

## 1. 动机
目前项目中的版本号 (`MARKETING_VERSION`) 和 Build 号 (`CURRENT_PROJECT_VERSION`) 在各个 Target（主 App、ScreenCapture、ScreenCaptureSetupUI 等扩展）中独立配置（甚至硬编码在 Info.plist 中）。
这导致每次发布新版本时，需要手动到多个地方修改，容易遗漏并造成版本不一致。

## 2. 范围
- 引入统一的 `PMConfig.xcconfig` 文件。
- 为所有 Targets 配置使用 `PMConfig.xcconfig`。
- 将版本号提取为 `APP_VERSION` 和 `APP_BUILD_NUMBER` 并在 `PMConfig.xcconfig` 中统一配置。
- 修改 `project.pbxproj` 中的配置，使其读取 `.xcconfig` 文件中的变量。

## 3. 非目标
- 不改变原有的打包、签名或发布流程。
- 不修改代码逻辑。

## 4. 验收标准
- `PMConfig.xcconfig` 文件正确集成并在项目中可见。
- 修改 `PMConfig.xcconfig` 中的 `APP_VERSION` 和 `APP_BUILD_NUMBER` 后，重新编译，所有相关扩展和主应用的 Info.plist 或打包结果中对应的版本号都同步更新。
- 能够正常编译和运行项目。

## 5. 风险
- `.xcconfig` 配置可能覆盖原有环境变量或被 Build Settings 覆盖，需确保 Target Build Settings 中的相关字段不含有覆盖值（或者设置为 `$(inherited)` / 等同引用）。
