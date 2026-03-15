# 技术方案：xcconfig 版本号提取

## 1. 模块变更
- **新增配置模块**：在项目根目录（或合适的公共配置目录，如 `LongScreenShot/` 同级）增加 `PMConfig.xcconfig` 文件。

## 2. 数据流与构建变更
- **定义**：在 `PMConfig.xcconfig` 中定义：
  ```xcconfig
  APP_VERSION = 1.0.1
  APP_BUILD_NUMBER = 1
  ```
- **注入**：在 `project.pbxproj` 级别，将 `PMConfig.xcconfig` 设置为主工程的 configuration baseline，或者手动设置各个 target 的 configuration file reference。
- **引用**：在 Target 的 Build Settings 中，移除硬编码的 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`：
  ```
  MARKETING_VERSION = $(APP_VERSION)
  CURRENT_PROJECT_VERSION = $(APP_BUILD_NUMBER)
  ```
  这样，Xcode 在生成产物时会自动填充正确的版本信息。

## 3. 取舍
- Xcode 原生的 Build Settings UI 非常方便使用，通过 `.xcconfig` 可能降低可视化便利性（对于不熟悉 `.xcconfig` 的开发者）。
- 但带来的好处明显大于坏处，维护成本大幅下降。

## 4. 回滚方案
- 直接使用 `git revert` 恢复 `project.pbxproj` 中的改动，并删除 `PMConfig.xcconfig`。
