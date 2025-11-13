//
//  MessageActionView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 28/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import SFSymbolsCompatKit

class MessageActionView: UIView {
    let cancelButton: LiquidGlassView = {
        MessageActionView.makeActionButton(text: "Cancel", color: nil, image: UIImage(systemName: "xmark.circle.fill", tintColor: .white)!)
    }()
    
    let editButton: LiquidGlassView = {
        MessageActionView.makeActionButton(text: "Edit", color: nil, image: UIImage(systemName: "square.and.pencil", tintColor: .white)!)
    }()
    
    let replyButton: LiquidGlassView = {
        MessageActionView.makeActionButton(text: "Reply", color: nil, image: UIImage(systemName: "arrowshape.turn.up.right.circle", tintColor: .white)!)
    }()
    
    let deleteButton: LiquidGlassView = {
        MessageActionView.makeActionButton(text: "Delete", color: UIColor(red: 232/255, green: 35/255, blue: 35/255, alpha: 0.4), image: UIImage(systemName: "trash.fill", tintColor: .white)!)
    }()
    
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    let glassView = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
    var slClient: SLClient?
    var message: Message?
    var channel: TextChannel?
    var isInDM: Bool?
    
    public init(_ slClient: SLClient, _ message: Message, _ channel: TextChannel) {
        self.slClient = slClient
        self.message = message
        
        self.channel = channel
        
        self.isInDM = {
            return (channel.type == .dm || channel.type == .groupDM)
        }()
        
        super.init(frame: .zero)
        
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        setupSubviews()
        setupConstraints()
    }
    
    static func makeActionButton(text: String, color: UIColor?, image: UIImage) -> LiquidGlassView {
        let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        glass.translatesAutoresizingMaskIntoConstraints = false
        if let color = color {
            glass.tintColorForGlass = color
        }
        let button = LargeHitAreaButton(hitAreaInset: .init(top: -6, left: -30, bottom: -6, right: -30))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(text, for: .normal)
        button.setImage(image, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        button.sizeToFit()
        glass.addSubview(button)
        glass.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: glass.leadingAnchor, constant: 30),
            button.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -30),
            button.topAnchor.constraint(equalTo: glass.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: glass.bottomAnchor, constant: -6)
        ])
        return glass
    }
    
    func setupButtons() {
        let replyButton = replyButton.subviews.compactMap({ $0 as? UIButton }).first
        let deleteButton = deleteButton.subviews.compactMap({ $0 as? UIButton }).first
        let editButton = editButton.subviews.compactMap({ $0 as? UIButton }).first
        let cancelButton = cancelButton.subviews.compactMap({ $0 as? UIButton }).first
        
        guard let replyButton = replyButton, let deleteButton = deleteButton, let editButton = editButton, let cancelButton = cancelButton else { return }
        
        
        
        replyButton.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self, let message = self.message else { return }
            
            if let dmVC = self.parentViewController as? TextViewController {
                dmVC.textInputView?.replyToMessage(message)
                dmVC.endMessageAction()
            }
        }

        editButton.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self, let message = self.message else { return }
            
            if let dmVC = self.parentViewController as? TextViewController {
                dmVC.textInputView?.editMessage(message)
                dmVC.endMessageAction()
            }
        }

        deleteButton.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self, let message = self.message, let channel = self.channel, let slClient = self.slClient else { return }
            
            if let dmVC = self.parentViewController as? TextViewController {
                slClient.delete(message: message, in: channel) { error in
                    // handle error if needed
                }
                dmVC.endMessageAction()
            }
        }

        cancelButton.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self else { return }
            
            if let dmVC = self.parentViewController as? TextViewController {
                dmVC.endMessageAction()
            }
        }
    }
    
    func setupSubviews() {
        guard let slClient = slClient else {
            return
        }
        
        if message?.author == slClient.clientUser {
            stackView.addArrangedSubview(replyButton)
            stackView.addArrangedSubview(editButton)
            stackView.addArrangedSubview(deleteButton)
            stackView.addArrangedSubview(cancelButton)
        } else {
            stackView.addArrangedSubview(replyButton)
            stackView.addArrangedSubview(cancelButton)
        }

        stackView.sizeToFit()
        addSubview(glassView)
        glassView.addSubview(stackView)
    }
    
    
    func setupConstraints() {
        stackView.pinToCenter(of: glassView)
        stackView.pinToEdges(of: glassView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        glassView.pinToCenter(of: self)
        glassView.pinToEdges(of: self)
        
        let buttonViews = stackView.arrangedSubviews.compactMap({ $0 as? LiquidGlassView })
        for buttonView in buttonViews {
            buttonView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }
    }
    
    public override func didMoveToSuperview() {
        setupButtons()
    }
}
