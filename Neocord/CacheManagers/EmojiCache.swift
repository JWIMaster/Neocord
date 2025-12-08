import UIKit
import Foundation
import FoundationCompatKit

final class EmojiCache {
    static let shared = EmojiCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "emoji.cache.queue")
    private let cacheDirectory: String = {
        let dirs = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return dirs.first ?? NSTemporaryDirectory()
    }()

    private init() {}

    func fetchEmoji(id: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = id as NSString
        let filePath = cacheDirectory + "/" + id + ".png"

        // Memory cache
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }

        // Disk cache
        if let diskData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
           let image = UIImage(data: diskData) {
            memoryCache.setObject(image, forKey: cacheKey)
            completion(image)
            return
        }

        // Fetch from CDN
        guard let url = URL(string: "https://cdn.discordapp.com/emojis/\(id).png?v=1") else {
            completion(nil)
            return
        }

        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, _, _ in
            guard let self = self, let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Cache and return
            self.cacheQueue.async {
                self.memoryCache.setObject(image, forKey: cacheKey)
                try? data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }.resume()
    }

    func clearCache() {
        cacheQueue.async {
            self.memoryCache.removeAllObjects()
            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: self.cacheDirectory) {
                for file in files where file.hasSuffix(".png") {
                    try? fileManager.removeItem(atPath: self.cacheDirectory + "/" + file)
                }
            }
        }
    }
}
