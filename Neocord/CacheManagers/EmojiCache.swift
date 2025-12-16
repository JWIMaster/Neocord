import UIKit
import Foundation
import FoundationCompatKit

final class EmojiCache {
    static let shared = EmojiCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "emoji.cache.queue")

    private let cacheDirectory: String = {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        ?? NSTemporaryDirectory()
    }()

    private init() {}

    func fetchEmoji(id: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = id as NSString
        let filePath = cacheDirectory + "/" + id + ".png"

        if let cached = memoryCache.object(forKey: cacheKey) {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: cacheKey)
            DispatchQueue.main.async { completion(image) }
            return
        }

        guard let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?v=1") else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?v=1"),
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            self.memoryCache.setObject(image, forKey: id as NSString)
            try? data.write(
                to: URL(fileURLWithPath: self.cacheDirectory + "/" + id + ".png"),
                options: .atomic
            )

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
