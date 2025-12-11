//
//  SceneDelegate.swift
//  Neocord
//
//  Created by Joshua Walraven on 11/12/2025.
//


import UIKit
import iOS6BarFix
import LiveFrost
import FoundationCompatKit
import UIKitExtensions
import SwiftcordLegacy

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var backgroundEnterDate: Date?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .discordGray

        let rootVC: UIViewController
        let navController: UINavigationController

        if token != nil {
            rootVC = ViewController()
            navController = CustomNavigationController(rootViewController: rootVC)

            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(navController, true)

            window.clipsToBounds = false
            window.frame = UIScreen.main.bounds
            window.rootViewController = navController
        } else {
            rootVC = AuthenticationViewController()
            window.rootViewController = rootVC
        }

        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        clientUser.saveCache()
        backgroundEnterDate = Date()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        if let enterDate = backgroundEnterDate {
            let timeAway = Date().timeIntervalSince(enterDate)
            if timeAway > 30 {
                if let navigationController = window?.rootViewController as? UINavigationController,
                   let currentVC = navigationController.topViewController as? TextViewController {
                    currentVC.getMessages()
                }
            }
        }
    }
}
