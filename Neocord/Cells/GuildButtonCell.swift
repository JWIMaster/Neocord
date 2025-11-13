import UIKit
import SwiftcordLegacy
import UIKitCompatKit
import SFSymbolsCompatKit
import UIKitExtensions

enum SidebarButtonType: Equatable {
    case dms
    case guild(Guild)
    case folder(GuildFolder, isExpanded: Bool)
    
    static func == (lhs: SidebarButtonType, rhs: SidebarButtonType) -> Bool {
        switch (lhs, rhs) {
        case (.dms, .dms):
            return true
        case (.folder(let a, _), .folder(let b, _)):
            return a.guildIDs == b.guildIDs
        case (.guild(let a), .guild(let b)):
            return a.id == b.id
        default:
            return false
        }
    }
}

class SidebarButtonCell: UICollectionViewCell {
    static let reuseID = "SidebarButtonCell"
    
    private var backgroundColorView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 8, snapshotTargetView: nil, disableBlur: true)
            glass.shadowRadius = 0
            glass.shadowOpacity = 0
            return glass
        } else {
            return UIView()
        }
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 8
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private(set) var type: SidebarButtonType?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(backgroundColorView)
        backgroundColorView.addSubview(imageView)
        backgroundColorView.pinToEdges(of: contentView)
        imageView.pinToEdges(of: backgroundColorView)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(named: "defaultavatar")
    }
    
    
    func configure(with type: SidebarButtonType) {
        self.type = type
        
        switch type {
        case .dms:
            imageView.image = UIImage(named: "DMsIcon")
            imageView.backgroundColor = .clear
        case .guild(let guild):
            GuildAvatarCache.shared.avatar(for: guild) { [weak self] image in
                DispatchQueue.main.async {
                    self?.imageView.image = image ?? UIImage(named: "defaultavatar")
                }
            }
        case .folder(let folder):
            guard let guildIDs = folder.0.guildIDs else { return }
            var guildImages = [UIImage?](repeating: nil, count: guildIDs.count)
            let group = DispatchGroup()
            
            for (index, guildID) in guildIDs.enumerated() {
                if let guild = clientUser.guilds[guildID] {
                    group.enter()
                    GuildAvatarCache.shared.avatar(for: guild) { image in
                        guildImages[index] = image ?? UIImage()
                        group.leave()
                    }
                } else {
                    guildImages[index] = UIImage()
                }
            }
            
            group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
                // Ensure we have at least 4 images
                var finalImages = guildImages.compactMap { $0 }
                while finalImages.count < 4 {
                    finalImages.append(UIImage())
                }
                
                let folderImage = createImageGrid(from: Array(finalImages.prefix(4)), rows: 2, columns: 2, scale: 0.7, spacing: 8, padding: 30)
                
                DispatchQueue.main.async {
                    self?.imageView.image = folderImage
                    if let glass = self?.backgroundColorView as? LiquidGlassView {
                        glass.tintColorForGlass = folder.0.color?.withAlphaComponent(0.4) ?? .clear
                    }
                }
            }

        }
    
    }
}


import UIKit

func createImageGrid(
    from images: [UIImage],
    rows: Int,
    columns: Int,
    scale: CGFloat = 0.9,
    spacing: CGFloat = 4,
    padding: CGFloat = 10
) -> UIImage? {
    // Ensure the number of images matches the grid layout
    guard images.count == rows * columns else {
        print("Error: The number of images does not match the grid size.")
        return nil
    }
    
    // Use the first image as reference size
    let baseWidth = images[0].size.width
    let baseHeight = images[0].size.height
    
    // Calculate scaled image size
    let imageWidth = baseWidth * scale
    let imageHeight = baseHeight * scale
    
    // Total grid dimensions including spacing and outer padding
    let totalWidth = (CGFloat(columns) * imageWidth)
        + (CGFloat(columns - 1) * spacing)
        + (padding * 2)
    let totalHeight = (CGFloat(rows) * imageHeight)
        + (CGFloat(rows - 1) * spacing)
        + (padding * 2)
    
    // Create drawing context
    UIGraphicsBeginImageContextWithOptions(CGSize(width: totalWidth, height: totalHeight), false, 0)
    
    // Draw each image in its grid position
    for row in 0..<rows {
        for col in 0..<columns {
            let index = row * columns + col
            let image = images[index]
            
            // Calculate position for each image
            let x = padding + CGFloat(col) * (imageWidth + spacing)
            let y = padding + CGFloat(row) * (imageHeight + spacing)
            
            // Draw the scaled image at its position
            let rect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)
            image.draw(in: rect)
        }
    }
    
    // Get final combined image
    let gridImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return gridImage
}

