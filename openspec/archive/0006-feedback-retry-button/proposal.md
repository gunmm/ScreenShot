# Proposal: 反馈提交失败时增加重试按钮

## 背景 / 动机

- 当前 `FeedbackViewController` 提交反馈失败后，仅弹出包含"确定"按钮的错误 Alert，用户只能关闭提示后手动再次点击"提交"按钮。
- 对于网络波动等瞬时错误，用户体验不佳；增加"重试"按钮可让用户一步完成重试操作。

## 目标（Goals）

- G1: 提交失败的 Alert 中增加"重试"按钮，点击后直接再次触发提交逻辑。
- G2: 保留"取消"按钮，让用户选择放弃重试。

## 非目标（Non-goals）

- NG1: 不引入自动重试逻辑（指数退避等），保持用户主动控制。
- NG2: 不改变成功流程和 UI 布局。

## 范围（Scope）

- **会改的部分**：
  - 文件：`LongScreenShot/FeedbackViewController.swift`
  - 行为变化：提交失败 Alert 从单按钮变为双按钮（重试 + 取消）。
- **不会改的部分**：CloudKitManager、成功流程、UI 布局。

## 需求概要

1. 提交失败 Alert 标题"提交失败"，展示错误信息。
2. Alert 包含两个操作：
   - **重试**（`.default` 样式）：点击后再次调用 `submitTapped()`。
   - **取消**（`.cancel` 样式）：点击后关闭 Alert，用户停留在页面可自行编辑或退出。

## 验收标准（Acceptance Criteria）

- AC1: 提交失败后弹出 Alert，同时显示"重试"和"取消"两个按钮。
- AC2: 点击"重试"后再次发起 CloudKit 上传，期间显示加载 Alert。
- AC3: 点击"取消"后关闭 Alert，页面不关闭，用户输入内容保留。
- AC4: 提交成功流程不受影响。

## 风险与回滚

- **风险**：极低，仅变更 Alert Action 配置。
- **回滚方案**：还原 `submitTapped` 方法中失败分支的 Alert Action 为单一"确定"按钮。
