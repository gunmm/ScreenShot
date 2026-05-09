import UIKit

final class MarkupEntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private static let entryRowHeight: CGFloat = 74

    fileprivate enum Destination {
        case markup
        case mosaic
    }

    fileprivate struct Entry {
        let id = UUID()
        var title: String
        var subtitle: String
        let iconName: String
        let accentColor: UIColor
        let destination: Destination
    }

    private let originalImage: UIImage

    var onConfirm: ((UIImage) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var entries: [Entry] = [
        Entry(
            title: NSLocalizedString("涂抹", comment: "Markup entry markup button"),
            subtitle: NSLocalizedString("使用现有画笔工具进行自由遮挡", comment: "Markup entry markup subtitle"),
            iconName: "pencil.tip.crop.circle",
            accentColor: .systemBlue,
            destination: .markup
        ),
        Entry(
            title: NSLocalizedString("马赛克", comment: "Markup entry mosaic button"),
            subtitle: NSLocalizedString("滑动涂抹局部区域，应用像素化打码效果", comment: "Markup entry mosaic subtitle"),
            iconName: "square.grid.3x3.fill",
            accentColor: .systemOrange,
            destination: .mosaic
        )
    ]

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

    private func setupNavigationBar() {
        title = NSLocalizedString("选择编辑方式", comment: "Markup entry title")
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("取消", comment: "Cancel"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = Self.entryRowHeight
        tableView.estimatedRowHeight = Self.entryRowHeight
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 16)
        tableView.register(ProEntryCell.self, forCellReuseIdentifier: "EntryCell")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        view.addSubview(tableView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: guide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func openMarkup() {
        AppLogger.shared.log("MarkupEntry openMarkup tapped")
        let markupViewController = MarkupViewController(image: originalImage)
        markupViewController.onConfirm = { [weak self] image in
            self?.onConfirm?(image)
        }
        navigationController?.pushViewController(markupViewController, animated: true)
    }

    private func openMosaic() {
        AppLogger.shared.log("MarkupEntry openMosaic tapped")
        let mosaicViewController = MosaicViewController(image: originalImage)
        mosaicViewController.onConfirm = { [weak self] image in
            self?.onConfirm?(image)
        }
        navigationController?.pushViewController(mosaicViewController, animated: true)
    }

    private func openDestination(for entry: Entry) {
        switch entry.destination {
        case .markup:
            openMarkup()
        case .mosaic:
            openMosaic()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell", for: indexPath) as? ProEntryCell else {
            return UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        }
        let entry = entries[indexPath.section]

        cell.configure(with: entry)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openDestination(for: entries[indexPath.section])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

private final class ProEntryCell: UITableViewCell {
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let chevronView = UIImageView()
    private let ribbonLabel = PaddingLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .default
        backgroundColor = .secondarySystemGroupedBackground
        accessoryType = .none
        clipsToBounds = false
        contentView.clipsToBounds = false

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.systemGray6
        iconContainer.layer.cornerRadius = 12
        contentView.addSubview(iconContainer)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail

        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 3
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        contentView.addSubview(textStack)

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit
        contentView.addSubview(chevronView)

        ribbonLabel.text = NSLocalizedString("PRO", comment: "Pro badge")
        ribbonLabel.font = .systemFont(ofSize: 8, weight: .heavy)
        ribbonLabel.textColor = .white
        ribbonLabel.backgroundColor = .systemOrange
        ribbonLabel.textAlignment = .center
        ribbonLabel.horizontalPadding = 8
        ribbonLabel.verticalPadding = 2
        ribbonLabel.layer.cornerRadius = 6
        ribbonLabel.layer.masksToBounds = true
        ribbonLabel.transform = CGAffineTransform(rotationAngle: -.pi / 10)
        ribbonLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ribbonLabel)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            chevronView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            chevronView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 10),
            chevronView.heightAnchor.constraint(equalToConstant: 16),

            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -14),

            ribbonLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            ribbonLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            ribbonLabel.heightAnchor.constraint(equalToConstant: 14),
            ribbonLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 26)
        ])
    }

    func configure(with entry: MarkupEntryViewController.Entry) {
        titleLabel.text = entry.title
        subtitleLabel.text = entry.subtitle
        iconView.image = UIImage(systemName: entry.iconName)
        iconView.tintColor = entry.accentColor
        iconContainer.backgroundColor = entry.accentColor.withAlphaComponent(0.12)
        contentView.bringSubviewToFront(ribbonLabel)
    }
}

private final class PaddingLabel: UILabel {
    var horizontalPadding: CGFloat = 0
    var verticalPadding: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + horizontalPadding * 2, height: size.height + verticalPadding * 2)
    }

    override func drawText(in rect: CGRect) {
        let insetRect = rect.insetBy(dx: horizontalPadding, dy: verticalPadding)
        super.drawText(in: insetRect)
    }
}