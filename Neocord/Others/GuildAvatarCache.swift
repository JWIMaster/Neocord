import UIKit
import FoundationCompatKit
import SwiftcordLegacy
import ImageIO
import MobileCoreServices

final class GuildAvatarCache {
    static let shared = GuildAvatarCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private var keys = Set<NSString>()
    private let cacheQueue = DispatchQueue(label: "guild.avatar.cache.queue")
    
    private let cacheDirectory: String = {
        let dirs = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return dirs.first ?? NSTemporaryDirectory()
    }()

    func avatar(for guild: Guild, completion: @escaping (UIImage?) -> Void) {
        guard let id = guild.id?.rawValue else {
            completion(nil)
            return
        }

        let iconHash = guild.icon ?? "default"
        let cacheKey = "\(id)-\(iconHash)" as NSString
        let filePath = cacheDirectory + "/" + (cacheKey as String) + ".png"

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

        // Download from CDN
        guard let iconHash = guild.icon else {
            completion(nil)
            return
        }

        let url = URL(string: "https://cdn.discordapp.com/icons/\(id)/\(iconHash).png?size=128")!
        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            // Cache image
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
