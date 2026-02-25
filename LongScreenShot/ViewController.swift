import UIKit
import ReplayKit
import Photos

class ViewController: UIViewController {

    private let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let stitchButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system) // New button
    private let saveButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let guideLabel = UILabel()
    
    private let actionsStack = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var imageAspectRatioConstraint: NSLayoutConstraint?
    private lazy var statusTapGesture = UITapGestureRecognizer(target: self, action: #selector(showPreview))
    
    private enum UIState: Equatable {
        case idle
        case generating(frameCount: Int)
        case generated(size: CGSize)
        case failed(message: String)
    }
    
    private var state: UIState = .idle {
        didSet { render(state: state) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        state = .idle
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Long Screenshot"
        
        // ... (broadcastPicker setup remains) ...
        
        broadcastPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(broadcastPicker)
        
        // 2. Stitch Button
        stitchButton.setTitle("Generate Long Screenshot", for: .normal)
        stitchButton.addTarget(self, action: #selector(generateLongScreenshot), for: .touchUpInside)
        stitchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stitchButton)
        
        // 2.1 Preview Button
        previewButton.setTitle("Debug: Preview Chunks", for: .normal)
        previewButton.addTarget(self, action: #selector(showPreview), for: .touchUpInside)
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewButton)
        
        // 3. Guide Label
        guideLabel.text = """
        录制步骤：
        1) 点上方“录制”开始
        2) 去目标 App 连续向下滚动 10–30 秒
        3) 回来点 Generate 生成长截图，然后分享/保存
        """
        guideLabel.textAlignment = .left
        guideLabel.font = .systemFont(ofSize: 13)
        guideLabel.textColor = .secondaryLabel
        guideLabel.numberOfLines = 0
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
                
        // 4. Share / Save Buttons
        shareButton.setTitle("Share / 分享", for: .normal)
        shareButton.addTarget(self, action: #selector(shareResult), for: .touchUpInside)
        shareButton.isEnabled = false
        
        saveButton.setTitle("Save / 保存", for: .normal)
        saveButton.addTarget(self, action: #selector(saveToPhotos), for: .touchUpInside)
        saveButton.isEnabled = false
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.distribution = .fillEqually
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsStack.addArrangedSubview(shareButton)
        actionsStack.addArrangedSubview(saveButton)
        view.addSubview(actionsStack)
        
        // 5. Status Label
        statusLabel.text = "准备就绪。请先开始录制，然后滚动内容。"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.numberOfLines = 0
        statusLabel.isUserInteractionEnabled = true
        statusLabel.addGestureRecognizer(statusTapGesture)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // 6. ScrollView & ImageView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        // 7. Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            broadcastPicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            broadcastPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            broadcastPicker.widthAnchor.constraint(equalToConstant: 60),
            broadcastPicker.heightAnchor.constraint(equalToConstant: 60),
            
            stitchButton.topAnchor.constraint(equalTo: broadcastPicker.bottomAnchor, constant: 20),
            stitchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            previewButton.topAnchor.constraint(equalTo: stitchButton.bottomAnchor, constant: 10),
            previewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            guideLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 12),
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
        ])
    }
    
    private func render(state: UIState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
            previewButton.isEnabled = true
            shareButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .label
            statusLabel.text = "准备就绪。请先开始录制，然后滚动内容。"
            
        case .generating(let frameCount):
            activityIndicator.startAnimating()
            stitchButton.isEnabled = false
            previewButton.isEnabled = false
            shareButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = false
            statusLabel.textColor = .label
            statusLabel.text = "正在拼接 \(frameCount) 帧…"
            
        case .generated(let size):
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
            previewButton.isEnabled = true
            shareButton.isEnabled = (imageView.image != nil)
            saveButton.isEnabled = (imageView.image != nil)
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .label
            statusLabel.text = "生成完成：\(Int(size.width))×\(Int(size.height))。可分享或保存到相册。"
            
        case .failed(let message):
            activityIndicator.stopAnimating()
            stitchButton.isEnabled = true
            previewButton.isEnabled = true
            shareButton.isEnabled = false
            saveButton.isEnabled = false
            view.isUserInteractionEnabled = true
            statusLabel.textColor = .systemRed
            statusLabel.text = message + "\n\n（点这里预览分片）"
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
            let stitchedImage = ImageStitcher.stitch(images: chunks)
            
            DispatchQueue.main.async {
                if let result = stitchedImage {
                    self.display(image: result)
                    self.state = .generated(size: result.size)
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
    
    @objc private func shareResult() {
        guard let image = imageView.image else { return }
        
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        present(vc, animated: true)
    }
    
    @objc private func saveToPhotos() {
        guard let image = imageView.image else { return }
        
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
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            statusLabel.text = "Error saving: \(error.localizedDescription)"
        } else {
            statusLabel.text = "Saved to Photos!"
        }
    }
    
    @objc private func showPreview() {
        let vc = ChunksPreviewViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    private func presentPhotoPermissionAlert() {
        let alert = UIAlertController(
            title: "需要照片权限",
            message: "用于将生成的长截图保存到相册。你也可以直接使用 Share 分享，不必授权相册。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }))
        present(alert, animated: true)
    }
}
