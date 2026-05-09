import UIKit

final class ProPaywallViewController: UIViewController {
    private let coordinator: ProAccessCoordinator
    private let gate: ProFeatureGate
    private let alternativeActionTitle: String?
    private let alternativeActionStyle: UIAlertAction.Style

    var onPrimaryAction: (() -> Void)?
    var onSecondaryAction: (() -> Void)?
    var onAlternativeAction: (() -> Void)?

    private let dimView = UIView()
    private let cardView = UIView()
    private let iconGlowView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let benefitsStack = UIStackView()
    private let priceLabel = UILabel()
    private let ownershipLabel = UILabel()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private let alternativeButton = UIButton(type: .system)
    private let buttonStack = UIStackView()
    private let loadingView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    init(
        coordinator: ProAccessCoordinator,
        gate: ProFeatureGate,
        alternativeActionTitle: String?,
        alternativeActionStyle: UIAlertAction.Style
    ) {
        self.coordinator = coordinator
        self.gate = gate
        self.alternativeActionTitle = alternativeActionTitle
        self.alternativeActionStyle = alternativeActionStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        AppLogger.shared.log("ProPaywall shown: gate=\(gate)")
        setupUI()
        populateContent()
    }

    func setLoading(_ isLoading: Bool) {
        loadingView.isHidden = !isLoading
        primaryButton.isEnabled = !isLoading
        secondaryButton.isEnabled = !isLoading
        alternativeButton.isEnabled = !isLoading
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func setupUI() {
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSecondaryAction))
        dimView.addGestureRecognizer(tap)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 24
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.14
        cardView.layer.shadowRadius = 28
        cardView.layer.shadowOffset = CGSize(width: 0, height: 16)
        view.addSubview(cardView)

        iconGlowView.translatesAutoresizingMaskIntoConstraints = false
        iconGlowView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        iconGlowView.layer.cornerRadius = 26
        cardView.addSubview(iconGlowView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "crown.fill")
        iconView.tintColor = .systemOrange
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        cardView.addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        cardView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        cardView.addSubview(subtitleLabel)

        benefitsStack.translatesAutoresizingMaskIntoConstraints = false
        benefitsStack.axis = .vertical
        benefitsStack.spacing = 10
        cardView.addSubview(benefitsStack)

        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        priceLabel.textColor = .systemOrange
        priceLabel.textAlignment = .center
        priceLabel.numberOfLines = 0
        priceLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        priceLabel.layer.cornerRadius = 14
        priceLabel.layer.masksToBounds = true
        cardView.addSubview(priceLabel)

        ownershipLabel.translatesAutoresizingMaskIntoConstraints = false
        ownershipLabel.font = .systemFont(ofSize: 13, weight: .medium)
        ownershipLabel.textColor = .secondaryLabel
        ownershipLabel.textAlignment = .center
        ownershipLabel.numberOfLines = 0
        cardView.addSubview(ownershipLabel)

        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.setTitle(NSLocalizedString("升级 Pro", comment: "Upgrade Pro action"), for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.backgroundColor = .systemOrange
        primaryButton.layer.cornerRadius = 16
        primaryButton.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)

        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        secondaryButton.setTitle(NSLocalizedString("取消", comment: "Cancel action"), for: .normal)
        secondaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        secondaryButton.setTitleColor(.secondaryLabel, for: .normal)
        secondaryButton.backgroundColor = .secondarySystemGroupedBackground
        secondaryButton.layer.cornerRadius = 16
        secondaryButton.addTarget(self, action: #selector(handleSecondaryAction), for: .touchUpInside)

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = 10
        buttonStack.addArrangedSubview(primaryButton)

        if let alternativeActionTitle {
            alternativeButton.translatesAutoresizingMaskIntoConstraints = false
            alternativeButton.setTitle(alternativeActionTitle, for: .normal)
            alternativeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            alternativeButton.setTitleColor(alternativeActionStyle == .destructive ? .systemRed : .systemBlue, for: .normal)
            alternativeButton.backgroundColor = .secondarySystemGroupedBackground
            alternativeButton.layer.cornerRadius = 16
            alternativeButton.addTarget(self, action: #selector(handleAlternativeAction), for: .touchUpInside)
            buttonStack.addArrangedSubview(alternativeButton)
        }

        buttonStack.addArrangedSubview(secondaryButton)
        cardView.addSubview(buttonStack)

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.isHidden = true
        loadingView.layer.cornerRadius = 18
        loadingView.clipsToBounds = true
        cardView.addSubview(loadingView)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        loadingView.contentView.addSubview(loadingIndicator)

        let loadingLabel = UILabel()
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = NSLocalizedString("正在请求支付...", comment: "Requesting purchase loading")
        loadingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        loadingLabel.textColor = .white
        loadingView.contentView.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            iconGlowView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            iconGlowView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconGlowView.widthAnchor.constraint(equalToConstant: 220),
            iconGlowView.heightAnchor.constraint(equalToConstant: 96),

            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 42),
            iconView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconGlowView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            benefitsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 22),
            benefitsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            benefitsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            priceLabel.topAnchor.constraint(equalTo: benefitsStack.bottomAnchor, constant: 20),
            priceLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            priceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            priceLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),

            ownershipLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 12),
            ownershipLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            ownershipLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            buttonStack.topAnchor.constraint(equalTo: ownershipLabel.bottomAnchor, constant: 22),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),

            primaryButton.heightAnchor.constraint(equalToConstant: 52),
            secondaryButton.heightAnchor.constraint(equalToConstant: 48),
            alternativeButton.heightAnchor.constraint(equalToConstant: 48),

            loadingView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 156),
            loadingView.heightAnchor.constraint(equalToConstant: 120),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingView.contentView.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: loadingView.contentView.topAnchor, constant: 22),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.contentView.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 12)
        ])
    }

    private func populateContent() {
        titleLabel.text = NSLocalizedString("解锁 Pro 权限", comment: "Unlock Pro title")
        subtitleLabel.text = gate.intro
        priceLabel.text = coordinator.priceDescription()
        ownershipLabel.text = NSLocalizedString("永久权益，一次支付即可长期使用。\n无订阅、无自动续费，解锁后可一直使用当前 Pro 功能。", comment: "Permanent ownership description")

        let benefitItems = [
            NSLocalizedString("1. 拼接调整", comment: "Pro benefit stitch adjustment"),
            NSLocalizedString("2. 去水印", comment: "Pro benefit remove watermark"),
            NSLocalizedString("3. 涂抹、打码", comment: "Pro benefit markup and mosaic"),
            NSLocalizedString("4. 保存 PDF", comment: "Pro benefit PDF export")
        ]

        for text in benefitItems {
            let row = makeBenefitRow(text: text)
            benefitsStack.addArrangedSubview(row)
        }
    }

    private func makeBenefitRow(text: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .systemOrange

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18)
        ])

        return stack
    }

    @objc private func handlePrimaryAction() {
        AppLogger.shared.log("ProPaywall primary tapped: gate=\(gate)")
        onPrimaryAction?()
    }

    @objc private func handleSecondaryAction() {
        AppLogger.shared.log("ProPaywall secondary tapped: gate=\(gate)")
        onSecondaryAction?()
    }

    @objc private func handleAlternativeAction() {
        let actionTitle = alternativeActionTitle ?? "unknown"
        AppLogger.shared.log("ProPaywall alternative tapped: gate=\(gate), action=\(actionTitle)")
        onAlternativeAction?()
    }
}
