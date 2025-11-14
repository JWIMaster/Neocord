//
//  InputView+Bubble.swift
//  Neocord
//
//  Created by JWI on 14/11/2025.
//

import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit
import FoundationCompatKit

extension InputView {
    public func addContextBubble(with text: String) {
        self.contextBubble = Bubble(text: text, type: .context)
        self.contextBubble?.cancelButton?.addAction(for: .touchUpInside) {
            self.cancelInputAction()
        }
        self.bubbleStack.addArrangedSubview(contextBubble!)
        self.topConstraint.constant = 6
        self.layoutIfNeeded()
    }
    
    
    
    public func removeContextBubble() {
        self.bubbleStack.removeArrangedSubview(self.contextBubble!)
        if self.bubbleStack.arrangedSubviews.count == 0 {
            self.topConstraint.constant = 0
        }
        self.layoutIfNeeded()
    }
}


extension InputView {
    
    private var parentIsAtBottom: Bool {
        if let parentVC = parentViewController as? TextViewController {
            return parentVC.isAtBottom
        }
        return false
    }
    
    // MARK: - Associated keys
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
    private struct TypingInfo {
        var timer: Timer
    }
    
    private var typingTimers: [Snowflake: TypingInfo] {
        get { objc_getAssociatedObject(self, &AssociatedKeys.typingTimers) as? [Snowflake: TypingInfo] ?? [:] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.typingTimers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    
    // MARK: - Handle typing
    public func handleTyping(for user: User, _ member: GuildMember? = nil) {
        guard let userID = user.id else { return }
        
        // Resolve the display name once and store it
        let name: String
        if let member = member {
            name = member.guildNickname
                ?? user.nickname
                ?? user.displayname
                ?? user.username
                ?? "unknown"
        } else {
            name = user.nickname
                ?? user.displayname
                ?? user.username
                ?? "unknown"
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
        topConstraint.constant = 6
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
            topConstraint.constant = 0
        } else {
            let names = activeTypingUsers.values.sorted().joined(separator: ", ")
            bubble.textLabel.text = names + " is typing"
        }
        
        layoutIfNeeded()
        
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

