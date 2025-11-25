import UIKit
import UIKitCompatKit
import SwiftcordLegacy
import UIKitExtensions

// MARK: - RoleCollectionView
class RoleCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // Roles array
    var roles: [Role] = [] {
        didSet {
            collectionView.reloadData()
            updateCollectionViewHeight()
        }
    }

    // Height constraint
    private var collectionViewHeightConstraint: NSLayoutConstraint?

    // CollectionView
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.sectionInset = .zero

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.isScrollEnabled = false
        cv.clipsToBounds = false
        cv.register(RoleCell.self, forCellWithReuseIdentifier: RoleCell.reuseIdentifier)
        return cv
    }()

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }

    private func setupCollectionView() {
        addSubview(collectionView)
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 1)
        collectionViewHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: Compute height manually
    private func updateCollectionViewHeight() {
        // Fixed cell height and spacing
        let cellHeight: CGFloat = 24
        let interItemSpacing: CGFloat = 6
        let lineSpacing: CGFloat = 6
        let collectionWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var maxHeight: CGFloat = 0

        for role in roles {
            let label = UILabel()
            label.font = .systemFont(ofSize: 12)
            label.text = role.name
            label.sizeToFit()
            let roleWidth = min(label.frame.width + 32, collectionWidth) // icon + padding

            if xOffset + roleWidth > collectionWidth {
                // Wrap to next line
                xOffset = 0
                yOffset += cellHeight + lineSpacing
            }
            xOffset += roleWidth + interItemSpacing
            maxHeight = yOffset + cellHeight
        }

        collectionViewHeightConstraint?.constant = maxHeight
        invalidateIntrinsicContentSize()
    }

    // MARK: Intrinsic content size
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: collectionViewHeightConstraint?.constant ?? 1)
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roles.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RoleCell.reuseIdentifier,
                                                            for: indexPath) as? RoleCell else {
            return UICollectionViewCell()
        }
        cell.role = roles[indexPath.item]
        return cell
    }

    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let role = roles[indexPath.item]
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.text = role.name
        label.sizeToFit()
        let width = min(label.frame.width + 32, collectionView.bounds.width) // icon + padding
        return CGSize(width: width, height: 24)
    }
}

// MARK: - Left-aligned Flow Layout
class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0

        for layoutAttribute in attributes where layoutAttribute.representedElementCategory == .cell {
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            layoutAttribute.frame.origin.x = leftMargin
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        return attributes
    }
}
