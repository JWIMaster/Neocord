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
        messageTextAndEmoji.setMarkdown("\(message?.content ?? "unknown")")
        messageTextAndEmoji.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        
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
}
