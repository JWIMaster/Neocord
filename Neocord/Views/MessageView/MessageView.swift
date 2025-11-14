//
//  MessageView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 18/10/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit



public class MessageView: UIView, UIGestureRecognizerDelegate {
    let messageContent: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .equalSpacing
        return stack
    }()
    var messageText = UILabel()
    var messageAttachments: UIImageView?
    var authorAvatar: UIImageView = UIImageView()
    public var averageAvatarColor: UIColor?
    let authorName = UILabel()
    let timestamp = UILabel()
    let edited = UILabel()
    let messageBackground: UIView? = {
        if ThemeEngine.enableGlass {
            return LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        } else {
            let background = UIView()
            background.layer.cornerRadius = 22
            return background
        }
    }()
    var slClient: SLClient?
    var message: Message?
    var reply: ReplyMessage?
    var replyView: ReplyMessageView?
    var isClientUser: Bool?
    var markdownParser: TSMarkdownParser = TSMarkdownParser.standard()
    var member: GuildMember?
    var guildTextChannel: GuildChannel?
    var isSameUser: Bool = false
    
    
    static let markdownQueue: DispatchQueue = DispatchQueue(label: "com.jwi.markdownrender", attributes: .concurrent, target: .global(qos: .userInitiated))
    
    static let avatarQueue: DispatchQueue = DispatchQueue(label: "com.jwi.avatarQueue", attributes: .concurrent, target: .global(qos: .userInitiated))
    
    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let calendar = Calendar.current
    
    let messageTextAndEmoji = DiscordMarkdownView()
    
    public init(_ slClient: SLClient, message: Message, guildTextChannel: GuildChannel? = nil, isSameUser: Bool = false) {
        super.init(frame: .zero)
        self.slClient = slClient
        self.message = message
        self.isSameUser = isSameUser
        self.isClientUser = {
            return message.author == slClient.clientUser
        }()
        
        self.guildTextChannel = guildTextChannel
        
        self.setup()
    }
    
    
    func setup() {
        if let guildTextChannel = guildTextChannel {
            setupMembers()
        }
        setupText()
        setupBackground()
        setupAuthorName()
        setupAuthorAvatar()
        setupEdited()
        setupTimestamp()
        setupGestureRecogniser()
        setupReply()
        setupSubviews()
        setupContraints()
        setupAttachments()
        self.clipsToBounds = false
        self.authorAvatar.clipsToBounds = false

    }
    
    func setupSubviews() {
        guard let messageBackground = messageBackground else { return }
        
        if let replyView = replyView {
            replyView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(replyView)
        }
        
        if #available(iOS 7.0.1, *) {
            messageContent.addArrangedSubview(messageTextAndEmoji)
        } else {
            messageContent.addArrangedSubview(messageText)
        }
        addSubview(messageContent)
        addSubview(messageBackground)
        sendSubviewToBack(messageBackground)
        addSubview(authorName)
        addSubview(timestamp)
        addSubview(edited)
        addSubview(authorAvatar)
    }
    
    func setupMembers() {
        guard let messageAuthorID = self.message?.author?.id else { return }
        
        if let guildID = self.guildTextChannel?.guild?.id,
           let cachedMember = slClient?.guilds[guildID]?.members[messageAuthorID] {
            self.member = cachedMember
            applyMember()
        }
        
        slClient?.gateway?.addGuildMemberChunkObserver { [weak self] members in
            guard let self = self else { return }
            if let member = members[messageAuthorID] {
                self.member = member
                self.applyMember()
            }
        }
    }
    
    func applyMember() {
        guard let member = self.member else { return }
        DispatchQueue.main.async {
            if let guildNickname = member.guildNickname {
                self.authorName.text = guildNickname
            }
            if let roles = member.roles, !roles.isEmpty, let topRoleColor = member.topRoleColor, topRoleColor.color != UIColor(red: 0, green: 0, blue: 0, alpha: 1) {
                self.authorName.textColor = topRoleColor.color
            }
            self.authorName.layoutIfNeeded()
        }
    }
    
    
    
    
    func setupBackground() {
        guard let messageBackground = messageBackground else { return }
        
        messageBackground.translatesAutoresizingMaskIntoConstraints = false
        messageBackground.isUserInteractionEnabled = false
        
        if let messageBackground = messageBackground as? LiquidGlassView {
            messageBackground.shadowOpacity = 0.3
            messageBackground.shadowRadius = 6
            messageBackground.solidViewColour = .discordGray
        } else {
            messageBackground.backgroundColor = .discordGray
        }
        
        messageBackground.sizeToFit()
    }
    
    
    func setupContraints() {
        guard let messageBackground = messageBackground else { return }
        
        if let replyView = replyView {
            NSLayoutConstraint.activate([
                replyView.topAnchor.constraint(equalTo: self.topAnchor),
                replyView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 6),
                replyView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -6)
            ])
            messageBackground.topAnchor.constraint(equalTo: replyView.bottomAnchor, constant: 6).isActive = true
        } else {
            messageBackground.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        }
        
        authorName.setContentHuggingPriority(.defaultLow, for: .horizontal)
        authorName.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        edited.setContentHuggingPriority(.required, for: .horizontal)
        edited.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        timestamp.setContentHuggingPriority(.required, for: .horizontal)
        timestamp.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        
        NSLayoutConstraint.activate([
            messageBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            messageBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            messageBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            
            messageContent.topAnchor.constraint(equalTo: messageBackground.topAnchor, constant: 20),
            messageContent.leadingAnchor.constraint(equalTo: messageBackground.leadingAnchor, constant: 20),
            messageContent.trailingAnchor.constraint(equalTo: messageBackground.trailingAnchor, constant: -20),
            messageContent.bottomAnchor.constraint(equalTo: messageBackground.bottomAnchor, constant: -6),
            
            
            authorName.topAnchor.constraint(equalTo: messageBackground.topAnchor, constant: 4),
            authorName.leadingAnchor.constraint(equalTo: messageContent.leadingAnchor),

            edited.centerYAnchor.constraint(equalTo: authorName.centerYAnchor),
            edited.leadingAnchor.constraint(equalTo: authorName.trailingAnchor, constant: 4),

            timestamp.centerYAnchor.constraint(equalTo: authorName.centerYAnchor),
            timestamp.leadingAnchor.constraint(equalTo: edited.trailingAnchor, constant: 4),
            timestamp.trailingAnchor.constraint(equalTo: messageContent.trailingAnchor),
            
            authorAvatar.topAnchor.constraint(equalTo: authorName.topAnchor),
            authorAvatar.trailingAnchor.constraint(equalTo: messageContent.leadingAnchor, constant: -4)
        ])
    }
    
    public func updateMessage(_ message: Message) {
        self.messageText.text = message.content
        if #available(iOS 7.0.1, *) {
            self.messageTextAndEmoji.setMarkdown(message.content ?? "unknown")
        }
        self.message?.content = message.content
        self.edited.text = "(edited)"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.slClient = nil
        self.message = nil
        self.isClientUser = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check all subviews, even outside bounds
        for subview in subviews {
            let convertedPoint = subview.convert(point, from: self)
            if let hitView = subview.hitTest(convertedPoint, with: event) {
                return hitView
            }
        }
        // Fallback
        return super.hitTest(point, with: event)
    }

}

