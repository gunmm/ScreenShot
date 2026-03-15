# Specification: English Localization

## 需求说明 (User Story)
作为一名设备的系统语言为英语的国际用户，我希望应用的界面以及系统的权限弹窗（如相册访问）均以全英文展示，以便我可以无障碍地使用该产品。

## 边界与规则 (Rules & Boundaries)
- **触发条件**：设备的区域与语言被设置为英语（English）。
- **默认回退**：如果在非英语且非中文的环境下（除非后续扩展），系统默认依照 iOS 备选语言列表回退，默认支持中文（原设定如果为中文的话）。
- **UI 适配**：由于英文单词长度往往超过中文单词，UI 布局需要利用约束弹性和多行显示 (`numberOfLines = 0` / minimumScaleFactor) 解决可能的文本截断，不能容忍 `...` 式的显示错误。
- **动态宽度**：开始录制按钮的容器 (`recordContainer`) 等带有固定宽度的控件，需要将其宽度约束设为 `greaterThanOrEqualToConstant`，并基于内部文本动态撑开以保证文字不超出边界或被截断。
