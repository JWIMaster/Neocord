//
//  ProfileView.swift
//  Cascade
//
//  Created by JWI on 2/11/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit

class ProfileView: UIView {
    var user: User?
    var userProfile: UserProfile?
    var member: GuildMember?
    
    // MARK: - Subviews
    
    var grabber: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        view.layer.cornerRadius = 2
        return view
    }()
    
    var displayname = UILabel()
    var username = UILabel()
    var profilePicture = UIImageView()
    var profileBanner = UIImageView()
    
    var bioBackground: UIView? = {
        switch device {
        case .a4:
            return UIView()
        default:
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true, filterOptions: [.darken, .depth, .rim, .tint])
            glass.shadowRadius = 6
            return glass
        }
    }()
    
    var bio = UILabel()
    
    var containerView = UIView()
    var scrollView = UIScrollView()
    
    var backgroundView: UIView? = {
        switch device {
        case .a4:
            return UIView()
        default:
            let bg = LiquidGlassView(
                blurRadius: 6,
                cornerRadius: 0,
                snapshotTargetView: nil,
                disableBlur: true,
                filterOptions: [.depth, .darken, .rim, .tint]
            )
            bg.shadowRadius = 50
            bg.shadowOpacity = 1
            return bg
        }
    }()
    
    /*func makeRole(name: String, color: UIColor) -> UIView {
        
    }*/
    
    // MARK: - Init
    
    init(user: User, member: GuildMember? = nil) {
        self.member = member
        self.user = user
        super.init(frame: .zero)
        
        setup() // Build base layout immediately
        
        // Fetch updated user info in the background
        clientUser.getUserProfile(withID: user.id!) { [weak self] user, userProfile, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.user = user
                self.userProfile = userProfile
                self.updateProfileInfo()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    func setup() {
        setupSubviews()
        setupProfileName()
        setupProfilePicture()
        setupBio()
        setupConstraints()
        setupGestureRecognizer()
    }
    
    func setupSubviews() {
        guard let backgroundView = backgroundView, let bioBackground = bioBackground else { return }
        
        addSubview(backgroundView)
        addSubview(scrollView)
        scrollView.addSubview(containerView)
   
        
        containerView.addSubview(profileBanner)
        containerView.addSubview(profilePicture)
        containerView.addSubview(displayname)
        containerView.addSubview(username)
        
        containerView.addSubview(bioBackground)
        containerView.addSubview(bio)
        
        addSubview(grabber) // grabber sits at the top of the view
    }
    
    func setupConstraints() {
        guard let backgroundView = backgroundView, let bioBackground = bioBackground else { return }
        
        let views = [backgroundView, scrollView, containerView, profileBanner, profilePicture, displayname, username, bio, bioBackground, grabber]
        for v in views { v.translatesAutoresizingMaskIntoConstraints = false }
        
        // Background
        backgroundView.pinToEdges(of: self)
        
        // Scroll view fills background
        scrollView.pinToEdges(of: self)
        
        // Container view inside scroll view
        containerView.pinToEdges(of: scrollView)
        containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        
        // Grabber at top
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 40),
            grabber.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        bioBackground.pinToEdges(of: bio, insetBy: .init(top: -10, left: -10, bottom: -10, right: -10))
        
        // Banner, avatar, name
        NSLayoutConstraint.activate([
            profileBanner.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            profileBanner.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 2),
            profileBanner.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
            profileBanner.heightAnchor.constraint(equalToConstant: 100),
            
            profilePicture.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            profilePicture.centerYAnchor.constraint(equalTo: profileBanner.bottomAnchor),
            profilePicture.widthAnchor.constraint(equalToConstant: 80),
            profilePicture.heightAnchor.constraint(equalToConstant: 80),
            
            displayname.topAnchor.constraint(equalTo: profilePicture.bottomAnchor, constant: 4),
            displayname.leadingAnchor.constraint(equalTo: profilePicture.leadingAnchor),
            
            username.topAnchor.constraint(equalTo: displayname.bottomAnchor, constant: 4),
            username.leadingAnchor.constraint(equalTo: displayname.leadingAnchor),
            
            bio.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            bio.topAnchor.constraint(equalTo: username.bottomAnchor, constant: 20),
            bio.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bio.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func setupProfileName() {
        displayname.text = member?.guildNickname ?? user?.displayname ?? user?.username ?? "unknown"
        displayname.textColor = .white
        displayname.backgroundColor = .clear
        displayname.font = .boldSystemFont(ofSize: 25)
        displayname.lineBreakMode = .byCharWrapping
        displayname.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        displayname.numberOfLines = 0
        
        username.text = user?.username ?? "unknown"
        username.textColor = .white
        username.backgroundColor = .clear
        username.font = .systemFont(ofSize: 17)
    }
    
    func setupBio() {
        bioStringParsing()
        bio.backgroundColor = .clear
        //bio.isScrollEnabled = false
        //bio.isEditable = false
        bio.numberOfLines = 0
        bio.lineBreakMode = .byWordWrapping
        bio.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
    }
    
    func bioStringParsing() {
        let bioText = user?.bio ?? "unknown"
        
        let attributedText = NSMutableAttributedString(
            string: "About me\n",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 13),
                .foregroundColor: UIColor.gray
            ]
        )
        
        let bioContent = NSAttributedString(
            string: bioText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white
            ]
        )
        
        attributedText.append(bioContent)
        bio.attributedText = attributedText
        bio.sizeToFit()
    }
    
    
    func setupProfilePicture() {
        guard let user = user else { return }
        
        AvatarCache.shared.avatar(for: user) { [weak self] image, color in
            guard let self = self, let image = image, let color = color else { return }
            
            let resized = image.resizeImage(image, targetSize: CGSize(width: 80, height: 80))
            
            DispatchQueue.main.async {
                self.profilePicture.image = resized
                self.profilePicture.contentMode = .scaleAspectFit
                self.profilePicture.layer.shadowRadius = 6
                self.profilePicture.layer.shadowOpacity = 0.5
                self.profilePicture.layer.shadowColor = UIColor.black.cgColor
                self.profilePicture.layer.shouldRasterize = true
                self.profilePicture.layer.rasterizationScale = UIScreen.main.scale
                self.profilePicture.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 80, height: 80), cornerRadius: 40).cgPath
                
                self.profileBanner.backgroundColor = color
                if let bg = self.backgroundView as? LiquidGlassView, let bioBackground = self.bioBackground as? LiquidGlassView {
                    bioBackground.tintColorForGlass = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(0.4)
                    bioBackground.setNeedsLayout()
                } else {
                    self.backgroundView?.backgroundColor = color.withIncreasedSaturation(factor: 1.4)
                    self.backgroundView?.setNeedsLayout()
                }
            }
        }
    }
    
    // MARK: - Colors
    
    func updateProfileColors() {
        guard let bg = self.backgroundView as? LiquidGlassView,
              let bioBg = self.bioBackground as? LiquidGlassView else { return }

        if let userProfile = userProfile, !userProfile.themeColors.isEmpty {
            let colors = userProfile.themeColors.map { $0.withIncreasedSaturation(factor: 0.7) }
            let shifted = shiftedGradientColorsIfTwoDistinct(colors)
            
            bg.tintGradientColors = shifted
            bg.tintColorForGlass = .clear
            bg.setNeedsLayout()

            let bioColors = userProfile.themeColors.map { $0.withAlphaComponent(0.4).withIncreasedSaturation(factor: 0.7) }
            bioBg.tintGradientColors = shiftedGradientColorsIfTwoDistinct(bioColors)
            bioBg.tintColorForGlass = .clear
            bioBg.setNeedsLayout()
        } else if let user = user {
            AvatarCache.shared.avatar(for: user) { [weak self] image, color in
                guard let self = self, let color = color else { return }
                DispatchQueue.main.async {
                    bg.tintGradientColors = nil
                    bg.tintColorForGlass = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(1)
                    bg.shadowColor = color.withIncreasedSaturation(factor: 1.4).cgColor
                    bg.shadowOpacity = 0.6
                    bg.setNeedsLayout()

                    bioBg.tintGradientColors = nil
                    bioBg.tintColorForGlass = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(0.4)
                    bioBg.setNeedsLayout()
                }
            }
        }
    }
    
    func shiftedGradientColorsIfTwoDistinct(_ colors: [UIColor]) -> [UIColor] {
        guard colors.count == 2, colors[0] != colors[1] else {
            return colors
        }

        let midColor = interpolateColor(from: colors[0], to: colors[1], fraction: 0.5)
        return [midColor, colors[1]]
    }

    func interpolateColor(from: UIColor, to: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(red: r1 + (r2 - r1) * fraction,
                       green: g1 + (g2 - g1) * fraction,
                       blue: b1 + (b2 - b1) * fraction,
                       alpha: a1 + (a2 - a1) * fraction)
    }

    // MARK: - Grabber / Drag-to-Dismiss
    
    
    func dismissProfile() {
        if let dmVC = parentViewController as? TextViewController {
            dmVC.removeProfileView()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()

        guard let backgroundView = backgroundView else { return }

        // Rounded top corners
        let path = UIBezierPath(
            roundedRect: backgroundView.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 22, height: 22)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        backgroundView.layer.mask = mask

        scrollView.clipsToBounds = true
        scrollView.layer.cornerRadius = 22

        // Force bio label to size to content
        let maxWidth = scrollView.bounds.width * 0.8
        let size = bio.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        bio.frame.size.height = size.height

        // Force containerView to expand to fit content
        containerView.layoutIfNeeded()
        
        // Manually set scrollView contentSize
        scrollView.contentSize = CGSize(
            width: scrollView.bounds.width,
            height: containerView.frame.maxY + 20 // optional padding
        )
    }

    
    // MARK: - Update profile
    
    func updateProfileInfo() {
        displayname.text = member?.guildNickname ?? user?.displayname ?? user?.username ?? "unknown"
        let name = user?.username ?? "unknown"
        let pronouns = userProfile?.pronouns ?? ""
        
        username.text = pronouns.isEmpty ? name : "\(name) • \(pronouns)"
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bioStringParsing()
        CATransaction.commit()

        setupProfilePicture()
        updateProfileColors()
        
        bio.setNeedsLayout()
        backgroundView?.setNeedsLayout()
        bioBackground?.setNeedsLayout()
        containerView.setNeedsLayout()
        setNeedsLayout()
    }
    var lastTranslationY: CGFloat = 0
    var dragStarted = false
}







