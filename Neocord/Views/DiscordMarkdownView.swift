import UIKit
import UIKitCompatKit
import FoundationCompatKit
import TSMarkdownParser
import SwiftcordLegacy

/*class DiscordMarkdownView: UILabel {
    
    /// Default text styling
    var textColorCustom: UIColor = .white
    var fontCustom: UIFont = .systemFont(ofSize: 17)
    let parser = TSMarkdownParser.standard()
    var message: Message?
    
    private static var emojiCache = [String: UIImage]()
    
    private static let markdownQueue: DispatchQueue = DispatchQueue(label: "markdownqueue.messageTextAndEmoji", target: .global(qos: .userInitiated))
    
    private static let emojiQueue: DispatchQueue = DispatchQueue(label: "jwi.neocord.emojiqueue", attributes: .concurrent, target: .global(qos: .userInitiated))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = .white
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        backgroundColor = .clear
    }
    
    init(frame: CGRect, message: Message? = nil) {
        self.message = message
        super.init(frame: frame)
        textColor = .white
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }
    
    /// Set markdown text with Discord emojis like <:name:id>
    func setMarkdown(_ markdown: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let attributedString = NSMutableAttributedString()
            let userFormattedMarkdown = self.replaceUserMentions(in: markdown)
            let parts = self.parseDiscordMarkdown(userFormattedMarkdown)

            for part in parts {
                switch part {
                case .text(let str):
                    let attr = self.parser.attributedString(fromMarkdown: str)
                    attributedString.append(attr)

                case .emoji(let id, _):
                    let attachment = NSTextAttachment()
                    attachment.bounds = CGRect(x: 0,
                                               y: (self.fontCustom.capHeight - self.fontCustom.lineHeight)/2,
                                               width: self.fontCustom.lineHeight,
                                               height: self.fontCustom.lineHeight)

                    if let image = Self.emojiCache[id] {
                        attachment.image = image
                    } else {
                        // Placeholder image
                        attachment.image = UIImage()

                        // Fetch asynchronously and update inline
                        self.fetchEmojiAsync(id: id) { [weak self, weak attachment] image in
                            guard let self = self, let image = image else { return }
                            DispatchQueue.main.async {
                                attachment?.image = image
                                // Force UILabel to redraw
                                self.setNeedsDisplay()
                            }
                        }
                    }

                    attributedString.append(NSAttributedString(attachment: attachment))
                }
            }

            DispatchQueue.main.async {
                self.attributedText = attributedString
            }
        }
    }

    
    // MARK: - Parsing
    private func parseDiscordMarkdown(_ markdown: String) -> [DiscordPart] {
        if #unavailable(iOS 7.0.1) {
            return [.text(markdown)]
        }
        var results: [DiscordPart] = []
        let pattern = "<:([a-zA-Z0-9_]+):([0-9]+)>"
        let regex = try? NSRegularExpression(pattern: pattern)
        var lastIndex = markdown.startIndex
        
        regex?.enumerateMatches(in: markdown, options: [], range: NSRange(markdown.startIndex..., in: markdown)) { match, _, _ in
            guard let match = match,
                  let nameRange = Range(match.range(at: 1), in: markdown),
                  let idRange = Range(match.range(at: 2), in: markdown) else { return }
            
            let emojiID = String(markdown[idRange])
            let matchStart = markdown.index(markdown.startIndex, offsetBy: match.range.location)
            
            if lastIndex < matchStart {
                let text = String(markdown[lastIndex..<matchStart])
                results.append(.text(text))
            }
            
            results.append(.emoji(id: emojiID, name: String(markdown[nameRange])))
            lastIndex = markdown.index(matchStart, offsetBy: match.range.length)
        }
        
        if lastIndex < markdown.endIndex {
            results.append(.text(String(markdown[lastIndex...])))
        }
        
        return results
    }
    
    private enum DiscordPart {
        case text(String)
        case emoji(id: String, name: String)
    }
    
    // MARK: - Emoji Fetching
    private func fetchEmojiAsync(id: String, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?v=1"),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            Self.emojiCache[id] = image
            completion(image)
        }
    }
    
    private func replaceUserMentions(in markdown: String) -> String {
        let pattern = #"<@!?([0-9]+)>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return markdown
        }

        let ns = markdown as NSString
        let range = NSRange(location: 0, length: ns.length)
        var result = markdown

        let matches = regex.matches(in: markdown, options: [], range: range)
        guard let users = message?.mentions, !users.isEmpty else { return result }
        
        for match in matches.reversed() {
            let id = ns.substring(with: match.range(at: 1))
            var mentionedUser: User?
            for user in users {
                if user.id! == Snowflake(id)! {
                    mentionedUser = user
                }
            }
            
            if let mentionedUser = mentionedUser {
                // Use displayname if available, fallback to username
                let replacement = "@\(mentionedUser.displayname ?? mentionedUser.username ?? "unknown")"
                result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
            } else {
                // Unknown user, fallback to plain text
                result = (result as NSString).replacingCharacters(in: match.range, with: "@unknown")
            }
        }

        return result
    }

}*/

