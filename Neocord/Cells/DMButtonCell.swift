import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import SFSymbolsCompatKit

class DMButtonCell: UICollectionViewCell {
    
    static let reuseID = "DMButtonCell"
    
    private var dmAuthorAvatar: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private var dmNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17)
        lbl.textColor = .white
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var backgroundGlass: UIView? = {
        if ThemeEngine.enableGlass {
            switch device {
            case .a4:
                let bg = UIView()
                bg.layer.cornerRadius = 22
                return bg
            default:
                let lg = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
                lg.shadowOpacity = 0.6
                lg.shadowRadius = 0
                lg.solidViewColour = .clear
                lg.translatesAutoresizingMaskIntoConstraints = false
                return lg
            }
        } else {
            let bg = UIView()
            bg.layer.cornerRadius = 22
            return bg
        }
    }()
    
    private var stack: UIStackView = {
        let st = UIStackView()
        st.axis = .horizontal
        st.spacing = 8
        st.alignment = .center
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        guard let backgroundGlass = backgroundGlass else {
            return
        }

        contentView.addSubview(backgroundGlass)
        contentView.addSubview(stack)
        stack.addArrangedSubview(dmAuthorAvatar)
        stack.addArrangedSubview(dmNameLabel)
        
        NSLayoutConstraint.activate([
            backgroundGlass.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundGlass.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundGlass.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundGlass.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            dmAuthorAvatar.widthAnchor.constraint(equalToConstant: 40),
            dmAuthorAvatar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with dm: DMChannel) {
        switch dm.type {
        case .dm:
            //Set DM Text
            guard let dm = dm as? DM, let recipient = dm.recipient else { return }
            self.dmNameLabel.text = dm.recipient?.nickname ?? dm.recipient?.displayname ?? dm.recipient?.username
            
            AvatarCache.shared.avatar(for: recipient) { [weak self] image, color in
                
                DispatchQueue.global(qos: .userInitiated).async {
                    
                    guard let self = self, let image = image, let color = color else { return }
                    
                    let resized = image.resizeImage(image, targetSize: CGSize(width: 40, height: 40))
                    
                    DispatchQueue.main.async {
                        self.dmAuthorAvatar.image = resized
                        if ThemeEngine.enableProfileTinting {
                            if let backgroundGlass = self.backgroundGlass as? LiquidGlassView {
                                backgroundGlass.tintColorForGlass = color
                            } else {
                                self.backgroundGlass?.backgroundColor = color
                            }
                        }
                    }
                    
                }
            }
        case .groupDM:
            guard let dm = dm as? GroupDM else { return }
            self.dmNameLabel.text = dm.name
            
            DispatchQueue.global(qos: .userInitiated).async {
                let resized = UIImage(named: "defaultavatar")!.resizeImage(UIImage(named: "defaultavatar")!, targetSize: CGSize(width: 40, height: 40))
                DispatchQueue.main.async {
                    self.dmAuthorAvatar.image = resized
                    if ThemeEngine.enableProfileTinting {
                        if let backgroundGlass = self.backgroundGlass as? LiquidGlassView {
                            backgroundGlass.tintColorForGlass = .blue.withAlphaComponent(0.5)
                        } else {
                            self.backgroundGlass?.backgroundColor = .blue.withAlphaComponent(0.5)
                        }
                    }
                }
            }
        default:
            break
        }
    }
}
