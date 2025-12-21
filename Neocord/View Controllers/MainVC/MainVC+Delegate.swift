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
import FoundationCompatKit

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
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DMButtonCell.reuseID, for: indexPath) as? DMButtonCell else { return UICollectionViewCell() }
            cell.configure(with: dms[indexPath.item])
            return cell
            
        case sidebarCollectionView:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarButtonCell.reuseID, for: indexPath) as? SidebarButtonCell else { return UICollectionViewCell() }
            cell.configure(with: sidebarButtons[indexPath.item])
            return cell
            
        case channelsCollectionView:
            let item = displayedChannels[indexPath.item]
            if let category = item as? GuildCategory {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelCategoryCell.reuseID, for: indexPath) as? ChannelCategoryCell else { return UICollectionViewCell() }
                cell.configure(with: category)
                return cell
            } else if let text = item as? GuildText {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelButtonCell.reuseID, for: indexPath) as? ChannelButtonCell else { return UICollectionViewCell() }
                cell.configure(with: text)
                return cell
            } else if let forum = item as? GuildForum {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelButtonCell.reuseID, for: indexPath) as? ChannelButtonCell else { return UICollectionViewCell() }
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
            if dm.type == .dm, let dm = dm as? DM {
                activeClient.acknowledge(messageID: dm.lastMessageID!, in: dm.id!, completion: { _ in })
                navigationController?.pushViewController(TextViewController(dm: dm), animated: true)
            } else if dm.type == .groupDM, let groupDM = dm as? GroupDM {
                activeClient.acknowledge(messageID: groupDM.lastMessageID!, in: groupDM.id!, completion: { _ in })
                navigationController?.pushViewController(TextViewController(dm: groupDM), animated: true)
            }
            
        case sidebarCollectionView:
            let button = sidebarButtons[indexPath.item]
            switch button {
            case .dms:
                showContentView(dmCollectionView)
                dmCollectionView.reloadData()
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
                activeClient.subscribeToChannel(self.activeGuild!, channel)
                activeClient.acknowledge(messageID: channel.lastMessageID!, in: channel.id!, completion: { _ in })
                navigationController?.pushViewController(TextViewController(channel: channel), animated: true)
            case .guildForum:
                activeClient.subscribeToChannel(self.activeGuild!, channel)
                if let forum = channel as? GuildForum { navigationController?.pushViewController(ForumViewController(forum: forum), animated: true) }
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
        guard activeGuild?.id != guild.id || displayedChannels.isEmpty else { return }
        activeGuild = guild
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
                self.channelsCollectionView.alpha = 1
                UIView.transition(with: self.channelsCollectionView, duration: 0.25, options: .transitionCrossDissolve) {
                    
                }
                self.updateTitle(guild.name ?? "Unknown Guild")
            }
        }
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
        
        if #available(iOS 10.0, *) {
            let haptic = UISelectionFeedbackGenerator()
            haptic.selectionChanged()
        }
         
        sidebarCollectionView.performBatchUpdates({
            if isExpanded {
                let endIndex = min(startIndex + guildsInFolder.count, sidebarButtons.count)
                let indexPaths = (startIndex..<endIndex).map { IndexPath(item: $0, section: 0) }
                sidebarButtons.removeSubrange(startIndex..<endIndex)
                sidebarCollectionView.deleteItems(at: indexPaths)
            } else {
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


