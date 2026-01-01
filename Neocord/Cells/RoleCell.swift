import UIKit
import UIKitCompatKit
import SwiftcordLegacy
import UIKitExtensions

class RoleCell: UICollectionViewCell {
    static let reuseIdentifier = "RoleCell"
    
    let roleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6) // padding between text/icon and background
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4) // spacing between icon and text
        button.backgroundColor = .clear
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        return button
    }()
    
    var roleBackground: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 8, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            //glass.shadowRadius = 6
            //glass.shadowOpacity = 0.3
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.clipsToBounds = false
            return glass
        } else {
            let bg = UIView()
            bg.layer.cornerRadius = 8
            bg.translatesAutoresizingMaskIntoConstraints = false
            return bg
        }
    }()
    
    var roleIcon: UIImage? {
        didSet {
            roleButton.setImage(roleIcon, for: .normal)
        }
    }
    
    var role: Role? {
        didSet {
            guard let role = role else { return }
            roleButton.setTitle(role.name, for: .normal)
            if role.icon != nil {
                RoleIconCache.shared.icon(for: role) { [weak self] image in
                    guard let self = self, let image = image else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        let resized = image.resizeImage(image, targetSize: CGSize(width: 16, height: 16))
                        DispatchQueue.main.async {
                            self.roleIcon = resized
                            if ThemeEngine.enableGlass {
                                guard let roleBackground = self.roleBackground as? LiquidGlassView else { return }
                                roleBackground.tintColorForGlass = self.bgColor.withAlphaComponent(0.3)
                                //roleBackground.shadowColor = self.bgColor.cgColor
                            } else {
                                self.roleButton.backgroundColor = UIColor(cgColor: self.bgColor.cgColor.copy(alpha: 0.3)!)
                            }
                        }
                    }
                }
            } else {
                if let roleBackground = self.roleBackground as? LiquidGlassView, ThemeEngine.enableGlass {
                    roleBackground.tintColorForGlass = bgColor.withAlphaComponent(0.3)
                    //roleBackground.shadowColor = bgColor.cgColor
                } else {
                    self.roleButton.backgroundColor = UIColor(cgColor: bgColor.cgColor.copy(alpha: 0.3)!)
                }
            }
        }
    }
    
    var bgColor: UIColor {
        if role?.color == UIColor(red: 0, green: 0, blue: 0, alpha: 1) {
            return .lightGray
        } else {
            return role?.color ?? .lightGray
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        contentView.addSubview(roleBackground)
        contentView.addSubview(roleButton)
        roleBackground.pinToEdges(of: contentView)
        roleButton.pinToEdges(of: contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

