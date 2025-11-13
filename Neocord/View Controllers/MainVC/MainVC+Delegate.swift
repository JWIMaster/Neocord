//
//  MainVC+Delegate.swift
//  Cascade
//
//  Created by JWI on 2/11/2025.
//

import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import iOS6BarFix
import LiveFrost
import AudioToolbox

// MARK: - Collection View
// MARK: - Collection View
extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case dmCollectionView: return dms.count
        case sidebarCollectionView: return sidebarButtons.count
        case channelsCollectionView: return displayedChannels.count
        default: fatalError("Unknown collection view")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case dmCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DMButtonCell.reuseID, for: indexPath) as! DMButtonCell
            cell.configure(with: dms[indexPath.item])
            return cell
            
        case sidebarCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarButtonCell.reuseID, for: indexPath) as! SidebarButtonCell
            cell.configure(with: sidebarButtons[indexPath.item])
            return cell
            
        case channelsCollectionView:
            let item = displayedChannels[indexPath.item]
            if let category = item as? GuildCategory {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelCategoryCell.reuseID, for: indexPath) as! ChannelCategoryCell
                cell.configure(with: category)
                return cell
            } else if let text = item as? GuildText {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelButtonCell.reuseID, for: indexPath) as! ChannelButtonCell
                cell.configure(with: text)
                return cell
            } else if let forum = item as? GuildForum {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelButtonCell.reuseID, for: indexPath) as! ChannelButtonCell
                cell.configure(with: forum)
                return cell
            } else {
                fatalError("Unknown channel type")
            }
            
        default:
            fatalError("Unknown collection view")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case dmCollectionView:
            let dm = dms[indexPath.item]
            if dm.type == .dm { navigationController?.pushViewController(TextViewController(dm: dm as! DM), animated: true) }
            else if dm.type == .groupDM { navigationController?.pushViewController(TextViewController(dm: dm as! GroupDM), animated: true) }
            
        case sidebarCollectionView:
            let button = sidebarButtons[indexPath.item]
            switch button {
            case .dms:
                showContentView(dmCollectionView)
                if dmCollectionView.numberOfItems(inSection: 0) != dms.count { dmCollectionView.reloadData() }
                updateTitle("Direct Messages")
            case .guild(let guild):
                showContentView(channelsCollectionView)
                setupChannelCollectionView(for: guild)
            case .folder(let folder, _):
                didSelectFolder(folder)
            }
            
        case channelsCollectionView:
            let channel = displayedChannels[indexPath.item]
            switch channel.type {
            case .guildText:
                //MARK: Must manually subscribe or else big guild's channel's events will not be picked up, leading to no websocket messages
                clientUser.subscribeToChannel(self.activeGuild!, channel)
                navigationController?.pushViewController(TextViewController(channel: channel), animated: true)
            case .guildForum:
                clientUser.subscribeToChannel(self.activeGuild!, channel)
                navigationController?.pushViewController(ForumViewController(forum: channel as! GuildForum), animated: true)
            default:
                break
            }
            
        default: break
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 20
        switch collectionView {
        case dmCollectionView: return CGSize(width: width, height: 50)
        case sidebarCollectionView:
            let size = collectionView.bounds.width - 10
            return CGSize(width: size, height: size)
        case channelsCollectionView:
            let item = displayedChannels[indexPath.item]
            switch item.type {
            case .guildCategory, .guildText, .guildForum: return CGSize(width: width, height: 40)
            default: return .zero
            }
        default: return .zero
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if ThemeEngine.enableAnimations {
            cell.springAnimation()
        }
    }
    
    
    
    // MARK: Channels Setup
    func setupChannelCollectionView(for guild: Guild) {
        guard activeGuild?.id != guild.id || displayedChannels.isEmpty || !guild.fullGuild else { return }
        activeGuild = guild
        print(activeGuild)
        updateTitle(guild.name ?? "Loading…")
        if activeContentView.subviews.first != channelsCollectionView || activeContentView.subviews.first == dmCollectionView{
            showContentView(channelsCollectionView)
        }
        
        
        if !guild.channels.isEmpty, guild.fullGuild {
            flattenChannelsForDisplay()
            channelsCollectionView.reloadData()
            return
        }
        
        UIView.animate(withDuration: 0.25) { self.channelsCollectionView.alpha = 0 }
        
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading channels…"
        loadingLabel.textColor = .lightGray
        loadingLabel.font = .systemFont(ofSize: 14)
        loadingLabel.backgroundColor = .clear
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        activeContentView.addSubview(loadingLabel)
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: activeContentView.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: activeContentView.centerYAnchor)
        ])
        
        self.fetchChannels(for: guild) {
            DispatchQueue.main.async {
                loadingLabel.removeFromSuperview()
                //self.flattenChannelsForDisplay()
                //self.channelsCollectionView.reloadData()
                self.channelsCollectionView.alpha = 1
                UIView.transition(with: self.channelsCollectionView, duration: 0.25, options: .transitionCrossDissolve) {
                    
                }
                self.updateTitle(guild.name ?? "Unknown Guild")
            }
        }
        
        /*clientUser.getFullGuild(guild) { [weak self] guilds, _ in
            guard let self = self, let fullGuild = guilds.values.first else { return }
            self.activeGuild = fullGuild
            
            if let index = self.guilds.firstIndex(where: { $0.id == fullGuild.id }) { self.guilds[index] = fullGuild }
        }*/
    }
    
    
    func didSelectFolder(_ folder: GuildFolder) {
        guard let folderID = folder.id?.description else { return }
        print(folderID)
        let isExpanded = UserDefaults.standard.bool(forKey: folderID)

        let guildsInFolder = orderedGuilds.filter { folder.guildIDs?.contains($0.id!) ?? false }
        guard !guildsInFolder.isEmpty else { return }

        guard let folderIndex = sidebarButtons.firstIndex(where: {
            if case .folder(let f, _) = $0 { return f.id == folder.id }
            return false
        }) else { return }

        let startIndex = folderIndex + 1
        
        let hapticSupport: Int = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int ?? 0
        switch hapticSupport {
        case 0:
            break
        case 1:
            AudioServicesPlaySystemSound(1519)
        case 2:
            if #available(iOS 10.0, *) {
                let haptic = UISelectionFeedbackGenerator()
                haptic.selectionChanged()
            } else {
                break
            }
        default:
            break
        }
        
        sidebarCollectionView.performBatchUpdates({
            if isExpanded {
                // Collapse

                let endIndex = min(startIndex + guildsInFolder.count, sidebarButtons.count)
                let indexPaths = (startIndex..<endIndex).map { IndexPath(item: $0, section: 0) }
                sidebarButtons.removeSubrange(startIndex..<endIndex)
                sidebarCollectionView.deleteItems(at: indexPaths)
            } else {
                // Expand

                sidebarButtons.insert(contentsOf: guildsInFolder.map { .guild($0) }, at: startIndex)
                let indexPaths = (startIndex..<startIndex + guildsInFolder.count).map { IndexPath(item: $0, section: 0) }
                sidebarCollectionView.insertItems(at: indexPaths)
            }

            // Update folder itself with new expanded state
            sidebarButtons[folderIndex] = .folder(folder, isExpanded: !isExpanded)
        }, completion: nil)
        
        UserDefaults.standard.set(!isExpanded, forKey: folderID)
        self.rebuildSidebarButtons()
    }
    
    func updateTitle(_ title: String) {
        self.title = title
        (navigationController as? CustomNavigationController)?.updateTitle(for: self)
    }
}


