//
//  WebsocketFunctions.swift
//  Cascade
//
//  Created by JWI on 31/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost


//MARK: Gateway functions
extension TextViewController {
    ///Attach websocket watchers to do realtime message events
    func attachGatewayObservers() {
        guard let gateway = clientUser.gateway else { return }
        // Assign closures
        
        /*gateway.onMessageCreate = { [weak self] message in
            self?.createMessage(message)
        }

        gateway.onMessageUpdate = { [weak self] message in
            self?.updateMessage(message)
        }
        gateway.onMessageDelete = { [weak self] message in
            self?.deleteMessage(message)
        }
        
        gateway.onTypingStart = { [weak self] channelID, userID in
            self?.typingStarted(by: userID, in: channelID)
        }*/
        
        messageCreateObserver = NotificationCenter.default.addObserver(forName: .messageCreate, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if let message = notification.object as? Message {
                self.createMessage(message)
            }
        }
        
        messageDeleteObserver = NotificationCenter.default.addObserver(forName: .messageDelete, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if let message = notification.object as? Message {
                self.deleteMessage(message)
            }
        }
        
        messageUpdateObserver = NotificationCenter.default.addObserver(forName: .messageUpdate, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if let message = notification.object as? Message {
                self.updateMessage(message)
            }
        }
        
        typingStartObserver = NotificationCenter.default.addObserver(forName: .typingStart, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if let typingInfo = notification.object as? (Snowflake, Snowflake) {
                self.typingStarted(by: typingInfo.1, in: typingInfo.0)
            }
        }
    }
    
    
    //Websocket create message function
    func createMessage(_ message: Message) {
        guard let messageID = message.id, let userID = message.author?.id, !messageIDsInStack.contains(messageID) else { return }
        self.messageIDsInStack.insert(messageID)
        let isDMMessage = (self.dm?.id == message.channelID)
        let isGuildMessage = (self.channel?.id == message.channelID)
        
        guard isDMMessage || isGuildMessage else { return }
        clientUser.acknowledge(messageID: messageID, in: message.channelID!, completion: { _ in })
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let user = message.author else { return }
            if let bubbleActionView = self.bubbleActionView, bubbleActionView.activeTypingUsers.keys.contains(user.id!) {
                bubbleActionView.removeTyping(for: user.id!)
            }
            var isSameUser: Bool
            self.secondLastUserToSpeak = self.lastUserToSpeak
            self.lastUserToSpeak = user
            isSameUser = (self.lastUserToSpeak == self.secondLastUserToSpeak)
            if isGuildMessage, let channel = self.channel {
                let messageView = MessageView(clientUser, message: message, guildTextChannel: channel, isSameUser: isSameUser)
                self.messageStack.addArrangedSubview(messageView)
                self.requestMemberIfNeeded(userID)
            } else {
                let messageView = MessageView(clientUser, message: message, isSameUser: isSameUser, dmChannel: self.dm)
                self.messageStack.addArrangedSubview(messageView)
            }
            
            // Track message and user IDs
            if !self.userIDsInStack.contains(userID) {
                self.userIDsInStack.insert(userID)
            }
            
            self.scrollView.layoutIfNeeded()
            // Optionally scroll to bottom
            // self.scrollToBottom(animated: true)
        }
    }

    
    func deleteMessage(_ message: Message) {
        for view in messageStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        messageView.alpha = 0
                        messageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                        
                        self.view.layoutIfNeeded()
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                            self.messageStack.removeArrangedSubview(messageView)
                            self.view.layoutIfNeeded()
                        }, completion: nil)
                    })
                }
            }
        }
    }
    
    func updateMessage(_ message: Message) {
        for view in messageStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        messageView.updateMessage(message)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
    
    func typingStarted(by userID: Snowflake, in channelID: Snowflake) {
        if let dm = self.dm as? DM, dm.id! == channelID {
            if userID == clientUser.clientUser?.id! {
                self.bubbleActionView?.handleTyping(for: clientUser.clientUser!)
            } else if userID == dm.recipient?.id! {
                self.bubbleActionView?.handleTyping(for: dm.recipient!)
            }
        } else if let groupDM = self.dm as? GroupDM, groupDM.id! == channelID {
            
        } else if let channel = self.channel, channel.id! == channelID {
            if let channelMembers = clientUser.guilds[channel.guild!.id!]?.members {
                let channelUserDict: [Snowflake: User] = Dictionary(
                    uniqueKeysWithValues: channelMembers.compactMap { (key: Snowflake, member: GuildMember) -> (Snowflake, User)? in
                        guard let id = member.user.id else { return nil }
                        return (id, member.user)
                    }
                )
                
                if let typingUser = channelUserDict[userID] {
                    if let typingMember = channelMembers[userID] {
                        self.bubbleActionView?.handleTyping(for: typingUser, typingMember)
                    }
                } else {
                    print("no user")
                }
            } else {
                print("no members")
            }

        }
    }
}
