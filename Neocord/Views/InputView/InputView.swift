import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit


public class InputView: UIView, UITextViewDelegate {
    public weak var snapshotView: UIView?
    
    public let backgroundView: UIView? = {
        if ThemeEngine.enableGlass {
            let bView = LiquidGlassView(blurRadius: 6, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
            bView.translatesAutoresizingMaskIntoConstraints = false
            bView.solidViewColour = .discordGray.withAlphaComponent(0.8)
            bView.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            bView.scaleFactor = PerformanceManager.scaleFactor
            bView.frameInterval = PerformanceManager.frameInterval
            return bView
        } else {
            let bView = UIView()
            bView.layer.cornerRadius = 20
            bView.backgroundColor = .discordGray.withAlphaComponent(0.8)
            return bView
        }
    }()
    
    public var channel: TextChannel?
    public var tokenInputView: Bool?
    
    let buttonBackground: UIView? = {
        if ThemeEngine.enableGlass {
            let background = LiquidGlassView(blurRadius: 6, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
            background.scaleFactor = 0.25
            background.frameInterval = 6
            background.isUserInteractionEnabled = false
            background.solidViewColour = .discordGray.withAlphaComponent(0.8)
            background.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            return background
        } else {
            let background = UIView()
            background.layer.cornerRadius = 20
            background.backgroundColor = .discordGray.withAlphaComponent(0.8)
            background.isUserInteractionEnabled = false
            return background
        }
    }()
    
    var replyMessage: Message?
    var editMessage: Message?
    
    public enum inputMode {
        case edit, reply, send
    }
    
    public let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isScrollEnabled = false
        textView.contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: -4)
        return textView
    }()
    
    
    public let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    public let sendButton: LargeHitAreaButton = {
        let button = LargeHitAreaButton()
        button.setImage(.init(systemName: "paperplane", tintColor: .white), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    public let attachmentButton: LargeHitAreaButton = {
        let button = LargeHitAreaButton()
        button.setImage(.init(systemName: "paperplane", tintColor: .white), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    var buttonIsActive: Bool = true

    
    public init(channel: TextChannel, snapshotView: UIView, tokenInputView: Bool = false) {
        super.init(frame: .zero)
        self.snapshotView = snapshotView
        self.channel = channel
        self.tokenInputView = tokenInputView
        setupSubviews()
        setupConstraints()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.snapshotView = nil
        self.channel = nil
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSubviews() {
        if let buttonBackground = buttonBackground as? LiquidGlassView, let backgroundView = backgroundView as? LiquidGlassView {
            buttonBackground.snapshotTargetView = snapshotView
            backgroundView.snapshotTargetView = snapshotView
        }
        guard let buttonBackground = buttonBackground, let backgroundView = backgroundView else { return }
        addSubview(backgroundView)
        
        textView.delegate = self
        backgroundView.addSubview(textView)
                
        addSubview(buttonBackground)
        
        sendButton.sendSubviewToBack(buttonBackground)
        
        
        //Must use weak self or else the whole inputview gets retained 
        sendButton.addAction(for: .touchUpInside) { [weak self] in
            self?.sendMessageAction()
        }
        
        addSubview(sendButton)
    }
    
    private func setupConstraints() {
        guard let backgroundView = backgroundView else { return }
        
        sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -6).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        activateButtonBackgroundConstraints()
        
        // Background view below bubbleStack, minimum height to prevent collapse
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            //THIS IS NEEDED OR ELSE IT COLLAPSES ON iOS 6
            backgroundView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        textView.pinToEdges(of: backgroundView)
    }

    
    func activateButtonBackgroundConstraints() {
        guard let buttonBackground = buttonBackground else { return }
        buttonBackground.pinToCenter(of: sendButton)
        buttonBackground.heightAnchor.constraint(equalToConstant: 40).isActive = true
        buttonBackground.widthAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    func deactivateButtonBackgroundConstraings() {
        guard let buttonBackground = buttonBackground else { return }
        buttonBackground.constraints.forEach { $0.isActive = false }
    }
    
    
    public func textViewDidChange(_ textView: UITextView) {
        var maxHeight: CGFloat = 0
        if let dmVC = parentViewController as? TextViewController, let navBarHeight = dmVC.navigationController?.navigationBar.frame.height {
            maxHeight = dmVC.view.bounds.height - 50 - navBarHeight
        }
        if let backgroundView = backgroundView as? LiquidGlassView {
            backgroundView.frameInterval = 60*60*60
        }
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100 // fallback
        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let clampedHeight = max(40, min(size.height, maxHeight))
        
        textView.isScrollEnabled = size.height > maxHeight
        
        if clampedHeight != self.bounds.height {
            self.invalidateIntrinsicContentSize()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let backgroundView = self.backgroundView as? LiquidGlassView {
                backgroundView.frameInterval = 6
            }
        }
    }
    
    
    public override var intrinsicContentSize: CGSize {
        var maxHeight: CGFloat = 0
        if let dmVC = parentViewController as? TextViewController, let navBarHeight = dmVC.navigationController?.navigationBar.frame.height {
            maxHeight = dmVC.view.bounds.height - 50 - navBarHeight
        } 
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100
        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = max(40, min(size.height, maxHeight))
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}




