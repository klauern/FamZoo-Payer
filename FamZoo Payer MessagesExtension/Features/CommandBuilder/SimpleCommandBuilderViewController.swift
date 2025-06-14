import UIKit
import Messages

class SimpleCommandBuilderViewController: UIViewController {
    weak var delegate: CommandBuilderDelegate?
    
    private lazy var textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Type command (e.g., 'account balance')"
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Command", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var compactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("← Compact", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(compactTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "💰 FamZoo Command Builder"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(compactButton)
        view.addSubview(textField)
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            compactButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            compactButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            textField.topAnchor.constraint(equalTo: compactButton.bottomAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 44),
            
            sendButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func sendTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        
        // Parse simple commands
        let components = text.lowercased().components(separatedBy: " ")
        guard components.count >= 2 else { return }
        
        let type: CommandType
        let action: CommandAction
        
        switch components[0] {
        case "account", "a":
            type = .account
        case "list", "l":
            type = .list
        default:
            type = .account
        }
        
        switch components[1] {
        case "balance", "b":
            action = .balance
        case "credit", "c":
            action = .credit
        case "list", "ls":
            action = .list
        default:
            action = .balance
        }
        
        let command = SimpleCommand(type: type, action: action, rawText: text)
        delegate?.commandBuilderDidCreateCommand(command)
    }
    
    @objc private func compactTapped() {
        delegate?.commandBuilderDidRequestCompact()
    }
    
    // State management
    func showLoading() {
        sendButton.isEnabled = false
        sendButton.alpha = 0.5
    }
    
    func hideLoading() {
        sendButton.isEnabled = true
        sendButton.alpha = 1.0
    }
    
    func updateWithResult(_ result: CommandResponse) {
        textField.text = ""
        showSuccessMessage(result.message)
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func reset() {
        hideLoading()
        textField.text = ""
    }
    
    private func showSuccessMessage(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}