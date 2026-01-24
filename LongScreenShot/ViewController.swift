import UIKit
import ReplayKit
import Photos

class ViewController: UIViewController {

    private let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let stitchButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Long Screenshot"
        
        // 1. Broadcast Picker
        // Note: The preferredExtension property must match the Bundle Identifier of the Extension
        // User needs to set this manually or I can leave it nil to show all. 
        // Best practice: set it to specific extension.
        // broadcastPicker.preferredExtension = "com.yourname.LongScreenShot.BroadCastExtension"
        
        broadcastPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(broadcastPicker)
        
        // 2. Stitch Button
        stitchButton.setTitle("Generate Long Screenshot", for: .normal)
        stitchButton.addTarget(self, action: #selector(generateLongScreenshot), for: .touchUpInside)
        stitchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stitchButton)
        
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
        
        NSLayoutConstraint.activate([
            broadcastPicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            broadcastPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            broadcastPicker.widthAnchor.constraint(equalToConstant: 60),
            broadcastPicker.heightAnchor.constraint(equalToConstant: 60),
            
            stitchButton.topAnchor.constraint(equalTo: broadcastPicker.bottomAnchor, constant: 20),
            stitchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: stitchButton.bottomAnchor, constant: 8),
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
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    @objc private func generateLongScreenshot() {
        // Load chunks
        let chunks = ChunkManager.shared.loadAllChunks()
        guard !chunks.isEmpty else {
            statusLabel.text = "No chunks found. Did you record and scroll?"
            return
        }
        
        statusLabel.text = "Stitching \(chunks.count) frames..."
        
        // Simple Vertical Stitching
        // Calculate total height
        // First image is full height (cropped). Subsequent images are stitched with offset.
        // Actually, we saved chunks cropped. But we also have offsets relative to *movement*.
        // If our logic in SampleHandler was:
        // Frame 0: Save Full (Cropped)
        // Frame 1: Offset detected = 20px. Saved Full (Cropped).
        // That means Frame 1 is shifted UP by 20px. So new content is 20px at the bottom?
        // Wait, standard scroll down: content moves UP.
        // If content moves UP by 20px, the bottom 20px of screen is new.
        // SampleHandler saved the whole frame.
        // So we need to take the bottom 'offset' pixels of the new frame and append it?
        // YES.
        
        // Wait, SampleHandler logic:
        // findOffset return Y.
        // If Y > 0, it means PREV row Y matches CURR row 0.
        // PREV:
        // [ A ]
        // [ B ]
        // [ C ]
        // CURR (Scrolled down, camera moved down, content moved up):
        // [ B ]
        // [ C ]
        // [ D ]
        // Stitcher found row 0 of CURR (B) matches row 1 of PREV (B). Offset = 1.
        // So CURR is shifted UP by 1 unit relative to PREV.
        // The new content is D.
        // D is at the bottom.
        // We need to keep PREV [A, B, C] and append [D].
        // D corresponds to the bottom 'Offset' pixels of CURR.
        
        var totalHeight: CGFloat = 0
        let width = chunks[0].image.size.width
        
        // First image: keep all
        totalHeight += chunks[0].image.size.height
        
        // Subsequent: keep only offset amount
        for i in 1..<chunks.count {
            let offset = CGFloat(chunks[i].offset)
            totalHeight += offset
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: totalHeight), false, 0.0)
        
        var currentY: CGFloat = 0
        
        // Draw first
        chunks[0].image.draw(at: CGPoint(x: 0, y: 0))
        currentY += chunks[0].image.size.height
        
        // Draw subsequent (slices)
        for i in 1..<chunks.count {
            let img = chunks[i].image
            let offset = CGFloat(chunks[i].offset)
            
            // We need bottom 'offset' slice of img
            // Since img is 'whole screen cropped', height is H.
            // We want the rect: y = H - offset, h = offset
            
            let sliceHeight = offset
            let sliceY = img.size.height - sliceHeight
            
            // Draw into context
            // But wait! If we append, we append to the bottom.
            // Correct.
            // Crop the slice from the new image
            if let cgImage = img.cgImage {
                let cropRect = CGRect(x: 0, y: sliceY, width: width, height: sliceHeight)
                if let slice = cgImage.cropping(to: cropRect) {
                    let sliceImg = UIImage(cgImage: slice)
                     // Note: currentY is where we *stopped* drawing the previous image.
                     // But previous image was full height.
                     // If we just append, we are good.
                     // But wait.
                     // Frame 0: [A B C], H=3.
                     // Frame 1: [B C D], Offset=1. Slice [D].
                     // If we draw Frame 0 fully: [A B C]
                     // Then append D: [A B C D]. Length 4. Correct.
                     
                     sliceImg.draw(in: CGRect(x: 0, y: currentY, width: width, height: sliceHeight))
                     currentY += sliceHeight
                }
            }
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        imageView.image = finalImage
        imageView.sizeToFit()
        scrollView.contentSize = imageView.frame.size
        saveButton.isEnabled = true
        statusLabel.text = "Stitched! Size: \(Int(width))x\(Int(totalHeight))"
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
}
