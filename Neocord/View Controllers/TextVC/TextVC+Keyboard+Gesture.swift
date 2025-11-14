//
//  DMVC+Keyboard.swift
//  Cascade
//
//  Created by JWI on 31/10/2025.
//

import UIKit
//import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost


//MARK: Keyboard and gesture functions
extension TextViewController {
    func setupKeyboardObservers() {
        let center = NotificationCenter.default
        
        observers.append(center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            self?.keyboardWillAppear(notification: notification as NSNotification)
        })
        
        observers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
            self?.keyboardWillDisappear(notification: notification as NSNotification)
        })
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.isEnabled = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        backGesture = UIPanGestureRecognizer(target: self, action: #selector(goBack))
        backGesture.isEnabled = true
        backGesture.cancelsTouchesInView = false
        backGesture.delegate = self
        containerView.addGestureRecognizer(backGesture)
    }
    
    @objc func goBack(_ pan: UIPanGestureRecognizer) {
        // Find the main scroll view
        if scrollView.isDecelerating {
            return
        }

        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)

        // Only consider horizontal swipes
        guard abs(velocity.x) > abs(velocity.y) else { return }
        
        // Only left-to-right
        guard velocity.x > 0 else { return }
        
        // Require minimum force (speed)
        let minimumVelocity: CGFloat = 500
        let minimumTranslation: CGFloat = 50

        if velocity.x > minimumVelocity || translation.x > minimumTranslation {
            if pan.state == .ended {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    
    

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Make back swipe wait if the other gesture is a reply swipe
        if gestureRecognizer == backGesture,
           let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer,
           otherPan.view is MessageView {
            return true
        }
        
        // Existing logic: tap waits for long press
        if gestureRecognizer is UITapGestureRecognizer, otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        
        return false
    }


    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl || touch.view is UITextView || touch.view is InputView {
            return false
        }
        
        return true
    }
    
    @objc private func dismissKeyboard() {
        print("tap")
        view.endEditing(true)
    }
    
    @objc private func keyboardWillAppear(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        var keyboardHeight: CGFloat
        if #available(iOS 11.0, *) {
            keyboardHeight = keyboardFrame.cgRectValue.height - view.safeAreaInsets.bottom
        } else {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }
        
        guard containerViewBottomConstraint.constant != -keyboardHeight else { return }
        
        
        
        
        containerViewBottomConstraint.constant = -keyboardHeight

        self.tapGesture.isEnabled = true
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16),
            animations: {
                self.view.layoutIfNeeded()
                self.scrollToBottom(animated: false)
            },
            completion: { _ in
                DispatchQueue.main.async {
                    self.isKeyboardVisible = true
                }
            }
        )
    }

    
    @objc private func keyboardWillDisappear(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        containerViewBottomConstraint.constant = 0
        isKeyboardVisible = false

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curve << 16),
            animations: {
                self.tapGesture.isEnabled = false
                self.view.layoutIfNeeded()
            }
        )
    }

}
