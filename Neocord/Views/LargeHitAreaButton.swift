//
//  LargeHitAreaButton.swift
//  Neocord
//
//  Created by JWI on 14/11/2025.
//

import Foundation
import UIKit
import UIKitCompatKit


public class LargeHitAreaButton: UIButton {
    var hitAreaInset: UIEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    
    init(hitAreaInset: UIEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)) {
        self.hitAreaInset = hitAreaInset
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerFrame = bounds.inset(by: hitAreaInset)
        return largerFrame.contains(point)
    }
}
