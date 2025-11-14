//
//  MessageView+Gestures.swift
//  Cascade
//
//  Created by JWI on 2/11/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit


extension MessageView {
    func setupGestureRecogniser() {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(messageAction))
        holdGesture.cancelsTouchesInView = false
        holdGesture.delegate = self
        self.addGestureRecognizer(holdGesture)
        self.isUserInteractionEnabled = true
        
        // Avatar tap
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(profileClick(_:)))
        avatarTap.cancelsTouchesInView = false
        avatarTap.delegate = self
        authorAvatar.isUserInteractionEnabled = true
        authorAvatar.addGestureRecognizer(avatarTap)

        // Name tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(profileClick(_:)))
        nameTap.cancelsTouchesInView = false
        nameTap.delegate = self
        authorName.isUserInteractionEnabled = true
        authorName.addGestureRecognizer(nameTap)
        
        let replySwipe = UIPanGestureRecognizer(target: self, action: #selector(replySwipe(_:)))
        replySwipe.cancelsTouchesInView = false
        replySwipe.delegate = self
        //self.addGestureRecognizer(replySwipe)
    }
    
    @objc func replySwipe(_ pan: UIPanGestureRecognizer) {
        let rawX = pan.translation(in: self).x
        let velocity = pan.velocity(in: self).x

        // Only leftwards drag
        guard rawX < 0 else { return }

        // The point where dragging must stop completely
        let halfway: CGFloat = -140

        switch pan.state {

        case .changed:
            // Clamp directly
            let clampedX = max(rawX, halfway)
            self.transform = CGAffineTransform(translationX: clampedX, y: 0)

        case .ended, .cancelled:
            // If user reached the clamp → reply
            let shouldReply = rawX <= halfway || velocity < -900

            if shouldReply,
               let dmVC = self.parentViewController as? TextViewController,
               let msg = self.message {
                if #available(iOS 10.0, *) {
                    let haptic = UISelectionFeedbackGenerator()
                    haptic.selectionChanged()
                }
                // Small straight nudge, no spring
                UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseInOut, animations: {
                    self.transform = .identity
                }, completion: nil)

                dmVC.textInputView?.replyToMessage(msg)
                return
            }

            // Not enough → simple linear snap back
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }

        default:
            break
        }
    }



    
    @objc func profileClick(_ gesture: UITapGestureRecognizer) {
        if #available(iOS 10.0, *) {
            let haptic = UISelectionFeedbackGenerator()
            haptic.selectionChanged()
        }
        guard let message = self.message, let user = message.author else { return }
        if let textVC = self.parentViewController as? TextViewController {
            if let member = self.member {
                textVC.presentProfileView(for: user, member)
            } else {
                textVC.presentProfileView(for: user)
            }
        }
    }
    
    @objc func imageClick(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let imageView = gesture.view as? UIImageView, let image = imageView.image else { return }
        
        let newImageView = UIImageView(image: image)
        newImageView.contentMode = .scaleAspectFit
        newImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let vc = AttachmentViewController(attachment: newImageView)
        vc.modalPresentationStyle = .pageSheet
        self.parentViewController?.present(vc, animated: true)
    }
    
    @objc func messageAction(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        if #available(iOS 10.0, *) {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
        }
        if let dmVC = parentViewController as? TextViewController {
            dmVC.takeMessageAction(self.message!)
        }
    }
    
    
    
}
