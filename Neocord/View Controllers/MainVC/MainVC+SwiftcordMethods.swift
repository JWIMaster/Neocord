//
//  MainVC+ObjectMethods.swift
//  Neocord
//
//  Created by JWI on 10/11/2025.
//

import Foundation
import SwiftcordLegacy

extension ViewController {
    func fetchDMs() {
        activeClient.getSortedDMs { [weak self] dms, _ in
            guard let self = self else { return }
            self.dms = dms
            self.dmCollectionView.reloadData()
            activeClient.saveCache()
        }
    }
    
    func fetchGuilds() {
        activeClient.getClientUserSettings { settings, _ in
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
            activeClient.getUserGuilds { [weak self] guilds, _ in
                guard let self = self else { return }
                for (id, guild) in guilds {
                    self.guilds[id] = guild
                }
                
                let orderedGuilds = orderID.compactMap { guildId in
                    return self.guilds.values.first { $0.id == guildId }
                }
                
                self.orderedGuilds = orderedGuilds
                
                self.rebuildSidebarButtons()
                self.sidebarCollectionView.reloadData()

            }
            
            activeClient.saveCache()
        }
    }
    
    func fetchChannels(for guild: Guild, completion: @escaping () -> Void) {
        activeClient.getGuildChannels(for: guild.id!) { [weak self] channels, _ in
            guard let self = self else { return }
            self.activeGuildChannels = channels
            self.flattenChannelsForDisplay()
            completion()
        }
    }
}

