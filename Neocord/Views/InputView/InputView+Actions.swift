//
//  InputView+Actions.swift
//  Neocord
//
//  Created by JWI on 14/11/2025.
//

import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit


extension InputView {
    public func cancelInputAction() {
        self.changeInputMode(to: .send)
        self.textView.text = nil
        self.textViewDidChange(self.textView)
        self.removeContextBubble()
        if let parentVC = parentViewController as? TextViewController {
            parentVC.updateInputOffset()
        }
    }
    
    public func editMessage(_ message: Message) {
        self.changeInputMode(to: .edit)
        self.editMessage = message
        self.textView.text = self.editMessage?.content
        self.textViewDidChange(self.textView)
        self.removeContextBubble()
        self.addContextBubble(with: "Editing")
        if let parentVC = parentViewController as? TextViewController {
            parentVC.updateInputOffset()
            parentVC.scrollToBottom(animated: true)
        }
    }
    
    public func replyToMessage(_ message: Message) {
        self.changeInputMode(to: .reply)
        self.replyMessage = message
        self.removeContextBubble()
        self.addContextBubble(with: "Replying to \(message.author?.displayname ?? message.author?.username ?? "unknown")")
        if let parentVC = parentViewController as? TextViewController {
            parentVC.updateInputOffset()
            parentVC.scrollToBottom(animated: true)
        }
    }
    
    public func changeInputMode(to mode: inputMode) {
        switch mode {
        case .reply:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [unowned self] in
                self.replyMessageAction()
            }
        case .edit:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [unowned self] in
                self.editMessageAction()
            }
        case .send:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [unowned self] in
                self.sendMessageAction()
            }
        }
    }
    
    func replyMessageAction() {
        guard buttonIsActive == true else { return }
        self.buttonIsActive = false
        
        guard let channel = self.channel, let replyMessage = self.replyMessage, var currentText = self.textView.text else { return }
        currentText = self.formatDiscordCommands(in: currentText)
        let newMessage = Message(clientUser, ["content": currentText])
        
        self.textView.text = nil
        self.editMessage = nil
        self.changeInputMode(to: .send)
        self.textViewDidChange(self.textView)
        self.buttonIsActive = true
        
        clientUser.reply(to: replyMessage, with: newMessage, in: channel) { [weak self] error in
            guard let self = self else { return }
            self.removeContextBubble()
            if let parentVC = self.parentViewController as? TextViewController {
                parentVC.updateInputOffset()
            }
        }
    }
    
    func sendMessageAction() {
        guard buttonIsActive == true else { return }
        self.buttonIsActive = false
        
        guard let channel = self.channel, var currentText = self.textView.text else { return }
        currentText = self.formatDiscordCommands(in: currentText)
        let message = Message(clientUser, ["content": currentText])
        self.textView.text = nil
        self.buttonIsActive = true
        self.textViewDidChange(self.textView)
        
        clientUser.send(message: message, in: channel) { [weak self] error in
            guard let self = self else { return }
            
        }
    }
    
    func editMessageAction() {
        guard buttonIsActive == true else { return }
        self.buttonIsActive = false
        
        guard let channel = self.channel, let editMessage = self.editMessage, var currentText = self.textView.text else { return }
        currentText = self.formatDiscordCommands(in: currentText)
        let newMessage = Message(clientUser, ["content": currentText])
        
        self.textView.text = nil
        self.editMessage = nil
        self.changeInputMode(to: .send)
        self.textViewDidChange(self.textView)
        self.buttonIsActive = true
        
        clientUser.edit(message: editMessage, to: newMessage, in: channel) { [weak self] error in
            guard let self = self else { return }
            self.removeContextBubble()
            if let parentVC = self.parentViewController as? TextViewController {
                parentVC.updateInputOffset()
            }
        }
    }
    
    
    func formatDiscordCommands(in string: String) -> String {
        var mutableString = string
        mutableString = mutableString.replacingOccurrences(of: #"/shrug"#, with: #"¯\_(ツ)_/¯"#)
        mutableString = mutableString.replacingOccurrences(of: #"/tableflip"#, with: #"(╯°□°)╯︵ ┻━┻"#)
        mutableString = mutableString.replacingOccurrences(of: #"/unflip"#, with: #"┬─┬ノ( º _ ºノ)"#)
        return mutableString
    }
}
