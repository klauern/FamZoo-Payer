import UIKit
import Messages

class SimpleMessagesViewController: MSMessagesAppViewController {
    
    private var compactViewController: SimpleQuickActionsViewController?
    private var expandedViewController: SimpleCommandBuilderViewController?
    private var currentCommand: FamZooCommand?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        presentViewController(for: presentationStyle)
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        presentViewController(for: presentationStyle)
    }
    
    private func presentViewController(for presentationStyle: MSMessagesAppPresentationStyle) {
        removeAllChildren()
        
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
        let compactVC = SimpleQuickActionsViewController()
        compactVC.delegate = self
        addChildVC(compactVC)
        self.compactViewController = compactVC
    }
    
    private func presentExpandedViewController() {
        let expandedVC = SimpleCommandBuilderViewController()
        expandedVC.delegate = self
        addChildVC(expandedVC)
        self.expandedViewController = expandedVC
    }
    
    private func addChildVC(_ childVC: UIViewController) {
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.frame = view.bounds
        childVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childVC.didMove(toParent: self)
    }
    
    private func removeAllChildren() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        compactViewController = nil
        expandedViewController = nil
    }
    
    private func executeCommand(_ command: FamZooCommand) {
        currentCommand = command
        
        Task {
            do {
                // Show loading
                await MainActor.run {
                    compactViewController?.showLoading()
                    expandedViewController?.showLoading()
                }
                
                // Execute command
                let result = try await command.execute()
                
                // Hide loading and show result
                await MainActor.run {
                    compactViewController?.hideLoading()
                    expandedViewController?.hideLoading()
                    compactViewController?.updateWithResult(result)
                    expandedViewController?.updateWithResult(result)
                }
                
                // Send message
                try await sendCommandMessage(command, result: result)
                
            } catch {
                await MainActor.run {
                    compactViewController?.hideLoading()
                    expandedViewController?.hideLoading()
                    compactViewController?.showError(error)
                    expandedViewController?.showError(error)
                }
            }
        }
    }
    
    private func sendCommandMessage(_ command: FamZooCommand, result: CommandResponse) async throws {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        layout.caption = result.message
        layout.subcaption = command.format()
        layout.imageTitle = result.success ? "✅" : "❌"
        
        message.layout = layout
        
        // Send the message
        activeConversation?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
}

// MARK: - Delegates

extension SimpleMessagesViewController: QuickActionsDelegate {
    func quickActionsDidSelectCommand(_ command: FamZooCommand) {
        executeCommand(command)
    }
    
    func quickActionsDidRequestExpanded() {
        requestPresentationStyle(.expanded)
    }
}

extension SimpleMessagesViewController: CommandBuilderDelegate {
    func commandBuilderDidCreateCommand(_ command: FamZooCommand) {
        executeCommand(command)
    }
    
    func commandBuilderDidRequestCompact() {
        requestPresentationStyle(.compact)
    }
}