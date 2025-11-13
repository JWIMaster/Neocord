//
//  SharedValues.swift
//  MakingADiscordAPI
//
//  Created by JWI on 20/10/2025.
//

import Foundation
import SwiftcordLegacy
import UIKitCompatKit
import UIKit
import LiveFrost
import Keychain


public var token: String? {
    get {
        return UserDefaults.standard.string(forKey: "discordToken")
    }
    set {
        let defaults = UserDefaults.standard
        if let value = newValue {
            defaults.set(value, forKey: "discordToken")
        } else {
            defaults.removeObject(forKey: "discordToken")
        }
        defaults.synchronize()
    }
}

public var activeChannel: Snowflake = Snowflake(0)


public let clientUser = SLClient(token: token ?? "idk")



public class StringCache {
    
    static let memoryCache = NSCache<NSString, NSString>()
    
    static let cacheDirectory: String = {
        let dirs = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return dirs.first ?? NSTemporaryDirectory()
    }()
    
    // File path helper
    public static func filePath(forKey key: String) -> URL {
        return URL(fileURLWithPath: cacheDirectory + "/" + key + ".txt")
    }
    
    // MARK: - Store
    public static func store(_ string: String, for key: String) {
        // Memory cache
        memoryCache.setObject(string as NSString, forKey: key as NSString)
        
        // Disk cache
        let url = filePath(forKey: key)
        try? string.write(to: url, atomically: true, encoding: .utf8) // crash if fails
    }
    
    // MARK: - Load
    public static func load(for key: String) -> String? {
        // Memory cache first
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached as String
        }
        
        // Disk cache fallback
        let url = filePath(forKey: key)
        if let string = try? String(contentsOf: url, encoding: .utf8) {
            memoryCache.setObject(string as NSString, forKey: key as NSString)
            return string
        }
        
        return nil
    }
}

private var DeviceInfoClass = DeviceInfo()
public var device: ChipsetClass {
    return DeviceInfoClass.chipsetClass()
}
private var captureScale: CGFloat {
    switch device {
    case .a4:
        return 0.1
    case .a5:
        return 0.15
    case .a6:
        return 0.2
    case .a7_a8:
        return 0.3
    case .a9Plus:
        return 0.4
    case .a12Plus:
        return 1
    case .unknown:
        return 0.3
    }
}

public enum PerformanceClass {
    case ultraHigh
    case high
    case medium
    case low
    case potato
}

public let isSimulator: Bool = {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}()

final class PerformanceManager {
    static var performanceClass: PerformanceClass {
        get {
            switch device {
            case .a4:
                return .potato
            case .a5:
                return .low
            case .a6:
                return .medium
            case .a7_a8:
                return .medium
            case .a9Plus:
                return .high
            case .a12Plus:
                return .ultraHigh
            case .unknown:
                return .low
            }
        }
    }
    static var scaleFactor: CGFloat {
        get {
            switch performanceClass {
            case .ultraHigh:
                return 0.5
            case .high:
                return 0.3
            case .medium:
                return 0.2
            case .low:
                return 0.1
            case .potato:
                return 0
            }
        }
    }
    static var disableBlur: Bool {
        get {
            if #available(iOS 9.0, *) {
                if isSimulator { return false } else { return false }
            } else {
                //MARK: One day I will fix iOS 9- blur...
                switch performanceClass {
                case .ultraHigh:
                    return false
                case .high:
                    return false
                case .medium:
                    return true
                case .low:
                    return true
                case .potato:
                    return true
                }
            }
        }
    }
    static var frameInterval: Int {
        get {
            switch performanceClass {
            case .ultraHigh:
                return 1
            case .high:
                return 2
            case .medium:
                return 6
            case .low:
                return 12
            case .potato:
                return 60*60*60
            }
        }
    }
}


public extension UIColor {
    class var discordGray: UIColor {
        return UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
    }
}

