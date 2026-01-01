//
//  LoadingView.swift
//  Neocord
//
//  Created by JWI on 6/12/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import FoundationCompatKit
import SwiftcordLegacy

class LoadingView: UIView {

    private let backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(
                blurRadius: 0,
                cornerRadius: 22,
                disableBlur: true,
                filterExclusions: ThemeEngine.glassFilterExclusions
            )
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.tintColorForGlass = .discordGray
            return glass
        } else {
            let bg = UIView()
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            bg.layer.cornerRadius = 22
            return bg
        }
    }()

    private let spinner: UIActivityIndicatorView = {
        let sp: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            sp = UIActivityIndicatorView(style: .large)
        } else {
            sp = UIActivityIndicatorView(style: .white)
        }
        sp.translatesAutoresizingMaskIntoConstraints = false
        sp.hidesWhenStopped = false
        return sp
    }()

    private let loadingText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17)
        label.backgroundColor = .clear
        label.textColor = .white
        label.text = "Waiting for Ready.."
        return label
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(backgroundView)
        addSubview(contentStack)

        contentStack.addArrangedSubview(loadingText)

        // Bubble padding
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        backgroundView.pinToEdges(of: self) // background matches bubble size
    }
}
