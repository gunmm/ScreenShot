# Design: 修复中文系统下显示英文的本地化回退问题

## 现状（As-is）

- 当前项目仅有 `Base.lproj`（存放了中文文案）与 `en.lproj` 两个本地化目录。
- `project.pbxproj` 中的 `developmentRegion` 被配置为 `en`。
- iOS 在中文系统下寻找 `zh-Hans.lproj` 失败后，由于开发语言配置为英文，直接降级采用 `en.lproj`，使得中文系统的用户看到了英文界面。

## 方案（To-be）

- **总体思路**：采用苹果推荐的本地化规范，为简体中文显式创建对应的语言目录，而不仅仅依赖 `Base.lproj`。
- **数据流 / 构建步骤**：
  1. 在 `LongScreenShot` 目录下新建 `zh-Hans.lproj` 文件夹。
  2. 拷贝 `LongScreenShot/Base.lproj/Localizable.strings` （由于里面目前存放的是中文）到 `zh-Hans.lproj/Localizable.strings`。
  3. 通过项目根目录提供的本地化脚本（或直接使用 ruby 脚本如 `add_localization_to_pbxproj.rb` / `Xcodeproj` 等工具）将 `zh-Hans.lproj/Localizable.strings` 添加到工程文件的 PBXVariantGroup 中。
  4. 同样如果存在其他如 `InfoPlist.strings`，也进行相同的处理。

## 兼容性与迁移

- 此改动仅涉及资源和 Build Phase，向后完全兼容，无老数据变动。
- `Base.lproj` 保持原样作为默认基准（或后续根据需逐步统一为只含界面构件而无特定语言字符串的形式，但本次改动不做大调）。

## 回滚策略

- 如果工程文件破坏导致构建失败，使用 `git checkout -- LongScreenShot.xcodeproj/project.pbxproj` 还原即可，同时 `rm -rf LongScreenShot/zh-Hans.lproj`。
