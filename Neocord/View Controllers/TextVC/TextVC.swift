//
//  DMView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 19/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost


class TextViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    public var dm: DMChannel?
    public var channel: GuildChannel?
    var textInputView: InputView?
    var bubbleActionView: BubbleActionView?
    var messageIDsInStack = Set<Snowflake>()
    var userIDsInStack = Set<Snowflake>()
    var initialViewSetupComplete = false
    var profileView: ProfileView?
    
    let backgroundGradient = CAGradientLayer()
    let scrollView = UIScrollView()
    let containerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    var containerViewBottomConstraint: NSLayoutConstraint!
    var lastUserToSpeak: User?
    var secondLastUserToSpeak: User?
    
    var tapGesture: UITapGestureRecognizer!
    
    var backGesture: UIPanGestureRecognizer!
    
    var observers = [NSObjectProtocol]()
    
    var requestedUserIDs = Set<Snowflake>()
    
    var isKeyboardVisible = false
    
    let logger = LegacyLogger(fileName: "legacy_debug.txt")
    
    var messageCreateObserver: NSObjectProtocol?
    var messageDeleteObserver: NSObjectProtocol?
    var messageUpdateObserver: NSObjectProtocol?
    var typingStartObserver: NSObjectProtocol?
    
    var messageStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    var topOffset: CGFloat {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets.top
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
    
    func requestMemberIfNeeded(_ userID: Snowflake) {
        guard !requestedUserIDs.contains(userID), let guildID = channel?.guild?.id else { return }
        requestedUserIDs.insert(userID)
        activeClient.gateway?.requestGuildMemberChunk(guildId: guildID, userIds: [userID])
    }
    
    var profileBlur = LiquidGlassView(blurRadius: 12, cornerRadius: 0, snapshotTargetView: nil, disableBlur: false, filterExclusions: [.highlight, .depth, .darken, .innerShadow, .tint, .rim])
    
    public init(dm: DMChannel? = nil, channel: GuildChannel? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.dm = dm
        self.channel = channel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        safelyRemoveScrollView()
        if let observer = messageCreateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = messageDeleteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = messageUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = typingStartObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        messageCreateObserver = nil
        messageUpdateObserver = nil
        messageDeleteObserver = nil
        typingStartObserver = nil
    }

    
    var isAtBottom: Bool {
        if let inputView = textInputView {
            let inputFrameInScroll = scrollView.convert(inputView.frame, from: inputView.superview)
            for view in messageStack.arrangedSubviews {
                let viewFrameInScroll = scrollView.convert(view.frame, from: view.superview)
                if inputFrameInScroll.intersects(viewFrameInScroll) {
                    return false
                }
            }
        }
        return true
    }
    
    var refreshControl = UIRefreshControl()
    
    func safelyRemoveScrollView() {
        scrollView.delegate = nil
        scrollView.layer.removeAllAnimations()
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        scrollView.removeFromSuperview()
    }

    
    override func viewDidLoad() {
        view.backgroundColor = .discordGray
        
        title = {
            if let channel = channel {
                return channel.name
            } else if let dm = dm {
                if let dm = dm as? DM {
                    return dm.recipient?.nickname ?? dm.recipient?.displayname ?? dm.recipient?.username
                } else if let dm = dm as? GroupDM {
                    return dm.name
                } else {
                    return "Unknown"
                }
            } else {
                return "Unknown"
            }
        }()
        
        
        
        if #unavailable(iOS 7.0.1) {
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(self, true)
        }
        
        setupKeyboardObservers()
        setupSubviews()
        setupConstraints()
        getMessages()
        attachGatewayObservers()
        setupScrollView()
        addTopAndBottomShadows(to: self.view, shadowHeight: 50)
        //animatedBackground()
        
        guard let gateway = activeClient.gateway else { return }
        
        gateway.onReconnect = { [weak self] in
            guard let self = self else { return }
            self.attachGatewayObservers()
        }
    }
    
    
    func setupScrollView() {
        self.refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        self.scrollView.refreshControl = self.refreshControl
    }
    
    @objc func didPullToRefresh() {
        self.getMessagesBeforeTopMessage()
        self.refreshControl.endRefreshing()
    }
    
    func setupSubviews() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        messageStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(messageStack)
        scrollView.delegate = self
        
        containerView.alpha = 0
        
    }
    
    func setupConstraints() {
        messageStack.pinToEdges(of: scrollView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        messageStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        scrollView.pinToEdges(of: containerView)
        scrollView.pinToCenter(of: containerView)
        
        if #available(iOS 11.0, *) {
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.height).isActive = true
        }
        
        NSLayoutConstraint.activate([
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        
        if #available(iOS 11.0, *) {
            containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            view.addConstraint(containerViewBottomConstraint)
        } else {
            containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            containerViewBottomConstraint.isActive = true
        }
        
    }
    
    func addTopAndBottomShadows(to view: UIView, shadowHeight: CGFloat = 50) {
        // Top shadow
        let topShadow = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: shadowHeight))
        let topGradient = CAGradientLayer()
        topGradient.frame = topShadow.bounds
        topGradient.colors = [UIColor.black.withAlphaComponent(0.3).cgColor, UIColor.clear.cgColor]
        topGradient.startPoint = CGPoint(x: 0.5, y: 0)
        topGradient.endPoint = CGPoint(x: 0.5, y: 1)
        topShadow.layer.addSublayer(topGradient)
        topShadow.isUserInteractionEnabled = false
        view.addSubview(topShadow)
        
        // Bottom shadow
        let bottomShadow = UIView(frame: CGRect(x: 0, y: view.bounds.height - shadowHeight, width: view.bounds.width, height: shadowHeight))
        let bottomGradient = CAGradientLayer()
        bottomGradient.frame = bottomShadow.bounds
        bottomGradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.3).cgColor]
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1)
        bottomShadow.layer.addSublayer(bottomGradient)
        bottomShadow.isUserInteractionEnabled = false
        view.addSubview(bottomShadow)
        
        // Optional: make sure shadows resize with the view
        topShadow.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        bottomShadow.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
    }
    
    
    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0,y: max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom))
        scrollView.setContentOffset(bottomOffset, animated: animated)
    }

    
    var navigationBarHeight: CGFloat {
        return navigationController?.navigationBar.frame.height ?? 0
    }
    
  
    var currentlyVisibleViews = NSHashTable<UIView>.weakObjects()

    private var backSwipeLocked = false
    private let scrollLockThreshold: CGFloat = 5 // points

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        backSwipeLocked = false
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if ThemeEngine.enableAnimations {
            switch device {
            case .a4, .a5, .a6:
                break
            default:
                for view in messageStack.arrangedSubviews {
                    let viewFrameInScroll = scrollView.convert(view.frame, from: view.superview)
                    let isVisibleNow = scrollView.bounds.intersects(viewFrameInScroll)
                    
                    if isVisibleNow && !currentlyVisibleViews.contains(view) {
                        currentlyVisibleViews.add(view)
                        view.springAnimation(bounceAmount: -4)
                    } else if !isVisibleNow && currentlyVisibleViews.contains(view) {
                        currentlyVisibleViews.remove(view)
                    }
                }
            }
        }
    }
}




import UIKit
import ObjectiveC

private var RefreshControlKey: UInt8 = 0

extension UIScrollView {

    @available(iOS, introduced: 6.0, deprecated: 10.0)
    public var refreshControl: UIRefreshControl? {
        get {
            return objc_getAssociatedObject(self, &RefreshControlKey) as? UIRefreshControl
        }
        set {
            let old = refreshControl
            old?.removeFromSuperview()

            objc_setAssociatedObject(
                self,
                &RefreshControlKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            guard let control = newValue else { return }

            if let tableView = self as? UITableView {
                tableView.backgroundView?.addSubview(control)
                tableView.backgroundView = UIView()
                tableView.addSubview(control)
            } else if let collectionView = self as? UICollectionView {
                collectionView.addSubview(control)
            } else {
                addSubview(control)
            }
        }
    }
}
