//
//  DMVC+Messages.swift
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

//MARK: REST API Message functions
extension TextViewController {
    //REST API past 50 message get function
    func getMessages() {
        var textChannel: TextChannel
        if let channel = channel {
            textChannel = channel
        } else if let dm = dm {
            textChannel = dm
        } else {
            fatalError("no channel")
        }
        
        clientUser.getChannelMessages(for: textChannel.id!) { [weak self] messages, error in
            guard let self = self else { return }
            
            self.addMessagesToStack(messages)
            
            if !self.initialViewSetupComplete {
                self.setupInputView(for: textChannel)
            }
            
            //Fade on container
            if self.containerView.alpha == 0 {
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut]) {
                    self.containerView.alpha = 1
                }
            }
        }
    }
    
    //Add messages fetched via REST API to the stack
    func addMessagesToStack(_ messages: [Message]) {
        for message in messages {
            if let messageID = message.id, let userID = message.author?.id, !messageIDsInStack.contains(messageID) {
                var messageView: MessageView
                if let channel = channel {
                    messageView = MessageView(clientUser, message: message, guildTextChannel: channel)
                    if !requestedUserIDs.contains(userID) {
                        requestedUserIDs.insert(userID)
                    }
                } else {
                    messageView = MessageView(clientUser, message: message)
                }
                self.messageStack.addArrangedSubview(messageView)
                messageIDsInStack.insert(messageID)
                scrollView.layoutIfNeeded()
                scrollToBottom(animated: true)
                if !userIDsInStack.contains(userID) { userIDsInStack.insert(userID) }
            }
        }
        guard let guildID = self.channel?.guild?.id else { return }
        clientUser.gateway?.requestGuildMemberChunk(guildId: guildID, userIds: self.requestedUserIDs)
    }
    
    func scrollToMessage(withID messageID: Snowflake) {
        guard let navBarHeight = navigationController?.navigationBar.frame.height else { return }
        let padding: CGFloat = 10

        for view in messageStack.arrangedSubviews {
            guard let messageView = view as? MessageView, messageView.message?.id == messageID else { continue }

            self.view.layoutIfNeeded()
            scrollView.layoutIfNeeded()
            messageStack.layoutIfNeeded()

            // Convert messageView frame to scrollView coordinates
            let messageFrameInScroll = messageView.convert(messageView.bounds, to: scrollView)

            // Top of scrollView visible area (below navbar)
            let visibleTop = scrollView.contentOffset.y + navBarHeight + padding

            // Only scroll if message is above the visible area
            if messageFrameInScroll.minY < visibleTop {
                let newOffsetY = messageFrameInScroll.minY - navBarHeight - padding

                // Clamp to scrollable range
                let maxOffsetY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom
                let clampedOffsetY = max(0, min(newOffsetY, maxOffsetY))

                scrollView.setContentOffset(CGPoint(x: 0, y: clampedOffsetY), animated: true)
            }
            return
        }
    }
}
