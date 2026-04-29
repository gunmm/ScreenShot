import UIKit
import ReplayKit
import Photos

class ViewController: UIViewController, UIScrollViewDelegate {

    private let recordContainer = UIView()
    private let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    private let recordingLabel = UILabel()
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let stitchButton = UIButton(type: .system)
#if DEBUG
    private let previewButton = UIButton(type: .system) // New button
#endif
    private let settingsButton = UIButton(type: .system) // Top right settings button
    private let editButton = UIButton(type: .system) // Edit button
    private let markupButton = UIButton(type: .system) // Markup button
    private let saveButton = UIButton(type: .system)
    private let unlockProButton = UIButton(type: .system) // New unlock button
    private var rawStitchedImage: UIImage? // Store raw image without watermark
    private var hasMarkupEdits = false
    private let statusLabel = UILabel()
    private let guideLabel = UILabel()
    private let demoButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    
    private let actionsStack = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var imageAspectRatioConstraint: NSLayoutConstraint?
#if DEBUG
    private lazy var statusTapGesture = UITapGestureRecognizer(target: self, action: #selector(showPreview))
#endif
    
    private enum UIState: Equatable {
        case idle
        case generating(frameCount: Int)
        case generated(size: CGSize, images: [UIImage], ranges: [(start: Int, end: Int)])
        case failed(message: String)
        
        static func == (lhs: UIState, rhs: UIState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.generating(let l), .generating(let r)): return l == r
            case (.generated(let lSize, _, _), .generated(let rSize, _, _)): 
                // For UI state tracking, comparing the size and that it is 'generated' is sufficient.
                return lSize == rSize 
            case (.failed(let lMsg), .failed(let rMsg)): return lMsg == rMsg
            default: return false
            }
        }
    }
    
    private var state: UIState = .idle {
        didSet { render(state: state) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        PurchaseStatusManager.shared.setPurchased(false)
        setupUI()
        state = .idle
        
        // Auto-stitch if chunks exist on load
//        autoGenerateIfPossible()
        
        // Auto-stitch when returning from background
        NotificationCenter.default.addObserver(self, selector: #selector(autoGenerateIfPossible), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func autoGenerateIfPossible() {
        if ChunkManager.shared.chunkCount() >= 2 {
            generateLongScreenshot()
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("Long Screenshot", comment: "Main title")
        
        // 1. Record Container
        recordContainer.backgroundColor = .systemGray6
        recordContainer.layer.cornerRadius = 35
        recordContainer.clipsToBounds = true
        recordContainer.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(triggerBroadcastPicker))
        recordContainer.addGestureRecognizer(tap)
        recordContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordContainer)
        
        broadcastPicker.translatesAutoresizingMaskIntoConstraints = false
        recordContainer.addSubview(broadcastPicker)
        
        // 1.1 Start Recording Label
        recordingLabel.text = NSLocalizedString("开始录制", comment: "Start recording label")
        recordingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        recordingLabel.textColor = .label
        recordingLabel.translatesAutoresizingMaskIntoConstraints = false
        recordContainer.addSubview(recordingLabel)
        
        // We use a gesture on the container to trigger the picker,
        // so we don't need to put the picker behind or expand it.
        // We just place them side by side.
        
        // 2. Stitch Button
        stitchButton.setTitle(NSLocalizedString("生成结果图", comment: "Generate result image button"), for: .normal)
        stitchButton.addTarget(self, action: #selector(generateLongScreenshot), for: .touchUpInside)
        stitchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stitchButton)
        
#if DEBUG
        // 2.1 Preview Button
        previewButton.setTitle("Debug: Preview Chunks", for: .normal)
        previewButton.addTarget(self, action: #selector(showPreview), for: .touchUpInside)
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewButton)
#endif
        
        // 3. Guide Label
        guideLabel.text = NSLocalizedString("""
        录制步骤：
        1) 点上方“开始录制”
        2) 倒计时结束前切换到目标截图 App 由上向下连续向下滚动
        3) 回来点生成长截图
        """, comment: "Recording guide")
        guideLabel.textAlignment = .left
        guideLabel.font = .systemFont(ofSize: 13)
        guideLabel.textColor = .secondaryLabel
        guideLabel.numberOfLines = 0
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
        
        demoButton.setTitle(NSLocalizedString("视频演示", comment: "Video demo"), for: .normal)
        demoButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        demoButton.addTarget(self, action: #selector(openDemoVideo), for: .touchUpInside)
        demoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(demoButton)
                
        // 4. Settings Button
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        settingsButton.setImage(UIImage(systemName: "gearshape", withConfiguration: config), for: .normal)
        settingsButton.tintColor = .systemBlue
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)
        
        // 4.1 Clear Button
        let clearConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        clearButton.setImage(UIImage(systemName: "trash", withConfiguration: clearConfig), for: .normal)
        clearButton.tintColor = .systemRed
        clearButton.addTarget(self, action: #selector(clearDataTapped), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearButton)
        
        // 5. Edit / Save Buttons
        
        editButton.setTitle(NSLocalizedString("拼接调整", comment: "Edit button"), for: .normal)
        editButton.addTarget(self, action: #selector(editResult), for: .touchUpInside)
        editButton.isEnabled = false
        
        markupButton.setTitle(NSLocalizedString("涂抹/打码", comment: "Markup button"), for: .normal)
        markupButton.addTarget(self, action: #selector(markupResult), for: .touchUpInside)
        markupButton.isEnabled = false
        
        saveButton.setTitle(NSLocalizedString("保存", comment: "Save button"), for: .normal)
        saveButton.addTarget(self, action: #selector(showSaveOptions), for: .touchUpInside)
        saveButton.isEnabled = false
        
        unlockProButton.setTitle(NSLocalizedString("去水印", comment: "Unlock Pro button"), for: .normal)
        unlockProButton.setTitleColor(.systemBlue, for: .normal)
        unlockProButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        unlockProButton.addTarget(self, action: #selector(unlockProTapped), for: .touchUpInside)
        unlockProButton.isHidden = PurchaseStatusManager.shared.isPurchased()
        unlockProButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(unlockProButton)
        
        editButton.translatesAutoresizingMaskIntoConstraints = false
        markupButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.distribution = .fillEqually
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.addArrangedSubview(editButton)
        actionsStack.addArrangedSubview(markupButton)
        actionsStack.addArrangedSubview(saveButton)
        view.addSubview(actionsStack)
        
        // 6. Status Label
        statusLabel.text = NSLocalizedString("准备就绪。请先开始录制，然后滚动内容。", comment: "Status ready")
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.numberOfLines = 0
        statusLabel.isUserInteractionEnabled = true
#if DEBUG
        statusLabel.addGestureRecognizer(statusTapGesture)
#endif
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // 7. ScrollView & ImageView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5.0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        // 8. Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        view.addSubview(activityIndicator)
        
        // Ensure unlockProButton is above scrollView
        view.bringSubviewToFront(unlockProButton)
        
        var constraints: [NSLayoutConstraint] = [
            recordContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            recordContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordContainer.heightAnchor.constraint(equalToConstant: 70),
            recordContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            
            // Picker is placed on the left edge
            broadcastPicker.centerYAnchor.constraint(equalTo: recordContainer.centerYAnchor),
            broadcastPicker.leadingAnchor.constraint(equalTo: recordContainer.leadingAnchor, constant: 10),
            broadcastPicker.widthAnchor.constraint(equalToConstant: 50),
            broadcastPicker.heightAnchor.constraint(equalToConstant: 50),
            
            // Label is placed to the right of the picker
            recordingLabel.centerYAnchor.constraint(equalTo: recordContainer.centerYAnchor),
            recordingLabel.leadingAnchor.constraint(equalTo: broadcastPicker.trailingAnchor, constant: 8),
            recordingLabel.trailingAnchor.constraint(equalTo: recordContainer.trailingAnchor, constant: -16),
            
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            clearButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            clearButton.widthAnchor.constraint(equalToConstant: 44),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            
            stitchButton.topAnchor.constraint(equalTo: recordContainer.bottomAnchor, constant: 24),
            stitchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            guideLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            guideLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            demoButton.topAnchor.constraint(equalTo: guideLabel.topAnchor, constant: -6),
            demoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: guideLabel.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionsStack.heightAnchor.constraint(equalToConstant: 44),
            
            unlockProButton.bottomAnchor.constraint(equalTo: actionsStack.topAnchor, constant: -16),
            unlockProButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            unlockProButton.heightAnchor.constraint(equalToConstant: 32),
            unlockProButton.widthAnchor.constraint(equalToConstant: 76),
            
            scrollView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: actionsStack.topAnchor, constant: -12),
            
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
#if DEBUG
        constraints.append(contentsOf: [
            previewButton.centerYAnchor.constraint(equalTo: stitchButton.centerYAnchor),
            previewButton.leadingAnchor.constraint(equalTo: stitchButton.trailingAnchor, constant: 16),
            guideLabel.topAnchor.constraint(equalTo: stitchButton.bottomAnchor, constant: 12)
        ])
#else
        constraints.append(
            guideLabel.topAnchor.constraint(equalTo: stitchButton.bottomAnchor, constant: 12)
        )
#endif
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func render(state: UIState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
#if DEBUG
            previewButton.isEnabled = true
#endif
            editButton.isEnabled = false
            markupButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .label
            statusLabel.text = NSLocalizedString("准备就绪。请先开始录制，然后滚动内容。", comment: "Status ready")
            
        case .generating(let frameCount):
            activityIndicator.startAnimating()
            stitchButton.isEnabled = false
#if DEBUG
            previewButton.isEnabled = false
#endif
            editButton.isEnabled = false
            markupButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = false
            statusLabel.textColor = .label
            statusLabel.text = String(format: NSLocalizedString("正在拼接 %d 张分片...", comment: "Generating chunks status"), frameCount)
            
        case .generated(let size, _, _):
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
#if DEBUG
            previewButton.isEnabled = true
#endif
            editButton.isEnabled = (imageView.image != nil)
            markupButton.isEnabled = (imageView.image != nil)
            saveButton.isEnabled = (imageView.image != nil)
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .label
            statusLabel.text = String(format: NSLocalizedString("生成成功：%d×%d。现在你可以保存了。", comment: "Generation success status"), Int(size.width), Int(size.height))
            
        case .failed(let message):
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
#if DEBUG
            previewButton.isEnabled = true
#endif
            editButton.isEnabled = false
            markupButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .systemRed
#if DEBUG
            statusLabel.text = message + "\n\n(点击此处预览分片)"
#else
            statusLabel.text = message
#endif
        }
    }
    
    private func display(image: UIImage?) {
        imageView.image = image
        
        if let existingConstraint = imageAspectRatioConstraint {
            existingConstraint.isActive = false
        }
        if let image, image.size.width > 0 {
            let ratio = image.size.height / image.size.width
            imageAspectRatioConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio)
            imageAspectRatioConstraint?.isActive = true
        }
    }
    
    @objc private func generateLongScreenshot() {
        // Quick pre-check (avoid loading all images if empty)
        let count = ChunkManager.shared.chunkCount()
        guard count >= 2 else {
            state = .failed(message: NSLocalizedString("""
            没有录到足够的分片（至少需要 2 张）。
            建议：
            - 先点击上方录制开始
            - 去目标 App 连续向下滚动 10–30 秒
            - 回来再点 Generate
            """, comment: "Error not enough chunks"))
            return
        }
        
        // Load chunks (images only)
        let chunksWithOffsets = ChunkManager.shared.loadAllChunks()
        let chunks = chunksWithOffsets.map { $0.image }
        
        guard !chunks.isEmpty else {
            state = .failed(message: NSLocalizedString("""
            没有找到录制分片。
            建议：
            - 确认已开始录制
            - 滚动要更连续、避免停顿太久
            - 需要时点 Debug 预览分片确认是否写入成功
            """, comment: "Error no chunks found"))
            return
        }
        
        display(image: nil)
        rawStitchedImage = nil
        hasMarkupEdits = false
        state = .generating(frameCount: chunks.count)
        
        // Run on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let ranges = ImageStitcher.calculateValidRanges(for: chunks)
            let stitchedImage = ImageStitcher.stitch(images: chunks, withRanges: ranges)
            
            DispatchQueue.main.async {
                if let result = stitchedImage {
                    self.rawStitchedImage = result
                    self.hasMarkupEdits = false
                    let displayImage = PurchaseStatusManager.shared.isPurchased() ? result : self.addFullScreenWatermark(to: result)
                    self.display(image: displayImage)
                    self.state = .generated(size: result.size, images: chunks, ranges: ranges)
                } else {
                    self.state = .failed(message: NSLocalizedString("""
                    拼接失败。
                    建议：
                    - 滚动更慢、更连续
                    - 避免大面积动态内容（视频/强动画）
                    - 点 Debug 预览分片确认内容是否连续
                    """, comment: "Error stitching failed"))
                }
            }
        }
    }
    
    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        let nav = UINavigationController(rootViewController: settingsVC)
        present(nav, animated: true)
    }
    
    @objc private func clearDataTapped() {
        let alert = UIAlertController(title: NSLocalizedString("清理数据", comment: "Clear data title"), message: NSLocalizedString("确定要清理当前的截图数据吗？此操作不可撤销。", comment: "Clear data message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("清理", comment: "Clear"), style: .destructive, handler: { [weak self] _ in
            ChunkManager.shared.clearAllChunks()
            self?.display(image: nil)
            self?.rawStitchedImage = nil
            self?.hasMarkupEdits = false
            self?.state = .idle
        }))
        present(alert, animated: true)
    }
    
    @objc private func openDemoVideo() {
        if let url = URL(string: "https://b23.tv/3Byo2uC") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func editResult() {
        guard case let .generated(_, images, ranges) = state else { return }

        if hasMarkupEdits {
            let alert = UIAlertController(
                title: NSLocalizedString("丢弃已涂抹效果？", comment: "Discard markup warning title"),
                message: NSLocalizedString("拼接调整会基于原始分片重新生成结果图，继续后将丢弃当前已经涂抹/打码的效果。", comment: "Discard markup warning message"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: "Cancel"), style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("继续调整", comment: "Continue editing"), style: .destructive, handler: { [weak self] _ in
                self?.presentEditResult(images: images, ranges: ranges)
            }))
            present(alert, animated: true)
            return
        }

        presentEditResult(images: images, ranges: ranges)
    }
    
    @objc private func markupResult() {
        guard let image = self.rawStitchedImage else { return }
        
        let entryVC = MarkupEntryViewController(image: image)
        entryVC.onConfirm = { [weak self] newImage in
            guard let self = self else { return }
            self.rawStitchedImage = newImage
            self.hasMarkupEdits = true
            let displayImage = PurchaseStatusManager.shared.isPurchased() ? newImage : self.addFullScreenWatermark(to: newImage)
            self.display(image: displayImage)
        }
        
        let nav = UINavigationController(rootViewController: entryVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func applyNewRanges(_ newRanges: [(start: Int, end: Int)], to images: [UIImage]) {
        state = .generating(frameCount: images.count)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let stitchedImage = ImageStitcher.stitch(images: images, withRanges: newRanges)
            
            DispatchQueue.main.async {
                if let result = stitchedImage {
                    self.rawStitchedImage = result
                    self.hasMarkupEdits = false
                    let displayImage = PurchaseStatusManager.shared.isPurchased() ? result : self.addFullScreenWatermark(to: result)
                    self.display(image: displayImage)
                    self.state = .generated(size: result.size, images: images, ranges: newRanges)
                } else {
                    self.state = .failed(message: NSLocalizedString("根据新裁剪参数拼接失败。", comment: "Error editing failed"))
                }
            }
        }
    }

    private func presentEditResult(images: [UIImage], ranges: [(start: Int, end: Int)]) {
        let editVC = EditViewController(images: images, initialRanges: ranges)
        editVC.onConfirm = { [weak self] newRanges in
            self?.applyNewRanges(newRanges, to: images)
        }

        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc private func showSaveOptions() {
        guard let image = imageView.image else { return }
        
        let actionSheet = UIAlertController(title: nil, message: NSLocalizedString("选择导出格式", comment: "Choose export format"), preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("保存图片到相册", comment: "Save Image to Photos"), style: .default, handler: { [weak self] _ in
            self?.performSave(image: image)
        }))
        
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("分享为 PDF", comment: "Share as PDF"), style: .default, handler: { [weak self] _ in
            self?.generatePDFAndShare(image: image)
        }))
        
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: "Cancel"), style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = saveButton
            popover.sourceRect = saveButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func generatePDFAndShare(image: UIImage) {
        let loadingAlert = UIAlertController(title: nil, message: NSLocalizedString("正在生成 PDF...", comment: "Generating PDF loading"), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        
        present(loadingAlert, animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                let pdfData = self.createPDFData(from: image)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let fileName = "LongScreenshot_\(dateFormatter.string(from: Date())).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                do {
                    try pdfData.write(to: tempURL)
                    
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            self.sharePDF(fileURL: tempURL)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            self.state = .failed(message: NSLocalizedString("生成 PDF 失败", comment: "Failed to generate PDF"))
                        }
                    }
                }
            }
        }
    }
    
    private func createPDFData(from image: UIImage) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Rolling Long Screenshot",
            kCGPDFContextAuthor: "User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(origin: .zero, size: image.size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { (context) in
            context.beginPage()
            image.draw(in: pageRect)
        }
        return pdfData
    }
    
    private func sharePDF(fileURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = saveButton
            popover.sourceRect = saveButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    @objc private func unlockProTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("解锁 Pro 权限", comment: "Unlock Pro title"),
            message: NSLocalizedString("只需支付 18 元即可解锁永久 Pro 权限，感谢支持", comment: "Unlock Pro message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: "Cancel action"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("去支付", comment: "Pay action"), style: .default, handler: { [weak self] _ in
            self?.performPurchase()
        }))
        
        present(alert, animated: true)
    }
    
    private func performPurchase() {
        let loadingAlert = UIAlertController(title: nil, message: NSLocalizedString("正在请求支付...", comment: "Requesting purchase loading"), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        
        present(loadingAlert, animated: true) {
            PurchaseManager.shared.requestPurchase { [weak self] success in
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        if success {
                            self?.unlockProButton.isHidden = true
                            if let raw = self?.rawStitchedImage {
                                self?.display(image: raw)
                            }
                            
                            let successAlert = UIAlertController(title: NSLocalizedString("购买成功", comment: "Purchase success title"), message: NSLocalizedString("感谢您的支持！", comment: "Purchase success message"), preferredStyle: .alert)
                            successAlert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK action"), style: .default))
                            self?.present(successAlert, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    private func addFullScreenWatermark(to image: UIImage) -> UIImage {
        let size = image.size
        let scale = image.scale
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }
        
        let text = NSLocalizedString("来自：滚动长截屏-滚动长截图", comment: "Watermark text")
        let font = UIFont.systemFont(ofSize: max(30, size.width * 0.05), weight: .bold)
        
        // 第一步：将文字在一个不透明的独立画布上画成图片（先画描边，再画实心）
        // 这样可以彻底解决文字笔画内部重叠、以及半透明描边穿透的问题，实现完美的“一体化”
        let strokeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .strokeColor: UIColor(white: 0.4, alpha: 1.0), // 将外轮廓改成浅灰色，降低对比度
            .strokeWidth: 4.0 // 正数表示只画描边
        ]
        
        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white // 纯白字芯
        ]
        
        let textSize = text.size(withAttributes: strokeAttributes)
        let padding: CGFloat = 8.0
        let tileSize = CGSize(width: textSize.width + padding * 2, height: textSize.height + padding * 2)
        
        UIGraphicsBeginImageContextWithOptions(tileSize, false, scale)
        text.draw(at: CGPoint(x: padding, y: padding), withAttributes: strokeAttributes)
        text.draw(at: CGPoint(x: padding, y: padding), withAttributes: fillAttributes)
        let tileImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let tile = tileImage else { return image }
        
        // 第二步：将生成的单图 Tile 以较低的透明度全屏平铺
        let angle = -CGFloat.pi / 6 // -30 degrees
        
        let stepX: CGFloat = tileSize.width + 100
        let stepY: CGFloat = tileSize.height + 150
        
        let diag = sqrt(size.width * size.width + size.height * size.height)
        let startX = -diag
        let startY = -diag
        
        context.saveGState()
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.rotate(by: angle)
        context.translateBy(x: -size.width / 2, y: -size.height / 2)
        
        for y in stride(from: startY, to: size.height + diag, by: stepY) {
            for x in stride(from: startX, to: size.width + diag, by: stepX) {
                // 明确使用 UIImage 的自带 alpha 绘制方法，确保系统强制生效
                tile.draw(at: CGPoint(x: x, y: y), blendMode: .normal, alpha: 0.18)
            }
        }
        
        context.restoreGState()
        
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return watermarkedImage ?? image
    }
    
    private func performSave(image: UIImage) {
        AppLogger.shared.log("Requesting photo authorization...")
        let handler: (PHAuthorizationStatus) -> Void = { status in
            if status == .authorized || status == .limited {
                AppLogger.shared.log("Photo authorization granted. Dispatching save to main thread.")
                DispatchQueue.main.async {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
            } else {
                AppLogger.shared.log("Photo authorization denied by user.")
                DispatchQueue.main.async {
                    self.state = .failed(message: NSLocalizedString("相册权限被拒绝。可在系统设置中开启“照片-添加”。", comment: "Photo permission denied"))
                    self.presentPhotoPermissionAlert()
                }
            }
        }
        
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: handler)
        } else {
            PHPhotoLibrary.requestAuthorization(handler)
        }
    }
    
    private func requestPurchaseAndSave() {
        let loadingAlert = UIAlertController(title: nil, message: NSLocalizedString("正在请求支付...", comment: "Requesting purchase loading"), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        
        let startFlow = { [weak self] in
            guard let self = self else { return }
            self.present(loadingAlert, animated: true)
            
            PurchaseManager.shared.requestPurchase { success in
                DispatchQueue.main.async {
                    let finishAction = {
                        if success {
                            if let image = self.imageView.image {
                                self.performSave(image: image)
                            }
                        }
                    }
                    
                    if loadingAlert.presentingViewController != nil {
                        loadingAlert.dismiss(animated: true, completion: finishAction)
                    } else {
                        finishAction()
                    }
                }
            }
        }
        
        if presentedViewController != nil {
            dismiss(animated: true) {
                startFlow()
            }
        } else {
            startFlow()
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                AppLogger.shared.log("Failed to save photo: \(error.localizedDescription)")
                self.statusLabel.text = String(format: NSLocalizedString("保存出错: %@", comment: "Save error status"), error.localizedDescription)
                
                let alert = UIAlertController(title: NSLocalizedString("保存失败", comment: "Save error title"), message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK action"), style: .default))
                self.present(alert, animated: true)
            } else {
                AppLogger.shared.log("Successfully saved photo to album.")
                self.statusLabel.text = NSLocalizedString("成功保存至相册!", comment: "Save success status")
                
                let alert = UIAlertController(title: NSLocalizedString("保存成功", comment: "Save success title"), message: NSLocalizedString("长截图已成功保存到相册。", comment: "Save success message"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK action"), style: .default, handler: { [weak self] _ in
                    self?.showReviewPromptIfNeeded()
                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Review Prompt
    private func showReviewPromptIfNeeded() {
        if UserDefaults.standard.bool(forKey: "hasReviewed") { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(
                title: NSLocalizedString("喜欢这个应用吗？", comment: "Review title"),
                message: NSLocalizedString("如果这个应用对您有帮助，请给个好评支持一下开发者，感谢！", comment: "Review message"),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("以后再说", comment: "Later action"), style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("去给好评", comment: "Go review action"), style: .default, handler: { _ in
                UserDefaults.standard.set(true, forKey: "hasReviewed")
                if let url = URL(string: "https://apps.apple.com/app/id6759634662?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }))
            
            self.present(alert, animated: true)
        }
    }

#if DEBUG
    @objc private func showPreview() {
        let vc = ChunksPreviewViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
#endif
    
    private func presentPhotoPermissionAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("需要照片权限", comment: "Need photo permission title"),
            message: NSLocalizedString("用于将生成的长截图保存到相册。", comment: "Need photo permission message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("取消", comment: "Cancel action"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("去设置", comment: "Go to settings action"), style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }))
        present(alert, animated: true)
    }
    
    @objc private func triggerBroadcastPicker() {
        // Find the internal button of the broadcast picker and trigger it
        if let button = broadcastPicker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.sendActions(for: .touchUpInside)
            // Sometimes it's wrapped in another view on newer iOS versions
        } else {
            // Fallback: search recursively if not direct child
            var foundButton: UIButton? = nil
            func searchForButton(in view: UIView) {
                if let btn = view as? UIButton {
                    foundButton = btn
                    return
                }
                for subview in view.subviews {
                    searchForButton(in: subview)
                    if foundButton != nil { return }
                }
            }
            searchForButton(in: broadcastPicker)
            foundButton?.sendActions(for: .touchUpInside)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
