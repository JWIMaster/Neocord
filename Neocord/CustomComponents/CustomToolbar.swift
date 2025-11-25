import UIKit
import UIKitCompatKit
import UIKitExtensions

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
    
    private let backgroundView: UIView? = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 6, cornerRadius: 12, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur, filterExclusions: ThemeEngine.glassFilterExclusions)
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
        guard let backgroundView = backgroundView else { return }
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
            stackView.addArrangedSubview(button)
            button.setContentHuggingPriority(.required, for: .horizontal)
        }
        
        // Force layout update
        stackView.layoutIfNeeded()
    }

}


