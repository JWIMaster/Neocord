import UIKit
import FoundationCompatKit
import SwiftcordLegacy

final class BannerCache {
    static let shared = BannerCache()

    public let memoryCache = NSCache<NSString, UIImage>()
    private let colorCache = NSCache<NSString, UIColor>()
    private let cacheQueue = DispatchQueue(label: "banner.cache.queue")

    private let cacheDirectory: String = {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        ?? NSTemporaryDirectory()
    }()

    private init() {}

    func banner(for userProfile: UserProfile, _ user: User, completion: @escaping (UIImage?, UIColor?) -> Void) {
        guard
            let id = user.id?.rawValue,
            let bannerHash = userProfile.bannerHash
        else {
            completion(nil, nil)
            return
        }

        let cacheKey = "\(id)-\(bannerHash)" as NSString
        let filePath = cacheDirectory + "/" + (cacheKey as String) + ".png"

        // Memory cache
        if let image = memoryCache.object(forKey: cacheKey),
           let color = colorCache.object(forKey: cacheKey) {
            completion(image, color)
            return
        }

        // Disk cache
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
           let image = UIImage(data: data) {

            memoryCache.setObject(image, forKey: cacheKey)

            cacheQueue.async {
                let avgColor = self.colorCache.object(forKey: cacheKey)
                    ?? image.averageColor()
                    ?? .gray

                self.colorCache.setObject(avgColor, forKey: cacheKey)

                DispatchQueue.main.async {
                    completion(image, avgColor)
                }
            }
            return
        }

        // Always PNG, even for animated hashes
        let urlString = "https://cdn.discordapp.com/banners/\(id)/\(bannerHash).png?size=512"
        guard let url = URL(string: urlString) else {
            completion(nil, nil)
            return
        }

        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                completion(nil, nil)
                return
            }

            self.cacheQueue.async {
                self.memoryCache.setObject(image, forKey: cacheKey)
                try? data.write(to: URL(fileURLWithPath: filePath), options: .atomic)

                let avgColor = image.averageColor() ?? .gray
                self.colorCache.setObject(avgColor, forKey: cacheKey)

                DispatchQueue.main.async {
                    completion(image, avgColor)
                }
            }
        }.resume()
    }

    func clearCache() {
        cacheQueue.async {
            self.memoryCache.removeAllObjects()
            self.colorCache.removeAllObjects()

            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: self.cacheDirectory) {
                for file in files where file.hasSuffix(".png") {
                    try? fileManager.removeItem(atPath: self.cacheDirectory + "/" + file)
                }
            }
        }
    }
}
