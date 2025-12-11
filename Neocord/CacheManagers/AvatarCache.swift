import UIKit
import FoundationCompatKit
import SwiftcordLegacy
import ImageIO
import MobileCoreServices

final class AvatarCache {
    static let shared = AvatarCache()

    public let memoryCache = NSCache<NSString, UIImage>()
    private let colorCache = NSCache<NSString, UIColor>()
    public var keys = Set<NSString>()

    private let cacheQueue = DispatchQueue(label: "avatar.cache.queue")
    
    private let cacheDirectory: String = {
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
        let filePath = cacheDirectory + "/" + (cacheKey as String) + ".png"

        // Memory cache
        if let cachedImage = memoryCache.object(forKey: cacheKey),
           let cachedColor = colorCache.object(forKey: cacheKey) {
            completion(cachedImage, cachedColor)
            return
        }

        // Disk cache
        if let diskData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
           let image = UIImage(data: diskData) {
            memoryCache.setObject(image, forKey: cacheKey)
            self.cacheQueue.async {
                let avgColor = self.colorCache.object(forKey: cacheKey) ?? image.averageColor() ?? .gray
                self.colorCache.setObject(avgColor, forKey: cacheKey)
                DispatchQueue.main.async {
                    completion(image, avgColor)
                }
            }
            return
        }

        // Download from CDN
        guard let avatarHash = user.avatarString else {
            completion(nil, nil)
            return
        }

        let url = URL(string: "https://cdn.discordapp.com/avatars/\(id)/\(avatarHash).png?size=128")!
        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil, nil)
                return
            }

            let circularImage = self.makeCircular(image: image)

            // Cache image and color
            self.cacheQueue.async {
                self.memoryCache.setObject(circularImage, forKey: cacheKey)

                // Convert to PNG8
                if let png8Data = self.png8Data(from: circularImage) {
                    try? png8Data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                }

                let avgColor = circularImage.averageColor() ?? .white
                self.colorCache.setObject(avgColor, forKey: cacheKey)

                DispatchQueue.main.async {
                    completion(circularImage, avgColor)
                }
            }
        }.resume()
    }

    // MARK: - Helpers

    private func makeCircular(image: UIImage) -> UIImage {
        let diameter = min(image.size.width, image.size.height)
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        let path = UIBezierPath(ovalIn: rect)
        path.addClip()
        image.draw(in: rect)
        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return circularImage ?? image
    }

    /// Convert UIImage to PNG8 (256 colours max, preserves alpha)
    private func png8Data(from image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let drawnImage = context.makeImage() else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nil) else { return nil }

        let properties: CFDictionary = [
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
            kCGImagePropertyDepth: 8
        ] as CFDictionary

        CGImageDestinationAddImage(destination, drawnImage, properties)
        guard CGImageDestinationFinalize(destination) else { return nil }

        return data as Data
    }

    public func clearCache() {
        cacheQueue.async {
            self.memoryCache.removeAllObjects()
            self.colorCache.removeAllObjects()

            let fileManager = FileManager.default
            if let files = try? fileManager.contentsOfDirectory(atPath: self.cacheDirectory) {
                for file in files where file.hasSuffix(".png") {
                    let filePath = self.cacheDirectory + "/" + file
                    try? fileManager.removeItem(atPath: filePath)
                }
            }
        }
    }
}
