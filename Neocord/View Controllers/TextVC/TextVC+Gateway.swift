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
        gateway.onMessageCreate = { [weak self] message in
            self?.createMessage(message)
        }
        gateway.onMessageUpdate = { [weak self] message in
            self?.updateMessage(message)
        }
        gateway.onMessageDelete = { [weak self] message in
            self?.deleteMessage(message)
        }
    }
    
    
    //Websocket create message function
    func createMessage(_ message: Message) {
        guard let messageID = message.id, let userID = message.author?.id, !messageIDsInStack.contains(messageID) else { return }
        

        let isDMMessage = (self.dm?.id == message.channelID)
        let isGuildMessage = (self.channel?.id == message.channelID)
        
        guard isDMMessage || isGuildMessage else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if isGuildMessage, let channel = self.channel {
                // Guild channel: include guild context
                let messageView = MessageView(clientUser, message: message, guildTextChannel: channel)
                self.messageStack.addArrangedSubview(messageView)
                self.requestMemberIfNeeded(userID)
            } else {
                // DM channel
                let messageView = MessageView(clientUser, message: message)
                self.messageStack.addArrangedSubview(messageView)
            }
            
            // Track message and user IDs
            self.messageIDsInStack.insert(messageID)
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
}
