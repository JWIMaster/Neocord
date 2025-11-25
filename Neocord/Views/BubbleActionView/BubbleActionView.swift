//
//  BubbleActionView.swift
//  Neocord
//
//  Created by JWI on 23/11/2025.
//

import Foundation
import UIKit
import UIKitExtensions
import UIKitCompatKit
import SwiftcordLegacy
import FoundationCompatKit

class BubbleActionView: UIView {
    
    var contextBubble: Bubble?
    var typingBubble: Bubble?
    
    
    public lazy var bubbleStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 4
        stack.axis = .vertical
        stack.alignment = .center
        return stack
    }()
    
    
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.addSubview(bubbleStack)
        bubbleStack.pinToEdges(of: self)
        bubbleStack.setContentHuggingPriority(.required, for: .vertical)
        bubbleStack.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    // MARK: - Associated keys
    
    
    deinit {
        for (_, typingInfo) in typingTimers {
            typingInfo.timer.invalidate()
        }
    }
}
