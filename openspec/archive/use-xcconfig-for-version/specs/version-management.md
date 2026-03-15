# 需求规格：版本号管理规范

## 1. 用户故事
作为项目维护者，我希望能在一个统一的配置文件中修改一次版本号和编译号，使得所有关联 Target（App 及 Extensions）都能自动生效，从而避免多次手动修改引发的出错。

## 2. 边界条件
- 该配置只作用于项目级别的公共设置（特定 Target 如有独立需要，可通过附加逻辑覆盖，但当前需求要求版本号严格统一）。
- 支持至少主 App (`LongScreenShot`)、抓屏扩展 (`ScreenCapture`) 以及抓屏设置扩展 (`ScreenCaptureSetupUI`)。

## 3. 验收细则
- **单点更新**：开发人员更新 `PMConfig.xcconfig` 时，所有目标应用程序、框架和应用扩展都应接收到新的版本和构建数字（分别体现在打包好的 `Info.plist` 中的 `CFBundleShortVersionString` 和 `CFBundleVersion`）。
- **兼容性**：必须在现有的 Xcode 构建生命周期中正常工作，不对 Fastlane 或其他 CI 产生破坏性影响（若 CI 有修改构建配置的脚本，后续可能需要适应读取 `.xcconfig`，但这属于正常演进）。
