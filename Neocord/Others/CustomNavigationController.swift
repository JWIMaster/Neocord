import UIKit
import UIKitCompatKit
import UIKitExtensions

public class CustomNavigationController: UINavigationController {

    private let customNavBar: UIView? = {
        switch device {
        case .a4:
            let navBar = UIView()
            navBar.layer.cornerRadius = 12
            navBar.backgroundColor = .discordGray.withAlphaComponent(0.8)
            navBar.layer.shadowRadius = 12
            navBar.layer.shadowOpacity = 0.6
            return navBar
        default:
            let glassView = LiquidGlassView(blurRadius: 6, cornerRadius: 12, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
            glassView.frameInterval = PerformanceManager.frameInterval
            glassView.scaleFactor = PerformanceManager.scaleFactor
            glassView.solidViewColour = .discordGray.withAlphaComponent(0.8)
            glassView.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            glassView.translatesAutoresizingMaskIntoConstraints = false
            return glassView
        }
    }()
    
    weak var snapshotTargetView: UIView?
    
    public var navBarFrame: UIView = UIView()

    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)

    public var navBarOpacity: CGFloat {
        get { customNavBar!.alpha }
        set { customNavBar!.alpha = max(0, min(1, newValue)) } // clamp 0–1
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let customNavBar = customNavBar else { return }
        // Hide the default navbar
        navBarFrame = UIView(frame: navigationBar.frame)
        
        setNavigationBarHidden(true, animated: false)
        isNavigationBarHidden = true

        // Add LiquidGlassView
        view.addSubview(customNavBar)
        view.bringSubviewToFront(customNavBar)
        layoutCustomNavBar()


        // Setup title and back button
        setupTitleAndBack()

        // Update navbar whenever top VC changes
        delegate = self
        updateTitle(for: topViewController)
        updateBackButton(for: topViewController)
    }
    
    func layoutBar() {
        customNavBar?.setNeedsLayout()
        titleLabel.setNeedsLayout()
    }

    private func layoutCustomNavBar() {
        guard let customNavBar = customNavBar else { return }
        customNavBar.widthAnchor.constraint(equalToConstant: navBarFrame.frame.width-20).isActive = true
        customNavBar.heightAnchor.constraint(equalToConstant: navBarFrame.frame.height).isActive = true
        customNavBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        if #available(iOS 11.0, *) {
            let guide: UIKit.UILayoutGuide = view.safeAreaLayoutGuide
            customNavBar.translatesAutoresizingMaskIntoConstraints = false
            let topConstraint = NSLayoutConstraint(
                item: customNavBar,
                attribute: .top,
                relatedBy: .equal,
                toItem: guide,
                attribute: .top,
                multiplier: 1,
                constant: 0
            )
            view.addConstraint(topConstraint)

        } else {
            customNavBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 22).isActive = true
        }
    }

    private func setupTitleAndBack() {
        // Title label
        guard let customNavBar = customNavBar else { return }
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail
        
        titleLabel.numberOfLines = 1
        customNavBar.addSubview(titleLabel)

        // Back button
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.backgroundColor = .clear
        backButton.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.addSubview(backButton)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        titleLabel.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor).isActive = true
        
        let maxWidthConstraint = NSLayoutConstraint(
            item: titleLabel,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: customNavBar,
            attribute: .width,
            multiplier: 0.55,
            constant: 0 // leave room for back button
        )
        customNavBar.addConstraint(maxWidthConstraint)
        
        NSLayoutConstraint.activate([
            
            backButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor)
        ])
    }

    @objc private func goBack() {
        popViewController(animated: true)
    }

    func updateTitle(for viewController: UIViewController?) {
        titleLabel.text = viewController?.title
        titleLabel.sizeThatFits(.init(width: self.navBarFrame.frame.width*0.8, height: self.navBarFrame.frame.height))
        //titleLabel.setIsHidden(viewController == viewControllers.first, animated: true)
    }

    private func updateBackButton(for viewController: UIViewController?) {
        //backButton.isHidden = viewController == viewControllers.first
        backButton.setIsHidden(viewController == viewControllers.first, animated: true)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        
        if let customNavBar = customNavBar as? LiquidGlassView {
            
        } else {
            customNavBar!.layer.shadowPath = UIBezierPath(roundedRect: customNavBar!.bounds, cornerRadius: 12).cgPath
        }
        
        guard let superview = self.view.superview, let customNavBar = customNavBar as? LiquidGlassView else { return }
        self.snapshotTargetView = superview
        customNavBar.snapshotTargetView = snapshotTargetView
    }
    
    private func updateNavBar(for viewController: UIViewController?) {
        guard let viewController = viewController else { return }

        let isRoot = (viewController == viewControllers.first)
        let newTitle = viewController.title ?? ""

        titleLabel.isHidden = false
        titleLabel.text = newTitle
        titleLabel.alpha = 0

        if isRoot {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.backButton.alpha = 0
                self.titleLabel.alpha = 1
            } completion: { _ in
                self.backButton.isHidden = true
            }
        } else {
            self.backButton.isHidden = false
            self.backButton.alpha = 0
            self.titleLabel.alpha = 0
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.backButton.alpha = 1
                self.titleLabel.alpha = 1
            }
        }
    }





}

// MARK: - UINavigationControllerDelegate
extension CustomNavigationController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        updateNavBar(for: viewController)
    }
}


public extension UIView {
    func setIsHidden(_ hidden: Bool, animated: Bool) {
        if animated {
            if self.isHidden && !hidden {
                self.alpha = 0.0
                self.isHidden = false
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = hidden ? 0.0 : 1.0
            }) { (complete) in
                self.isHidden = hidden
            }
        } else {
            self.isHidden = hidden
        }
    }
}
