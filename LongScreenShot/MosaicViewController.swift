import UIKit

final class MosaicViewController: UIViewController {

    private let originalImage: UIImage

    var onConfirm: ((UIImage) -> Void)?

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let placeholderCard = UIView()
    private let imageView = UIImageView()
    private var imageHeightConstraint: NSLayoutConstraint?

    private var isNavigationRoot: Bool {
        navigationController?.viewControllers.first === self || navigationController == nil
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let availableWidth = scrollView.bounds.width
        guard availableWidth > 0, originalImage.size.width > 0 else { return }
        imageHeightConstraint?.constant = availableWidth * (originalImage.size.height / originalImage.size.width)
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

        let doneItem = UIBarButtonItem(
            title: NSLocalizedString("完成", comment: "Done"),
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        doneItem.isEnabled = false
        navigationItem.rightBarButtonItem = doneItem
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 16

        placeholderCard.translatesAutoresizingMaskIntoConstraints = false
        placeholderCard.backgroundColor = .secondarySystemBackground
        placeholderCard.layer.cornerRadius = 14
        placeholderCard.layer.borderWidth = 1
        placeholderCard.layer.borderColor = UIColor.separator.cgColor

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("马赛克功能开发中", comment: "Mosaic placeholder title")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = NSLocalizedString("当前页面先提供导航、预览和后续扩展骨架。真实像素化编辑、笔刷和导出逻辑会在后续迭代接入。", comment: "Mosaic placeholder body")
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0

        placeholderCard.addSubview(titleLabel)
        placeholderCard.addSubview(bodyLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = originalImage
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.separator.cgColor

        contentStackView.addArrangedSubview(placeholderCard)
        contentStackView.addArrangedSubview(imageView)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            titleLabel.topAnchor.constraint(equalTo: placeholderCard.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: placeholderCard.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: placeholderCard.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(equalTo: placeholderCard.bottomAnchor, constant: -16)
        ])

        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 240)
        imageHeightConstraint?.isActive = true
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
    }
}