import UIKit

class EditViewController: UIViewController {
    
    // Core Data
    private let originalImages: [UIImage]
    private var currentRanges: [(start: Int, end: Int)]
    
    // Callbacks
    var onConfirm: (([(start: Int, end: Int)]) -> Void)?
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var chunkContainers: [ChunkContainer] = []
    private var selectedIndex: Int?
    
    // Constants for handle thickness etc
    private let handleHeight: CGFloat = 30.0
    
    init(images: [UIImage], initialRanges: [(start: Int, end: Int)]) {
        self.originalImages = images
        self.currentRanges = initialRanges
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        layoutChunks()
    }
    
    private func setupNavigationBar() {
        title = "Edit Stitching"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0 // Key for seamless stitching look
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func layoutChunks() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chunkContainers.removeAll()
        
        for (index, image) in originalImages.enumerated() {
            let container = ChunkContainer(image: image, index: index, delegate: self)
            container.update(with: currentRanges[index])
            container.isSelected = false
            
            stackView.addArrangedSubview(container)
            chunkContainers.append(container)
        }
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onConfirm?(self.currentRanges)
        }
    }
}

extension EditViewController: ChunkContainerDelegate {
    func chunkContainer(_ container: ChunkContainer, didUpdateRange newRange: (start: Int, end: Int)) {
        let index = container.index
        currentRanges[index] = newRange
        container.update(with: newRange)
    }
    
    func chunkContainerDidSelect(_ container: ChunkContainer) {
        let newIndex = container.index
        
        if selectedIndex == newIndex {
            // Deselect if tapping the same
            selectedIndex = nil
            container.isSelected = false
        } else {
            // Deselect old
            if let oldIndex = selectedIndex {
                chunkContainers[oldIndex].isSelected = false
            }
            // Select new
            selectedIndex = newIndex
            container.isSelected = true
        }
    }
}

// MARK: - Custom Views

protocol ChunkContainerDelegate: AnyObject {
    func chunkContainer(_ container: ChunkContainer, didUpdateRange newRange: (start: Int, end: Int))
    func chunkContainerDidSelect(_ container: ChunkContainer)
}

class ChunkContainer: UIView {
    let index: Int
    private let imageContainer = UIView()
    private let imageView = UIImageView()
    private weak var delegate: ChunkContainerDelegate?
    
    private let topHandle = UIView()
    private let bottomHandle = UIView()
    
    // Properties to store original image info
    private let originalImage: UIImage
    private var currentRange: (start: Int, end: Int) = (0, 0)
    
    // Constraints we will animate/update
    private var containerHeightConstraint: NSLayoutConstraint!
    private var imageViewTopConstraint: NSLayoutConstraint!
    private var imageViewHeightConstraint: NSLayoutConstraint!
    
    // Interaction State
    private var panStartY: CGFloat = 0.0
    private var initialRangeOnPanStart: (start: Int, end: Int) = (0, 0)
    
    var isSelected: Bool = false {
        didSet {
            topHandle.isHidden = !isSelected
            bottomHandle.isHidden = !isSelected
            
            // Add a subtle border to the selected chunk container
            layer.borderWidth = isSelected ? 2.0 : 0.0
            layer.borderColor = isSelected ? UIColor.systemYellow.withAlphaComponent(0.3).cgColor : nil
        }
    }
    
