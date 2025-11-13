//
//  ThemeEngine.swift
//  Neocord
//
//  Created by JWI on 6/11/2025.
//

import UIKit
import UIKitCompatKit
import UIKitExtensions



public final class ThemeEngine {
    public static var enableGlass: Bool {
        get {
            switch device {
            case .a4:
                return false
            default:
                if UserDefaults.standard.object(forKey: "enableGlass") == nil {
                    return true  // default value
                }
                return UserDefaults.standard.bool(forKey: "enableGlass")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enableGlass")
            UserDefaults.standard.synchronize()
        }
    }
    public static var enableAnimations: Bool {
        get {
            switch device {
            case .a4, .a5, .a6:
                return false
            default:
                if UserDefaults.standard.object(forKey: "enableAnimations") == nil {
                    return true  // default value
                }
                return UserDefaults.standard.bool(forKey: "enableAnimations")
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enableAnimations")
            UserDefaults.standard.synchronize()
        }
    }
    public static var enableProfileTinting: Bool {
        get {
            if UserDefaults.standard.object(forKey: "enableProfileTinting") == nil {
                return true  // default value
            }
            return UserDefaults.standard.bool(forKey: "enableProfileTinting")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enableProfileTinting")
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        
    }
}
