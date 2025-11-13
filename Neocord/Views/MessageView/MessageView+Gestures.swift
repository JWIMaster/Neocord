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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileClick(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.authorAvatar.isUserInteractionEnabled = true
        self.authorAvatar.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func profileClick(_ gesture: UITapGestureRecognizer) {
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
