import Foundation

enum ProFeatureGate {
    case removeWatermark
    case applyStitchAdjustment
    case saveMarkupEffects
    case exportPDF

    var intro: String {
        switch self {
        case .removeWatermark:
            return NSLocalizedString("去水印属于 Pro 权益。", comment: "Pro gate intro for remove watermark")
        case .applyStitchAdjustment:
            return NSLocalizedString("拼接调整结果应用属于 Pro 权益。", comment: "Pro gate intro for stitch adjustment")
        case .saveMarkupEffects:
            return NSLocalizedString("涂抹和打码效果保存属于 Pro 权益。", comment: "Pro gate intro for markup save")
        case .exportPDF:
            return NSLocalizedString("PDF 导出属于 Pro 权益。", comment: "Pro gate intro for PDF export")
        }
    }
}

final class ProAccessCoordinator {
    static let shared = ProAccessCoordinator()

    private init() {}

    func isProUser() -> Bool {
        PurchaseManager.shared.isPurchased()
    }

    func preloadProductInfo(completion: (() -> Void)? = nil) {
        PurchaseManager.shared.loadProductInfo { _ in
            completion?()
        }
    }

    func priceDescription() -> String {
        if let price = PurchaseManager.shared.currentProductInfo?.localizedPrice {
            return String(format: NSLocalizedString("立即解锁永久 Pro，仅需 %@。", comment: "Pro upgrade price description"), price)
        }

        return NSLocalizedString("立即解锁永久 Pro，解锁全部权益。", comment: "Pro upgrade fallback description")
    }

    func benefitsText() -> String {
        [
            NSLocalizedString("Pro 权益：", comment: "Pro benefits title"),
            NSLocalizedString("1. 拼接调整", comment: "Pro benefit stitch adjustment"),
            NSLocalizedString("2. 去水印", comment: "Pro benefit remove watermark"),
            NSLocalizedString("3. 涂抹、打码", comment: "Pro benefit markup and mosaic"),
            NSLocalizedString("4. 保存 PDF", comment: "Pro benefit PDF export")
        ].joined(separator: "\n")
    }

    func paywallMessage(for gate: ProFeatureGate) -> String {
        [
            gate.intro,
            benefitsText(),
            priceDescription()
        ].joined(separator: "\n\n")
    }
}