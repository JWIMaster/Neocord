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
    
    var contextBubble: Bubble?
    var typingBubble: Bubble?
    
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
        textView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
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
    
    public lazy var bubbleStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        return stack
    }()
    
    var buttonIsActive: Bool = true
    
    var topConstraint: NSLayoutConstraint!
    
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
        addSubview(bubbleStack)
        addSubview(backgroundView)
        
        textView.delegate = self
        backgroundView.addSubview(textView)
                
        addSubview(buttonBackground)
        
        sendButton.sendSubviewToBack(buttonBackground)
        
        
        //Must use weak self or else the whole inputview gets retained 
        sendButton.addAction(for: .touchUpInside) { [weak self] in
            self?.sendMessageAction()
        }
        
        buttonStack.addArrangedSubview(sendButton)
        addSubview(buttonStack)
        bringSubviewToFront(sendButton)
    }
    
    private func setupConstraints() {
        guard let backgroundView = backgroundView else { return }
        
        topConstraint = backgroundView.topAnchor.constraint(equalTo: bubbleStack.bottomAnchor)
        
        NSLayoutConstraint.activate([
            bubbleStack.topAnchor.constraint(equalTo: self.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            topConstraint,
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -60)
        ])
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
        
        buttonStack.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
        buttonStack.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 20).isActive = true
        
        activateButtonBackgroundConstraints()
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




