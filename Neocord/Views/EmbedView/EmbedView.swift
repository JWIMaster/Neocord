//
//  EmbedView.swift
//  Neocord
//
//  Created by JWI on 23/11/2025.
//

import Foundation
import UIKit
import UIKitExtensions
import UIKitCompatKit
import SwiftcordLegacy

class EmbedView: UIView {
    
    var embed: Embed
    
    private let backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(
                blurRadius: 0,
                cornerRadius: 22,
                disableBlur: true,
                filterExclusions: ThemeEngine.glassFilterExclusions
            )
            glass.translatesAutoresizingMaskIntoConstraints = false
            return glass
        } else {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 22
            return view
        }
    }()
    
    private let stack = UIStackView()
    private let titleLabel = DiscordMarkdownView()
    private let descriptionLabel = DiscordMarkdownView()
    
    
    init(embed: Embed) {
        self.embed = embed
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        setupSubviews()
        setupConstraints()
        configureFromEmbed()
    }
    
    private func setupSubviews() {
        addSubview(backgroundView)
        
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.textSize = 16
        titleLabel.textColor = .white
        titleLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 120
        titleLabel.numberOfLines = 0
        
        descriptionLabel.textSize = 14
        descriptionLabel.textColor = .white
        descriptionLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 120
        descriptionLabel.numberOfLines = 0
        
        backgroundView.addSubview(stack)
    }
    
    private func setupConstraints() {
        backgroundView.pinToEdges(of: self)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -12)
        ])
    }
    
    private func configureFromEmbed() {
        
        if let title = embed.title, title.isEmpty == false {
            titleLabel.setMarkdown("## \(title)")
            stack.addArrangedSubview(titleLabel)
        }
        
        if let description = embed.description, description.isEmpty == false {
            descriptionLabel.setMarkdown(description)
            stack.addArrangedSubview(descriptionLabel)
        }
        
        if let fields = embed.fields, fields.isEmpty == false {
            for field in fields {
                let fieldView = createFieldView(field)
                stack.addArrangedSubview(fieldView)
            }
        }
    }
    
    private func createFieldView(_ field: EmbedField) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        
        if let name = field.name, name.isEmpty == false {
            let nameLabel = DiscordMarkdownView()
            nameLabel.textSize = 14
            nameLabel.textColor = .white
            nameLabel.numberOfLines = 0
            nameLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 120
            nameLabel.setMarkdown("### \(name)")
            container.addArrangedSubview(nameLabel)
        }
        
        if let value = field.value, value.isEmpty == false {
            let valueLabel = DiscordMarkdownView()
            valueLabel.textSize = 14
            valueLabel.textColor = .white
            valueLabel.numberOfLines = 0
            valueLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 120
            valueLabel.setMarkdown(value)
            container.addArrangedSubview(valueLabel)
        }
        
        return container
    }
}
