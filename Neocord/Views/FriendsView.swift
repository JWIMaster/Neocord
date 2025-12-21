//
//  FriendsView.swift
//  Neocord
//
//  Created by JWI on 13/11/2025.
//

import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy

class FriendsView: UIView {
    private var backgroundView: UIView = {
        if ThemeEngine.enableGlass {
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true, filterExclusions: ThemeEngine.glassFilterExclusions)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
            return glass
        } else {
            let bg = UIView()
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            bg.layer.cornerRadius = 22
            bg.translatesAutoresizingMaskIntoConstraints = false
            return bg
        }
    }()

    lazy var friendsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.layer.cornerRadius = 22
        cv.backgroundColor = .clear
        cv.register(FriendCell.self, forCellWithReuseIdentifier: FriendCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    var friends = [User]()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(backgroundView)
        backgroundView.addSubview(friendsCollectionView)
        backgroundView.pinToEdges(of: self)
        friendsCollectionView.pinToEdges(of: self.backgroundView)
    }
    
    
    func reloadFriends() {
        self.friends = []
        let sortedUsers = activeClient.friends.sorted {
            let name1 = $0.displayname ?? $0.username ?? "unknown"
            let name2 = $1.displayname ?? $1.username ?? "unknown"
            return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
        }
        self.friends = sortedUsers
        DispatchQueue.main.async {
            self.friendsCollectionView.reloadData()
        }
    }
}

extension FriendsView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FriendCell.reuseID, for: indexPath) as? FriendCell else { return UICollectionViewCell() }
        cell.configure(with: friends[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 20
        return CGSize(width: width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if ThemeEngine.enableAnimations {
            cell.springAnimation()
        }
    }
}