    init(image: UIImage, index: Int, delegate: ChunkContainerDelegate?) {
        self.originalImage = image
        self.index = index
        self.delegate = delegate
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
        
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.clipsToBounds = true
        addSubview(imageContainer)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = originalImage
        imageView.contentMode = .scaleAspectFill // To allow precise mapping
        imageContainer.addSubview(imageView)
        
        // Setup Handles
        topHandle.translatesAutoresizingMaskIntoConstraints = false
        topHandle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
        topHandle.layer.borderWidth = 1
        topHandle.layer.borderColor = UIColor.systemBlue.cgColor
        topHandle.isHidden = true
        addSubview(topHandle)
        
        let topPan = UIPanGestureRecognizer(target: self, action: #selector(handleTopPan(_:)))
        topHandle.addGestureRecognizer(topPan)
        
        bottomHandle.translatesAutoresizingMaskIntoConstraints = false
        bottomHandle.backgroundColor = UIColor.systemRed.withAlphaComponent(0.4)
        bottomHandle.layer.borderWidth = 1
        bottomHandle.layer.borderColor = UIColor.systemRed.cgColor
        bottomHandle.isHidden = true
        addSubview(bottomHandle)
        
        let bottomPan = UIPanGestureRecognizer(target: self, action: #selector(handleBottomPan(_:)))
        bottomHandle.addGestureRecognizer(bottomPan)
        
        // Tap to select
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // Initial Constraints placeholders (will be updated dynamically)
        containerHeightConstraint = heightAnchor.constraint(equalToConstant: 100)
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor)
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 100)
        
        NSLayoutConstraint.activate([
            containerHeightConstraint,
            
            imageContainer.topAnchor.constraint(equalTo: topAnchor),
            imageContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageViewTopConstraint,
            imageViewHeightConstraint,
            
            topHandle.topAnchor.constraint(equalTo: topAnchor),
            topHandle.centerXAnchor.constraint(equalTo: centerXAnchor),
            topHandle.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2),
            topHandle.heightAnchor.constraint(equalToConstant: 20),
            
            bottomHandle.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomHandle.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomHandle.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2),
            bottomHandle.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    /// Updates layout when new crop ranges are provided.
    /// Range unit: Original Image Pixels (scale-adjusted)
    func update(with range: (start: Int, end: Int)) {
        self.currentRange = range
        
        let totalHeightPx = Float(originalImage.size.height * originalImage.scale)
        guard totalHeightPx > 0 else { return }
        
        // The display logic needs the rendered width of the view to map pixels to points.
        // However, we are in setup mode, bounds might be 0. We've constrained via ScrollView frameLayoutGuide.
        // Since we know aspect ratio, we can calculate the intended display height.
        // Screen width is usually standard. We can wait for layoutSubviews, or we can use the main screen bounds as a proxy for the scrollView width
        let displayWidth = UIScreen.main.bounds.width
        let ratio = originalImage.size.height / originalImage.size.width
        let fullImageViewHeight = displayWidth * ratio
        
        let pointRatio = fullImageViewHeight / CGFloat(totalHeightPx)
        
        let visibleStartPt = CGFloat(range.start) * pointRatio
        let visibleEndPt = CGFloat(range.end) * pointRatio
        let visibleHeightPt = max(visibleEndPt - visibleStartPt, 0.0) // Reflect exact accurate height
        
        // The Container height shrinks to just the visible part
        containerHeightConstraint.constant = visibleHeightPt
        // The ImageView's full height stays the same relative proportion
        imageViewHeightConstraint.constant = fullImageViewHeight
        // The ImageView shifts up so the 'start' is at Y = 0 of the container
        imageViewTopConstraint.constant = -visibleStartPt
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isHidden && alpha > 0.01 && isUserInteractionEnabled && isSelected {
            // Check top handle
            let topPoint = topHandle.convert(point, from: self)
            if topHandle.bounds.contains(topPoint) {
                return topHandle
            }
            
            // Check bottom handle
            let bottomPoint = bottomHandle.convert(point, from: self)
            if bottomHandle.bounds.contains(bottomPoint) {
                return bottomHandle
            }
        }
        return super.hitTest(point, with: event)
    }
    
    // MARK: - Gestures
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.chunkContainerDidSelect(self)
    }
    
    @objc private func handleTopPan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .began:
            initialRangeOnPanStart = currentRange
        case .changed:
            let displayWidth = UIScreen.main.bounds.width
            let ratio = originalImage.size.height / originalImage.size.width
            let fullImageViewHeight = displayWidth * ratio
            
            let totalHeightPx = originalImage.size.height * originalImage.scale
            let pointToPxRatio = totalHeightPx / fullImageViewHeight
            
            // drag downwards increases the cut (crops more from top)
            let deltaPx = translation.y * pointToPxRatio
            var newStart = initialRangeOnPanStart.start + Int(deltaPx)
            
            // Bounds check
            newStart = max(0, min(newStart, currentRange.end - 100)) // Keep at least 100px difference
            
            delegate?.chunkContainer(self, didUpdateRange: (start: newStart, end: currentRange.end))
        default:
            break
        }
    }
    
    @objc private func handleBottomPan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .began:
            initialRangeOnPanStart = currentRange
        case .changed:
            let displayWidth = UIScreen.main.bounds.width
            let ratio = originalImage.size.height / originalImage.size.width
            let fullImageViewHeight = displayWidth * ratio
            
            let totalHeightPx = originalImage.size.height * originalImage.scale
            let pointToPxRatio = totalHeightPx / fullImageViewHeight
            
            // drag upwards decreases the cut (crops more from bottom)
            let deltaPx = translation.y * pointToPxRatio
            var newEnd = initialRangeOnPanStart.end + Int(deltaPx)
            
            let maxHeightPx = Int(originalImage.size.height * originalImage.scale)
            
            // Bounds check
            newEnd = max(currentRange.start + 100, min(newEnd, maxHeightPx))
            
            delegate?.chunkContainer(self, didUpdateRange: (start: currentRange.start, end: newEnd))
        default:
            break
        }
    }
}
