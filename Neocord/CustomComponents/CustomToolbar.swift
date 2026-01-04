import UIKit
import UIKitCompatKit
import UIKitExtensions
import DeprecatedAPIKit



class CustomToolbar: UIView {
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fill
        sv.alignment = .center
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 6, cornerRadius: 22, disableBlur: PerformanceManager.disableBlur, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            glass.translatesAutoresizingMaskIntoConstraints = false
            return glass
        } else {
            let bg = UIView()
            bg.translatesAutoresizingMaskIntoConstraints = false
            return bg
        }
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        addSubview(stackView)
        
        // Center stackView horizontally and vertically
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.distribution = .fill // let buttons keep intrinsic width
    }

    func setItems(_ buttons: [UIButton]) {
        // Remove old buttons
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add buttons directly to stackView
        for button in buttons {
            button.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 7.0.1, *) {
                button.alignVertical()
            }
            stackView.addArrangedSubview(button)
            button.setContentHuggingPriority(.required, for: .horizontal)
        }
        
        // Force layout update
        stackView.layoutIfNeeded()
    }

}


extension UIButton {
    func alignVertical(spacing: CGFloat = 6.0) {
        guard let imageSize = self.imageView?.image?.size,
            let text = self.titleLabel?.text,
            let font = self.titleLabel?.font
            else { return }
        self.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: -imageSize.width, bottom: -(imageSize.height + spacing), right: 0.0)
        let labelString = NSString(string: text)
        let titleSize = labelString.size(withAttributes: [kCTFontAttributeName as NSAttributedString.Key: font])
        self.imageEdgeInsets = UIEdgeInsets(top: -(titleSize.height + spacing), left: 0.0, bottom: 0.0, right: -titleSize.width)
        let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0;
        self.contentEdgeInsets = UIEdgeInsets(top: edgeOffset, left: 0.0, bottom: edgeOffset, right: 0.0)
    }
}



