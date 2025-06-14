import UIKit
import Messages

class MinimalTestViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTestUI()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        updateUIForPresentationStyle(presentationStyle)
    }
    
    private func setupTestUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Create a simple test button
        let testButton = UIButton(type: .system)
        testButton.setTitle("💰 Test FamZoo", for: .normal)
        testButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        testButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        testButton.layer.cornerRadius = 12
        testButton.layer.borderWidth = 1
        testButton.layer.borderColor = UIColor.systemBlue.cgColor
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        
        view.addSubview(testButton)
        
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 200),
            testButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateUIForPresentationStyle(_ style: MSMessagesAppPresentationStyle) {
        // Add visual feedback for different presentation styles
        switch style {
        case .compact:
            view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        case .expanded:
            view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        case .transcript:
            view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        @unknown default:
            view.backgroundColor = UIColor.systemBackground
        }
    }
    
    @objc private func testButtonTapped() {
        // Create a test message
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        layout.caption = "💰 $125.50"
        layout.subcaption = "Account Balance"
        layout.imageTitle = "FamZoo"
        
        message.layout = layout
        
        // Send the message
        activeConversation?.send(message) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to send: \(error.localizedDescription)")
                } else {
                    self.showAlert(title: "Success", message: "Message sent successfully!")
                }
            }
        }
        
        // Try to expand if we're in compact mode
        if presentationStyle == .compact {
            requestPresentationStyle(.expanded)
        } else {
            requestPresentationStyle(.compact)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}