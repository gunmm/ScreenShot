# Tasks: 初赛 Demo 最小闭环（可执行清单）

> 规则：任务必须**可执行、可验证、可按顺序完成**。完成一项打勾一项。

## A. 规格与方案（先文档）

- [x] 完成本变更 `proposal.md`
- [x] 完成本变更 `design.md`
- [x] 补齐本变更 `specs/`（流程/演示脚本/PPT 大纲）

## B. 产品闭环（实现）

### B1 引导与状态（主流程顺滑）

- [x] 在 `LongScreenShot/ViewController.swift` 引入显式状态机（Idle/Generating/Generated/Failed 等），统一管理：
  - [x] 主按钮可点击状态
  - [x] statusLabel 文案
  - [x] loading 展示与交互禁用
- [x] 在主界面增加“如何录制”的引导文案卡片（最少 3 条）：
  - [x] 点击开始录制
  - [x] 去目标 App 连续向下滚动 10-30 秒
  - [x] 回来一键生成并分享/保存
- [x] 生成前做一次“是否有 chunk”的快速检查，并给出可行动建议（而不是仅提示没有 chunk）

### B2 分享导出（创新性 + 完成度）

- [x] 新增“Share”按钮（生成成功后启用）
- [x] 使用 `UIActivityViewController` 分享生成的长图
- [ ] 处理边界：
  - [x] 无图时点击分享不崩溃（按钮禁用或提示）
  - [ ] 分享前若需要落临时文件，失败要提示

### B3 失败/降级提示（可解释）

- [x] 为以下情况提供明确提示文案：
  - [x] NoChunks（未录制/未找到 chunk）
  - [x] StitchFailed（拼接失败）
  - [x] PermissionDenied（相册拒绝）
- [x] 在失败提示中提供“下一步怎么做”的建议（复现友好）
- [x] 保留并强化 Debug 入口：
  - [x] 在失败提示旁提供“预览分片”入口（跳到 `ChunksPreviewViewController`；失败提示文本可点击）

### B4 结果更惊艳（延后）

- [ ] 结果历史（最近 3 次）或基础编辑能力（裁边/马赛克）作为后续变更，不进入本次初赛最小闭环

## C. 自测（必须）

- [ ] AT-1 主流程顺畅（见 `specs/demo-flow.md`）
- [ ] AT-2 未录到 chunk 的可解释性
- [ ] AT-3 拼接失败的可解释性

## D. 同步主规格（必须）

- [x] 将“初赛 Demo 新增的用户可见行为”同步回 `openspec/specs/long-screenshot.md`（UI/流程章节）

## E. 归档（完成后）

- [ ] 将 `openspec/changes/0002-contest-demo/` 移动到 `openspec/archive/`（保留编号）

