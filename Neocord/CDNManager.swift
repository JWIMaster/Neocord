//
//  CDNManager.swift
//  Neocord
//
//  Created by J_W_I_ on 1/1/2026.
//

import Foundation
import SwiftcordLegacy
import FoundationCompatKit
import UIKit
import ETFKit

public final class DiscordCDNManager {
    public let baseURLString = "https://cdn.discordapp.com"
    
    public func request(media: DiscordCDNOptions, completion: @escaping (Any?, Error?) -> ()) {
        guard let url = URL(string: baseURLString + media.httpInfo.url) else { return }
        URLSessionCompat.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            guard let data = data else { return }
            if let image = UIImage(data: data) {
                completion(image, nil)
            } 
        }
    }
}

public enum DiscordCDNOptions {
    case profileBadge(hash: String)
    case userAvatar(userID: Snowflake, hash: String)
    case guildIcon(guildID: Snowflake, hash: String)
    case userBanner(userID: Snowflake, hash: String)
}

public extension DiscordCDNOptions {
    var httpInfo: EndpointInfo {
        switch self {
        case let .profileBadge(hash):
            return (.get, "/badge-icons/\(hash).png")
        case let .guildIcon(guildID, hash):
            return (.get, "/icons/\(guildID)/\(hash).png")
        case let .userAvatar(userID, hash):
            return (.get, "/avatars/\(userID)/\(hash).png")
        case let .userBanner(userID, hash):
            return (.get, "/banners/\(userID)/\(hash).png")
        }
    }
}
