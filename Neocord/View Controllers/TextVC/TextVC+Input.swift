//
//  DMVC+Input.swift
//  Cascade
//
//  Created by JWI on 31/10/2025.
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
    func setupInputView(for textChannel: TextChannel) {
        textInputView = InputView(channel: textChannel)
        guard let textInputView = textInputView else {
            return
        }
        
        containerView.addSubview(textInputView)
        textInputView.translatesAutoresizingMaskIntoConstraints = false
        
        textInputView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        textInputView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        textInputView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20).isActive = true
        
        view.layoutIfNeeded()
        self.setupBubbleActionView(for: textChannel)
    }
    
    func updateInputOffset() {
        UIView.animate(withDuration: 0.5) {
            self.scrollView.contentInset.bottom = (self.textInputView?.bounds.height)! + (self.bubbleActionView?.bounds.height)! + 10
        }
    }
}