extension ViewController {
    func fetchDMs() {
        clientUser.getSortedDMs { [weak self] dms, error in
            guard let self = self else { return }
            self.dms = dms
            self.dmCollectionView.reloadData()
            clientUser.saveCache()
        }
    }
    
    func fetchGuilds() {
        clientUser.getClientUserSettings() { settings, error in
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
            clientUser.getUserGuilds() { [weak self] guilds, error in
                guard let self = self else { return }
                for (id, guild) in guilds {
                    self.guilds[id] = guild
                }
                
                let orderedGuilds = orderID.compactMap { guildId in
                    return self.guilds.values.first { $0.id == guildId }
                }
                
                //self.guilds = orderedGuilds
                self.orderedGuilds = orderedGuilds
                
                self.rebuildSidebarButtons()
                self.sidebarCollectionView.reloadData()

            }
            
            clientUser.saveCache()
        }
    }
    
    func fetchChannels(for guild: Guild, completion: @escaping () -> Void) {
        clientUser.getGuildChannels(for: guild.id!) { [weak self] channels, error in
            guard let self = self else { return }

            // Replace activeGuild with the canonical guild from the cache
            
            self.activeGuildChannels = channels

            print("channels fetched: \(channels.count)")
            self.flattenChannelsForDisplay()
            completion()
        }
    }

    
    
}

extension UIView {
    func springAnimation(scaleDuration: CGFloat = 0.3, bounceDuration: CGFloat = 0.2, scaleOptions: UIView.AnimationOptions = [.curveEaseOut, .allowUserInteraction], bounceOptions: UIView.AnimationOptions = [.curveEaseInOut, .allowUserInteraction], bounceAmount: CGFloat = -6, delay: CGFloat = 0) {
        self.alpha = 0
        self.transform = CGAffineTransform(translationX: 0, y: 50).scaledBy(x: 0.8, y: 0.8)

        UIView.animate(withDuration: scaleDuration, delay: delay, options: scaleOptions, animations: {
            self.alpha = 1
            self.transform = CGAffineTransform(translationX: 0, y: bounceAmount)
        }, completion: { _ in
            UIView.animate(withDuration: bounceDuration, delay: 0, options: bounceOptions, animations: {
                self.transform = .identity
            }, completion: nil)
        })
    }
}
