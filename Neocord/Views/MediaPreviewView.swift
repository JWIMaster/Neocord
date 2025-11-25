import UIKit
import AVFoundation
import UIKitCompatKit

final class MediaPreviewView: UIView, UIScrollViewDelegate {

    // MARK: - Public Properties
    var image: UIImage? {
        didSet { configureForImage() }
    }
    
    var videoURL: URL? {
        didSet { configureForVideo() }
    }

    // MARK: - Private Views
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = .clear
        return sv
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private let dismissButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("×", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        btn.setTitleColor(.white, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
    }

    // MARK: - Setup Views
    private func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        scrollView.addSubview(imageView)
        
        addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
        
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        addGestureRecognizer(tap)
    }
    
    // MARK: - Configure Media
    private func configureForImage() {
        guard let img = image else { return }
        
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        player = nil
        playerLayer = nil
        
        imageView.image = img
        imageView.frame = CGRect(origin: .zero, size: img.size)
        scrollView.contentSize = img.size
        centerContent()
    }
    
    private func configureForVideo() {
        guard let url = videoURL else { return }
        
        imageView.image = nil
        scrollView.contentSize = scrollView.bounds.size
        imageView.frame = scrollView.bounds
        
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = scrollView.bounds
        playerLayer?.videoGravity = .resizeAspect
        scrollView.layer.addSublayer(playerLayer!)
        
        player?.play()
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return image != nil ? imageView : nil
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }
    
    private func centerContent() {
        let scrollSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let insetX = max((scrollSize.width - contentSize.width) / 2, 0)
        let insetY = max((scrollSize.height - contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
    
    // MARK: - Show / Dismiss
    func show(in parent: UIView) {
        frame = parent.bounds
        alpha = 0
        parent.addSubview(self)
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    @objc func dismissSelf() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.player?.pause()
            self.removeFromSuperview()
        })
    }
}
