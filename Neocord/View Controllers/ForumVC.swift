//
//  ForumViewController.swift
//  Neocord
//
//  Created by JWI on 5/11/2025.
//

import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import LiveFrost
import iOS6BarFix

class ForumViewController: UIViewController {

    let forum: GuildForum
    var threads: [GuildThread] = []
    
    var offset: CGFloat {
        if #available(iOS 6.0.1, *) {
            return UIApplication.shared.statusBarFrame.height+(self.navigationController?.navigationBar.frame.height)!
        } else {
            return UIApplication.shared.statusBarFrame.height*2+(self.navigationController?.navigationBar.frame.height)!
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(ChannelButtonCell.self, forCellWithReuseIdentifier: ChannelButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    init(forum: GuildForum) {
        self.forum = forum
        super.init(nibName: nil, bundle: nil)
        self.title = forum.name ?? "Forum"
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .discordGray
        
        if #unavailable(iOS 7.0.1) {
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(self, true)
        }
        
        view.addSubview(collectionView)
        collectionView.pinToEdges(of: view, insetBy: .init(top: offset, left: 0, bottom: 0, right: 0))
        
        loadThreads()
        
        // Listen for Thread List Sync events from the gateway
        clientUser.gateway?.handleThreadListSync = { [weak self] guildId in
            guard let self = self else { return }
            guard guildId == self.forum.guild?.id else { return }
            self.loadThreads()
        }
    }
    
    func loadThreads() {
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading threads…"
        loadingLabel.textColor = .lightGray
        loadingLabel.font = .systemFont(ofSize: 14)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingLabel)
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        clientUser.getForumThreads(for: self.forum) { threads in
            DispatchQueue.main.async {
                loadingLabel.removeFromSuperview()
                self.threads = threads.sorted {
                    ($0.lastMessageID?.rawValue ?? 0) > ($1.lastMessageID?.rawValue ?? 0)
                }
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - Collection View
extension ForumViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return threads.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let thread = threads[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelButtonCell.reuseID, for: indexPath) as! ChannelButtonCell
        cell.configure(with: thread)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if ThemeEngine.enableAnimations {
            cell.springAnimation()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let thread = threads[indexPath.item]
        guard let guild = forum.guild else { return }
        clientUser.subscribeToChannel(guild, thread)
        navigationController?.pushViewController(TextViewController(channel: thread), animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 20
        return CGSize(width: width, height: 40)
    }
}
