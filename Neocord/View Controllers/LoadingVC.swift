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
    var readyProcessedObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        let loader = UIActivityIndicatorView()
        loader.style = .gray
        view.addSubview(loader)
        loader.pinToCenter(of: view)
        activeClient.connect()
        
        readyProcessedObserver = NotificationCenter.default.addObserver(forName: .readyProcessed, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let window = UIApplication.shared.windows.first else { return }
                let rootVC = ViewController()
                let navController = CustomNavigationController(rootViewController: rootVC)
                
                SetStatusBarBlackTranslucent()
                SetWantsFullScreenLayout(navController, true)
                if let readyProcessedObserver = self.readyProcessedObserver {
                    NotificationCenter.default.removeObserver(readyProcessedObserver)
                }
                self.readyProcessedObserver = nil
                window.rootViewController = navController
                window.makeKeyAndVisible()
            }
        }
        /*clientUser.onReady = {
            DispatchQueue.main.async {
                guard let window = UIApplication.shared.windows.first else { return }
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
