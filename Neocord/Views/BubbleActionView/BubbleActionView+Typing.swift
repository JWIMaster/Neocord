//
//  BubbleActionView+Typing.swift
//  Neocord
//
//  Created by JWI on 23/11/2025.
//

import Foundation
import UIKit
import UIKitExtensions
import UIKitCompatKit
import SwiftcordLegacy
import FoundationCompatKit

extension BubbleActionView {
    private var parentIsAtBottom: Bool {
        if let parentVC = parentViewController as? TextViewController {
            return parentVC.isAtBottom
        }
        return false
    }
    
    private struct AssociatedKeys {
        static var activeTypingUsers = "activeTypingUsers"
        static var typingTimers = "typingTimers"
    }
    
    // MARK: - Active typing users
    // Store userID -> finalResolvedName
    var activeTypingUsers: [Snowflake: String] {
        get { objc_getAssociatedObject(self, &AssociatedKeys.activeTypingUsers) as? [Snowflake: String] ?? [:] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.activeTypingUsers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Timers per user
    internal struct TypingInfo {
        var timer: Timer
    }
    
    internal var typingTimers: [Snowflake: TypingInfo] {
        get { objc_getAssociatedObject(self, &AssociatedKeys.typingTimers) as? [Snowflake: TypingInfo] ?? [:] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.typingTimers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    public func addContextBubble(with text: String) {
        self.contextBubble = Bubble(text: text, type: .context)
        self.contextBubble?.cancelButton?.addAction(for: .touchUpInside) {
            self.cancelAction()
        }
        self.bubbleStack.addArrangedSubview(contextBubble!)
        self.layoutIfNeeded()
    }
    
    public func cancelAction() {
        self.removeContextBubble()
        if let parentVC = parentViewController as? TextViewController {
            parentVC.textInputView?.cancelInputAction()
            parentVC.updateInputOffset()
        }
    }
    
    
    
    public func removeContextBubble() {
        guard let contextBubble = self.contextBubble else { return }
        self.bubbleStack.removeArrangedSubview(contextBubble)
        self.layoutIfNeeded()
    }
    
    
    // MARK: - Handle typing
    public func handleTyping(for user: User, _ member: GuildMember? = nil) {
        guard let userID = user.id else { return }
        
        // Resolve the display name once and store it
        let name: String
        if let member = member {
            name = member.guildNickname ?? user.nickname ?? user.displayname ?? user.username ?? "unknown"
        } else {
            name = user.nickname ?? user.displayname ?? user.username ?? "unknown"
        }
        
        // Store name directly
        activeTypingUsers[userID] = name
        
        // Add bubble if needed
        if typingBubble == nil {
            addTypingBubble(for: name)
        } else {
            updateTypingBubbleText()
        }
        
        // Reset timer
        resetTypingTimer(for: userID)
    }
    
    
    // MARK: - Add typing bubble
    private func addTypingBubble(for name: String) {
        let wasParentAtBottom = parentIsAtBottom
        typingBubble = Bubble(text: "\(name) is typing", type: .regular)
        bubbleStack.addArrangedSubview(typingBubble!)
        layoutIfNeeded()
        
        if let parentVC = parentViewController as? TextViewController {
            parentVC.updateInputOffset()
            if wasParentAtBottom {
                parentVC.scrollToBottom(animated: true)
            }
        }
    }
    
    
    // MARK: - Update typing bubble text
    private func updateTypingBubbleText() {
        guard let bubble = typingBubble else { return }
        let wasParentAtBottom = parentIsAtBottom
        
        if activeTypingUsers.isEmpty {
            bubbleStack.removeArrangedSubview(bubble)
            bubble.removeFromSuperview()
            typingBubble = nil
        } else {
            let names = activeTypingUsers.values.sorted().joined(separator: ", ")
            if activeTypingUsers.count > 1 {
                let allButLast = activeTypingUsers.values.sorted().dropLast().joined(separator: ", ")
                let last = activeTypingUsers.values.sorted().last!
                bubble.textLabel.text = "\(allButLast) and \(last) are typing"
            } else {
                bubble.textLabel.text = names + " is typing"
            }
        }
        
        layoutIfNeeded()
        
        if bubble.textLabel.isTextTruncated {
            bubble.textLabel.text = "Several people are typing"
        }
        
        if let parentVC = parentViewController as? TextViewController {
            parentVC.updateInputOffset()
            if wasParentAtBottom {
                parentVC.scrollToBottom(animated: true)
            }
        }
    }
    
    
    // MARK: - Reset typing timer
    private func resetTypingTimer(for userID: Snowflake) {
        typingTimers[userID]?.timer.invalidate()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.removeTyping(for: userID)
        }
        
        typingTimers[userID] = TypingInfo(timer: timer)
    }
    
    
    // MARK: - Remove typing
    func removeTyping(for userID: Snowflake) {
        typingTimers[userID]?.timer.invalidate()
        typingTimers.removeValue(forKey: userID)
        
        activeTypingUsers.removeValue(forKey: userID)
        updateTypingBubbleText()
    }
}

import DeprecatedAPIKit

extension UILabel {
    var isTextTruncated: Bool {
        let size = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let expectedSize = self.size(with: self.font, constrainedTo: size, lineBreakMode: self.lineBreakMode)
        return expectedSize.height > self.bounds.height
    }
}
