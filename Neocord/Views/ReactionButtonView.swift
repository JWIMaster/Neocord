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
    var channelID: Snowflake
    var messageID: Snowflake
    private var _isOwnReactionTemp: Bool?

    var isOwnReaction: Bool {
        get {
            // If a temp value was set, use it; otherwise use reaction.me
            if let temp = _isOwnReactionTemp {
                return temp
            }
            return self.reaction.me ?? false
        }
        set {
            _isOwnReactionTemp = newValue
        }
    }


    
    let backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(
                blurRadius: 0,
                cornerRadius: 14,
                snapshotTargetView: nil,
                disableBlur: true,
                filterExclusions: ThemeEngine.glassFilterExclusions
            )
            glass.tintColorForGlass = UIColor.discordGray
            glass.translatesAutoresizingMaskIntoConstraints = false
            return glass
        } else {
            let bg = UIView()
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.layer.cornerRadius = 14
            return bg
        }
    }()

    init(reaction: Reaction, channelID: Snowflake, messageID: Snowflake) {
        self.reaction = reaction
        self.channelID = channelID
        self.messageID = messageID
        super.init(frame: .zero)

        self.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        self.contentHorizontalAlignment = .left
        self.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self else { return }
            if !self.isOwnReaction {
                clientUser.create(reaction: self.reaction, in: self.channelID, on: self.messageID, completion: { _ in })
                self.isOwnReaction = true
            } else {
                print("hi")
            }
        }
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        addSubview(backgroundView)
        backgroundView.isUserInteractionEnabled = false
        backgroundView.pinToEdges(of: self, insetBy: .init(top: 4, left: 4, bottom: 4, right: 4))
        sendSubviewToBack(backgroundView)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        self.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true

        self.titleLabel?.font = .systemFont(ofSize: 12)
        self.setTitleColor(.white, for: .normal)

        if let emojiName = reaction.emoji?.name, reaction.emoji?.id == nil {
            // No image: just show text
            self.setImage(nil, for: .normal)
            self.setTitle("\(emojiName)\(reaction.count ?? 0)", for: .normal)
            self.imageEdgeInsets = .zero
            self.titleEdgeInsets = .zero
            return
        }

        if let emoji = reaction.emoji, let emojiID = emoji.id {
            self.setTitle("\(reaction.count ?? 0)", for: .normal)

            EmojiCache.shared.fetchEmoji(id: emojiID.description) { [weak self] emojiImage in
                guard let self = self else { return }
                guard let emojiImage = emojiImage else {
                    print("ReactionButtonView: failed to load emoji image for id", emojiID.description)
                    return
                }

                DispatchQueue.main.async {
                    // Match emoji height to text
                    let textHeight = self.titleLabel?.font.lineHeight ?? 12
                    let resized = emojiImage.resizeImage(emojiImage, targetSize: CGSize(width: textHeight, height: textHeight))

                    self.setImage(resized, for: .normal)
                    self.imageView?.contentMode = .scaleAspectFit

                    // Adjust spacing
                    self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
                    self.titleEdgeInsets = .zero

                    self.sendSubviewToBack(self.backgroundView)

                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                }
            }
        } else {
            // fallback: no emoji
            self.setTitle("\(reaction.count ?? 0)", for: .normal)
            self.setImage(nil, for: .normal)
            self.imageEdgeInsets = .zero
            self.titleEdgeInsets = .zero
        }
    }
}

class OffsetAttachment: NSTextAttachment {
    var yOffset: CGFloat = 0
    var customSize: CGSize?

    override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
        let size = customSize ?? image?.size ?? .zero
        return CGRect(x: 0, y: yOffset, width: size.width, height: size.height)
    }
}


