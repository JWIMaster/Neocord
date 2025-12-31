//
//  DMsCollectionViewController.swift
//  MakingADiscordAPI
//
//  Created by JWI on 24/10/2025.
//

import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import iOS6BarFix
import LiveFrost
import SFSymbolsCompatKit
import FoundationCompatKit

#if !targetEnvironment(macCatalyst)
#if compiler(<6.0)
#if !MODERN_BUILD
public typealias UIStackView = UIKitCompatKit.UIStackView
#endif
#endif
#endif

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var dms: [DMChannel] {
        get {
            return Array(activeClient.dms.values).sorted { $0.lastMessageID?.rawValue ?? 0 > $1.lastMessageID?.rawValue ?? 0 }
        }
        set {
            for dm in newValue {
                if let id = dm.id {
                    activeClient.dms[id] = dm
                }
            }
        }
    }
    
    var orderedGuilds: [Guild] = []
    
    var guilds: [Snowflake: Guild] {
        get {
            return activeClient.guilds
        }
        set {
            for (id, guild) in newValue {
                activeClient.guilds[id] = guild
            }
        }
    }
    
    var activeGuildChannels: [GuildChannel] = []
    
    var mainView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var offset: CGFloat {
        if #available(iOS 11.0, *) {
            return (self.navigationController?.navigationBar.frame.height)! + view.safeAreaInsets.top
        } else {
            return UIApplication.shared.statusBarFrame.height+(self.navigationController?.navigationBar.frame.height)!
        }
    }
    
    var expandedFolderIDs: Set<String> {
        get {
            if let array = UserDefaults.standard.array(forKey: "expandedFolderIDs") as? [String] {
                return Set(array)
            }
            return []
        }
        set {
            let array = Array(newValue)
            UserDefaults.standard.set(array, forKey: "expandedFolderIDs")
            UserDefaults.standard.synchronize()
        }
    }
    
    var sidebarButtons: [SidebarButtonType] = []
    var profileView: ProfileView?
    let activeContentView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            return glass
        } else {
            let bg = UIView()
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            bg.layer.cornerRadius = 22
            bg.translatesAutoresizingMaskIntoConstraints = false
            return bg
        }
    }()
    
    lazy var dmCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(DMButtonCell.self, forCellWithReuseIdentifier: DMButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    lazy var sidebarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.layer.cornerRadius = 18
        cv.register(SidebarButtonCell.self, forCellWithReuseIdentifier: SidebarButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    lazy var channelsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(ChannelButtonCell.self, forCellWithReuseIdentifier: ChannelButtonCell.reuseID)
        cv.register(ChannelCategoryCell.self, forCellWithReuseIdentifier: "ChannelCategoryCell")

        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    var navigationBarHeight: CGFloat {
        return navigationController?.navigationBar.frame.height ?? 0
    }
    
    var sidebarBackgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            return glass
        } else {
            let bg = UIView()
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.layer.cornerRadius = 22
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            return bg
        }
    }()
    
    var toolbar: CustomToolbar = {
        let toolbar = CustomToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()
    
    
    var activeGuild: Guild? {
        get {
            guard let id = _activeGuildID else { return nil }
            return activeClient.guilds[id] // always get the up-to-date object
        }
        set {
            _activeGuildID = newValue?.id
        }
    }
    private var _activeGuildID: Snowflake?
    
    var readyProcessedObserver: NSObjectProtocol?
    
    var displayedChannels: [GuildChannel] = []
    
    var settingsView: SettingsView = {
        let settingsView = SettingsView()
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.isHidden = true
        return settingsView
    }()
    
    var friendsView: FriendsView = {
        let fview = FriendsView()
        fview.translatesAutoresizingMaskIntoConstraints = false
        fview.isHidden = true
        return fview
    }()
    
    var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var settingsButton: UIButton = {
        let button1 = UIButton(type: .custom)
        button1.setTitle("Settings", for: .normal)
        button1.titleLabel?.font = .systemFont(ofSize: 12)
        button1.translatesAutoresizingMaskIntoConstraints = false
        button1.setImage(.init(systemName:"person.fill", tintColor: .white), for: .normal)
        return button1
    }()
    
    var mainMenuButton: UIButton = {
        let button2 = UIButton(type: .custom)
        button2.setTitle("Menu", for: .normal)
        button2.titleLabel?.font = .systemFont(ofSize: 12)
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.setImage(.init(systemName:"list.bullet.below.rectangle", tintColor: .white), for: .normal)
        return button2
    }()
    
    var friendsButton: UIButton = {
        let button2 = UIButton(type: .custom)
        button2.setTitle("Friends", for: .normal)
        button2.titleLabel?.font = .systemFont(ofSize: 12)
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.setImage(.init(systemName:"person.crop.circle.fill.badge.checkmark", tintColor: .white), for: .normal)
        return button2
    }()
    
    lazy var currentlyActiveView: UIView = mainView
    
    var loadingView: LoadingView = {
        let loading = LoadingView()
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.transform = CGAffineTransform(translationX: 0, y: -50)
        loading.alpha = 0
        loading.isUserInteractionEnabled = false
        return loading
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activeClient.connect()
        
        activeClient.loadCache {
            self.setupOrderedGuilds()
            self.rebuildSidebarButtons()
            self.setupMainView()
        }
    }
    
    func setupMainView() {
        title = "Direct Messages"
        view.backgroundColor = .discordGray
        if #unavailable(iOS 7.0.1) {
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(self, true)
        }
        
        
        setupMainViewSubviews()
        setupConstraints()
        showLoadingView()
        setupButtonActions()
        setupToolbar()
        readyWatcher()
        
        if ThemeEngine.enableAnimations {
            activeContentView.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
            toolbar.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
            sidebarBackgroundView.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
        }
    }
    
    func setupMainViewSubviews() {
        view.addSubview(containerView)
        containerView.addSubview(mainView)
        containerView.addSubview(settingsView)
        containerView.addSubview(friendsView)
        
        mainView.addSubview(sidebarBackgroundView)
        
        mainView.addSubview(activeContentView)
        
        sidebarBackgroundView.addSubview(sidebarCollectionView)
        
        view.addSubview(toolbar)
    }
    
    func showLoadingView() {
        self.mainView.addSubview(loadingView)
        UIView.animate(withDuration: 0.5) {
            self.loadingView.transform = CGAffineTransform(translationX: 0, y: 0)
            self.loadingView.alpha = 1
        }
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 6),
            loadingView.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
        ])
    }
    
    func hideLoadingView() {
        UIView.animate(withDuration: 0.5) {
            self.loadingView.alpha = 0
            self.loadingView.transform = CGAffineTransform(translationX: 0, y: -50)
        } completion: { _ in
            self.loadingView.removeFromSuperview()
        }
    }

    
    func readyWatcher() {
        /*clientUser.onReady = {
            DispatchQueue.main.async {
                self.hideLoadingView()
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.setupOrderedGuilds()
                self.rebuildSidebarButtons()
                self.channelsCollectionView.reloadData()
                self.sidebarCollectionView.reloadData()
                self.dmCollectionView.reloadData()
                self.friendsContainerView.reloadFriends()
                CATransaction.commit()
            }
        }*/
        readyProcessedObserver =  NotificationCenter.default.addObserver(forName: .readyProcessed, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideLoadingView()
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.setupOrderedGuilds()
                self.rebuildSidebarButtons()
                self.channelsCollectionView.reloadData()
                self.sidebarCollectionView.reloadData()
                self.dmCollectionView.reloadData()
                self.friendsView.reloadFriends()
                CATransaction.commit()
            }
        }
    }
    
    deinit {
        if let observer = self.readyProcessedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.readyProcessedObserver = nil
    }
    
    func setupToolbar() {
        toolbar.setItems([mainMenuButton, friendsButton, settingsButton])
    }
    
    func setupButtonActions() {
        if ThemeEngine.isHighPowerDevice {
            self.mainMenuButton.layer.shadowOpacity = 0.6
            self.mainMenuButton.layer.shadowRadius = 12
            self.mainMenuButton.layer.shadowColor = .white
        }
        
        settingsButton.addAction(for: .touchUpInside) {
            self.settingsButton.isUserInteractionEnabled = false
            
            if ThemeEngine.isHighPowerDevice {
                UIView.animate(withDuration: 0.5) {
                    self.settingsButton.layer.shadowColor = .white
                    self.settingsButton.layer.shadowOpacity = 0.6
                    self.settingsButton.layer.shadowRadius = 12
                    
                    self.friendsButton.layer.shadowOpacity = 0
                    self.friendsButton.layer.shadowRadius = 0
                    self.friendsButton.layer.shadowColor = .clear
                    
                    self.mainMenuButton.layer.shadowOpacity = 0
                    self.mainMenuButton.layer.shadowRadius = 0
                    self.mainMenuButton.layer.shadowColor = .clear
                }
            }
            
            UIView.transition(from: self.currentlyActiveView, to: self.settingsView, in: self.containerView) {
                self.mainMenuButton.isUserInteractionEnabled = true
                self.friendsButton.isUserInteractionEnabled = true
                self.currentlyActiveView = self.settingsView
            }
            
            if ThemeEngine.enableAnimations {
                self.settingsView.springAnimation()
            }
        }
        
        friendsButton.addAction(for: .touchUpInside) {
            self.friendsButton.isUserInteractionEnabled = false
            if ThemeEngine.isHighPowerDevice {
                UIView.animate(withDuration: 0.5) {
                    self.friendsButton.layer.shadowColor = .white
                    self.friendsButton.layer.shadowOpacity = 0.6
                    self.friendsButton.layer.shadowRadius = 12
                    
                    self.mainMenuButton.layer.shadowOpacity = 0
                    self.mainMenuButton.layer.shadowRadius = 0
                    self.mainMenuButton.layer.shadowColor = .clear
                    
                    self.settingsButton.layer.shadowOpacity = 0
                    self.settingsButton.layer.shadowRadius = 0
                    self.settingsButton.layer.shadowColor = .clear
                }
            }
            
            UIView.transition(from: self.currentlyActiveView, to: self.friendsView, in: self.containerView) {
                self.mainMenuButton.isUserInteractionEnabled = true
                self.settingsButton.isUserInteractionEnabled = true
                self.currentlyActiveView = self.friendsView
            }
            
            if ThemeEngine.enableAnimations {
                self.friendsView.springAnimation()
            }
        }
        
        mainMenuButton.addAction(for: .touchUpInside) {
            self.mainMenuButton.isUserInteractionEnabled = false
            
            if ThemeEngine.isHighPowerDevice {
                UIView.animate(withDuration: 0.5) {
                    self.mainMenuButton.layer.shadowColor = .white
                    self.mainMenuButton.layer.shadowOpacity = 0.6
                    self.mainMenuButton.layer.shadowRadius = 12
                    
                    self.friendsButton.layer.shadowOpacity = 0
                    self.friendsButton.layer.shadowRadius = 0
                    self.friendsButton.layer.shadowColor = .clear
                    
                    self.settingsButton.layer.shadowOpacity = 0
                    self.settingsButton.layer.shadowRadius = 0
                    self.settingsButton.layer.shadowColor = .clear
                }
            }

            UIView.transition(from: self.currentlyActiveView, to: self.mainView, in: self.containerView) {
                self.settingsButton.isUserInteractionEnabled = true
                self.friendsButton.isUserInteractionEnabled = true
                self.currentlyActiveView = self.mainView
            }
            
            if ThemeEngine.enableAnimations {
                self.mainView.springAnimation()
            }
        }
    }
    
    func rebuildSidebarButtons() {
        var items: [SidebarButtonType] = [.dms]

        guard let folders = activeClient.clientUserSettings?.guildFolders else {
            items.append(contentsOf: orderedGuilds.map { .guild($0) })
            sidebarButtons = items
            return
        }

        for folder in folders {
            guard let guildIDs = folder.guildIDs else { continue }
            let guildsInFolder = orderedGuilds.filter { guildIDs.contains($0.id!) }

            // Skip showing folder if it has only one guild
            if guildsInFolder.count == 1 {
                items.append(.guild(guildsInFolder[0]))
                continue
            }
            
            //If there's no ID, we have to give it one.
            if folder.id == nil || folder.id?.description == "" {
                let uuidString = UUID().uuidString
                let digitsString = uuidString.compactMap { $0.wholeNumberValue }.map(String.init).joined()
                folder.id = Int(digitsString.prefix(9))
            }
            
            let folderKey = folder.id?.description ?? ""
            let isExpanded = UserDefaults.standard.bool(forKey: folderKey)
            // Add the folder with its persisted expanded state
            items.append(.folder(folder, isExpanded: isExpanded))

            // If it’s expanded, add its guilds
            if isExpanded {
                items.append(contentsOf: guildsInFolder.map { .guild($0) })
            }
        }

        sidebarButtons = items
    }

    func setupOrderedGuilds() {
        guard let settings = activeClient.clientUserSettings else { return }
        let guildFolders = settings.guildFolders
        var orderID: [Snowflake] = []
        guard let guildFolders = guildFolders else {
            return
        }
        
        for folder in guildFolders {
            guard let guildIDs = folder.guildIDs else { return }
            for id in guildIDs {
                orderID.append(id)
            }
        }
        
        let orderedGuilds = orderID.compactMap { guildId in
            return self.guilds.values.first { $0.id == guildId }
        }

        
        self.orderedGuilds = orderedGuilds
        
        self.sidebarCollectionView.reloadData()
    }
    
    func refreshView() {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    func setupConstraints() {

        // MARK: Toolbar layout
        if let customController = navigationController as? CustomNavigationController {
            NSLayoutConstraint.activate([
                toolbar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                toolbar.widthAnchor.constraint(equalToConstant: customController.navBarFrame.frame.width - 20),
                toolbar.heightAnchor.constraint(equalToConstant: customController.navBarFrame.frame.height)
            ])
            
            if #available(iOS 11.0, *) {
                toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
            } else {
                toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
            }
        }

        // MARK: Container view
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: offset),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        ])
        
        mainView.pinToEdges(of: containerView)
        
        settingsView.pinToEdges(of: containerView, insetBy: .init(top: 10, left: 10, bottom: 10, right: 10))
        friendsView.pinToEdges(of: containerView, insetBy: .init(top: 10, left: 10, bottom: 10, right: 10))

        // MARK: Sidebar
        NSLayoutConstraint.activate([
            sidebarBackgroundView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 10),
            sidebarBackgroundView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 10),
            sidebarBackgroundView.widthAnchor.constraint(equalToConstant: 64),
            sidebarBackgroundView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -10)
        ])

        // MARK: Active content area
        NSLayoutConstraint.activate([
            activeContentView.leadingAnchor.constraint(equalTo: sidebarBackgroundView.trailingAnchor, constant: 10),
            activeContentView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 10),
            activeContentView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -10),
            activeContentView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -10)
        ])

        // MARK: Sidebar collection
        sidebarCollectionView.pinToEdges(of: sidebarBackgroundView, insetBy: .init(top: 6, left: 6, bottom: 6, right: 6))
    }

    
    
    func showContentView(_ view: UIView) {
        activeContentView.subviews.forEach { $0.removeFromSuperview() }
        
        activeContentView.addSubview(view)
        view.layer.cornerRadius = 22
        view.translatesAutoresizingMaskIntoConstraints = false
        view.pinToEdges(of: activeContentView)
    }
    
    
   

    func flattenChannelsForDisplay() {
        guard let guild = activeGuild else { return }
        displayedChannels.removeAll()
        let textChannels = guild.channels.values.compactMap { $0 as GuildChannel }
            .filter { !($0 is GuildCategory) }

        // Get categories
        let categories = guild.channels.values.compactMap { $0 as? GuildCategory }

        // Sort categories based on the highest-positioned child channel
        let sortedCategories = categories.sorted { category1, category2 in
            let maxPos1 = textChannels.filter { $0.parentID == category1.id }.map { $0.position ?? 0 }.max() ?? 0
            let maxPos2 = textChannels.filter { $0.parentID == category2.id }.map { $0.position ?? 0 }.max() ?? 0
            return maxPos2 > maxPos1// higher channels first
        }

        for category in sortedCategories {
            displayedChannels.append(category)

            let channelsInCategory = textChannels.filter { $0.parentID == category.id }.sorted { ($0.position ?? 0) < ($1.position ?? 0) }

            displayedChannels.append(contentsOf: channelsInCategory)
        }

        // Add uncategorized channels at the end
        //let uncategorized = textChannels.filter { $0.parentID == nil || categories.first(where: { $0.id == $0.parentID }) == nil }.sorted { ($0.position ?? 0) < ($1.position ?? 0) }

        //displayedChannels.append(contentsOf: uncategorized)
        
        channelsCollectionView.reloadData()
    }
}





public extension UIView {

    class func transition(
        from oldView: UIView?,
        to newView: UIView,
        in container: UIView,
        animated: Bool = true,
        duration: TimeInterval = 0.25,
        completionHandler: @escaping () -> Void
    ) {
        guard newView !== oldView else { return }

        newView.alpha = 0
        newView.isHidden = false
        container.bringSubviewToFront(newView)

        let animations = {
            oldView?.alpha = 0
            newView.alpha = 1
        }

        let completion: (Bool) -> Void = { _ in
            oldView?.isHidden = true
            completionHandler()
        }

        if animated {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseInOut],
                animations: animations,
                completion: completion
            )
        } else {
            animations()
            completion(true)
        }
    }
}
