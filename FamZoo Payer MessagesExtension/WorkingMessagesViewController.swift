import UIKit
import Messages

class WorkingMessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        updateUI(for: presentationStyle)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let balanceButton = createButton(title: "💰\nBalance", tag: 1)
        let creditButton = createButton(title: "➕\nCredit", tag: 2)
        let debitButton = createButton(title: "➖\nDebit", tag: 3)
        let moreButton = createButton(title: "⚙️\nMore", tag: 4)
        
        stackView.addArrangedSubview(balanceButton)
        stackView.addArrangedSubview(creditButton)
        stackView.addArrangedSubview(debitButton)
        stackView.addArrangedSubview(moreButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func createButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        button.tag = tag
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func updateUI(for style: MSMessagesAppPresentationStyle) {
        switch style {
        case .compact:
            view.backgroundColor = UIColor.systemBackground
        case .expanded:
            view.backgroundColor = UIColor.systemGray6
            addExpandedContent()
        case .transcript:
            break
        @unknown default:
            break
        }
    }
    
    private func addExpandedContent() {
        // Add text field for expanded mode
        let textField = UITextField()
        textField.placeholder = "Type FamZoo command..."
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tag = 100
        
        view.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        switch sender.tag {
        case 1: // Balance
            layout.caption = "💰 $125.50"
            layout.subcaption = "Account Balance"
            layout.imageTitle = "Balance"
        case 2: // Credit
            layout.caption = "➕ $25.00"
            layout.subcaption = "Money Added"
            layout.imageTitle = "Credit"
        case 3: // Debit
            layout.caption = "➖ $10.00"
            layout.subcaption = "Money Spent"
            layout.imageTitle = "Debit"
        case 4: // More
            requestPresentationStyle(.expanded)
            return
        default:
            return
        }
        
        message.layout = layout
        
        activeConversation?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
}