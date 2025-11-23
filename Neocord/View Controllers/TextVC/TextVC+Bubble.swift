//
//  TextVC+Bubble.swift
//  Neocord
//
//  Created by JWI on 23/11/2025.
//
import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost

//MARK: View input functions
extension TextViewController {
    func setupBubbleActionView(for textChannel: TextChannel) {
        bubbleActionView = BubbleActionView()
        guard let bubbleActionView = bubbleActionView, let textInputView = textInputView else {
            return
        }
        
        containerView.addSubview(bubbleActionView)
        bubbleActionView.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleActionView.bottomAnchor.constraint(equalTo: textInputView.topAnchor, constant: -6).isActive = true
        bubbleActionView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        bubbleActionView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20).isActive = true
        bubbleActionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
        
        view.layoutIfNeeded()
        self.updateInputOffset()
        scrollView.contentInset.top = (navigationController?.navigationBar.frame.height) ?? 0
        
        scrollView.layoutIfNeeded()
        scrollToBottom(animated: false)
        
        initialViewSetupComplete = true
    }
}
