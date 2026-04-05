# Design: 反馈提交失败重试按钮

## 方案概述

在 `submitTapped()` 的失败回调中，将错误 Alert 的 Action 从单一"确定"扩展为"重试"+"取消"两个 Action。

## 模块 / 数据流

```
submitTapped()
  └─ CloudKitManager.uploadFeedback(...)
       ├─ success=true  → 成功 Alert → dismiss VC
       └─ success=false → 失败 Alert
                          ├─ [重试] → 再次调用 submitTapped()
                          └─ [取消] → dismiss Alert，停留页面
```

## 接口变更

无新接口，仅变更 `FeedbackViewController.submitTapped()` 内的失败分支 Alert 配置。

## 取舍

- 选择 `UIAlertController` 双 Action 而非自定义视图内嵌重试按钮，保持与现有代码风格一致，改动最小。
- 重试直接复用 `submitTapped()`，确保逻辑单一来源，无重复代码。

## 回滚方案

将失败分支 Alert 的"重试"Action 删除，只保留"取消"（原"确定"）即可恢复。
