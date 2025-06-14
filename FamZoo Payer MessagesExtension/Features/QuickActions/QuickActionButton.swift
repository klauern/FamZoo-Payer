import UIKit

class QuickActionButton: UIButton {
    
    // MARK: - UI Components
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var customTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false
        return stack
    }()
    
    // MARK: - Properties
    private var buttonColor: UIColor = .systemBlue
    
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
        // Setup button appearance
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = UIColor.systemBackground
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        
        // Add container stack view
        addSubview(containerStackView)
        
        // Add emoji and title to stack
        containerStackView.addArrangedSubview(emojiLabel)
        containerStackView.addArrangedSubview(customTitleLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            
            heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Add touch feedback
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Configuration
    
    func configure(title: String, emoji: String, color: UIColor) {
        customTitleLabel.text = title
        emojiLabel.text = emoji
        buttonColor = color
        customTitleLabel.textColor = color
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        layer.borderColor = buttonColor.withAlphaComponent(0.3).cgColor
    }
    
    // MARK: - Touch Handling
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.backgroundColor = self.buttonColor.withAlphaComponent(0.1)
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.backgroundColor = UIColor.systemBackground
        }
    }
    
    // MARK: - State Management
    
    override var isEnabled: Bool {
        didSet {
            updateEnabledState()
        }
    }
    
    private func updateEnabledState() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = self.isEnabled ? 1.0 : 0.5
        }
    }
    
    // MARK: - Accessibility
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = customTitleLabel.text
        accessibilityHint = "Tap to perform \(customTitleLabel.text ?? "action")"
    }
}

// MARK: - Quick Action Types

extension QuickActionButton {
    static func balanceButton() -> QuickActionButton {
        let button = QuickActionButton()
        button.configure(title: "Balance", emoji: "💰", color: .systemBlue)
        return button
    }
    
    static func creditButton() -> QuickActionButton {
        let button = QuickActionButton()
        button.configure(title: "Add Money", emoji: "➕", color: .systemGreen)
        return button
    }
    
    static func debitButton() -> QuickActionButton {
        let button = QuickActionButton()
        button.configure(title: "Spend", emoji: "➖", color: .systemRed)
        return button
    }
    
    static func listButton() -> QuickActionButton {
        let button = QuickActionButton()
        button.configure(title: "Lists", emoji: "📝", color: .systemOrange)
        return button
    }
    
    static func moreButton() -> QuickActionButton {
        let button = QuickActionButton()
        button.configure(title: "More", emoji: "⚙️", color: .systemGray)
        return button
    }
}