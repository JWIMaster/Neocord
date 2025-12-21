import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import SFSymbolsCompatKit




public enum PresenceColor {
    static func color(for presence: PresenceType) -> UIColor {
        switch presence {
        case .online:
            return .onlineGreen
        case .idle:
            return .idleOrange
        case .dnd:
            return .dndRed
        case .offline:
            return .offlineGray
        }
    }
}

public extension UIColor {
    class var onlineGreen: UIColor {
        return UIColor(red: 85.0/255.0, green: 239.0/255.0, blue: 196.0/255.0, alpha: 0.7)
    }
    
    class var idleOrange: UIColor {
        return UIColor(red: 253.0/255.0, green: 203.0/255.0, blue: 110.0/255.0, alpha: 0.7)
    }
    
    class var dndRed: UIColor {
        return UIColor(red: 235.0/255.0, green: 59.0/255.0, blue: 90.0/255.0, alpha: 0.7)
    }
    
    class var offlineGray: UIColor {
        return UIColor(red: 116.0/255.0, green: 125.0/255.0, blue: 140.0/255.0, alpha: 0.7)
    }
}

class DMButtonCell: UICollectionViewCell, UIGestureRecognizerDelegate {

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
            let lg = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            lg.shadowOpacity = 0
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

    private lazy var presenceIndicator: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 6, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.shadowColor = presenceColor.withAlphaComponent(1).cgColor
            glass.shadowRadius = 6
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
    
    private var recipientIDs = Set<Snowflake>()
    
    var presenceUpdateObserver: NSObjectProtocol?
    
    var dm: DMChannel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        guard let backgroundGlass = backgroundGlass else { return }

        contentView.addSubview(backgroundGlass)
        contentView.addSubview(stack)
        stack.addArrangedSubview(dmAuthorAvatar)
        stack.addArrangedSubview(dmNameLabel)
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

            dmAuthorAvatar.widthAnchor.constraint(equalToConstant: 40),
            dmAuthorAvatar.heightAnchor.constraint(equalToConstant: 40),

            presenceIndicator.widthAnchor.constraint(equalToConstant: 12),
            presenceIndicator.heightAnchor.constraint(equalToConstant: 12),

            presenceIndicator.bottomAnchor.constraint(equalTo: dmAuthorAvatar.bottomAnchor),
            presenceIndicator.trailingAnchor.constraint(equalTo: dmAuthorAvatar.trailingAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        presenceColor = .offlineGray
        updatePresenceIndicatorColor()
        dmAuthorAvatar.image = nil
        dmNameLabel.text = nil
        recipientIDs.removeAll()
    }

    private func updatePresenceIndicatorColor() {
        if let glass = presenceIndicator as? LiquidGlassView {
            glass.tintColorForGlass = presenceColor
            glass.shadowColor = presenceColor.cgColor
        } else {
            presenceIndicator.backgroundColor = presenceColor
        }
    }
    
    deinit {
        if let observer = self.presenceUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.presenceUpdateObserver = nil
    }

    func configure(with dm: DMChannel) {
        switch dm.type {
        case .dm:
            guard let dm = dm as? DM, let recipient = dm.recipient else { return }
            dmNameLabel.text = recipient.nickname ?? recipient.displayname ?? recipient.username
            self.dm = dm
            
            // Keep track of the current user ID for this cell
            let currentRecipientID = recipient.id
            self.recipientIDs.insert(currentRecipientID!)
            
            // Set initial presence
            let presence = activeClient.presences[currentRecipientID!] ?? .offline
            presenceColor = PresenceColor.color(for: presence)
            updatePresenceIndicatorColor()
            
            /*clientUser.gateway?.addPresenceUpdateObserver { [weak self] presenceDict in
                guard let self = self, let updatedPresence = presenceDict[currentRecipientID!] else { return }
                self.presenceColor = PresenceColor.color(for: updatedPresence)
                DispatchQueue.main.async {
                    if self.recipientIDs.contains(recipient.id!) {
                        self.updatePresenceIndicatorColor()
                    }
                }
            }*/
            
            presenceUpdateObserver = NotificationCenter.default.addObserver(forName: .presenceUpdate, object: nil, queue: .main) { [weak self] notification in
                guard let self = self else { return }
                if let presenceDict = notification.object as? [Snowflake: PresenceType], let updatedPresence = presenceDict[currentRecipientID!] {
                    self.presenceColor = PresenceColor.color(for: updatedPresence)
                    DispatchQueue.main.async {
                        if self.recipientIDs.contains(recipient.id!) {
                            self.updatePresenceIndicatorColor()
                        }
                    }
                }
            }
            
            // Load avatar asynchronously
            AvatarCache.shared.avatar(for: recipient) { [weak self] image, color in
                guard let self = self, let image = image, let color = color else { return }
                
                let resized = image.resizeImage(image, targetSize: CGSize(width: 40, height: 40))
                
                DispatchQueue.main.async {
                    if self.recipientIDs.contains(recipient.id!) {
                        self.dmAuthorAvatar.image = resized
                        if ThemeEngine.enableProfileTinting {
                            if let glass = self.backgroundGlass as? LiquidGlassView {
                                glass.tintColorForGlass = color
                                //glass.shadowColor = color.cgColor
                            } else {
                                self.backgroundGlass?.backgroundColor = color
                            }
                        }
                    }
                }
            }

        case .groupDM:
            guard let dm = dm as? GroupDM else { return }
            dmNameLabel.text = dm.name
            
            DispatchQueue.global(qos: .userInitiated).async {
                let defaultImage = UIImage(named: "defaultavatar")!.resizeImage(UIImage(named: "defaultavatar")!, targetSize: CGSize(width: 40, height: 40))
                DispatchQueue.main.async {
                    self.dmAuthorAvatar.image = defaultImage
                    if ThemeEngine.enableProfileTinting {
                        if let glass = self.backgroundGlass as? LiquidGlassView {
                            glass.tintColorForGlass = UIColor.blue.withAlphaComponent(0.5)
                        } else {
                            self.backgroundGlass?.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
                        }
                    }
                }
            }
            
        default:
            break
        }
    }

}








