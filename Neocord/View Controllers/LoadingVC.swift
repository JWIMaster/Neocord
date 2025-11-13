//
//  LoadingVC.swift
//  Neocord
//
//  Created by JWI on 8/11/2025.
//

import Foundation
import UIKitCompatKit
import UIKit
import UIKitExtensions
import iOS6BarFix

class LoadingViewController: UIViewController {
    
    override func viewDidLoad() {
        let loader = UIActivityIndicatorView()
        view.addSubview(loader)
        loader.pinToCenter(of: view)
        //clientUser.connect()
        
        clientUser.getSortedDMs() { dms, error in
            clientUser.getUserGuilds() { guilds, error in
                clientUser.getClientUserSettings() { settings, error in
                    clientUser.saveCache()
                    guard let window = UIApplication.shared.windows.first else { return }
                    let rootVC = ViewController()
                    let navController = CustomNavigationController(rootViewController: rootVC)
                    
                    SetStatusBarBlackTranslucent()
                    SetWantsFullScreenLayout(navController, true)
                    
                    window.rootViewController = navController
                    window.makeKeyAndVisible()
                }
            }
        }
        /*
        clientUser.onReady = {
            DispatchQueue.main.async {
                guard let window = UIApplication.shared.windows.first else { return }
                clientUser.saveCache()
                let rootVC = ViewController()
                let navController = CustomNavigationController(rootViewController: rootVC)
                
                SetStatusBarBlackTranslucent()
                SetWantsFullScreenLayout(navController, true)
                
                window.rootViewController = navController
                window.makeKeyAndVisible()
            }
        }*/
    }
}
