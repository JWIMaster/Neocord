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
    var messageIDsInStack = Set<Snowflake>()
    var userIDsInStack = Set<Snowflake>()
    var initialViewSetupComplete = false
    var profileView: ProfileView?
    
    let backgroundGradient = CAGradientLayer()
    let scrollView = UIScrollView()
    let containerView = UIView()
    var containerViewBottomConstraint: NSLayoutConstraint!
    
    var tapGesture: UITapGestureRecognizer!
    
    var observers = [NSObjectProtocol]()
    
    var requestedUserIDs = Set<Snowflake>()
    
    var isKeyboardVisible = false
    
    let logger = LegacyLogger(fileName: "legacy_debug.txt")
    
    var messageStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    func requestMemberIfNeeded(_ userID: Snowflake) {
        guard !requestedUserIDs.contains(userID), let guildID = channel?.guild?.id else { return }
        requestedUserIDs.insert(userID)
        clientUser.gateway?.requestGuildMemberChunk(guildId: guildID, userIds: [userID])
    }
    
    var profileBlur = LiquidGlassView(blurRadius: 12, cornerRadius: 0, snapshotTargetView: nil, disableBlur: false, filterOptions: [])
    
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
    }
    
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
        addTopAndBottomShadows(to: self.view, shadowHeight: 50)
        
        //animatedBackground()
        
        guard let gateway = clientUser.gateway else { return }
        
        gateway.onReconnect = { [weak self] in
            guard let self = self else { return }
            self.attachGatewayObservers()
        }
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
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.height),
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



