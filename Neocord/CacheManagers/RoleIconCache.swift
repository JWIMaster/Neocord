import UIKit
import FoundationCompatKit
import SwiftcordLegacy
import ImageIO
import MobileCoreServices

final class RoleIconCache {
    static let shared = RoleIconCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private var keys = Set<NSString>()
    private let cacheQueue = DispatchQueue(label: "role.icon.cache.queue")

    private let cacheDirectory: String = {
        let dirs = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return dirs.first ?? NSTemporaryDirectory()
    }()

    func icon(for role: Role, completion: @escaping (UIImage?) -> Void) {
        let id = role.id.rawValue

        // Discord role icons use a hash and may be emoji based
        guard let iconHash = role.icon else {
            completion(nil)
            return
        }

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

        // Build CDN URL
        // Role icons live at
        // https cdn dot discordapp dot com role-icons ROLE_ID ICON_HASH PNG
        guard let url = URL(string: "https://cdn.discordapp.com/role-icons/\(id)/\(iconHash).png?size=128") else {
            completion(nil)
            return
        }

        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }

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
