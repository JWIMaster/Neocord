import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import SFSymbolsCompatKit

class FriendCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    static let reuseID = "FriendCell"
    
    private var friendAvatar: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private var friendName: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17)
        lbl.textColor = .white
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var backgroundGlass: UIView? = {
        if ThemeEngine.enableGlass {
            let lg = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
            lg.shadowOpacity = 0.6
            lg.shadowRadius = 0
            lg.solidViewColour = .clear
            lg.translatesAutoresizingMaskIntoConstraints = false
            return lg
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
    
    private var friend: User?
    
    private lazy var presenceIndicator: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 6, snapshotTargetView: nil, disableBlur: true)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.tintColorForGlass = presenceColor
            return glass
        } else {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = presenceColor
            return view
        }
    }()

    private var presenceColor: UIColor = .offlineGray
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        addTapGesture()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        guard let backgroundGlass = backgroundGlass else {
            return
        }

        contentView.addSubview(backgroundGlass)
        contentView.addSubview(stack)
        stack.addArrangedSubview(friendAvatar)
        stack.addArrangedSubview(friendName)
        contentView.addSubview(presenceIndicator)
        
        NSLayoutConstraint.activate([
            backgroundGlass.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundGlass.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundGlass.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundGlass.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            friendAvatar.widthAnchor.constraint(equalToConstant: 40),
            friendAvatar.heightAnchor.constraint(equalToConstant: 40),
            
            presenceIndicator.widthAnchor.constraint(equalToConstant: 12),
            presenceIndicator.heightAnchor.constraint(equalToConstant: 12),

            presenceIndicator.bottomAnchor.constraint(equalTo: friendAvatar.bottomAnchor),
            presenceIndicator.trailingAnchor.constraint(equalTo: friendAvatar.trailingAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        presenceColor = .offlineGray
        updatePresenceIndicatorColor()
        friendAvatar.image = nil
        friendName.text = nil
        friend = nil
    }

    private func updatePresenceIndicatorColor() {
        if let glass = presenceIndicator as? LiquidGlassView {
            glass.tintColorForGlass = presenceColor
        } else {
            presenceIndicator.backgroundColor = presenceColor
        }
    }
    
    func configure(with user: User) {
        self.friendName.text = user.nickname ?? user.displayname ?? user.username
        self.friend = user
        
        let presence = clientUser.presences[user.id!] ?? .offline
        presenceColor = PresenceColor.color(for: presence)
        updatePresenceIndicatorColor()
        
        clientUser.gateway?.addPresenceUpdateObserver { [weak self] presenceDict in
            guard let self = self, let updatedPresence = presenceDict[user.id!] else { return }
            self.presenceColor = PresenceColor.color(for: updatedPresence)
            DispatchQueue.main.async {
                if self.friend?.id == user.id {
                    self.updatePresenceIndicatorColor()
                }
            }
        }
        
        AvatarCache.shared.avatar(for: user) { [weak self] image, color in
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                guard let self = self else { return }
                
                if let image = image, let color = color {
                    let resized = image.resizeImage(image, targetSize: CGSize(width: 40, height: 40))
                    
                    DispatchQueue.main.async {
                        self.friendAvatar.image = resized
                        if ThemeEngine.enableProfileTinting {
                            if let backgroundGlass = self.backgroundGlass as? LiquidGlassView {
                                backgroundGlass.tintColorForGlass = color
                            } else {
                                self.backgroundGlass?.backgroundColor = color
                            }
                        }
                    }
                } else {
                    let defaultPFP = UIImage(named: "defaultavatar")!
                    let resized = defaultPFP.resizeImage(defaultPFP, targetSize: .init(width: 40, height: 40))
                    DispatchQueue.main.async {
                        self.friendAvatar.image = resized
                        if let backgroundGlass = self.backgroundGlass as? LiquidGlassView {
                            backgroundGlass.tintColorForGlass = .blue
                        } else {
                            self.backgroundGlass?.backgroundColor = .blue
                        }
                    }
                }
            }
        }
    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileClick(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func profileClick(_ gesture: UITapGestureRecognizer) {
        if #available(iOS 10.0, *) {
            let haptic = UISelectionFeedbackGenerator()
            haptic.selectionChanged()
        }
        if let textVC = self.parentViewController as? ViewController {
            if let friend = self.friend {
                textVC.presentProfileView(for: friend)
            }
        }
    }
}
