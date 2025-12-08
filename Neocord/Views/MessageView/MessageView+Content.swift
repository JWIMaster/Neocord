//
//  MessageView+Content.swift
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
    
    
    func setupText() {
        messageTextAndEmoji.text = "\(message?.content ?? "unknown")"
        let text: String = {
            if let relationship = clientUser.relationships[(message?.author?.id)!], relationship.0 == .blocked {
                return "User blocked"
            } else {
                return message?.content ?? "unknown"
            }
        }()
        messageTextAndEmoji.setMarkdown("\(text)")
        messageTextAndEmoji.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        messageTextAndEmoji.translatesAutoresizingMaskIntoConstraints = false
        
        messageText.translatesAutoresizingMaskIntoConstraints = false
        
        messageText.text = "\(message?.content ?? "unknown")"
        messageText.backgroundColor = .clear
        messageText.textColor = .white
        messageText.lineBreakMode = .byWordWrapping
        messageText.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        messageText.numberOfLines = 0
        //messageText.sizeToFit()
        
        MessageView.markdownQueue.async { [weak self] in
            guard let self = self else { return }
            let parsed = self.markdownParser.attributedString(fromMarkdown: "\(self.message?.content ?? "unknown")")
            
            DispatchQueue.main.async {
                self.messageText.attributedText = parsed
                self.messageText.sizeToFit()
                
                // Give Auto Layout a short delay to settle before scrolling
                guard let parentVC = self.parentViewController else { return }
                if let dmVC = parentVC as? TextViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        dmVC.scrollToBottom(animated: true)
                    }
                }
                
            }
        }
    }
    
    func setupReply() {
        guard let replyMessage = message?.replyMessage, let slClient = self.slClient else { return }
        self.replyView = ReplyMessageView(slClient, reply: replyMessage)
        self.replyView?.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupEdited() {
        edited.text = {
            guard let message = message else {
                return ""
            }
            
            if message.edited {
                return "(edited)"
            } else {
                return ""
            }
        }()
        edited.font = .systemFont(ofSize: 10)
        edited.textColor = .gray
        edited.backgroundColor = .clear
        edited.translatesAutoresizingMaskIntoConstraints = false
        edited.sizeToFit()
    }
    
    func setupSelfPing() {
        clientUserPinged = self.message?.mentions.contains { mention in
            mention.id == clientUser.clientUser?.id
        } ?? false

        if clientUserPinged {
            pingHighlightView.backgroundColor = .orange.withAlphaComponent(0.3)
            
            UIView.animate(withDuration: 2.5) { [weak self] in
                guard let self = self else { return }
                self.pingHighlightView.backgroundColor = .orange.withAlphaComponent(0.1)
            }
            
            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                UIView.animate(withDuration: 2.5) {
                    self.pingHighlightView.backgroundColor = .orange.withAlphaComponent(0.3)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    UIView.animate(withDuration: 2.5) {
                        self.pingHighlightView.backgroundColor = .orange.withAlphaComponent(0.1)
                    }
                }
            }
        }
    }
    
    
    func setupTimestamp() {
        guard let messageTimestamp = message?.timestamp else { return }
        let calendar = Self.calendar
        
        // Cache these once per function call
        let isToday = calendar.isDateInToday(messageTimestamp)
        let isYesterday = calendar.isDateInYesterday(messageTimestamp)
        
        let formatter: DateFormatter
        if isToday || isYesterday {
            formatter = Self.timestampFormatter
        } else {
            formatter = Self.dateFormatter
        }
        
        let formattedTime = formatter.string(from: messageTimestamp)
        timestamp.text = isYesterday ? "Yesterday at \(formattedTime)" : formattedTime
        
        timestamp.font = .systemFont(ofSize: 12)
        timestamp.textColor = .white
        timestamp.backgroundColor = .clear
        timestamp.translatesAutoresizingMaskIntoConstraints = false
        timestamp.sizeToFit()
    }
    
    func setupReactions() {
        guard let reactions = message?.reactions, !reactions.isEmpty else { return }
        for reaction in reactions {
            let reactionView = ReactionButtonView(reaction: reaction)
            reactionView.translatesAutoresizingMaskIntoConstraints = false
            reactionStack.addArrangedSubview(reactionView)
        }
    }
}
