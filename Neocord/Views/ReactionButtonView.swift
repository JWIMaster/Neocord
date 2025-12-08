//
//  ReactionButtonView.swift
//  Neocord
//
//  Created by JWI on 8/12/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy

class ReactionButtonView: UIButton {
    var reaction: Reaction
    
    let backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 14, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.tintColorForGlass = .discordGray
            glass.translatesAutoresizingMaskIntoConstraints = false
            return glass
        } else {
            let bg = UIView()
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.layer.cornerRadius = 14
            return bg
        }
    }()
    
    init(reaction: Reaction) {
        self.reaction = reaction
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(backgroundView)
        backgroundView.pinToEdges(of: self)
        if let emoji = reaction.emoji, let emojiID = emoji.id, let count = self.reaction.count?.description{
            EmojiCache.shared.fetchEmoji(id: emojiID.description) { emojiImage in
                guard let emojiImage = emojiImage else {
                    return
                }
                let size = CGSize(width: UIFont.systemFont(ofSize: 17).lineHeight, height: UIFont.systemFont(ofSize: 17).lineHeight)
                let resized = emojiImage.resizeImage(emojiImage, targetSize: size)
                let textAttachment = NSTextAttachment()
                textAttachment.image = resized
                let mutableString = NSMutableAttributedString()
                mutableString.append(NSAttributedString(attachment: textAttachment))
                mutableString.append(NSAttributedString(string: count))
                //self.setImage(resized, for: .normal)
                //self.setTitle(self.reaction.count?.description ?? "0", for: .normal)
                self.setAttributedTitle(mutableString, for: .normal)
            }
        } else if let emoji = reaction.emoji?.name, let count = self.reaction.count?.description {
            self.setTitle(emoji + count, for: .normal)
        }
        
    }
}
