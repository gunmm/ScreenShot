import UIKit
import PencilKit

class MarkupViewController: UIViewController, UIScrollViewDelegate, PKCanvasViewDelegate {

    private let originalImage: UIImage
    var onConfirm: ((UIImage) -> Void)?

    // 底层：背景图滚动视图（被动跟随，isScrollEnabled = false）
    private let backgroundScrollView = UIScrollView()
    private let backgroundImageView = UIImageView()

    // 顶层：PencilKit 画布（透明，负责滚动和画画）
    private let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()

    // 按屏幕宽度适配的展示尺寸
    private var displaySize: CGSize = .zero

    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.removeObserver(canvasView)
    }

    private func setupNavigationBar() {
        title = NSLocalizedString("涂鸦/打码", comment: "Markup title")
        view.backgroundColor = .systemBackground

        let cancelItem = UIBarButtonItem(
            title: NSLocalizedString("取消", comment: "Cancel"), style: .plain,
            target: self, action: #selector(cancelTapped))
        let doneItem = UIBarButtonItem(
            title: NSLocalizedString("完成", comment: "Done"), style: .done,
            target: self, action: #selector(doneTapped))
        let undoItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"), style: .plain,
            target: self, action: #selector(undoTapped))
        let redoItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.forward"), style: .plain,
            target: self, action: #selector(redoTapped))

        navigationItem.leftBarButtonItem = cancelItem
        navigationItem.rightBarButtonItems = [doneItem, redoItem, undoItem]
    }

    private func setupUI() {
        // 计算 displaySize：图片按屏幕宽度等比缩放
        let screenWidth = UIScreen.main.bounds.width
        let aspect = originalImage.size.height / originalImage.size.width
        displaySize = CGSize(width: screenWidth, height: screenWidth * aspect)

        // ── 底层：背景图 ──────────────────────────────────
        backgroundScrollView.translatesAutoresizingMaskIntoConstraints = false
        backgroundScrollView.isScrollEnabled = false  // 由顶层 canvasView 驱动
        backgroundScrollView.contentSize = displaySize
        backgroundScrollView.showsVerticalScrollIndicator = false
        view.addSubview(backgroundScrollView)

        backgroundImageView.image = originalImage
        backgroundImageView.frame = CGRect(origin: .zero, size: displaySize)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundScrollView.addSubview(backgroundImageView)

        // ── 顶层：PencilKit 画布 ──────────────────────────
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .clear  // 透明，露出底层图片
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.contentSize = displaySize
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0
        canvasView.delegate = self
        view.addSubview(canvasView)

        // 两个视图都铺满安全区域
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backgroundScrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            backgroundScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundScrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            canvasView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    // MARK: - UIScrollViewDelegate（同步 canvasView 滚动 → backgroundScrollView）

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === canvasView else { return }
        backgroundScrollView.contentOffset = canvasView.contentOffset
    }

    // MARK: - PKCanvasViewDelegate

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // 调试期间可打开：
        // print("[Markup] strokes=\(canvasView.drawing.strokes.count)")
    }

    // MARK: - Undo / Redo

    override var canBecomeFirstResponder: Bool { true }

    @objc private func undoTapped() { undoManager?.undo() }
    @objc private func redoTapped() { undoManager?.redo() }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        // 将 displaySize 坐标系的笔画等比缩放回原图像素坐标系
        let scaleX = originalImage.size.width / displaySize.width
        let scaleY = originalImage.size.height / displaySize.height
        let scaledDrawing = canvasView.drawing.transformed(
            using: CGAffineTransform(scaleX: scaleX, y: scaleY)
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = originalImage.scale
        let renderer = UIGraphicsImageRenderer(size: originalImage.size, format: format)
        let newImage = renderer.image { _ in
            originalImage.draw(at: .zero)
            let drawingImage = scaledDrawing.image(
                from: CGRect(origin: .zero, size: originalImage.size),
                scale: originalImage.scale
            )
            drawingImage.draw(at: .zero)
        }

        dismiss(animated: true) { [weak self] in
            self?.onConfirm?(newImage)
        }
    }
}
