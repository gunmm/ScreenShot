import CoreImage
import UIKit

final class MosaicViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    private static let maximumZoomScale: CGFloat = 4.0
    private static let defaultMosaicBlockSize: CGFloat = 18.0
    private static let minimumBrushWidth: CGFloat = 10.0
    private static let maximumBrushWidth: CGFloat = 100.0
    private static let defaultBrushWidth: CGFloat = 42.0
    private static let minimumOpacity: CGFloat = 0.2
    private static let defaultOpacity: CGFloat = 1.0

    private struct MosaicStroke {
        var points: [CGPoint]
        var lineWidth: CGFloat
        var opacity: CGFloat

        func bezierPath(scale: CGFloat) -> UIBezierPath? {
            guard let firstPoint = points.first else { return nil }

            let path = UIBezierPath()
            path.move(to: CGPoint(x: firstPoint.x / scale, y: firstPoint.y / scale))

            if points.count == 1 {
                path.addLine(to: CGPoint(x: firstPoint.x / scale, y: firstPoint.y / scale))
            } else {
                for point in points.dropFirst() {
                    path.addLine(to: CGPoint(x: point.x / scale, y: point.y / scale))
                }
            }

            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = lineWidth / scale
            return path
        }
    }

    private final class MosaicCanvasView: UIView {

        var previewImage: UIImage? {
            didSet { setNeedsDisplay() }
        }

        var imageScale: CGFloat = 1.0 {
            didSet { setNeedsDisplay() }
        }

        var strokes: [MosaicStroke] = [] {
            didSet { setNeedsDisplay() }
        }

        var currentStroke: MosaicStroke? {
            didSet { setNeedsDisplay() }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            isOpaque = false
            backgroundColor = .clear
            contentMode = .redraw
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            guard let previewImage, imageScale > 0 else { return }
            guard let context = UIGraphicsGetCurrentContext() else { return }

            for stroke in strokes {
                drawStroke(stroke, in: context, previewImage: previewImage)
            }

            if let currentStroke {
                drawStroke(currentStroke, in: context, previewImage: previewImage)
            }
        }

        private func drawStroke(_ stroke: MosaicStroke, in context: CGContext, previewImage: UIImage) {
            guard let path = stroke.bezierPath(scale: imageScale) else { return }

            context.saveGState()
            context.addPath(path.cgPath)
            context.setLineWidth(path.lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.replacePathWithStrokedPath()
            context.clip()
            previewImage.draw(in: bounds, blendMode: .normal, alpha: stroke.opacity)
            context.restoreGState()
        }
    }

    private let originalImage: UIImage
    private let ciContext = CIContext(options: nil)

    var onConfirm: ((UIImage) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let imageView = UIImageView()
    private let canvasView = MosaicCanvasView()
    private let controlCard = UIView()
    private let widthValueLabel = UILabel()
    private let opacityValueLabel = UILabel()
    private let widthSlider = UISlider()
    private let opacitySlider = UISlider()

    private lazy var doneItem = UIBarButtonItem(
        title: NSLocalizedString("完成", comment: "Done"),
        style: .done,
        target: self,
        action: #selector(doneTapped)
    )

    private lazy var undoItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.uturn.backward"),
        style: .plain,
        target: self,
        action: #selector(undoTapped)
    )

    private lazy var redoItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.uturn.forward"),
        style: .plain,
        target: self,
        action: #selector(redoTapped)
    )

    private var displaySize: CGSize = .zero
    private var lastLayoutWidth: CGFloat = 0
    private var lastLayoutHeight: CGFloat = 0
    private var currentStroke: MosaicStroke?
    private var strokes: [MosaicStroke] = []
    private var redoStrokes: [MosaicStroke] = []
    private var previewPixelatedImage: UIImage?
    private var exportPixelatedImage: UIImage?

    private var brushWidth: CGFloat = MosaicViewController.defaultBrushWidth {
        didSet { updateControlValues() }
    }

    private var brushOpacity: CGFloat = MosaicViewController.defaultOpacity {
        didSet { updateControlValues() }
    }

    private var isNavigationRoot: Bool {
        navigationController?.viewControllers.first === self || navigationController == nil
    }

    private var imageScale: CGFloat {
        guard displaySize.width > 0 else { return 1.0 }
        return originalImage.size.width / displaySize.width
    }

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
        updateControlValues()
        updateActionItems()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCanvasLayoutIfNeeded()
    }

    private func setupNavigationBar() {
        title = NSLocalizedString("马赛克", comment: "Mosaic title")
        view.backgroundColor = .systemBackground

        if isNavigationRoot {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("取消", comment: "Cancel"),
                style: .plain,
                target: self,
                action: #selector(cancelTapped)
            )
        }

        navigationItem.rightBarButtonItems = [doneItem, redoItem, undoItem]
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .secondarySystemBackground
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.bouncesZoom = false
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2

        contentView.backgroundColor = .clear

        imageView.image = originalImage
        imageView.contentMode = .scaleToFill
        imageView.isUserInteractionEnabled = false

        let drawingPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrawingPan(_:)))
        drawingPanGesture.minimumNumberOfTouches = 1
        drawingPanGesture.maximumNumberOfTouches = 1
        drawingPanGesture.delegate = self
        canvasView.addGestureRecognizer(drawingPanGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delaysTouchesBegan = false
        doubleTapGesture.delegate = self
        canvasView.addGestureRecognizer(doubleTapGesture)
        drawingPanGesture.require(toFail: doubleTapGesture)

        controlCard.translatesAutoresizingMaskIntoConstraints = false
        controlCard.backgroundColor = .secondarySystemGroupedBackground
        controlCard.layer.cornerRadius = 16

        let widthTitleLabel = makeControlTitleLabel(text: NSLocalizedString("粗细", comment: "Mosaic width title"))
        let opacityTitleLabel = makeControlTitleLabel(text: NSLocalizedString("透明度", comment: "Mosaic opacity title"))

        widthValueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        widthValueLabel.textColor = .secondaryLabel
        widthValueLabel.textAlignment = .right

        opacityValueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        opacityValueLabel.textColor = .secondaryLabel
        opacityValueLabel.textAlignment = .right

        widthSlider.minimumValue = Float(Self.minimumBrushWidth)
        widthSlider.maximumValue = Float(Self.maximumBrushWidth)
        widthSlider.value = Float(brushWidth)
        widthSlider.addTarget(self, action: #selector(widthSliderChanged(_:)), for: .valueChanged)

        opacitySlider.minimumValue = Float(Self.minimumOpacity)
        opacitySlider.maximumValue = 1.0
        opacitySlider.value = Float(brushOpacity)
        opacitySlider.addTarget(self, action: #selector(opacitySliderChanged(_:)), for: .valueChanged)

        let widthRow = makeControlRow(titleLabel: widthTitleLabel, valueLabel: widthValueLabel, slider: widthSlider)
        let opacityRow = makeControlRow(titleLabel: opacityTitleLabel, valueLabel: opacityValueLabel, slider: opacitySlider)

        let hintLabel = UILabel()
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.text = NSLocalizedString("单指涂抹，双指移动/缩放，双击快速放大或还原。", comment: "Mosaic hint")
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0

        let controlsStack = UIStackView(arrangedSubviews: [widthRow, opacityRow, hintLabel])
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.axis = .vertical
        controlsStack.spacing = 14

        controlCard.addSubview(controlsStack)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(canvasView)
        view.addSubview(controlCard)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            controlCard.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            controlCard.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            controlCard.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -12),

            controlsStack.topAnchor.constraint(equalTo: controlCard.topAnchor, constant: 14),
            controlsStack.leadingAnchor.constraint(equalTo: controlCard.leadingAnchor, constant: 14),
            controlsStack.trailingAnchor.constraint(equalTo: controlCard.trailingAnchor, constant: -14),
            controlsStack.bottomAnchor.constraint(equalTo: controlCard.bottomAnchor, constant: -14),

            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: controlCard.topAnchor, constant: -12)
        ])
    }

    private func makeControlTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }

    private func makeControlRow(titleLabel: UILabel, valueLabel: UILabel, slider: UISlider) -> UIStackView {
        let labelsRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel])
        labelsRow.axis = .horizontal
        labelsRow.alignment = .center

        let row = UIStackView(arrangedSubviews: [labelsRow, slider])
        row.axis = .vertical
        row.spacing = 6
        return row
    }

    private func updateCanvasLayoutIfNeeded() {
        let availableWidth = scrollView.bounds.width
        let availableHeight = scrollView.bounds.height
        guard availableWidth > 0, availableHeight > 0, originalImage.size.width > 0 else { return }

        if abs(availableWidth - lastLayoutWidth) < 0.5,
            abs(availableHeight - lastLayoutHeight) < 0.5,
            displaySize != .zero {
            centerContentIfNeeded()
            return
        }

        let aspectRatio = originalImage.size.height / originalImage.size.width
        displaySize = CGSize(width: availableWidth, height: availableWidth * aspectRatio)
        lastLayoutWidth = availableWidth
        lastLayoutHeight = availableHeight

        contentView.frame = CGRect(origin: .zero, size: displaySize)
        imageView.frame = contentView.bounds
        canvasView.frame = contentView.bounds
        scrollView.contentSize = displaySize

        let minimumZoomScale = min(1.0, availableHeight / displaySize.height)
        let maximumZoomScale = max(minimumZoomScale, Self.maximumZoomScale)
        let currentZoomScale = scrollView.zoomScale > 0 ? scrollView.zoomScale : minimumZoomScale

        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.zoomScale = min(max(currentZoomScale, minimumZoomScale), maximumZoomScale)

        previewPixelatedImage = makePreviewPixelatedImage(for: displaySize)
        canvasView.previewImage = previewPixelatedImage
        canvasView.imageScale = imageScale
        centerContentIfNeeded()
    }

    private func centerContentIfNeeded() {
        let scaledWidth = displaySize.width * scrollView.zoomScale
        let scaledHeight = displaySize.height * scrollView.zoomScale
        let horizontalInset = max((scrollView.bounds.width - scaledWidth) / 2, 0)
        let verticalInset = max((scrollView.bounds.height - scaledHeight) / 2, 0)

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    private func makePreviewPixelatedImage(for size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let scaledImage = resizedImage(from: originalImage, targetSize: size)
        let displayBlockSize = max(Self.defaultMosaicBlockSize / imageScale, 1.0)
        return pixelatedImage(from: scaledImage, blockSize: displayBlockSize)
    }

    private func resizedImage(from image: UIImage, targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func pixelatedImage(from image: UIImage, blockSize: CGFloat) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return nil }
        guard let filter = CIFilter(name: "CIPixellate") else { return nil }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(blockSize, forKey: kCIInputScaleKey)
        filter.setValue(CIVector(x: inputImage.extent.midX, y: inputImage.extent.midY), forKey: kCIInputCenterKey)

        guard let outputImage = filter.outputImage?.cropped(to: inputImage.extent) else { return nil }
        guard let cgImage = ciContext.createCGImage(outputImage, from: inputImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func exportPixelatedImageIfNeeded() -> UIImage? {
        if let exportPixelatedImage {
            return exportPixelatedImage
        }

        let image = pixelatedImage(from: originalImage, blockSize: Self.defaultMosaicBlockSize)
        exportPixelatedImage = image
        return image
    }

    private func updateControlValues() {
        widthValueLabel.text = String(
            format: NSLocalizedString("%.0f%%", comment: "Mosaic width value"),
            normalizedPercentage(for: brushWidth, minimum: Self.minimumBrushWidth, maximum: Self.maximumBrushWidth)
        )
        opacityValueLabel.text = String(
            format: NSLocalizedString("%.0f%%", comment: "Mosaic opacity value"),
            normalizedPercentage(for: brushOpacity, minimum: Self.minimumOpacity, maximum: 1.0)
        )
    }

    private func normalizedPercentage(for value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        guard maximum > minimum else { return 0 }
        let ratio = (value - minimum) / (maximum - minimum)
        return min(max(ratio, 0), 1) * 100
    }

    private func refreshCurrentStrokeStyleIfNeeded() {
        guard var currentStroke else { return }
        currentStroke.lineWidth = brushWidth * imageScale
        currentStroke.opacity = brushOpacity
        self.currentStroke = currentStroke
        canvasView.currentStroke = currentStroke
    }

    private func updateActionItems() {
        undoItem.isEnabled = !strokes.isEmpty
        redoItem.isEnabled = !redoStrokes.isEmpty
        doneItem.isEnabled = true
    }

    private func beginStroke(at point: CGPoint) {
        redoStrokes.removeAll()
        currentStroke = MosaicStroke(
            points: [convertToImagePoint(point)],
            lineWidth: brushWidth * imageScale,
            opacity: brushOpacity
        )
        canvasView.currentStroke = currentStroke
        updateActionItems()
    }

    private func appendStrokePoint(_ point: CGPoint) {
        guard var currentStroke else { return }
        currentStroke.points.append(convertToImagePoint(point))
        self.currentStroke = currentStroke
        canvasView.currentStroke = currentStroke
    }

    private func finishStroke() {
        guard var currentStroke else { return }

        if currentStroke.points.count == 1, let point = currentStroke.points.first {
            currentStroke.points.append(point)
        }

        strokes.append(currentStroke)
        self.currentStroke = nil
        canvasView.currentStroke = nil
        canvasView.strokes = strokes
        updateActionItems()
    }

    private func cancelCurrentStroke() {
        currentStroke = nil
        canvasView.currentStroke = nil
        updateActionItems()
    }

    private func convertToImagePoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * imageScale, y: point.y * imageScale)
    }

    private func renderEditedImage() -> UIImage {
        guard !strokes.isEmpty, let mosaicImage = exportPixelatedImageIfNeeded() else {
            return originalImage
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = originalImage.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: originalImage.size, format: format)
        return renderer.image { context in
            originalImage.draw(at: .zero)

            let rect = CGRect(origin: .zero, size: originalImage.size)
            for stroke in strokes {
                guard let path = stroke.bezierPath(scale: 1.0) else { continue }

                let cgContext = context.cgContext
                cgContext.saveGState()
                cgContext.addPath(path.cgPath)
                cgContext.setLineWidth(path.lineWidth)
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)
                cgContext.replacePathWithStrokedPath()
                cgContext.clip()
                mosaicImage.draw(in: rect, blendMode: .normal, alpha: stroke.opacity)
                cgContext.restoreGState()
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard scrollView === self.scrollView else { return nil }
        return contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        centerContentIfNeeded()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    @objc private func widthSliderChanged(_ sender: UISlider) {
        brushWidth = CGFloat(sender.value)
        refreshCurrentStrokeStyleIfNeeded()
    }

    @objc private func opacitySliderChanged(_ sender: UISlider) {
        brushOpacity = CGFloat(sender.value)
        refreshCurrentStrokeStyleIfNeeded()
    }

    @objc private func handleDrawingPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: canvasView)
        guard canvasView.bounds.contains(location) else {
            if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
                finishStroke()
            }
            return
        }

        switch gesture.state {
        case .began:
            beginStroke(at: location)
        case .changed:
            appendStrokePoint(location)
        case .ended:
            appendStrokePoint(location)
            finishStroke()
        case .cancelled, .failed:
            cancelCurrentStroke()
        default:
            break
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        let targetZoomScale = min(scrollView.maximumZoomScale, 2.5)
        let tapLocation = gesture.location(in: contentView)
        let zoomRectSize = CGSize(
            width: scrollView.bounds.width / targetZoomScale,
            height: scrollView.bounds.height / targetZoomScale
        )
        let zoomRect = CGRect(
            x: tapLocation.x - zoomRectSize.width / 2,
            y: tapLocation.y - zoomRectSize.height / 2,
            width: zoomRectSize.width,
            height: zoomRectSize.height
        )

        scrollView.zoom(to: zoomRect, animated: true)
    }

    @objc private func undoTapped() {
        guard let stroke = strokes.popLast() else { return }
        redoStrokes.append(stroke)
        canvasView.strokes = strokes
        updateActionItems()
    }

    @objc private func redoTapped() {
        guard let stroke = redoStrokes.popLast() else { return }
        strokes.append(stroke)
        canvasView.strokes = strokes
        updateActionItems()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        onConfirm?(renderEditedImage())
        if let navigationController {
            navigationController.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}