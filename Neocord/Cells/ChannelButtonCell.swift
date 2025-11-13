import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import SFSymbolsCompatKit
import LiveFrost

class ChannelButtonCell: UICollectionViewCell {
    
    static let reuseID = "ChannelButtonCell"
    
    private var channelIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 0
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private var channelNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17)
        lbl.textColor = .white
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var backgroundGlass: UIView? = {
        if ThemeEngine.enableGlass {
            switch device {
            case .a4:
                let bg = UIView()
                bg.layer.cornerRadius = 22
                return bg
            default:
                let lg = LiquidGlassView(blurRadius: 0, cornerRadius: 14, snapshotTargetView: nil, disableBlur: true)
                lg.shadowOpacity = 0.6
                lg.shadowRadius = 0
                lg.solidViewColour = .clear
                lg.translatesAutoresizingMaskIntoConstraints = false
                return lg
            }
        } else {
            let bg = UIView()
            bg.layer.cornerRadius = 22
            return bg
        }
    }()
    
    private var stack: UIStackView = {
        let st = UIStackView()
        st.axis = .horizontal
        st.spacing = 8
        st.alignment = .center
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        guard let backgroundGlass = backgroundGlass else { return }
        contentView.addSubview(backgroundGlass)
        contentView.addSubview(stack)
        stack.addArrangedSubview(channelIcon)
        stack.addArrangedSubview(channelNameLabel)
        
        NSLayoutConstraint.activate([
            backgroundGlass.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundGlass.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundGlass.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundGlass.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            channelIcon.widthAnchor.constraint(equalToConstant: 20),
            channelIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with channel: GuildChannel) {
        channelNameLabel.text = channel.name ?? "Unknown Channel"
        
        let iconName: String
        switch channel.type {
        case .guildText: iconName = "number"
        case .guildVoice: iconName = "speaker.wave.2"
        case .guildForum: iconName = "bubble.left.and.text.bubble.right"
        case .publicThread, .privateThread: iconName = "text.bubble"
        default: iconName = "questionmark"
        }

        channelIcon.image = UIImage(systemName: iconName, tintColor: .white)

        if let glass = backgroundGlass as? LiquidGlassView {
            glass.tintColorForGlass = .discordGray
        } else {
            backgroundGlass?.backgroundColor = .discordGray
        }
    }

}


class ChannelCategoryCell: UICollectionViewCell {
    static let reuseID = "ChannelCategoryCell"

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textColor = .lightGray
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        print("yay")
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with category: GuildCategory) {
        titleLabel.text = category.name ?? "Unknown Category"
    }
}
