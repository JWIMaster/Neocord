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
            if let relationship = activeClient.relationships[(message?.author?.id)!], relationship.0 == .blocked {
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
                if let dmVC = parentVC as? TextViewController, self.scrollToBottom {
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
    
    func setupCall() {
        guard let call = self.message?.call, let participants = call.participants else { return }
        if let dm = self.dmChannel as? DM, let clientUser = activeClient.clientUser, let recipient = dm.recipient {
            let content = "\(clientUser.username ?? "unknown") and \(recipient.username ?? "unknown") were in a call"
            self.messageTextAndEmoji.setMarkdown(content)
        } else if let groupDM = self.dmChannel as? GroupDM {
            guard let recipients = groupDM.recipients else { return }
            let recipientDict = Dictionary(
                uniqueKeysWithValues: recipients.compactMap { recipient in
                    recipient.id.map { ($0, recipient) }
                }
            )
            
            let finalParticipants: [User] = participants.compactMap {
                recipientDict[$0]
            }
            
            var usernames = finalParticipants.compactMap { $0.username }
            if participants.contains(activeClient.clientUser!.id!) {
                usernames.append(activeClient.clientUser!.username ?? "unknown")
            }
            
            var contentString: String = ""
            switch usernames.count {
            case 0:
                contentString = ""
            case 1:
                contentString = usernames[0] + " was in a call"
            case 2:
                contentString = "\(usernames[0]) and \(usernames[1])"
            default:
                let allButLast = usernames.dropLast().joined(separator: ", ")
                contentString = "\(allButLast), and \(usernames.last!)"
            }
            
            messageTextAndEmoji.setMarkdown(contentString)
        }
    }
}
