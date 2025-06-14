import UIKit

class SuggestionCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            label.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with text: String) {
        label.text = text
    }
    
    // MARK: - Selection State
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateHighlightState()
        }
    }
    
    private func updateSelectionState() {
        UIView.animate(withDuration: 0.2) {
            if self.isSelected {
                self.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
                self.label.textColor = UIColor.systemBlue
            } else {
                self.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
                self.label.textColor = UIColor.systemBlue
            }
        }
    }
    
    private func updateHighlightState() {
        UIView.animate(withDuration: 0.1) {
            if self.isHighlighted {
                self.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } else {
                self.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
                self.transform = .identity
            }
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        transform = .identity
        contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
    }
}