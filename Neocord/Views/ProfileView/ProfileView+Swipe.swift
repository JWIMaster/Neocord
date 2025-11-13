//
//  File.swift
//  Neocord
//
//  Created by JWI on 5/11/2025.
//

import Foundation
import UIKit

extension ProfileView: UIGestureRecognizerDelegate, UIScrollViewDelegate {

    func setupGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
        scrollView.delegate = self
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.view is UIScrollView
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: self)
        return abs(velocity.y) > abs(velocity.x)
    }

    private struct AssociatedKeys { static var dragTranslation = "dragTranslation" }
    private var dragTranslation: CGFloat {
        get { objc_getAssociatedObject(self, &AssociatedKeys.dragTranslation) as? CGFloat ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.dragTranslation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translationY = gesture.translation(in: self).y

        switch gesture.state {
        case .began, .changed:
            // Only start drag if scrollView at top and dragging down
            if scrollView.contentOffset.y <= 0 && translationY > 0 {
                if !dragStarted {
                    dragStarted = true
                    scrollView.isScrollEnabled = false
                }

                // Move the view directly
                self.transform = CGAffineTransform(translationX: 0, y: translationY)

                // Fade background gradually
                let progress = min(translationY / (self.bounds.height / 2), 1)
                self.backgroundView?.alpha = 1 - progress * 0.5
            }

        case .ended, .cancelled:
            guard dragStarted else { break }

            let velocityY = gesture.velocity(in: self).y
            let threshold = self.bounds.height / 4

            // Calculate a robust shouldDismiss
            let offscreenFraction = max(0, self.frame.maxY - self.bounds.height) / self.bounds.height
            let alphaLow = (self.alpha < 0.05)
            let shouldDismiss = translationY > threshold || velocityY > 1000 || offscreenFraction > 0.5 || alphaLow

            // Animate to final state
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                if shouldDismiss {
                    self.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
                    self.alpha = 0
                    self.backgroundView?.alpha = 0
                } else {
                    self.transform = .identity
                    self.alpha = 1
                    self.backgroundView?.alpha = 1
                }
            }, completion: { _ in
                if shouldDismiss {
                    self.dismissProfile()
                }
                self.dragStarted = false
                self.scrollView.isScrollEnabled = true
            })

        default: break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Prevent bouncing at top while drag is not active
        if !dragStarted && scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        }
    }


}

