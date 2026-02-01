import UIKit

class ChunksPreviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var chunks: [(image: UIImage, offset: Int)] = []
    private let collectionView: UICollectionView
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 180)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chunks Preview"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
        loadChunks()
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ChunkCell.self, forCellWithReuseIdentifier: "ChunkCell")
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadChunks() {
        chunks = ChunkManager.shared.loadAllChunks()
        if chunks.isEmpty {
            let label = UILabel()
            label.text = "No chunks found"
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.frame = view.bounds
            collectionView.backgroundView = label
        }
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return chunks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChunkCell", for: indexPath) as! ChunkCell
        let chunk = chunks[indexPath.item]
        cell.configure(image: chunk.image, index: indexPath.item, offset: chunk.offset)
        return cell
    }
}

class ChunkCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let indexLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.secondarySystemFill.cgColor
        
        indexLabel.font = .systemFont(ofSize: 10)
        indexLabel.textColor = .label
        indexLabel.textAlignment = .center
        indexLabel.backgroundColor = .systemBackground.withAlphaComponent(0.7)
        
        contentView.addSubview(imageView)
        contentView.addSubview(indexLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            indexLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            indexLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            indexLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            indexLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(image: UIImage, index: Int, offset: Int) {
        imageView.image = image
        indexLabel.text = "#\(index) (off: \(offset))"
    }
}
