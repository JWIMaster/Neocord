import UIKit
import UIKitCompatKit
import UIKitExtensions

class CustomToolbar: UIView {

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let backgroundView: UIView? = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 6, cornerRadius: 22, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
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
        //backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        
        addSubview(stackView)
        //stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Pin stackView to safe area
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Public API
    func setItems(_ buttons: [UIButton]) {
        // Remove old buttons
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for button in buttons {
            stackView.addArrangedSubview(button)
        }
    }
}


