import UIKit
import UIKitCompatKit
import FoundationCompatKit
import TSMarkdownParser

class DiscordMarkdownView: UILabel {
    
    /// Default text styling
    var textColorCustom: UIColor = .white
    var fontCustom: UIFont = .systemFont(ofSize: 17)
    let parser = TSMarkdownParser.standard()
    
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
            let parts = self.parseDiscordMarkdown(markdown)

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
    
}
