//
//  MainVC+ProfileView.swift
//  Neocord
//
//  Created by JWI on 14/11/2025.
//

import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import iOS6BarFix
import LiveFrost
import AudioToolbox


extension ViewController {
    func presentProfileView(for user: User, _ member: GuildMember? = nil) {
        guard let parentView = self.view else { return }
        let profile = ProfileView(user: user, member: member)
        var topOffset: CGFloat
        if #available(iOS 11.0, *) {
            topOffset = self.navigationBarHeight + view.safeAreaInsets.top
        } else {
            topOffset = self.navigationBarHeight
        }
        let height = parentView.bounds.height - topOffset
        
        // Start off-screen
        profile.frame = CGRect(
            x: 0,
            y: parentView.bounds.height,
            width: parentView.bounds.width,
            height: height
        )
        
        parentView.addSubview(profile)
        profileView = profile
        if ThemeEngine.enableAnimations {
            profileView?.springAnimation(bounceAmount: -20)
        }
        
        self.containerView.isUserInteractionEnabled = false
        // Animate in
        
        
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            profile.frame.origin.y = topOffset
            //self.profileBlur.blurRadius = 6
            if let nav = UIApplication.shared.keyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 0
            }
        }, completion: { _ in
            //self.profileBlur.frameInterval = 60*60*60
        })
    }


    func removeProfileView() {
        guard let profile = profileView, let parent = profile.superview else { return }
        self.containerView.isUserInteractionEnabled = true
        
        //self.profileBlur.frameInterval = 2
        profile.removeFromSuperview()
        self.profileView = nil
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            profile.frame.origin.y = parent.bounds.height
            self.containerView.layer.filters = nil
            if let nav = UIApplication.shared.keyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 1
            }
        }, completion: { _ in
            //self.profileBlur.removeFromSuperview()
            
        })
    }
}
