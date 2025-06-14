//
//  MessagesViewController.swift
//  FamZoo Payer MessagesExtension
//
//  Created by Nick Klauer on 6/14/25.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Properties
    private var commandParser: CommandParser!
    private var messageSender: MessageSender!
    private var apiClient: FamZooAPIClient!
    private var keychain: KeychainManager!
    
    private var compactViewController: QuickActionsViewController?
    private var expandedViewController: CommandBuilderViewController?
    private var currentCommand: FamZooCommand?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupServices()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupServices() {
        keychain = KeychainManager()
        apiClient = FamZooAPIClient(keychain: keychain)
        commandParser = CommandParser()
        messageSender = MessageSender()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        
        messageSender.updateConversation(conversation)
        presentViewController(for: presentationStyle)
        
        // Check if user needs authentication
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
        
        // Save any pending state
        saveCurrentState()
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        
        // Parse incoming command messages
        if let command = messageSender.parseCommandFromMessage(message) {
            handleReceivedCommand(command)
        }
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
        
        // Handle command execution when user sends a message
        if let command = currentCommand {
            Task {
                await executeCommand(command)
            }
        }
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
        
        // Clean up canceled command
        currentCommand = nil
        resetUI()
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        
        // Prepare for presentation style change
        prepareForTransition(to: presentationStyle)
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        
        // Update UI for new presentation style
        presentViewController(for: presentationStyle)
    }
    
    // MARK: - Presentation Management
    
    private func presentViewController(for presentationStyle: MSMessagesAppPresentationStyle) {
        // Remove existing child view controllers
        removeAllChildViewControllers()
        
        switch presentationStyle {
        case .compact:
            presentCompactViewController()
        case .expanded:
            presentExpandedViewController()
        case .transcript:
            break
        @unknown default:
            break
        }
    }
    
    private func presentCompactViewController() {
        let compactVC = QuickActionsViewController()
        compactVC.delegate = self
        
        addChild(compactVC)
        view.addSubview(compactVC.view)
        compactVC.view.frame = view.bounds
        compactVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        compactVC.didMove(toParent: self)
        
        self.compactViewController = compactVC
    }
    
    private func presentExpandedViewController() {
        let expandedVC = CommandBuilderViewController()
        expandedVC.delegate = self
        
        addChild(expandedVC)
        view.addSubview(expandedVC.view)
        expandedVC.view.frame = view.bounds
        expandedVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        expandedVC.didMove(toParent: self)
        
        self.expandedViewController = expandedVC
    }
    
    private func removeAllChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        compactViewController = nil
        expandedViewController = nil
    }
    
    private func prepareForTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Save current state before transition
        saveCurrentState()
    }
    
    // MARK: - Command Handling
    
    private func handleReceivedCommand(_ command: FamZooCommand) {
        // Update UI to show received command
        currentCommand = command
        
        // Execute the command if it's valid
        Task {
            await executeCommand(command)
        }
    }
    
    private func executeCommand(_ command: FamZooCommand) async {
        // Validate command first
        let validation = command.validate()
        guard validation.isValid else {
            await handleCommandError(ValidationError.invalidParameterFormat("Command validation failed"))
            return
        }
        
        do {
            // Show loading state
            await showLoadingState()
            
            // Execute the command
            let result = try await command.execute()
            
            // Hide loading state
            await hideLoadingState()
            
            // Send result message
            try await messageSender.sendCommandResult(command, result: result)
            
            // Update UI with result
            await updateUIWithResult(result)
            
        } catch {
            await hideLoadingState()
            await handleCommandError(error)
        }
    }
    
    @MainActor
    private func showLoadingState() {
        // Update UI to show loading
        compactViewController?.showLoading()
        expandedViewController?.showLoading()
    }
    
    @MainActor
    private func hideLoadingState() {
        // Hide loading UI
        compactViewController?.hideLoading()
        expandedViewController?.hideLoading()
    }
    
    @MainActor
    private func updateUIWithResult(_ result: CommandResponse) {
        // Update UI with command result
        compactViewController?.updateWithResult(result)
        expandedViewController?.updateWithResult(result)
    }
    
    @MainActor
    private func handleCommandError(_ error: Error) {
        // Show error in UI
        compactViewController?.showError(error)
        expandedViewController?.showError(error)
        
        // Send error message
        Task {
            try? await messageSender.sendErrorMessage(error)
        }
    }
    
    // MARK: - Authentication
    
    private func checkAuthenticationStatus() async {
        do {
            let hasToken = try await keychain.hasValidAuthToken()
            if !hasToken {
                await promptForAuthentication()
            }
        } catch {
            await promptForAuthentication()
        }
    }
    
    @MainActor
    private func promptForAuthentication() {
        // Show authentication prompt
        let alert = UIAlertController(
            title: "FamZoo Login",
            message: "Please enter your FamZoo credentials",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Username"
            textField.autocapitalizationType = .none
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Login", style: .default) { _ in
            guard let username = alert.textFields?[0].text,
                  let password = alert.textFields?[1].text else { return }
            
            Task {
                await self.performAuthentication(username: username, password: password)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func performAuthentication(username: String, password: String) async {
        do {
            await showLoadingState()
            let _ = try await apiClient.authenticate(username: username, password: password)
            await hideLoadingState()
        } catch {
            await hideLoadingState()
            await handleCommandError(error)
        }
    }
    
    // MARK: - State Management
    
    private func saveCurrentState() {
        // Save current command and UI state
        UserDefaults.standard.set(currentCommand?.rawText, forKey: "currentCommand")
    }
    
    private func restoreState() {
        // Restore previous state if available
        if let commandText = UserDefaults.standard.string(forKey: "currentCommand") {
            currentCommand = commandParser.parse(commandText)
        }
    }
    
    private func resetUI() {
        currentCommand = nil
        compactViewController?.reset()
        expandedViewController?.reset()
    }
}

// MARK: - QuickActionsDelegate

extension MessagesViewController: QuickActionsDelegate {
    func quickActionsDidSelectCommand(_ command: FamZooCommand) {
        currentCommand = command
        
        Task {
            try await messageSender.sendCommand(command)
        }
        
        // Switch to expanded mode for command building
        requestPresentationStyle(.expanded)
    }
    
    func quickActionsDidRequestExpanded() {
        requestPresentationStyle(.expanded)
    }
}

// MARK: - CommandBuilderDelegate

extension MessagesViewController: CommandBuilderDelegate {
    func commandBuilderDidCreateCommand(_ command: FamZooCommand) {
        currentCommand = command
        
        Task {
            try await messageSender.sendCommand(command)
        }
    }
    
    func commandBuilderDidRequestCompact() {
        requestPresentationStyle(.compact)
    }
}

// MARK: - Delegate Protocols

protocol QuickActionsDelegate: AnyObject {
    func quickActionsDidSelectCommand(_ command: FamZooCommand)
    func quickActionsDidRequestExpanded()
}

protocol CommandBuilderDelegate: AnyObject {
    func commandBuilderDidCreateCommand(_ command: FamZooCommand)
    func commandBuilderDidRequestCompact()
}
