//
//  MessageView+MessageInfo.swift
//  Neocord
//
//  Created by J_W_I_ on 18/12/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit

extension MessageView {
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
            let reactionView = ReactionButtonView(reaction: reaction, channelID: (self.message?.channelID)!, messageID: (self.message?.id)!)
            reactionView.translatesAutoresizingMaskIntoConstraints = false
            reactionStack.addArrangedSubview(reactionView)
        }
        
        messageReactionAddObserver = NotificationCenter.default.addObserver(forName: .messageReactionAdd, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            guard let reaction = notification.object as? Reaction, reaction.messageID == self.message?.id else { return }
            
            for reactionView in self.reactionStack.arrangedSubviews {
                guard let buttonView = reactionView as? ReactionButtonView else { continue }
                if buttonView.reaction.emoji == reaction.emoji {
                    buttonView.reaction.count! += 1
                    buttonView.updateReaction()
                    return
                }
            }
            
            let reactionView = ReactionButtonView(reaction: reaction, channelID: (self.message?.channelID)!, messageID: (self.message?.id)!)
            reactionView.translatesAutoresizingMaskIntoConstraints = false
            self.reactionStack.addArrangedSubview(reactionView)
        }
        
        messageReactionRemoveObserver = NotificationCenter.default.addObserver(forName: .messageReactionRemove, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            guard let reaction = notification.object as? Reaction, reaction.messageID == self.message?.id else { return }
            
            for reactionView in self.reactionStack.arrangedSubviews {
                guard let buttonView = reactionView as? ReactionButtonView else { continue }
                if buttonView.reaction.emoji == reaction.emoji {
                    buttonView.reaction.count! -= 1
                    if reaction.me! {
                        buttonView.isOwnReaction = false
                    }
                    buttonView.updateReaction()
                    if buttonView.reaction.count == 0 {
                        self.message?.reactions.removeAll { $0.emoji == reaction.emoji }
                        UIView.animate(withDuration: 0.5) {
                            self.reactionStack.removeArrangedSubview(buttonView)
                            buttonView.removeFromSuperview()
                        }
                    }
                    return
                }
            }
            
            let reactionView = ReactionButtonView(reaction: reaction, channelID: (self.message?.channelID)!, messageID: (self.message?.id)!)
            reactionView.translatesAutoresizingMaskIntoConstraints = false
            self.reactionStack.addArrangedSubview(reactionView)
        }
    }
}
