import UIKit
import FoundationCompatKit
import SwiftcordLegacy
import ImageIO
import MobileCoreServices

final class AvatarCache {

    static let shared = AvatarCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let colorCache = NSCache<NSString, UIColor>()
    private let inflight = NSMapTable<NSString, NSMutableArray>(keyOptions: .strongMemory, valueOptions: .strongMemory)

    private let queue = DispatchQueue(label: "avatar.cache.queue", target: .global(qos: .userInitiated))

    private let cacheDir: String = {
        let dirs = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return dirs.first ?? NSTemporaryDirectory()
    }()

    func avatar(for user: User, completion: @escaping (UIImage?, UIColor?) -> Void) {
        guard let id = user.id?.rawValue else {
            completion(nil, nil)
            return
        }

        let avatarHash = user.avatarString ?? "default"
        let cacheKey = "\(id)-\(avatarHash)" as NSString
        let filePath = cacheDir + "/" + (cacheKey as String) + ".png"

        // MEMORY CACHE
        if let img = memoryCache.object(forKey: cacheKey),
           let col = colorCache.object(forKey: cacheKey) {
            completion(img, col)
            return
        }

        queue.async {
            // DISK CACHE (async)
            if FileManager.default.fileExists(atPath: filePath),
               let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
               let img = UIImage(data: data) {

                let col = self.colorCache.object(forKey: cacheKey) ?? img.averageColor() ?? .gray

                self.memoryCache.setObject(img, forKey: cacheKey)
                self.colorCache.setObject(col, forKey: cacheKey)

                DispatchQueue.main.async { completion(img, col) }
                return
            }

            // No avatar hash means default
            guard let avatarHash = user.avatarString else {
                DispatchQueue.main.async { completion(nil, nil) }
                return
            }

            // SINGLE FLIGHT: queue identical requests
            if let waiting = self.inflight.object(forKey: cacheKey) {
                waiting.add(completion)
                return
            } else {
                let arr = NSMutableArray(object: completion)
                self.inflight.setObject(arr, forKey: cacheKey)
            }

            // Start network load
            let url = URL(string: "https://cdn.discordapp.com/avatars/\(id)/\(avatarHash).png?size=128")!
            URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
                guard let data = data, let img = UIImage(data: data) else {
                    self.completeAll(for: cacheKey, image: nil, color: nil)
                    return
                }

                self.queue.async {
                    // Circular mask (no UIGraphicsImageRenderer)
                    let circ = self.circular(image: img)

                    let avg = circ.averageColor() ?? .white

                    self.memoryCache.setObject(circ, forKey: cacheKey)
                    self.colorCache.setObject(avg, forKey: cacheKey)

                    // PNG8 conversion in background
                    DispatchQueue.global(qos: .utility).async {
                        if let png = self.png8Data(from: circ) {
                            try? png.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                        }
                    }

                    self.completeAll(for: cacheKey, image: circ, color: avg)
                }
            }.resume()
        }
    }

    private func completeAll(for key: NSString, image: UIImage?, color: UIColor?) {
        guard let arr = inflight.object(forKey: key) else { return }
        inflight.removeObject(forKey: key)

        let completions = arr.compactMap { $0 as? (UIImage?, UIColor?) -> Void }
        DispatchQueue.main.async {
            completions.forEach { $0(image, color) }
        }
    }

    // MARK: - Helpers

    private func circular(image: UIImage) -> UIImage {
        let diameter = min(image.size.width, image.size.height)
        let rect = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))

        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }

        ctx.addEllipse(in: rect)
        ctx.clip()
        image.draw(in: rect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result ?? image
    }

    private func png8Data(from image: UIImage) -> Data? {
        guard let cg = image.cgImage else { return nil }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nil) else { return nil }

        CGImageDestinationAddImage(dest, cg, [
            kCGImagePropertyDepth: 8,
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ] as CFDictionary)

        return CGImageDestinationFinalize(dest) ? (data as Data) : nil
    }

    public func clear() {
        queue.async {
            self.memoryCache.removeAllObjects()
            self.colorCache.removeAllObjects()

            let fm = FileManager.default
            if let files = try? fm.contentsOfDirectory(atPath: self.cacheDir) {
                for f in files where f.hasSuffix(".png") {
                    try? fm.removeItem(atPath: self.cacheDir + "/" + f)
                }
            }
        }
    }
}
