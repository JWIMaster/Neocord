//
//  GlassSettingsView.swift
//  Neocord
//
//  Created by JWI on 6/11/2025.
//

import UIKit
import UIKitCompatKit
import UIKitExtensions

class SettingsView: UIView {
    
    private var backgroundView = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
    
    private var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()
    
    private var glassButton: UIView!
    private var animationsButton: UIView!
    private var profileTintingButton: UIView!
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(backgroundView)
        backgroundView.pinToEdges(of: self)
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8)
        ])
        
        // Create buttons
        glassButton = makeGlassButton(title: "Enable Glass", isOn: ThemeEngine.enableGlass) { value in
            ThemeEngine.enableGlass = value
            if let parentVC = self.parentViewController as? ViewController {
                parentVC.refreshView()
            }
        }
        animationsButton = makeGlassButton(title: "Enable Animations", isOn: ThemeEngine.enableAnimations) { value in
            ThemeEngine.enableAnimations = value
        }
        profileTintingButton = makeGlassButton(title: "Enable Profile Tinting", isOn: ThemeEngine.enableProfileTinting) { value in
            ThemeEngine.enableProfileTinting = value
        }
        
        stackView.addArrangedSubview(glassButton)
        stackView.addArrangedSubview(animationsButton)
        stackView.addArrangedSubview(profileTintingButton)
    }
    
    private func makeGlassButton(title: String, isOn: Bool, action: @escaping (Bool) -> Void) -> UIView {
        let glass = LiquidGlassView(blurRadius: 8, cornerRadius: 16, snapshotTargetView: nil, disableBlur: true)
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.heightAnchor.constraint(equalToConstant: 50).isActive = true
        glass.tintColorForGlass = isOn ? UIColor.green.withAlphaComponent(0.3) : UIColor.red.withAlphaComponent(0.3)
        
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        
        // Store state
        button.tag = isOn ? 1 : 0
        
        // Store the glass reference so we can update its color on tap
        objc_setAssociatedObject(button, &AssociatedKeys.glassView, glass, .OBJC_ASSOCIATION_ASSIGN)
        // Store action
        objc_setAssociatedObject(button, &AssociatedKeys.toggleAction, action, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        button.addTarget(self, action: #selector(glassButtonTapped(_:)), for: .touchUpInside)
        
        // Add button inside glass
        glass.addSubview(button)
        button.pinToEdges(of: glass)
        
        return glass
    }

    @objc private func glassButtonTapped(_ sender: UIButton) {
        let isOn = sender.tag == 0
        sender.tag = isOn ? 1 : 0
        
        // Update the glass color
        if let glass = objc_getAssociatedObject(sender, &AssociatedKeys.glassView) as? LiquidGlassView {
            glass.tintColorForGlass = isOn ? UIColor.green.withAlphaComponent(0.3) : UIColor.red.withAlphaComponent(0.3)
        }
        
        // Call the stored action
        if let action = objc_getAssociatedObject(sender, &AssociatedKeys.toggleAction) as? (Bool) -> Void {
            action(isOn)
        }
    }

    // MARK: - Associated Object Key
    private struct AssociatedKeys {
        static var toggleAction = "toggleAction"
        static var glassView = "glassView"
    }

}

// MARK: - Associated Object Key
private struct AssociatedKeys {
    static var toggleAction = "toggleAction"
}
