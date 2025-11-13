//
//  AttachmentViewController.swift
//  MakingADiscordAPI
//
//  Created by JWI on 29/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix

final class AttachmentViewController: UIViewController, UIScrollViewDelegate {

    public var attachment: UIView

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let bottomBar: LiquidGlassView = {
        let view = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        view.solidViewColour = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(attachment: UIView) {
        self.attachment = attachment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayout()
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerAttachment()
    }

    private func setupLayout() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.addSubview(attachment)
        view.addSubview(bottomBar)
        bottomBar.addSubview(shareButton)

        scrollView.pinToEdges(of: view)

        bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomBar.heightAnchor.constraint(equalToConstant: (self.parent?.navigationController?.navigationBar.frame.height) ?? 44).isActive = true

        shareButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor).isActive = true
        shareButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor).isActive = true

        // Set the attachment frame to its intrinsic size if it's an image
        if let imageView = attachment as? UIImageView, let image = imageView.image {
            attachment.frame = CGRect(origin: .zero, size: image.size )
        } else {
            attachment.frame = scrollView.bounds
        }
        scrollView.contentSize = attachment.frame.size
    }

    private func setupActions() {
        shareButton.addTarget(self, action: #selector(presentShareSheet), for: .touchUpInside)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return (attachment is UIImageView) ? attachment : nil
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerAttachment()
    }

    private func centerAttachment() {
        let scrollViewSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let insetX = max((scrollViewSize.width - contentSize.width) / 2, 0)
        let insetY = max((scrollViewSize.height - contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }

    @objc private func presentShareSheet() {
        if let imageView = attachment as? UIImageView, let image = imageView.image {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            present(activityVC, animated: true)
        } else {
            let alert = UIAlertView(title: "Unsupported", message: "Only image attachments can be shared right now.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
}
