import UIKit
import Messages

class QuickActionsViewController: UIViewController {
    weak var delegate: QuickActionsDelegate?
    
    // MARK: - UI Components
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var balanceButton: QuickActionButton = {
        let button = QuickActionButton()
        button.configure(
            title: "Balance",
            emoji: "💰",
            color: .systemBlue
        )
        button.addTarget(self, action: #selector(balanceButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var creditButton: QuickActionButton = {
        let button = QuickActionButton()
        button.configure(
            title: "Add Money",
            emoji: "➕",
            color: .systemGreen
        )
        button.addTarget(self, action: #selector(creditButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var listButton: QuickActionButton = {
        let button = QuickActionButton()
        button.configure(
            title: "Lists",
            emoji: "📝",
            color: .systemOrange
        )
        button.addTarget(self, action: #selector(listButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var moreButton: QuickActionButton = {
        let button = QuickActionButton()
        button.configure(
            title: "More",
            emoji: "⚙️",
            color: .systemGray
        )
        button.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Add main stack view
        view.addSubview(stackView)
        view.addSubview(loadingView)
        
        // Add buttons to stack
        stackView.addArrangedSubview(balanceButton)
        stackView.addArrangedSubview(creditButton)
        stackView.addArrangedSubview(listButton)
        stackView.addArrangedSubview(moreButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func balanceButtonTapped() {
        let command = ConcreteCommand(
            type: .account,
            action: .balance,
            parameters: [],
            rawText: "account balance"
        )
        delegate?.quickActionsDidSelectCommand(command)
    }
    
    @objc private func creditButtonTapped() {
        // Show amount input for credit
        showAmountInput(for: .credit)
    }
    
    @objc private func listButtonTapped() {
        let command = ConcreteCommand(
            type: .list,
            action: .list,
            parameters: [],
            rawText: "list list"
        )
        delegate?.quickActionsDidSelectCommand(command)
    }
    
    @objc private func moreButtonTapped() {
        delegate?.quickActionsDidRequestExpanded()
    }
    
    // MARK: - Amount Input
    
    private func showAmountInput(for action: CommandAction) {
        let alert = UIAlertController(
            title: action.displayName,
            message: "Enter amount",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "$0.00"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            guard let amountText = alert.textFields?.first?.text,
                  !amountText.isEmpty else { return }
            
            let parameters = [ParameterBuilder.amount(amountText)]
            let command = ConcreteCommand(
                type: .account,
                action: action,
                parameters: parameters,
                rawText: "account \(action.rawValue) \(amountText)"
            )
            
            self.delegate?.quickActionsDidSelectCommand(command)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - State Management
    
    func showLoading() {
        loadingView.isHidden = false
        stackView.isUserInteractionEnabled = false
    }
    
    func hideLoading() {
        loadingView.isHidden = true
        stackView.isUserInteractionEnabled = true
    }
    
    func updateWithResult(_ result: CommandResponse) {
        // Update UI based on result
        if result.success {
            showSuccessAnimation()
        } else {
            showErrorAnimation()
        }
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func reset() {
        hideLoading()
        // Reset any state
    }
    
    // MARK: - Animations
    
    private func showSuccessAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.view.backgroundColor = UIColor.systemBackground
            }
        }
    }
    
    private func showErrorAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.view.backgroundColor = UIColor.systemBackground
            }
        }
    }
}