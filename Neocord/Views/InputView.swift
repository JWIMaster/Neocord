import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit


public class InputView: UIView, UITextViewDelegate {
    public weak var snapshotView: UIView?
    
    public let backgroundView: UIView? = {
        switch device {
        case .a4:
            let bView = UIView()
            bView.layer.cornerRadius = 20
            bView.backgroundColor = .discordGray.withAlphaComponent(0.8)
            return bView
        default:
            let bView = LiquidGlassView(blurRadius: 6, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
            bView.translatesAutoresizingMaskIntoConstraints = false
            bView.solidViewColour = .discordGray.withAlphaComponent(0.8)
            bView.scaleFactor = PerformanceManager.scaleFactor
            bView.frameInterval = PerformanceManager.frameInterval
            return bView
        }
    }()
    
    public var channel: TextChannel?
    public var tokenInputView: Bool?
    
    let buttonBackground: UIView? = {
        switch device {
        case .a4:
            let background = UIView()
            background.layer.cornerRadius = 20
            background.backgroundColor = .discordGray.withAlphaComponent(0.8)
            background.isUserInteractionEnabled = false
            return background
        default:
            let background = LiquidGlassView(blurRadius: 6, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
            background.scaleFactor = 0.25
            background.frameInterval = 6
            background.isUserInteractionEnabled = false
            background.solidViewColour = .discordGray.withAlphaComponent(0.8)
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
    
    public let cancelButton: LargeHitAreaButton = {
        let button = LargeHitAreaButton()
        button.setImage(.init(systemName: "xmark.circle.fill", tintColor: .white), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
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
        
        //sendButton.setTitle("Send", for: .normal)
        
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
        guard let buttonBackground = buttonBackground, let backgroundView = backgroundView else { return }
        
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
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
        guard let buttonBackground = buttonBackground, let backgroundView = backgroundView else { return }
        buttonBackground.pinToCenter(of: sendButton)
        buttonBackground.heightAnchor.constraint(equalToConstant: 40).isActive = true
        buttonBackground.widthAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    func deactivateButtonBackgroundConstraings() {
        guard let buttonBackground = buttonBackground, let backgroundView = backgroundView else { return }
        buttonBackground.constraints.forEach { $0.isActive = false }
    }
    
    public func editMessage(_ message: Message) {
        self.changeInputMode(to: .edit)
        self.editMessage = message
        self.textView.text = self.editMessage?.content
        self.textViewDidChange(self.textView)
        //self.addCancelButton()
    }
    
    public func replyToMessage(_ message: Message) {
        self.changeInputMode(to: .reply)
        self.replyMessage = message
        //self.addCancelButton()
    }
    
    public func changeInputMode(to mode: inputMode) {
        switch mode {
        case .reply:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [unowned self] in
                self.replyMessageAction()
            }
        case .edit:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [unowned self] in
                self.editMessageAction()
            }
        case .send:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [unowned self] in
                self.sendMessageAction()
            }
        }
    }
    
    var buttonIsActive: Bool = true
    
    private func replyMessageAction() {
        guard buttonIsActive == true else { return }
        self.buttonIsActive = false
        
        guard let channel = self.channel, let replyMessage = self.replyMessage else { return }
        
        let newMessage = Message(clientUser, ["content": self.textView.text])
        
        self.textView.text = nil
        self.editMessage = nil
        self.changeInputMode(to: .send)
        self.textViewDidChange(self.textView)
        self.buttonIsActive = true
        
        clientUser.reply(to: replyMessage, with: newMessage, in: channel) { [weak self] error in
            guard let self = self else { return }
            
            //self.removeCancelButton()
        }
    }
    
    private func sendMessageAction() {
        guard buttonIsActive == true else { return }
        self.buttonIsActive = false
        
        guard let channel = self.channel else { return }
        
        let message = Message(clientUser, ["content": self.textView.text])
        self.textView.text = nil
        self.buttonIsActive = true
        self.textViewDidChange(self.textView)
        
        clientUser.send(message: message, in: channel) { [weak self] error in
            guard let self = self else { return }
            
        }
    }
    
    private func editMessageAction() {
        guard buttonIsActive == true else { return }
        self.buttonIsActive = false
        
        guard let channel = self.channel, let editMessage = self.editMessage else { return }
        
        let newMessage = Message(clientUser, ["content": self.textView.text])
        
        self.textView.text = nil
        self.editMessage = nil
        self.changeInputMode(to: .send)
        self.textViewDidChange(self.textView)
        self.buttonIsActive = true
        
        clientUser.edit(message: editMessage, to: newMessage, in: channel) { [weak self] error in
            guard let self = self else { return }
            
            //self.removeCancelButton()
        }
    }
    
    public func addCancelButton() {
        cancelButton.addAction(for: .touchUpInside) { [weak self] in
            guard let self = self else { return }
            self.textView.text = nil
            self.editMessage = nil
            self.changeInputMode(to: .send)
            self.textViewDidChange(self.textView)
            self.sendButton.isUserInteractionEnabled = true
            self.removeCancelButton()
        }
        buttonStack.addArrangedSubview(cancelButton)
    }
    
    public func removeCancelButton() {
        // Remove first
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        buttonBackground?.removeFromSuperview()
        deactivateButtonBackgroundConstraings()

        // Add the button back
        buttonStack.addArrangedSubview(sendButton)

        // Add the background **inside the sendButton** behind its content
        if let background = buttonBackground {
            sendButton.insertSubview(background, at: 0) // always behind content
            activateButtonBackgroundConstraints()
        }
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

