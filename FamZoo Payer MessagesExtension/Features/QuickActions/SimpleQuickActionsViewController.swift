import UIKit
import Messages

class SimpleQuickActionsViewController: UIViewController {
    weak var delegate: QuickActionsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSimpleUI()
    }
    
    private func setupSimpleUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let balanceButton = createButton(title: "💰\nBalance", tag: 1)
        let creditButton = createButton(title: "➕\nAdd Money", tag: 2)
        let listButton = createButton(title: "📝\nLists", tag: 3)
        let moreButton = createButton(title: "⚙️\nMore", tag: 4)
        
        stackView.addArrangedSubview(balanceButton)
        stackView.addArrangedSubview(creditButton)
        stackView.addArrangedSubview(listButton)
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
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let command: SimpleCommand
        
        switch sender.tag {
        case 1: // Balance
            command = SimpleCommand(type: .account, action: .balance, rawText: "account balance")
        case 2: // Credit
            command = SimpleCommand(type: .account, action: .credit, rawText: "account credit")
        case 3: // Lists
            command = SimpleCommand(type: .list, action: .list, rawText: "list list")
        case 4: // More
            delegate?.quickActionsDidRequestExpanded()
            return
        default:
            return
        }
        
        delegate?.quickActionsDidSelectCommand(command)
    }
    
    // State management methods
    func showLoading() {
        view.alpha = 0.5
    }
    
    func hideLoading() {
        view.alpha = 1.0
    }
    
    func updateWithResult(_ result: CommandResponse) {
        // Simple success animation
        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = result.success ? 
                UIColor.systemGreen.withAlphaComponent(0.1) : 
                UIColor.systemRed.withAlphaComponent(0.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.view.backgroundColor = UIColor.systemBackground
            }
        }
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func reset() {
        hideLoading()
    }
}