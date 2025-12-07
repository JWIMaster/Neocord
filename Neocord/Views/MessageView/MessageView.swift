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
    var messageText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var messageAttachments: UIImageView?
    var authorAvatar: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 30, height: 30), cornerRadius: 15).cgPath
        iv.layer.shadowRadius = 6
        iv.layer.shadowOpacity = 0.5
        iv.layer.shadowColor = UIColor.black.cgColor
        return iv
    }()
    public var averageAvatarColor: UIColor?
    let authorName = UILabel()
    let timestamp = UILabel()
    let edited = UILabel()
    let messageBackground: UIView? = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.translatesAutoresizingMaskIntoConstraints = false
            return glass
        } else {
            let background = UIView()
            background.translatesAutoresizingMaskIntoConstraints = false
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
    
    var pingHighlightView: UIView = {
        let pinged = UIView()
        pinged.layer.cornerRadius = 22
        pinged.translatesAutoresizingMaskIntoConstraints = false
        return pinged
    }()
    
    var clientUserPinged: Bool = false
    
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
    
    lazy var messageTextAndEmoji = DiscordMarkdownView(frame: .zero, message: self.message)
    
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
        if guildTextChannel != nil {
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
        setupSelfPing()
        setupSubviews()
        setupContraints()
        setupAttachments()
        self.clipsToBounds = false
        self.authorAvatar.clipsToBounds = false

    }
    
    func setupSubviews() {
        guard let messageBackground = messageBackground else { return }
        
        if clientUserPinged {
            addSubview(pingHighlightView)
        }
        
        if let replyView = replyView {
            replyView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(replyView)
        }
        
        messageContent.addArrangedSubview(messageTextAndEmoji)
        if let embeds = message?.embeds, !embeds.isEmpty {
            for embed in embeds {
                let embedView = EmbedView(embed: embed)
                embedView.translatesAutoresizingMaskIntoConstraints = false
                messageContent.addArrangedSubview(embedView)
            }
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
        
        if let guildID = self.guildTextChannel?.guild?.id, let cachedMember = slClient?.guilds[guildID]?.members[messageAuthorID] {
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
        
        if clientUserPinged {
            self.pingHighlightView.pinToEdges(of: self)
        }
        
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
        self.messageTextAndEmoji.setMarkdown(message.content ?? "unknown")
        self.message?.content = message.content
        self.edited.text = "(edited)"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.slClient = nil
        self.message = nil
        self.isClientUser = nil
    }
}

