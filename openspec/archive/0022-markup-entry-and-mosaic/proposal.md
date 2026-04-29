# Proposal: 编辑方式中间页与马赛克页骨架

## 背景 / 动机

- 当前主页点击“涂抹/打码”后会直接进入 MarkupViewController，缺少在“自由涂抹”和“真实马赛克”之间做能力分流的入口。
- 现有 MarkupViewController 基于 PencilKit，适合自由笔迹遮挡，但并不具备像素化马赛克能力。
- 在不打断现有涂抹能力的前提下，先插入一个中间选择页并补齐 MosaicViewController 骨架，能为后续真正的马赛克算法接入预留稳定的交互和导航结构。

## 目标（Goals）

- G1: 主页点击“涂抹/打码”后，先进入编辑方式中间页而不是直接进入 MarkupViewController。
- G2: 中间页允许用户继续进入现有涂抹页，或进入一个可导航、可返回的马赛克页骨架。
- G3: 保持主页与编辑页之间现有的图片回传接口不变，避免扩大到拼接、保存和水印逻辑。

## 非目标（Non-goals）

- NG1: 本次不实现真实的像素化马赛克算法。
- NG2: 本次不重构 MarkupViewController 的绘制与导出机制。
- NG3: 本次不引入编辑工程持久化、再次编辑恢复或马赛克历史记录。

## 范围（Scope）

- **会改的部分**：
  - 文件/模块：ViewController、MarkupViewController、新增 MarkupEntryViewController、新增 MosaicViewController、OpenSpec 文档。
  - 行为变化：主页“涂抹/打码”入口先进入中间选择页；从中间页可跳到涂抹页或马赛克骨架页。
- **不会改的部分**：
  - 拼接算法、保存/PDF 导出、付费水印、Broadcast 录制链路。

## 需求概要

- 主页点击“涂抹/打码”后，应先展示“选择编辑方式”页面。
- 中间页应提供“涂抹”与“马赛克”两个入口。
- “涂抹”入口应继续复用现有 MarkupViewController，并保持完成后回写主页图片。
- “马赛克”入口应进入新的 MosaicViewController 骨架页，页面具备基础导航、预览区域和占位说明。
- 若子页面是从中间页 push 进入，返回行为应回到中间页而不是直接关闭整个流程。

## 验收标准（Acceptance Criteria）

- AC1: 主页点击“涂抹/打码”后，不再直接进入 MarkupViewController，而是进入中间选择页。
- AC2: 在中间页点击“涂抹”后，可进入现有涂抹编辑页；点击系统返回后可回到中间页。
- AC3: 在中间页点击“马赛克”后，可进入 MosaicViewController 骨架页；页面至少包含标题、原图预览和“功能开发中”占位文案。
- AC4: 涂抹页点击“完成”后，仍会把结果图回传主页并关闭整个编辑流程。

## 风险与回滚

- **风险**：
  - MarkupViewController 之前以“独立模态页”假设实现取消逻辑，接入 push 流程后若返回策略调整不完整，可能造成导航不符合预期。
  - 马赛克页骨架若暴露了可保存的假动作，可能误导用户以为真实马赛克已经可用。
- **回滚方案**（如何恢复到变更前状态）：
  - 删除中间页与 MosaicViewController，恢复 ViewController 直接 present MarkupViewController 的旧链路。
