//
//  ReplyView.swift
//  Cascade
//
//  Created by JWI on 29/10/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit

public class ReplyMessageView: UIView, UIGestureRecognizerDelegate {
    let messageBackground: UIView? = {
        if ThemeEngine.enableGlass {
            switch device {
            case .a4:
                let bg = UIView()
                bg.layer.cornerRadius = 14
                return bg
            default:
                return LiquidGlassView(blurRadius: 0, cornerRadius: 14, snapshotTargetView: nil, disableBlur: true)
            }
        } else {
            let bg = UIView()
            bg.layer.cornerRadius = 14
            return bg
        }
    }()
    
    let replyContent: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    var reply: ReplyMessage?
    
    var messageText = UILabel()
    var authorAvatar: UIImageView = UIImageView()
    let authorName = UILabel()
    let slClient: SLClient?
    
    public init(_ slClient: SLClient, reply: ReplyMessage) {
        self.slClient = slClient
        self.reply = reply
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        setupText()
        setupAuthorAvatar()
        setupAuthorName()
        setupSubviews()
        setupConstraints()
        addTapGesture()
    }
    
    private func setupSubviews() {
        guard let messageBackground = messageBackground else { return }
        replyContent.addArrangedSubview(authorAvatar)
        replyContent.addArrangedSubview(authorName)
        replyContent.addArrangedSubview(messageText)
        replyContent.addArrangedSubview(UIView())
        messageBackground.addSubview(replyContent)
        addSubview(messageBackground)
        
        
    }
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(replyTapped))
        tapGesture.cancelsTouchesInView = false
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func replyTapped() {
        guard let replyMessageID = reply?.id else { return }
        
        if let dmVC = self.parentViewController as? TextViewController {
            dmVC.scrollToMessage(withID: replyMessageID)
        }
        
        
    }

    // Allow taps to work alongside long press gestures
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // Ensure tap takes precedence over long press
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer,
           otherGestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        return false
    }

    
    private func setupText() {
        messageText.text = reply?.content
        messageText.backgroundColor = .clear
        messageText.textColor = .white
        messageText.font = .systemFont(ofSize: 12)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        messageText.sizeToFit()
    }
    
    private func setupAuthorName() {
        authorName.text = reply?.author?.nickname ?? reply?.author?.displayname ?? reply?.author?.username
        authorName.font = .boldSystemFont(ofSize: 12)
        authorName.textColor = .white
        authorName.backgroundColor = .clear
        authorName.translatesAutoresizingMaskIntoConstraints = false
        authorName.sizeToFit()
    }
    
    private func setupConstraints() {
        guard let messageBackground = messageBackground else { return }

        authorAvatar.widthAnchor.constraint(equalToConstant: 20).isActive = true
        authorAvatar.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        NSLayoutConstraint.activate([
            messageBackground.topAnchor.constraint(equalTo: self.topAnchor),
            messageBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            messageBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            messageBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            
            replyContent.topAnchor.constraint(equalTo: messageBackground.topAnchor, constant: 4),
            replyContent.leadingAnchor.constraint(equalTo: messageBackground.leadingAnchor, constant: 4),
            replyContent.trailingAnchor.constraint(equalTo: messageBackground.trailingAnchor, constant: -4),
            replyContent.bottomAnchor.constraint(equalTo: messageBackground.bottomAnchor, constant: -4),
        ])
    }
    
    private func setupAuthorAvatar() {
        guard let author = reply?.author else { return }
        
        authorAvatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        authorAvatar.translatesAutoresizingMaskIntoConstraints = false
        
        AvatarCache.shared.avatar(for: author) { [weak self] image, color in
            guard let self = self, let image = image, let color = color else { return }
            
            MessageView.avatarQueue.async {
                let resized = image.resizeImage(image, targetSize: CGSize(width: 20, height: 20))
                
                DispatchQueue.main.async {
                    self.authorAvatar.image = resized
                    self.authorAvatar.contentMode = .scaleAspectFit
                    self.authorAvatar.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 20, height: 20), cornerRadius: 10).cgPath
                    self.authorAvatar.layer.shadowRadius = 6
                    self.authorAvatar.layer.shadowOpacity = 0.5
                    self.authorAvatar.layer.shadowColor = UIColor.black.cgColor
                    self.authorAvatar.layer.shouldRasterize = true
                    self.authorAvatar.layer.rasterizationScale = UIScreen.main.scale
                    
                    if ThemeEngine.enableProfileTinting {
                        if let messageBackground = self.messageBackground as? LiquidGlassView {
                            messageBackground.tintColorForGlass = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(0.4)
                            messageBackground.shadowColor = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(1).cgColor
                            messageBackground.shadowOpacity = 0.6
                            messageBackground.setNeedsLayout()
                        } else {
                            self.messageBackground?.backgroundColor = color.withIncreasedSaturation(factor: 1.4)
                            self.messageBackground?.setNeedsLayout()
                        }
                    }
                }
            }
        }
    }
}
