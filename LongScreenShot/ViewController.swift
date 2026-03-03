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
    private let editButton = UIButton(type: .system) // Edit button
    private let saveButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system) // Settings button
    private let statusLabel = UILabel()
    private let guideLabel = UILabel()
    
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
        setupUI()
        state = .idle
        
        // Auto-stitch if chunks exist on load
        autoGenerateIfPossible()
        
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
        title = "Long Screenshot"
        
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
        recordingLabel.text = "开始录制"
        recordingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        recordingLabel.textColor = .label
        recordingLabel.translatesAutoresizingMaskIntoConstraints = false
        recordContainer.addSubview(recordingLabel)
        
        // We use a gesture on the container to trigger the picker,
        // so we don't need to put the picker behind or expand it.
        // We just place them side by side.
        
        // 2. Stitch Button
        stitchButton.setTitle("生成结果图", for: .normal)
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
        guideLabel.text = """
        录制步骤：
        1) 点上方“开始录制”
        2) 倒计时结束前切换到目标截图 App 由上向下连续向下滚动
        3) 回来点生成长截图
        """
        guideLabel.textAlignment = .left
        guideLabel.font = .systemFont(ofSize: 13)
        guideLabel.textColor = .secondaryLabel
        guideLabel.numberOfLines = 0
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
                
        // 4. Settings / Edit / Save Buttons
        settingsButton.setTitle("设置", for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        editButton.setTitle("编辑", for: .normal)
        editButton.addTarget(self, action: #selector(editResult), for: .touchUpInside)
        editButton.isEnabled = false
        
        saveButton.setTitle("保存", for: .normal)
        saveButton.addTarget(self, action: #selector(saveToPhotos), for: .touchUpInside)
        saveButton.isEnabled = false
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.distribution = .fillEqually
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.addArrangedSubview(editButton)
        actionsStack.addArrangedSubview(saveButton)
        actionsStack.addArrangedSubview(settingsButton)
        view.addSubview(actionsStack)
        
        // 5. Status Label
        statusLabel.text = "准备就绪。请先开始录制，然后滚动内容。"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.numberOfLines = 0
        statusLabel.isUserInteractionEnabled = true
#if DEBUG
        statusLabel.addGestureRecognizer(statusTapGesture)
#endif
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // 6. ScrollView & ImageView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5.0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        // 7. Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        view.addSubview(activityIndicator)
        
        var constraints: [NSLayoutConstraint] = [
            recordContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            recordContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordContainer.heightAnchor.constraint(equalToConstant: 70),
            recordContainer.widthAnchor.constraint(equalToConstant: 160),
            
            // Picker is placed on the left edge
            broadcastPicker.centerYAnchor.constraint(equalTo: recordContainer.centerYAnchor),
            broadcastPicker.leadingAnchor.constraint(equalTo: recordContainer.leadingAnchor, constant: 10),
            broadcastPicker.widthAnchor.constraint(equalToConstant: 50),
            broadcastPicker.heightAnchor.constraint(equalToConstant: 50),
            
            // Label is placed to the right of the picker
            recordingLabel.centerYAnchor.constraint(equalTo: recordContainer.centerYAnchor),
            recordingLabel.leadingAnchor.constraint(equalTo: broadcastPicker.trailingAnchor, constant: 8),
            
            stitchButton.topAnchor.constraint(equalTo: recordContainer.bottomAnchor, constant: 24),
            stitchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            guideLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            guideLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: guideLabel.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            actionsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionsStack.heightAnchor.constraint(equalToConstant: 44),
            
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
            previewButton.topAnchor.constraint(equalTo: stitchButton.bottomAnchor, constant: 10),
            previewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 12)
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
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .label
            statusLabel.text = "准备就绪。请先开始录制，然后滚动内容。"
            
        case .generating(let frameCount):
            activityIndicator.startAnimating()
            stitchButton.isEnabled = false
#if DEBUG
            previewButton.isEnabled = false
#endif
            editButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = false
            statusLabel.textColor = .label
            statusLabel.text = "正在拼接 \(frameCount) 张分片..."
            
        case .generated(let size, _, _):
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
#if DEBUG
            previewButton.isEnabled = true
#endif
            editButton.isEnabled = (imageView.image != nil)
            saveButton.isEnabled = (imageView.image != nil)
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .label
            statusLabel.text = "生成成功：\(Int(size.width))×\(Int(size.height))。现在你可以保存了。"
            
        case .failed(let message):
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
#if DEBUG
            previewButton.isEnabled = true
#endif
            editButton.isEnabled = false
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
            state = .failed(message: """
            没有录到足够的分片（至少需要 2 张）。
            建议：
            - 先点击上方录制开始
            - 去目标 App 连续向下滚动 10–30 秒
            - 回来再点 Generate
            """)
            return
        }
        
        // Load chunks (images only)
        let chunksWithOffsets = ChunkManager.shared.loadAllChunks()
        let chunks = chunksWithOffsets.map { $0.image }
        
        guard !chunks.isEmpty else {
            state = .failed(message: """
            没有找到录制分片。
            建议：
            - 确认已开始录制
            - 滚动要更连续、避免停顿太久
            - 需要时点 Debug 预览分片确认是否写入成功
            """)
            return
        }
        
        display(image: nil)
        state = .generating(frameCount: chunks.count)
        
        // Run on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let ranges = ImageStitcher.calculateValidRanges(for: chunks)
            let stitchedImage = ImageStitcher.stitch(images: chunks, withRanges: ranges)
            
            DispatchQueue.main.async {
                if let result = stitchedImage {
                    self.display(image: result)
                    self.state = .generated(size: result.size, images: chunks, ranges: ranges)
                } else {
                    self.state = .failed(message: """
                    拼接失败。
                    建议：
                    - 滚动更慢、更连续
                    - 避免大面积动态内容（视频/强动画）
                    - 点 Debug 预览分片确认内容是否连续
                    """)
                }
            }
        }
    }
    
    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        let nav = UINavigationController(rootViewController: settingsVC)
        present(nav, animated: true)
    }
    
    @objc private func editResult() {
        guard case let .generated(_, images, ranges) = state else { return }
        
        let editVC = EditViewController(images: images, initialRanges: ranges)
        editVC.onConfirm = { [weak self] newRanges in
            self?.applyNewRanges(newRanges, to: images)
        }
        
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func applyNewRanges(_ newRanges: [(start: Int, end: Int)], to images: [UIImage]) {
        state = .generating(frameCount: images.count)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let stitchedImage = ImageStitcher.stitch(images: images, withRanges: newRanges)
            
            DispatchQueue.main.async {
                if let result = stitchedImage {
                    self.display(image: result)
                    self.state = .generated(size: result.size, images: images, ranges: newRanges)
                } else {
                    self.state = .failed(message: "根据新裁剪参数拼接失败。")
                }
            }
        }
    }
    
    @objc private func saveToPhotos() {
        guard let image = imageView.image else { return }
        
        let statusManager = PurchaseStatusManager.shared
//        statusManager.setPurchased(false)
        let isPurchased = statusManager.isPurchased()
        let isTrialExpired = statusManager.isTrialExpired()
        
        if isTrialExpired && !isPurchased {
            let alert = UIAlertController(title: "提示", message: "免费使用一周，只需支付8元即可无限使用，感谢支持", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "去解锁", style: .default, handler: { [weak self] _ in
                self?.requestPurchaseAndSave()
            }))
            present(alert, animated: true)
            return
        }
        
        performSave(image: image)
    }
    
    private func performSave(image: UIImage) {
        let handler: (PHAuthorizationStatus) -> Void = { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                DispatchQueue.main.async {
                    self.state = .failed(message: "相册权限被拒绝。可在系统设置中开启“照片-添加”。")
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
        let loadingAlert = UIAlertController(title: nil, message: "正在请求支付...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        
        present(loadingAlert, animated: true) {
            PurchaseManager.shared.requestPurchase { [weak self] success in
                DispatchQueue.main.async {
                    self?.dismiss(animated: true) {
                        if success {
                            if let image = self?.imageView.image {
                                self?.performSave(image: image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            statusLabel.text = "保存出错: \(error.localizedDescription)"
        } else {
            statusLabel.text = "成功保存至相册!"
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
            title: "需要照片权限",
            message: "用于将生成的长截图保存到相册。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
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
