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
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Make tap wait to see if hold activates
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
