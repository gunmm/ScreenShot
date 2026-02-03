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
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var imageAspectRatioConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        
        
        // 3. Save Button
        saveButton.setTitle("Save to Photos", for: .normal)
        saveButton.addTarget(self, action: #selector(saveToPhotos), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.isEnabled = false
        view.addSubview(saveButton)
        
        // 4. Status Label
        statusLabel.text = "Ready. Tap Record to start."
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // 5. ScrollView & ImageView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        // 6. Activity Indicator
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

            
            statusLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func generateLongScreenshot() {
        // Load chunks
        // ChunkManager loads (image, offset). We only care about images now.
        let chunksWithOffsets = ChunkManager.shared.loadAllChunks()
        let chunks = chunksWithOffsets.map { $0.image }
        
        guard !chunks.isEmpty else {
            statusLabel.text = "No chunks found. Did you record and scroll?"
            return
        }
        
        statusLabel.text = "Stitching \(chunks.count) frames (Deep Analysis)..."
        
        // Start loading
        activityIndicator.startAnimating()
        stitchButton.isEnabled = false
        view.isUserInteractionEnabled = false // Optional: block other interactions
        
        // Run on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let stitchedImage = ImageStitcher.stitch(images: chunks)
            
            print("")
            DispatchQueue.main.async {
                if let result = stitchedImage {
                    self.imageView.image = result
                    
                    // Update aspect ratio constraint
                    if let existingConstraint = self.imageAspectRatioConstraint {
                        existingConstraint.isActive = false
                    }
                    if result.size.width > 0 {
                        let ratio = result.size.height / result.size.width
                        self.imageAspectRatioConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: ratio)
                        self.imageAspectRatioConstraint?.isActive = true
                    }
                    
                    self.saveButton.isEnabled = true
                    self.statusLabel.text = "Stitched! Size: \(Int(result.size.width))x\(Int(result.size.height))"
                } else {
                    self.statusLabel.text = "Stitching failed."
                }
                
                // Stop loading
                self.activityIndicator.stopAnimating()
                self.stitchButton.isEnabled = true
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc private func saveToPhotos() {
        guard let image = imageView.image else { return }
        
        let handler: (PHAuthorizationStatus) -> Void = { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Permission denied."
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
}
