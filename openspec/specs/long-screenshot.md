# LongScreenShot — 已实现规格

> 本文档描述**当前代码已实现**的行为与约束，是主规格（Source of Truth）。

## 1. 项目概述

- **项目名称**：LongScreenShot
- **平台**：iOS（工程 `IPHONEOS_DEPLOYMENT_TARGET = 18.2`）
- **核心能力**：通过 ReplayKit 广播扩展采集用户滚动过程中的屏幕帧（分片），使用 OpenCV 估计相邻帧重叠位置并裁剪拼接，生成一张长截图并保存到系统相册。
- **网络/服务端**：无（本项目当前不上传、不联网；所有数据本地落盘在 App Group 共享容器）

## 2. 术语

- **主 App**：`LongScreenShot`（用户看到的界面，负责生成/预览/保存长图）
- **上传扩展（Broadcast Upload Extension）**：`ScreenCapture`（实现 `RPBroadcastSampleHandler`，负责接收视频帧并写入分片）
- **Setup UI 扩展**：`ScreenCaptureSetupUI`（ReplayKit 的设置 UI，当前基本为模板）
- **Chunk/分片**：扩展采集到的单帧截图（JPEG 文件），按顺序存入共享目录
- **Overlap/重叠**：相邻两张分片之间可匹配的重复内容，用于裁剪拼接

## 3. 目标与非目标

### 3.1 目标（Goals）

- **G1：稳定采集**：只在用户“向下滚动”且画面确实变化时保存帧，避免静止帧/抖动帧导致重复与错拼。
- **G2：可重复生成**：主 App 能在任意时间读取当前 chunk 目录，生成一张长图（允许生成失败并提示原因）。
- **G3：可落盘保存**：用户授权后可将生成的长图保存到系统相册（Add-only 权限）。
- **G4：可调试**：提供分片预览（Debug）以定位采集与拼接问题。

### 3.2 非目标（Non-goals）

- **NG1**：不做云端同步/分享链接/账号系统
- **NG2**：不保证对所有 App/所有滚动形态都完美拼接（例如大面积动态内容、视频、强视差动画）
- **NG3**：不做 OCR、自动裁边、自动去状态栏/导航栏的全自动编辑（可作为后续变更提案）

## 4. 代码结构（当前实现）

- **主 App**
  - `LongScreenShot/ViewController.swift`：主界面与“生成/预览/保存”入口
  - `LongScreenShot/Main/ChunksPreviewViewController.swift`：分片预览（Debug）
- **共享逻辑（主 App 与扩展共用，走 App Group）**
  - `LongScreenShot/Shared/AppGroupConfig.swift`：App Group 与共享目录
  - `LongScreenShot/Shared/ChunkManager.swift`：分片落盘与读取
  - `LongScreenShot/Shared/ImageStitcher.swift`：拼接（裁剪+纵向拼贴）
  - `LongScreenShot/Shared/OpenCVWrapper.{h,mm}`：OpenCV（ORB + 模板匹配）能力封装
  - `LongScreenShot/Shared/LongScreenShot-Bridging-Header.h`：Swift/ObjC 桥接
- **扩展**
  - `ScreenCapture/SampleHandler.swift`：采集、过滤、落盘 chunk
  - `ScreenCapture/Info.plist`：`com.apple.broadcast-services-upload`
  - `ScreenCaptureSetupUI/BroadcastSetupViewController.swift`：设置 UI（模板）
  - `ScreenCaptureSetupUI/Info.plist`：`com.apple.broadcast-services-setupui`

## 5. 数据与存储规范

### 5.1 App Group

- **App Group ID**：`group.gunmm.LongScreenShot`
  - 来源：`LongScreenShot/LongScreenShot.entitlements`、`ScreenCapture/ScreenCapture.entitlements`、`LongScreenShot/Shared/AppGroupConfig.swift`
