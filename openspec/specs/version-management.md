# 版本号管理规范

## 核心规范
项目采用中心化的 `.xcconfig` 文件对版本号进行统一配置，确保所有子模块（主工程和扩展应用）具有一致的版本和构建号。

## 实现机制
- 根目录存在配置文件 `PMConfig.xcconfig`。
- 所有 Xcode 目标应用配置为读取此 `.xcconfig` 用作它们的 Configuration Profile。
- 项目的 `MARKETING_VERSION` (Version) 和 `CURRENT_PROJECT_VERSION` (Build) 被设置为对 `$(APP_VERSION)` 和 `$(APP_BUILD_NUMBER)` 变量的引用。

## 版本升级指引
每次发布新版本或进行构建号自增时，只需要在 `PMConfig.xcconfig` 修改对应的变量数值，即可完成全局配置生效，严禁将值覆盖写死在任何 target 的 Build Settings 中。
