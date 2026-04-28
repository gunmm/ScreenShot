# Tasks

- [x] OpenSpec 流程
  - [x] 创建 `proposal.md`
  - [x] 创建 `design.md`
  - [x] 创建并修改 `specs/long-screenshot.md`
- [x] 代码修改
  - [x] `LongScreenShot/Pay/PurchaseStatusManager.swift`: 删除试用期逻辑
  - [x] `LongScreenShot/ViewController.swift`: 删除旧的保存拦截和试用判断
  - [x] `LongScreenShot/ViewController.swift`: 添加 `unlockProButton` 引导付费按钮
  - [x] `LongScreenShot/ViewController.swift`: 添加全屏水印绘制逻辑 (`addFullScreenWatermark`)，文本为："图片来自 App Store滚动长截屏-滚动长截图"
  - [x] `LongScreenShot/ViewController.swift`: 修改预览逻辑，如果是未付费状态，直接使用全屏水印图展示和后续保存
- [ ] 同步与清理
  - [ ] Sync 到 `openspec/specs/long-screenshot.md`
  - [ ] Archive 当前变更记录
