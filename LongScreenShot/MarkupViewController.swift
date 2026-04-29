import UIKit
import PencilKit

class MarkupViewController: UIViewController, UIScrollViewDelegate, PKCanvasViewDelegate {

    private static let maximumMarkupZoomScale: CGFloat = 4.0

    private let originalImage: UIImage
    var onConfirm: ((UIImage) -> Void)?

    private let backgroundScrollView = UIScrollView()
    private let backgroundImageView = UIImageView()
    private let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()

    private var displaySize: CGSize = .zero
    private var lastLayoutWidth: CGFloat = 0
    private var lastLayoutHeight: CGFloat = 0

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCanvasLayoutIfNeeded()
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
            title: NSLocalizedString("取消", comment: "Cancel"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        let doneItem = UIBarButtonItem(
            title: NSLocalizedString("完成", comment: "Done"),
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        let undoItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(undoTapped)
        )
        let redoItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.forward"),
            style: .plain,
            target: self,
            action: #selector(redoTapped)
        )

        navigationItem.leftBarButtonItem = cancelItem
        navigationItem.rightBarButtonItems = [doneItem, redoItem, undoItem]
    }

    private func setupUI() {
        backgroundScrollView.translatesAutoresizingMaskIntoConstraints = false
        backgroundScrollView.backgroundColor = .secondarySystemBackground
        backgroundScrollView.delegate = self
        backgroundScrollView.isUserInteractionEnabled = false
        backgroundScrollView.showsVerticalScrollIndicator = false
        backgroundScrollView.showsHorizontalScrollIndicator = false
        backgroundScrollView.bounces = false
        backgroundScrollView.bouncesZoom = false

        backgroundImageView.image = originalImage
        backgroundImageView.isUserInteractionEnabled = false
        backgroundImageView.contentMode = .scaleToFill

        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = self
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = true
        canvasView.bouncesZoom = false
        canvasView.showsVerticalScrollIndicator = true
        canvasView.showsHorizontalScrollIndicator = true
        canvasView.maximumZoomScale = Self.maximumMarkupZoomScale

        view.addSubview(backgroundScrollView)
        backgroundScrollView.addSubview(backgroundImageView)
        view.addSubview(canvasView)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delaysTouchesBegan = false
        canvasView.addGestureRecognizer(doubleTapGesture)

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

    private func updateCanvasLayoutIfNeeded() {
        let layoutFrame = view.safeAreaLayoutGuide.layoutFrame
        let availableWidth = layoutFrame.width
        let availableHeight = layoutFrame.height
        guard availableWidth > 0, availableHeight > 0 else { return }

        if abs(availableWidth - lastLayoutWidth) < 0.5,
            abs(availableHeight - lastLayoutHeight) < 0.5,
            displaySize != .zero {
            centerContentIfNeeded()
            syncBackgroundScrollView()
            return
        }

        let aspectRatio = originalImage.size.height / originalImage.size.width
        displaySize = CGSize(width: availableWidth, height: availableWidth * aspectRatio)
        lastLayoutWidth = availableWidth
        lastLayoutHeight = availableHeight

        backgroundImageView.frame = CGRect(origin: .zero, size: displaySize)
        backgroundScrollView.contentSize = displaySize
        canvasView.contentSize = displaySize

        let zoomBounds = zoomScaleBounds(forAvailableHeight: availableHeight)
        let currentZoomScale = canvasView.zoomScale > 0 ? canvasView.zoomScale : zoomBounds.minimum

        applyZoomScaleBounds(zoomBounds)
        let clampedZoomScale = min(max(currentZoomScale, zoomBounds.minimum), zoomBounds.maximum)
        canvasView.zoomScale = clampedZoomScale
        backgroundScrollView.zoomScale = clampedZoomScale

        centerContentIfNeeded()
        syncBackgroundScrollView()
    }

    private func zoomScaleBounds(forAvailableHeight availableHeight: CGFloat) -> (minimum: CGFloat, maximum: CGFloat) {
        let minimumZoomScale = min(1.0, availableHeight / displaySize.height)
        let maximumZoomScale = max(minimumZoomScale, Self.maximumMarkupZoomScale)
        return (minimum: minimumZoomScale, maximum: maximumZoomScale)
    }

    private func applyZoomScaleBounds(_ bounds: (minimum: CGFloat, maximum: CGFloat)) {
        backgroundScrollView.minimumZoomScale = bounds.minimum
        backgroundScrollView.maximumZoomScale = bounds.maximum
        canvasView.minimumZoomScale = bounds.minimum
        canvasView.maximumZoomScale = bounds.maximum
    }

    private func centerContentIfNeeded() {
        let scaledWidth = displaySize.width * canvasView.zoomScale
        let scaledHeight = displaySize.height * canvasView.zoomScale
        let horizontalInset = max((canvasView.bounds.width - scaledWidth) / 2, 0)
        let verticalInset = max((canvasView.bounds.height - scaledHeight) / 2, 0)

        let contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )

        canvasView.contentInset = contentInset
        backgroundScrollView.contentInset = contentInset
    }

    private func syncBackgroundScrollView() {
        backgroundScrollView.zoomScale = canvasView.zoomScale
        backgroundScrollView.contentInset = canvasView.contentInset
        backgroundScrollView.contentOffset = canvasView.contentOffset
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard scrollView === backgroundScrollView else { return nil }
        return backgroundImageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView === canvasView else { return }
        centerContentIfNeeded()
        syncBackgroundScrollView()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === canvasView else { return }
        syncBackgroundScrollView()
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
    }

    override var canBecomeFirstResponder: Bool { true }

    @objc private func undoTapped() {
        canvasView.undoManager?.undo()
    }

    @objc private func redoTapped() {
        canvasView.undoManager?.redo()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if canvasView.zoomScale > canvasView.minimumZoomScale {
            canvasView.setZoomScale(canvasView.minimumZoomScale, animated: true)
            return
        }

        let targetZoomScale = min(canvasView.maximumZoomScale, 2.5)
        let tapLocation = gesture.location(in: canvasView)
        let zoomRectSize = CGSize(
            width: canvasView.bounds.width / targetZoomScale,
            height: canvasView.bounds.height / targetZoomScale
        )
        let zoomRect = CGRect(
            x: tapLocation.x - zoomRectSize.width / 2,
            y: tapLocation.y - zoomRectSize.height / 2,
            width: zoomRectSize.width,
            height: zoomRectSize.height
        )

        canvasView.zoom(to: zoomRect, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
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