- **共享容器路径**：`<AppGroupContainer>/ScreenChunks/`

### 5.2 Chunk 文件

- **格式**：JPEG（当前质量 `0.8`）
- **文件名**：`chunk_%04d.jpg`（例如 `chunk_0000.jpg`）
- **排序规则**：按文件名字符串排序，保证顺序与 index 一致
- **生命周期**
  - 广播开始时必须清空目录（避免历史 chunk 干扰）
  - 广播结束后不强制清空，便于回放/调试（可由后续提案调整）

> 约束：任何未来改动**不得**把 chunk 写到 App 沙盒私有目录，否则主 App/扩展将无法共享数据。

## 6. 端到端流程（E2E）

### 6.1 采集流程（扩展 `ScreenCapture`）

触发点：用户在主 App 点击系统录制入口启动广播。

1. `broadcastStarted`：
   - 设置 `isRecording = true`
   - `chunkIndex = 0`
   - 清空共享目录：`AppGroupConfig.clearChunkDirectory()`
2. `processSampleBuffer`（仅处理 `.video`）：
   - **时间节流**：两次处理间隔至少 `0.2s`
   - **有效性判断**：
     - 若有上一帧 `lastProcessedBuffer`，调用 `OpenCVWrapper.comparePixelBuffer(..., staticThreshold: 5.0)`
     - 判定为“有效下滑”的条件（当前代码）：
       - `dy > 50`（dy 越大表示内容上移越明显，用户下滑越明显）
       - `confidence >= 0.15`
     - 否则丢弃该帧（静止/上滑/误匹配/置信度低）
   - **保存 chunk**：
     - 将 pixelBuffer 转 `UIImage`（CIContext 生成 CGImage）
     - `ChunkManager.shared.saveChunk(image:index:)`
     - 更新 `lastProcessedBuffer`（深拷贝）与 `lastTimestamp`

#### 采集验收标准（Acceptance）

- **A-CAP-1**：用户不滚动时，目录中 chunk 数量应基本不增长（允许偶发误检，但不应持续增长）。
- **A-CAP-2**：用户持续向下滚动时，目录中 chunk 应稳定增长且 index 连续。

### 6.2 拼接流程（主 App）

触发点：用户点击 “Generate Long Screenshot”。

1. `ChunkManager.shared.loadAllChunks()` 读取 `ScreenChunks/` 下全部 `.jpg`
2. 若无 chunk：提示 “No chunks found...”
3. 后台线程调用 `ImageStitcher.stitch(images:)`：
   - 对每对相邻图片调用 `OpenCVWrapper.findOverlapBetween(img1, img2)`
   - 依据 `offsetY` 与 `matchYInImg2` 推导裁剪范围 `validRanges`
   - 对所有图片按 `validRanges` 逐张裁剪并**纵向拼贴**输出最终长图
4. 回到主线程展示结果：
   - 更新 imageView 与约束（保持宽度，按高宽比调整高度）
   - 启用 “Save to Photos”

#### 拼接验收标准（Acceptance）

- **A-STITCH-1**：当 chunk ≥ 2 时，能生成非空图片或明确失败提示（“Stitching failed.”）。
- **A-STITCH-2**：正常滚动场景下，拼接结果应**整体连续**，最多出现少量重复区域（当某一对匹配失败时允许“安全回退”为重复，而非缺失）。

### 6.3 保存到相册（主 App）

- iOS 14+ 请求 `.addOnly` 相册权限（或更低系统请求通用权限）
- 授权成功后调用 `UIImageWriteToSavedPhotosAlbum`
- 失败需在 UI 上提示错误原因

## 7. OpenCV 匹配与裁剪约定

### 7.1 “帧是否有效下滑”检测（`comparePixelBuffer`）

