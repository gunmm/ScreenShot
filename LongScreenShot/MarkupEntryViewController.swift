import UIKit

final class MarkupEntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private static let entryRowHeight: CGFloat = 74

    private enum Destination {
        case markup
        case mosaic
    }

    private struct Entry {
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
            subtitle: NSLocalizedString("进入马赛克编辑页骨架，后续接入真实像素化能力", comment: "Markup entry mosaic subtitle"),
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EntryCell")
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
        let markupViewController = MarkupViewController(image: originalImage)
        markupViewController.onConfirm = { [weak self] image in
            self?.onConfirm?(image)
        }
        navigationController?.pushViewController(markupViewController, animated: true)
    }

    private func openMosaic() {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell", for: indexPath)
        let entry = entries[indexPath.section]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = entry.title
        content.secondaryText = entry.subtitle
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        content.secondaryTextProperties.font = .systemFont(ofSize: 13)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 1
        content.secondaryTextProperties.lineBreakMode = .byTruncatingTail
        content.image = UIImage(systemName: entry.iconName)
        content.imageProperties.tintColor = entry.accentColor
        content.imageProperties.cornerRadius = 8
        content.imageProperties.maximumSize = CGSize(width: 22, height: 22)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 4, bottom: 12, trailing: 4)

        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.backgroundColor = .secondarySystemGroupedBackground
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