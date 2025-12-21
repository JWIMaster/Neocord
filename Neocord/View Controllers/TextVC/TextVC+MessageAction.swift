//
//  DMVC+MessageAction.swift
//  Cascade
//
//  Created by JWI on 31/10/2025.
//

import UIKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost


// MARK: Message Action Functions
extension TextViewController {
    func takeMessageAction(_ message: Message) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.setAnimationsEnabled(false)
        applyGaussianBlur(to: containerView.layer, radius: 12)
        var messageActionView: MessageActionView
        if let channel = channel {
            messageActionView = MessageActionView(activeClient, message, channel)
        } else {
            messageActionView = MessageActionView(activeClient, message, self.dm!)
        }
        messageActionView.alpha = 0
        messageActionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        view.addSubview(messageActionView)
        messageActionView.translatesAutoresizingMaskIntoConstraints = false
        messageActionView.pinToCenter(of: view)
        UIView.setAnimationsEnabled(true)
        CATransaction.commit()
        
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            messageActionView.alpha = 1
            messageActionView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.containerView.isUserInteractionEnabled = false
            if let nav = UIApplication.shared.currentKeyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 0
            }
        }
    }

    
    func endMessageAction() {
        let messageActionViews = self.view.subviews.compactMap({ $0 as? MessageActionView })
        
        guard !messageActionViews.isEmpty else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            for messageActionView in messageActionViews {
                messageActionView.alpha = 0
                messageActionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            self.containerView.isUserInteractionEnabled = true
            self.containerView.layer.filters = nil

            if let nav = UIApplication.shared.windows.first?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 1
            }
        }, completion: { _ in
            for messageActionView in messageActionViews {
                messageActionView.removeFromSuperview()
            }
        })
    }
    
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
        
        profile.frame = CGRect(x: 0, y: parentView.bounds.height, width: parentView.bounds.width, height: height)
        parentView.addSubview(profile)
        profileView = profile
        if ThemeEngine.enableAnimations {
            profileView?.springAnimation(bounceAmount: -20)
        }
        
        self.containerView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            profile.frame.origin.y = topOffset
            if let nav = UIApplication.shared.currentKeyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 0
            }
        }, completion: nil)
    }


    func removeProfileView() {
        guard let profile = profileView, let parent = profile.superview else { return }
        self.containerView.isUserInteractionEnabled = true
        profile.removeFromSuperview()
        self.profileView = nil
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            profile.frame.origin.y = parent.bounds.height
            self.containerView.layer.filters = nil
            self.profileBlur.blurRadius = 0
            if let nav = UIApplication.shared.currentKeyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 1
            }
        }, completion: nil)
    }
}
