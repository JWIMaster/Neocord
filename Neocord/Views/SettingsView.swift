import UIKit
import UIKitCompatKit
import UIKitExtensions

class SettingsView: UIView {
    
    private var backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(
                blurRadius: 0,
                cornerRadius: 22,
                snapshotTargetView: nil,
                disableBlur: true,
                filterExclusions: ThemeEngine.glassFilterExclusions
            )
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            return glass
        } else {
            let bg = UIView()
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            bg.layer.cornerRadius = 22
            bg.translatesAutoresizingMaskIntoConstraints = false
            return bg
        }
    }()
    
    private var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        return scroll
    }()
    
    private var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var glassButton: UIView!
    private var animationsButton: UIView!
    private var profileTintingButton: UIView!
    private var resetTokenButton: UIView!
    
    private var filterButtons: [LiquidGlassView.AdvancedFilterOptions: UIView] = [:]
    
    public init() {
        super.init(frame: .zero)
        setup()
        setupFilterToggles()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(backgroundView)
        backgroundView.pinToEdges(of: self)
        
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Main toggle buttons
        glassButton = makeToggleButton(title: "Enable Glass", isOn: ThemeEngine.enableGlass) { [weak self] in
            ThemeEngine.enableGlass.toggle()
            self?.updateButtonTint(self?.glassButton, isOn: ThemeEngine.enableGlass)
            if let parentVC = self?.parentViewController as? ViewController {
                parentVC.refreshView()
            }
        }
        
        animationsButton = makeToggleButton(title: "Enable Animations", isOn: ThemeEngine.enableAnimations) {
            ThemeEngine.enableAnimations.toggle()
            self.updateButtonTint(self.animationsButton, isOn: ThemeEngine.enableAnimations)
        }
        
        profileTintingButton = makeToggleButton(title: "Enable Profile Tinting", isOn: ThemeEngine.enableProfileTinting) {
            ThemeEngine.enableProfileTinting.toggle()
            self.updateButtonTint(self.profileTintingButton, isOn: ThemeEngine.enableProfileTinting)
        }
        
        resetTokenButton = makeToggleButton(title: "Reset Token", isOn: false) {
            activeClient.disconnect()
            token = nil
            UIApplication.shared.currentKeyWindow?.rootViewController = AuthenticationViewController()
        }
        
        contentStack.addArrangedSubview(glassButton)
        contentStack.addArrangedSubview(animationsButton)
        contentStack.addArrangedSubview(profileTintingButton)
        contentStack.addArrangedSubview(resetTokenButton)
    }
    
    // MARK: - Advanced Filters
    
    private func setupFilterToggles() {
        let label = UILabel()
        label.text = "Glass Options"
        label.textColor = .white
        label.backgroundColor = .clear
        label.font = UIFont.boldSystemFont(ofSize: 18)
        contentStack.addArrangedSubview(label)
        
        for filter in LiquidGlassView.AdvancedFilterOptions.allCases.filter( { $0 != .tint } ) {
            let isEnabled = !ThemeEngine.glassFilterExclusions.contains(filter)
            let button = makeToggleButton(title: "\(filter)".capitalized, isOn: isEnabled) { [weak self] in
                self?.toggleFilter(filter)
            }
            contentStack.addArrangedSubview(button)
            filterButtons[filter] = button
        }
    }
    
    private func toggleFilter(_ filter: LiquidGlassView.AdvancedFilterOptions) {
        var exclusions = ThemeEngine.glassFilterExclusions
        if let index = exclusions.firstIndex(of: filter) {
            exclusions.remove(at: index)
        } else {
            exclusions.append(filter)
        }
        ThemeEngine.glassFilterExclusions = exclusions
        updateButtonTint(filterButtons[filter], isOn: !exclusions.contains(filter))
    }
    
    // MARK: - Utility
    
    private func makeToggleButton(title: String, isOn: Bool, action: @escaping () -> Void) -> UIView {
        let glass = LiquidGlassView(blurRadius: 8, cornerRadius: 16, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.heightAnchor.constraint(equalToConstant: 50).isActive = true
        glass.tintColorForGlass = isOn ? UIColor.green.withAlphaComponent(0.3) : UIColor.red.withAlphaComponent(0.3)
        glass.shadowOpacity = 0
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        
        button.addAction(for: .touchUpInside, {
            action()
        })
        
        glass.addSubview(button)
        button.pinToEdges(of: glass)
        
        return glass
    }
    
    private func updateButtonTint(_ button: UIView?, isOn: Bool) {
        guard let glass = button as? LiquidGlassView else { return }
        glass.tintColorForGlass = isOn ? UIColor.green.withAlphaComponent(0.3) : UIColor.red.withAlphaComponent(0.3)
    }
}
