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
    
    private var friend: User?
    
    var presenceUpdateObserver: NSObjectProtocol?
    
    private lazy var presenceIndicator: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 6, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
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

    deinit {
        if let observer = self.presenceUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.presenceUpdateObserver = nil
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
        
        /*clientUser.gateway?.addPresenceUpdateObserver { [weak self] presenceDict in
            guard let self = self, let updatedPresence = presenceDict[user.id!] else { return }
            self.presenceColor = PresenceColor.color(for: updatedPresence)
            DispatchQueue.main.async {
                if self.friend?.id == user.id {
                    self.updatePresenceIndicatorColor()
                }
            }
        }*/
        
        presenceUpdateObserver = NotificationCenter.default.addObserver(forName: .presenceUpdate, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if let presenceDict = notification.object as? [Snowflake: PresenceType], let updatedPresence = presenceDict[user.id!] {
                self.presenceColor = PresenceColor.color(for: updatedPresence)
                DispatchQueue.main.async {
                    if self.friend?.id == user.id {
                        self.updatePresenceIndicatorColor()
                    }
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

import UIKit

public final class FeltView: UIView {

    public var feltColor: UIColor = UIColor(red: 0.88, green: 0.16, blue: 0.16, alpha: 1) {
        didSet { updateColors() }
    }

    public var cornerRadius: CGFloat = 14 {
        didSet { layer.cornerRadius = cornerRadius }
    }

    private let baseLayer = CAGradientLayer()
    private let fibreLayer = CAReplicatorLayer()
    private let fibrePrototype = CALayer()
    private let noiseLayer = CAReplicatorLayer()
    private let noiseDot = CALayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {

        clipsToBounds = true
        layer.cornerRadius = cornerRadius

        // BASE FELT GRADIENT
        baseLayer.colors = [
            feltColor.withAlphaComponent(1).cgColor,
            feltColor.withAlphaComponent(0.92).cgColor
        ]
        baseLayer.startPoint = CGPoint(x: 0, y: 0)
        baseLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(baseLayer)

        // FIBRES (soft long strands)
        fibreLayer.instanceCount = 180
        fibreLayer.instanceTransform = CATransform3DMakeTranslation(0, 1.2, 0)
        fibreLayer.instanceAlphaOffset = -0.004

        fibrePrototype.backgroundColor = UIColor.white.withAlphaComponent(0.035).cgColor
        fibrePrototype.cornerRadius = 1
        fibreLayer.addSublayer(fibrePrototype)
        layer.addSublayer(fibreLayer)

        // NOISE SPECKS
        noiseLayer.instanceCount = 260
        noiseLayer.instanceTransform = CATransform3DMakeTranslation(1.5, 0, 0)
        noiseLayer.instanceAlphaOffset = -0.003

        noiseDot.backgroundColor = UIColor.white.withAlphaComponent(0.06).cgColor
        noiseDot.cornerRadius = 0.6
        noiseLayer.addSublayer(noiseDot)
        layer.addSublayer(noiseLayer)

        backgroundColor = .clear
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        baseLayer.frame = bounds

        // fibres: long faint lines
        fibrePrototype.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: 1.2
        )
        fibreLayer.frame = bounds

        // noise: tiny dots scattered
        noiseDot.frame = CGRect(x: 0, y: 0, width: 1.2, height: 1.2)
        noiseLayer.frame = bounds

        // scatter noise more by randomising base position
        noiseDot.position = CGPoint(
            x: CGFloat.random(in: 0...bounds.width),
            y: CGFloat.random(in: 0...bounds.height)
        )
    }

    private func updateColors() {
        baseLayer.colors = [
            feltColor.cgColor,
            feltColor.withAlphaComponent(0.92).cgColor
        ]
    }
}
