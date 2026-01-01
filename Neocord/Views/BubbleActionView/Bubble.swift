//
//  InputViewBubble.swift
//  Neocord
//
//  Created by JWI on 14/11/2025.
//
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit

enum BubbleType {
    case regular
    case context   // includes cancel button
}

class Bubble: UIView {
    public let backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let bView = LiquidGlassView(blurRadius: 6, cornerRadius: 17, disableBlur: PerformanceManager.disableBlur, filterExclusions: ThemeEngine.glassFilterExclusions)
            bView.translatesAutoresizingMaskIntoConstraints = false
            bView.solidViewColour = .discordGray.withAlphaComponent(0.8)
            bView.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            return bView
        } else {
            let bView = UIView()
            bView.layer.cornerRadius = 17
            bView.translatesAutoresizingMaskIntoConstraints = false
            bView.backgroundColor = .discordGray.withAlphaComponent(0.8)
            return bView
        }
    }()
    
    public let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.backgroundColor = .clear
        return label
    }()
    
    public var cancelButton: LargeHitAreaButton?
    
    private let type: BubbleType
    
    public init(text: String, type: BubbleType = .regular) {
        self.type = type
        super.init(frame: .zero)
        textLabel.text = text
        textLabel.numberOfLines = 1
        textLabel.lineBreakMode = .byCharWrapping
        textLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        
        addSubview(backgroundView)
        backgroundView.addSubview(textLabel)
        backgroundView.pinToEdges(of: self)
        
        let padding: CGFloat = 8
        
        if type == .context {
            // add cancel button
            let button = LargeHitAreaButton()
            button.setImage(.init(systemName: "xmark.circle.fill", tintColor: .white), for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(button)
            self.cancelButton = button
            
            NSLayoutConstraint.activate([
                // Cancel button constraints
                button.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -padding),
                button.centerYAnchor.constraint(equalTo: textLabel.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 20),
                button.heightAnchor.constraint(equalToConstant: 20),
                
                // Text label constraints with space for button
                textLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: padding),
                textLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: padding),
                textLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -padding),
                textLabel.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -6)
            ])
        } else {
            // Regular bubble, no cancel button
            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: padding),
                textLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: padding),
                textLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -padding),
                textLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -padding)
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
