//
//  File.swift
//  Cascade
//
//  Created by JWI on 2/11/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit

extension MessageView {
    func setupAuthorName() {
        authorName.text = message?.author?.nickname ?? message?.author?.displayname ?? message?.author?.username
        authorName.font = .boldSystemFont(ofSize: 14)
        authorName.textColor = .white
        authorName.backgroundColor = .clear
        authorName.preferredMaxLayoutWidth = messageContent.bounds.width - timestamp.bounds.width
        authorName.numberOfLines = 1
        authorName.lineBreakMode = .byTruncatingTail
        authorName.textAlignment = .left
        authorName.translatesAutoresizingMaskIntoConstraints = false
        authorName.sizeToFit()
    }
    
    func setupAuthorAvatar() {
        guard let author = message?.author else { return }
        
        authorAvatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        authorAvatar.translatesAutoresizingMaskIntoConstraints = false
        
        AvatarCache.shared.avatar(for: author) { [weak self] image, color in
            guard let self = self, let image = image, let color = color else { return }
            
            MessageView.avatarQueue.async {
                let resized = image.resizeImage(image, targetSize: CGSize(width: 30, height: 30))
                
                DispatchQueue.main.async {
                    self.authorAvatar.image = resized
                    self.authorAvatar.contentMode = .scaleAspectFit
                    self.authorAvatar.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 30, height: 30), cornerRadius: 15).cgPath
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