//MARK: new class, need to understand
class DiscordMarkdownView: UILabel {

    // Default styling
    var textColorCustom: UIColor = .white
    var fontCustom: UIFont = .systemFont(ofSize: 17)
    let parser = TSMarkdownParser.standard()
    var message: DiscordMessage?

    private static var emojiCache = [String: UIImage]()

    private static let markdownQueue = DispatchQueue(label: "markdownqueue.messageTextAndEmoji", target: .global(qos: .userInitiated))

    private static let emojiQueue = DispatchQueue(label: "jwi.neocord.emojiqueue", attributes: .concurrent, target: .global(qos: .userInitiated))

    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = .white
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        backgroundColor = .clear
    }

    init(frame: CGRect, message: DiscordMessage? = nil) {
        self.message = message
        super.init(frame: frame)
        textColor = .white
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }

    // MARK: - Public

    func setMarkdown(_ markdown: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let attributedString = NSMutableAttributedString()

            // Mentions -> safe tokens
            let userFormatted = self.replaceUserMentions(in: markdown)

            // Split into parts
            let parts = self.parseDiscordMarkdown(userFormatted)

            // Build attributed output
            for part in parts {
                switch part {

                case .text(let str):
                    let attr = self.parser.attributedString(fromMarkdown: str)
                    attributedString.append(attr)

                case .mention(let name):
                    let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightPurple, .font: self.fontCustom]
                    let text = NSAttributedString(string: "@\(name)", attributes: attrs)
                    attributedString.append(text)

                case .emoji(let id, _):
                    guard #available(iOS 7.0.1, *) else {
                        attributedString.append(NSAttributedString(string: "<:emoji:\(id)>"))
                        continue
                    }

                    let attachment = NSTextAttachment()
                    attachment.bounds = CGRect(x: 0,
                                               y: (self.fontCustom.capHeight - self.fontCustom.lineHeight) / 2,
                                               width: self.fontCustom.lineHeight,
                                               height: self.fontCustom.lineHeight)

                    if let image = Self.emojiCache[id] {
                        attachment.image = image
                    } else {
                        attachment.image = UIImage() // placeholder

                        self.fetchEmojiAsync(id: id) { [weak self, weak attachment] image in
                            guard let self = self, let image = image else { return }
                            DispatchQueue.main.async {
                                attachment?.image = image
                                self.setNeedsDisplay()
                            }
                        }
                    }

                    attributedString.append(NSAttributedString(attachment: attachment))
                }
            }

            DispatchQueue.main.async {
                self.attributedText = attributedString
            }
        }
    }

    // MARK: - Parsing

    private enum DiscordPart {
        case text(String)
        case emoji(id: String, name: String)
        case mention(String)
    }

    private func parseDiscordMarkdown(_ markdown: String) -> [DiscordPart] {

        // First: extract mention tokens
        let mentionPattern = #"§MENTION:([^§]+)§"#
        if let regex = try? NSRegularExpression(pattern: mentionPattern) {

            let full = markdown
            var pos = full.startIndex
            let matches = regex.matches(in: full, range: NSRange(full.startIndex..., in: full))
            var parts: [DiscordPart] = []

            if !matches.isEmpty {
                for match in matches {
                    let start = full.index(full.startIndex, offsetBy: match.range.location)

                    if pos < start {
                        let text = String(full[pos..<start])
                        parts.append(.text(text))
                    }

                    if let nameRange = Range(match.range(at: 1), in: full) {
                        let name = String(full[nameRange])
                        parts.append(.mention(name))
                    }

                    pos = full.index(start, offsetBy: match.range.length)
                }

                if pos < full.endIndex {
                    parts.append(.text(String(full[pos...])))
                }

                // After splitting mentions, parse emojis only on iOS 7.0.1+
                return flattenEmoji(parts)
            }
        }

        // If no mentions, fallback directly to emoji parsing
        return flattenEmoji([.text(markdown)])
    }

    // Extract emojis from text parts (but not mentions)
    private func flattenEmoji(_ parts: [DiscordPart]) -> [DiscordPart] {

        guard #available(iOS 7.0.1, *) else {
            return parts // no emoji parsing on older iOS
        }

        var output: [DiscordPart] = []
        let pattern = "<:([a-zA-Z0-9_]+):([0-9]+)>"
        let regex = try? NSRegularExpression(pattern: pattern)

        for part in parts {
            switch part {
            case .mention:
                output.append(part)

            case .emoji:
                output.append(part)

            case .text(let markdown):
                guard let regex = regex else {
                    output.append(.text(markdown))
                    continue
                }

                var lastIndex = markdown.startIndex
                let str = markdown

                regex.enumerateMatches(in: str, range: NSRange(str.startIndex..., in: str)) { match, _, _ in
                    guard let match = match,
                          let nameRange = Range(match.range(at: 1), in: str),
                          let idRange = Range(match.range(at: 2), in: str)
                    else { return }

                    let emojiID = String(str[idRange])
                    let matchStart = str.index(str.startIndex, offsetBy: match.range.location)

                    if lastIndex < matchStart {
                        output.append(.text(String(str[lastIndex..<matchStart])))
                    }

                    output.append(.emoji(id: emojiID, name: String(str[nameRange])))
                    lastIndex = str.index(matchStart, offsetBy: match.range.length)
                }

                if lastIndex < str.endIndex {
                    output.append(.text(String(str[lastIndex...])))
                }
            }
        }

        return output
    }

    // MARK: - Emoji Fetching

    private func fetchEmojiAsync(id: String, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?v=1"),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else {
                completion(nil)
                return
            }

            Self.emojiCache[id] = image
            completion(image)
        }
    }

    // MARK: - Mention Handling

    private func replaceUserMentions(in markdown: String) -> String {
        let pattern = #"<@!?([0-9]+)>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return markdown }

        let ns = markdown as NSString
        let range = NSRange(location: 0, length: ns.length)
        var result = markdown

        guard let users = message?.mentions, !users.isEmpty else { return result }

        let matches = regex.matches(in: markdown, options: [], range: range)

        for match in matches.reversed() {
            let id = ns.substring(with: match.range(at: 1))
            let user = users.first { $0.id == Snowflake(id) }
            print(user)
            let name = user?.nickname ?? user?.displayname ?? user?.username ?? "unknown"

            // Safe placeholder not parsed by Markdown
            let replacement = "§MENTION:\(name)§"

            result = (result as NSString)
                .replacingCharacters(in: match.range, with: replacement)
        }

        return result
    }
}
