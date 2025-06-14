import UIKit
import Messages

class CommandBuilderViewController: UIViewController {
    weak var delegate: CommandBuilderDelegate?
    
    // MARK: - Properties
    private let commandParser = CommandParser()
    private var currentCommand: FamZooCommand?
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "💰 FamZoo Command Builder"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var commandTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Type command (e.g., 'account balance' or 'a b')"
        field.borderStyle = .roundedRect
        field.font = UIFont.systemFont(ofSize: 16)
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.translatesAutoresizingMaskIntoConstraints = false
        field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return field
    }()
    
    private lazy var suggestionsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.register(SuggestionCell.self, forCellWithReuseIdentifier: "SuggestionCell")
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    private lazy var templatesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Command", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var compactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("← Compact", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(compactButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Data
    private var suggestions: [String] = []
    private let commandTemplates: [CommandTemplate] = [
        CommandTemplate(title: "Check Balance", command: "account balance", description: "View account balance"),
        CommandTemplate(title: "Add Money", command: "account credit", description: "Add money to account"),
        CommandTemplate(title: "View Lists", command: "list list", description: "Show todo lists"),
        CommandTemplate(title: "Add List Item", command: "list add", description: "Add item to list")
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTemplates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        commandTextField.becomeFirstResponder()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Add main components
        view.addSubview(scrollView)
        view.addSubview(loadingView)
        scrollView.addSubview(contentView)
        
        // Add content components
        contentView.addSubview(headerView)
        contentView.addSubview(compactButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(commandTextField)
        contentView.addSubview(suggestionsCollectionView)
        contentView.addSubview(templatesStackView)
        contentView.addSubview(sendButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            compactButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            compactButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            commandTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            commandTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commandTextField.topAnchor.constraint(equalTo: compactButton.bottomAnchor, constant: 16),
            commandTextField.heightAnchor.constraint(equalToConstant: 44),
            
            suggestionsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            suggestionsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            suggestionsCollectionView.topAnchor.constraint(equalTo: commandTextField.bottomAnchor, constant: 8),
            suggestionsCollectionView.heightAnchor.constraint(equalToConstant: 40),
            
            templatesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            templatesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            templatesStackView.topAnchor.constraint(equalTo: suggestionsCollectionView.bottomAnchor, constant: 24),
            
            sendButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sendButton.topAnchor.constraint(equalTo: templatesStackView.bottomAnchor, constant: 24),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTemplates() {
        for template in commandTemplates {
            let templateView = CommandTemplateView()
            templateView.configure(with: template)
            templateView.delegate = self
            templatesStackView.addArrangedSubview(templateView)
        }
    }
    
    // MARK: - Actions
    
    @objc private func textFieldDidChange() {
        guard let text = commandTextField.text else { return }
        
        // Update suggestions
        suggestions = commandParser.suggestCompletions(for: text)
        suggestionsCollectionView.reloadData()
        
        // Validate command
        validateCurrentCommand()
    }
    
    @objc private func sendButtonTapped() {
        guard let command = currentCommand else { return }
        delegate?.commandBuilderDidCreateCommand(command)
    }
    
    @objc private func compactButtonTapped() {
        delegate?.commandBuilderDidRequestCompact()
    }
    
    // MARK: - Command Validation
    
    private func validateCurrentCommand() {
        guard let text = commandTextField.text, !text.isEmpty else {
            currentCommand = nil
            sendButton.isEnabled = false
            return
        }
        
        currentCommand = commandParser.parse(text)
        
        if let command = currentCommand {
            let validation = command.validate()
            sendButton.isEnabled = validation.isValid
            
            if !validation.isValid {
                // Show validation errors
                showValidationErrors(validation.errors)
            }
        } else {
            sendButton.isEnabled = false
        }
    }
    
    private func showValidationErrors(_ errors: [ValidationError]) {
        let errorMessage = errors.map { $0.localizedDescription }.joined(separator: "\n")
        // Could show in a subtle way, like changing text field border color
        commandTextField.layer.borderColor = UIColor.systemRed.cgColor
        commandTextField.layer.borderWidth = 1
    }
    
    // MARK: - State Management
    
    func showLoading() {
        loadingView.isHidden = false
        view.isUserInteractionEnabled = false
    }
    
    func hideLoading() {
        loadingView.isHidden = true
        view.isUserInteractionEnabled = true
    }
    
    func updateWithResult(_ result: CommandResponse) {
        // Update UI based on result
        if result.success {
            commandTextField.text = ""
            currentCommand = nil
            sendButton.isEnabled = false
            showSuccessMessage(result.message)
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
        commandTextField.text = ""
        currentCommand = nil
        sendButton.isEnabled = false
        suggestions = []
        suggestionsCollectionView.reloadData()
    }
    
    private func showSuccessMessage(_ message: String) {
        let alert = UIAlertController(
            title: "Success",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension CommandBuilderViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath) as! SuggestionCell
        cell.configure(with: suggestions[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CommandBuilderViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let suggestion = suggestions[indexPath.item]
        
        // Auto-complete the text field
        if let currentText = commandTextField.text {
            let components = currentText.components(separatedBy: " ")
            var newComponents = Array(components.dropLast())
            newComponents.append(suggestion)
            commandTextField.text = newComponents.joined(separator: " ") + " "
        }
        
        textFieldDidChange()
    }
}

// MARK: - CommandTemplateDelegate

extension CommandBuilderViewController: CommandTemplateDelegate {
    func templateDidSelect(_ template: CommandTemplate) {
        commandTextField.text = template.command
        textFieldDidChange()
    }
}

// MARK: - Supporting Types

struct CommandTemplate {
    let title: String
    let command: String
    let description: String
}

protocol CommandTemplateDelegate: AnyObject {
    func templateDidSelect(_ template: CommandTemplate)
}