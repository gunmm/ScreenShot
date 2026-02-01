import UIKit
import ReplayKit
import Photos

class ViewController: UIViewController {

    private let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let stitchButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system) // New button
    private let calcOverlapButton = UIButton(type: .system) // New debug button
    private let saveButton = UIButton(type: .system)
    private let statusLabel = UILabel()

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
        
        // 2.2 Calculate Overlap Button (Debug)
        calcOverlapButton.setTitle("Debug: Calc Overlap Logs", for: .normal)
        calcOverlapButton.addTarget(self, action: #selector(runOverlapCalculation), for: .touchUpInside)
        calcOverlapButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calcOverlapButton)

        
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
            
            previewButton.topAnchor.constraint(equalTo: stitchButton.bottomAnchor, constant: 10),
            previewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            previewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            calcOverlapButton.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 10),
            calcOverlapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: calcOverlapButton.bottomAnchor, constant: 8),
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
        // ChunkManager loads (image, offset). We only care about images now.
//        let chunksWithOffsets = ChunkManager.shared.loadAllChunks()
//        let chunks = chunksWithOffsets.map { $0.image }
//        
//        guard !chunks.isEmpty else {
//            statusLabel.text = "No chunks found. Did you record and scroll?"
//            return
//        }
//        
//        statusLabel.text = "Stitching \(chunks.count) frames (Deep Analysis)..."
        
        // Run on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            if let image1 = UIImage(named: "photo1.PNG"),
               let image2 = UIImage(named: "photo2.PNG"),
               let image3 = UIImage(named: "photo3.PNG"),
               let image4 = UIImage(named: "photo4.PNG"),
               let image5 = UIImage(named: "photo5.PNG"),
               let image6 = UIImage(named: "photo6.PNG") {

            
                let stitchedImage = ImageStitcher.stitch(images: [image1, image2,image3, image4, image5,image6])
                print("")
                DispatchQueue.main.async {
                    if let result = stitchedImage {
                        self.imageView.image = result
                        self.imageView.sizeToFit()
                        self.scrollView.contentSize = self.imageView.frame.size
                        self.saveButton.isEnabled = true
                        self.statusLabel.text = "Stitched! Size: \(Int(result.size.width))x\(Int(result.size.height))"
                    } else {
                        self.statusLabel.text = "Stitching failed."
                    }
                }
            }
            
//            DispatchQueue.main.async {
//                if let result = stitchedImage {
//                    self.imageView.image = result
//                    self.imageView.sizeToFit()
//                    self.scrollView.contentSize = self.imageView.frame.size
//                    self.saveButton.isEnabled = true
//                    self.statusLabel.text = "Stitched! Size: \(Int(result.size.width))x\(Int(result.size.height))"
//                } else {
//                    self.statusLabel.text = "Stitching failed."
//                }
//            }
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
    @objc private func runOverlapCalculation() {
        let chunksWithOffsets = ChunkManager.shared.loadAllChunks()
        let chunks = chunksWithOffsets.map { $0.image }
        
        guard !chunks.isEmpty else {
            statusLabel.text = "No chunks to calculate overlap."
            return
        }
        
        statusLabel.text = "Calculating overlaps (See logs)..."
        
        ImageOverlapCalculator.calculateOverlaps(images: chunks) { results in
            DispatchQueue.main.async {
                self.statusLabel.text = "Overlap Calc Done! Check Console."
                print("\n=== Overlap Calculation Results ===")
                for res in results {
                    print(res)
                }
                print("===================================")
            }
        }
    }
}
