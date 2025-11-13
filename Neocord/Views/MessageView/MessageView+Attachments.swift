//
//  MessageView+Attachments.swift
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

extension MessageView {
    func getAttachment(attachment: Attachment) {
        guard let attachmentWidth = attachment.width, let attachmentHeight = attachment.height else { return }
        
        let aspectRatio = attachmentWidth / attachmentHeight
        let width = UIScreen.main.bounds.width-40
        let height = width / aspectRatio
        let scaledSize = CGSize(width: width, height: height)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.messageAttachments = imageView
        
        self.messageContent.addArrangedSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.messageContent.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.messageContent.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio)
        ])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageClick))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        
        attachment.fetch { [weak imageView] attachment in
            guard let imageView = imageView, let image = attachment as? UIImage else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                autoreleasepool {
                    let resizedImage = image.getThumbnail(ofQuality: .low)
                    DispatchQueue.main.async {
                        imageView.image = resizedImage
                        imageView.backgroundColor = .clear
                    }
                }
            }
        }
    }
    
    //MARK: TODO cannot fix multi attachments on iOS 6 it is slow as hell for some reason
    func setupAttachments() {
        guard let message = message else {
            return
        }
        
        if #available(iOS 7.0.1, *) {
            setupAttachments7()
        } else {
            guard let firstAttachment = message.attachments.first else { return }
            getAttachment(attachment: firstAttachment)
        }
    }
    
    func setupAttachments7() {
        guard let message = message else { return }
        let attachments = message.attachments
        guard !attachments.isEmpty else { return }
        var index = 0
        
        //Stack of all the attachments
        let attachmentStack = UIStackView()
        attachmentStack.axis = .vertical
        attachmentStack.spacing = 8
        attachmentStack.distribution = .fillEqually
        attachmentStack.translatesAutoresizingMaskIntoConstraints = false
        
        while index < attachments.count {
            //Stack for row of 2 attachments
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            
            // Add up to 2 attachments per row
            for increment in 0...1 where index + increment < attachments.count {
                let attachment = attachments[index + increment]
                
                guard let attachmentWidth = attachment.width, let attachmentHeight = attachment.height else { return }
                
                let aspectRatio = attachmentWidth / attachmentHeight
                let width = (UIScreen.main.bounds.width-40)/2
                let height = width / aspectRatio
                let scaledSize = CGSize(width: width, height: height)
                
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageClick))
                tapGesture.cancelsTouchesInView = false
                tapGesture.delegate = self
                imageView.addGestureRecognizer(tapGesture)
                imageView.isUserInteractionEnabled = true
                rowStack.addArrangedSubview(imageView)
                
                //Set height or else behaves poorly
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio).isActive = true
                
                // Fetch image async
                attachment.fetch { [weak imageView] attachment in
                    guard let imageView = imageView, let image = attachment as? UIImage else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        autoreleasepool {
                            let resizedImage = image.getThumbnail(ofQuality: .low)
                            DispatchQueue.main.async {
                                imageView.image = resizedImage
                                imageView.backgroundColor = .clear
                            }
                        }
                    }
                }
            }
            attachmentStack.addArrangedSubview(rowStack)
            //Move onto next pair
            index += 2
        }
        self.messageContent.addArrangedSubview(attachmentStack)
    }
}
