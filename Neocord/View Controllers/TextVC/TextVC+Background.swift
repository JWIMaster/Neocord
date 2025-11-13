//
//  DMVC+Background.swift
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

//MARK: View Background Functions
extension TextViewController {
    func animatedBackground() {
        backgroundGradient.frame = view.frame
        backgroundGradient.colors = [self.view.backgroundColor?.cgColor, self.view.backgroundColor?.cgColor]
        view.layer.insertSublayer(backgroundGradient, below: view.layer.superlayer)
        animateGradient()
    }
    
    func animateGradient(completion: (() -> Void)? = nil) {
        var avatarColors: [UIColor] = []
        var gradientColors: [CGColor] = []
        
        var dmRecipients: [User] = []
        
        if let dm = self.dm as? DM, let recipient = dm.recipient {
            dmRecipients.append(recipient)
        } else if let groupDM = self.dm as? GroupDM, let recipients = groupDM.recipients {
            for recipient in recipients {
                dmRecipients.append(recipient)
            }
        }
        
        for recipient in dmRecipients {
            AvatarCache.shared.avatar(for: recipient) { image, color in
                guard let color = color else { return }
                avatarColors.append(color)
            }
        }
        
        
        
        for color in avatarColors {
            gradientColors.append(color.cgColor)
            gradientColors.append(UIColor.random(around: color, variance: 0.1).cgColor)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.backgroundGradient.colors = gradientColors
            self?.animateGradient(completion: completion)
        }
        
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 3.0
        animation.toValue = gradientColors
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        backgroundGradient.add(animation, forKey: "colorChange")
        CATransaction.commit()
    }
}
