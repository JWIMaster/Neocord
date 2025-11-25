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
            return Array(clientUser.dms.values).sorted { $0.lastMessageID?.rawValue ?? 0 > $1.lastMessageID?.rawValue ?? 0 }
        }
        set {
            for dm in newValue {
                if let id = dm.id {
                    clientUser.dms[id] = dm
                }
            }
        }
    }
    
    var orderedGuilds: [Guild] = []
    
    var guilds: [Snowflake: Guild] {
        get {
            return clientUser.guilds
        }
        set {
            for (id, guild) in newValue {
                clientUser.guilds[id] = guild
            }
        }
    }
    
    var activeGuildChannels: [GuildChannel] = []
    
    var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var offset: CGFloat {
        return UIApplication.shared.statusBarFrame.height+(self.navigationController?.navigationBar.frame.height)!
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
    
    var sidebarBackgroundView: UIView? = {
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
            return clientUser.guilds[id] // always get the up-to-date object
        }
        set {
            _activeGuildID = newValue?.id
        }
    }
    private var _activeGuildID: Snowflake?
    
    var displayedChannels: [GuildChannel] = []
    
    var settingsContainerView: SettingsView = {
        let settingsView = SettingsView()
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.isHidden = true
        return settingsView
    }()
    
    var friendsContainerView: FriendsView = {
        let fview = FriendsView()
        fview.translatesAutoresizingMaskIntoConstraints = false
        fview.isHidden = true
        return fview
    }()
    
    var mainContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var settingsButton: UIButton = {
        let button1 = UIButton(type: .custom)
        button1.setTitle("Settings", for: .normal)
        button1.translatesAutoresizingMaskIntoConstraints = false
        button1.setImage(.init(systemName:"person.fill", tintColor: .white), for: .normal)
        return button1
    }()
    
    var mainMenuButton: UIButton = {
        let button2 = UIButton(type: .custom)
        button2.setTitle("Menu", for: .normal)
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.setImage(.init(systemName:"list.bullet.below.rectangle", tintColor: .white), for: .normal)
        return button2
    }()
    
    var friendsButton: UIButton = {
        let button2 = UIButton(type: .custom)
        button2.setTitle("Friends", for: .normal)
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.setImage(.init(systemName:"person.2.fill", tintColor: .white), for: .normal)
        return button2
    }()
    
    lazy var currentlyActiveView: UIView = containerView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clientUser.connect()
        
        clientUser.loadCache {
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
        setupButtonActions()
        setupToolbar()
        readyWatcher()
        
        if ThemeEngine.enableAnimations {
            activeContentView.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
            toolbar.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
            sidebarBackgroundView?.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
        }
    }
    
    func setupMainViewSubviews() {
        guard let sidebarBackgroundView = sidebarBackgroundView else { return }
        view.addSubview(mainContainerView)
        mainContainerView.addSubview(containerView)
        mainContainerView.addSubview(settingsContainerView)
        mainContainerView.addSubview(friendsContainerView)
        
        containerView.addSubview(sidebarBackgroundView)
        
        containerView.addSubview(activeContentView)
        
        sidebarBackgroundView.addSubview(sidebarCollectionView)
        
        view.addSubview(toolbar)
    }
    
    func readyWatcher() {
        clientUser.onReady = {
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.setupOrderedGuilds()
                self.rebuildSidebarButtons()
                self.sidebarCollectionView.reloadData()
                self.dmCollectionView.reloadData()
                self.friendsContainerView.reloadFriends()
                CATransaction.commit()
            }
        }
    }
    
    func setupToolbar() {
        toolbar.setItems([mainMenuButton, friendsButton, settingsButton])
    }
    
    func setupButtonActions() {
        settingsButton.addAction(for: .touchUpInside) {
            self.settingsButton.isUserInteractionEnabled = false
            
            UIView.transition(from: self.currentlyActiveView, to: self.settingsContainerView, direction: .left, in: self.mainContainerView, completionHandler: {
                self.mainMenuButton.isUserInteractionEnabled = true
                self.friendsButton.isUserInteractionEnabled = true
                self.currentlyActiveView = self.settingsContainerView
            })
        }
        
        friendsButton.addAction(for: .touchUpInside) {
            self.friendsButton.isUserInteractionEnabled = false
            let direction: UIView.SlideDirection = {
                switch self.currentlyActiveView {
                case self.containerView:
                    return .left
                case self.settingsContainerView:
                    return .right
                default:
                    return .right
                }
            }()
            UIView.transition(from: self.currentlyActiveView, to: self.friendsContainerView, direction: direction, in: self.mainContainerView, completionHandler: {
                self.mainMenuButton.isUserInteractionEnabled = true
                self.settingsButton.isUserInteractionEnabled = true
                self.currentlyActiveView = self.friendsContainerView
            })
        }
        
        mainMenuButton.addAction(for: .touchUpInside) {
            self.mainMenuButton.isUserInteractionEnabled = false
            UIView.transition(from: self.currentlyActiveView, to: self.containerView, direction: .right, in: self.mainContainerView, completionHandler: {
                self.settingsButton.isUserInteractionEnabled = true
                self.friendsButton.isUserInteractionEnabled = true
                self.currentlyActiveView = self.containerView
            })
        }
    }
    
    func rebuildSidebarButtons() {
        var items: [SidebarButtonType] = [.dms]

        guard let folders = clientUser.clientUserSettings?.guildFolders else {
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
        guard let settings = clientUser.clientUserSettings else { return }
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
        guard let sidebarBackgroundView = sidebarBackgroundView else { return }

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
            mainContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: offset),
            mainContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainerView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        ])
        
        containerView.pinToEdges(of: mainContainerView)
        
        settingsContainerView.pinToEdges(of: mainContainerView, insetBy: .init(top: 10, left: 10, bottom: 10, right: 10))
        friendsContainerView.pinToEdges(of: mainContainerView, insetBy: .init(top: 10, left: 10, bottom: 10, right: 10))

        // MARK: Sidebar
        NSLayoutConstraint.activate([
            sidebarBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            sidebarBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            sidebarBackgroundView.widthAnchor.constraint(equalToConstant: 64),
            sidebarBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])

        // MARK: Active content area
        NSLayoutConstraint.activate([
            activeContentView.leadingAnchor.constraint(equalTo: sidebarBackgroundView.trailingAnchor, constant: 10),
            activeContentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            activeContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            activeContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
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