- 输出：`dy`、`confidence`、`meanDiff`
- 先用 `meanDiff < staticThreshold` 判静止帧（返回 0 shift/0 conf）
- ORB 匹配估计垂直位移：
  - 假设主要是**纵向滚动**（X 偏差过大丢弃）
  - dy 为正表示内容从旧帧到新帧“上移”（用户下滑）

### 7.2 “两张图片怎么拼”检测（`findOverlapBetween`）

优先 ORB，失败后回退模板匹配：

- **ORB 模式**：
  - Img1 取下半区域（排除 bottomMargin），Img2 取上部区域（跳过 topMargin）
  - 统计一致 shift 的比例作为 confidence
  - 若 shift ≤ 0 视为方向不可能（强制失败回退）
- **模板匹配回退**：
  - 在 Img1 ROI 底部取一条 strip 作为模板，在 Img2 ROI 中匹配
  - 要求匹配值 `> 0.55` 且 shift > 0

### 7.3 裁剪与拼贴规则（`ImageStitcher`）

- 每张图片有一个有效区间 `[start, end)`（像素坐标）
- 对每对相邻图推导：
  - Img(i) 的 `end = min(matchYInImg2 + offsetY, H1)`
  - Img(i+1) 的 `start = matchYInImg2`
- 若某一对匹配失败：保留默认 `[0, H]`（安全回退，允许重复内容出现）
- 负高度处理：若 `end < start`，认为该图冗余，将重叠“债务”向前传播裁剪前面图片
- 输出画布宽度以第一张图为准，最终高度为各有效区间高度之和

> 约束：任何对拼接算法的改动必须同时更新本节与对应验收标准（A-STITCH-*）。

## 8. UI/交互规范（当前）

主界面（`ViewController`）包含：

- **系统录屏入口**：`RPSystemBroadcastPickerView`（用户选择并启动广播）
  - 建议未来设置 `preferredExtension` 绑定到 `ScreenCapture` 的 Bundle ID，以减少用户选择成本（当前代码未设置）
- **录制引导文案**：提示用户“开始录制 → 去目标 App 连续下滑 10–30 秒 → 回来生成并分享/保存”
- **Generate Long Screenshot**：生成长图（生成前会检查 chunk 数量是否足够）
- **Debug: Preview Chunks**：打开分片预览（UICollectionView）
- **Share / 分享**：分享生成结果（无结果时禁用）
- **Save / 保存**：保存长图到相册（无结果时禁用；若权限拒绝会提示并可跳转系统设置）
- **状态提示**：展示生成进度、失败原因与下一步建议；失败状态下点击状态提示可快速打开分片预览

## 9. 权限与隐私

- **相册权限**：仅用于保存最终长图；不读取用户相册内容
- **ReplayKit**：采集的是“屏幕画面”，属于高敏数据
  - 本项目当前不上传、不外发
  - chunk 落盘在 App Group 容器中，用户卸载 App 后系统会清理

## 10. 性能与稳定性要求（NFR）

- **NFR-1（采集性能）**：扩展的 `processSampleBuffer` 不应阻塞太久；需保持节流与丢弃策略，避免大量写盘导致系统杀扩展。
- **NFR-2（拼接内存）**：拼接过程可能产生超长图片，必须在后台线程执行；必要时引入分段渲染/磁盘缓存（后续提案）。
- **NFR-3（可诊断性）**：关键路径需保留可读日志（当前已有打印），但不应泄露到线上日志系统（当前无日志上传）。

## 11. 变更流程（OpenSpec 落地方式）

当你要增加/修改功能时：

1. 在 `openspec/changes/` 新建变更目录（复制 `openspec/changes/_template/`）。
2. 按顺序完善 `proposal.md` → `specs/` → `design.md` → `tasks.md`。
3. 仅在文档齐备后开始改代码，并以 `tasks.md` 为唯一执行清单。
4. 完成后把本次变更沉淀回 `openspec/specs/`（更新本文档或新增规格文件）。
5. 将变更目录移动到 `openspec/archive/` 归档。

