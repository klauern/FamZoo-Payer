import Foundation
import Messages

class MessageSender {
    private weak var conversation: MSConversation?
    
    init(conversation: MSConversation? = nil) {
        self.conversation = conversation
    }
    
    func updateConversation(_ conversation: MSConversation) {
        self.conversation = conversation
    }
    
    // MARK: - Command Messages
    
    func sendCommand(_ command: FamZooCommand) async throws {
        let message = createCommandMessage(command)
        try await sendMessage(message)
    }
    
    func sendCommandResult(_ command: FamZooCommand, result: CommandResponse) async throws {
        let message = createResultMessage(command, result: result)
        try await sendMessage(message)
    }
    
    // MARK: - Response Messages
    
    func sendBalanceResponse(_ balance: AccountBalanceResponse) async throws {
        let message = createBalanceMessage(balance)
        try await sendMessage(message)
    }
    
    func sendTransactionResponse(_ transaction: Transaction) async throws {
        let message = createTransactionMessage(transaction)
        try await sendMessage(message)
    }
    
    func sendErrorMessage(_ error: Error) async throws {
        let message = createErrorMessage(error)
        try await sendMessage(message)
    }
    
    // MARK: - Message Creation
    
    private func createCommandMessage(_ command: FamZooCommand) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        layout.caption = command.format()
        layout.subcaption = "FamZoo Command"
        layout.imageTitle = "💰"
        
        // Create URL components for the command
        let url = createCommandURL(command)
        message.url = url
        message.layout = layout
        
        return message
    }
    
    private func createResultMessage(_ command: FamZooCommand, result: CommandResponse) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        layout.caption = result.message
        layout.subcaption = command.format()
        
        if result.success {
            layout.imageTitle = "✅"
        } else {
            layout.imageTitle = "❌"
        }
        
        // Include result data in URL
        let url = createResultURL(command, result: result)
        message.url = url
        message.layout = layout
        
        return message
    }
    
    private func createBalanceMessage(_ balance: AccountBalanceResponse) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        layout.caption = formatter.string(from: balance.balance as NSDecimalNumber) ?? "$0.00"
        layout.subcaption = balance.accountName
        layout.imageTitle = "💰"
        
        let url = createBalanceURL(balance)
        message.url = url
        message.layout = layout
        
        return message
    }
    
    private func createTransactionMessage(_ transaction: Transaction) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        layout.caption = transaction.formattedAmount
        layout.subcaption = transaction.displayDescription
        layout.imageTitle = transaction.category?.emoji ?? "💳"
        
        let url = createTransactionURL(transaction)
        message.url = url
        message.layout = layout
        
        return message
    }
    
    private func createErrorMessage(_ error: Error) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        layout.caption = "Error"
        layout.subcaption = error.localizedDescription
        layout.imageTitle = "⚠️"
        
        let url = createErrorURL(error)
        message.url = url
        message.layout = layout
        
        return message
    }
    
    // MARK: - URL Creation
    
    private func createCommandURL(_ command: FamZooCommand) -> URL? {
        var components = URLComponents()
        components.scheme = "famzoo"
        components.host = "command"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "type", value: command.type.rawValue),
            URLQueryItem(name: "action", value: command.action.rawValue),
            URLQueryItem(name: "raw", value: command.rawText)
        ]
        
        for (index, parameter) in command.parameters.enumerated() {
            queryItems.append(URLQueryItem(name: "param_\(index)", value: parameter.stringValue))
            queryItems.append(URLQueryItem(name: "param_\(index)_type", value: String(describing: parameter.type)))
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    private func createResultURL(_ command: FamZooCommand, result: CommandResponse) -> URL? {
        var components = URLComponents()
        components.scheme = "famzoo"
        components.host = "result"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "success", value: String(result.success)),
            URLQueryItem(name: "message", value: result.message),
            URLQueryItem(name: "command", value: command.rawText)
        ]
        
        if let data = result.data {
            for (key, value) in data {
                queryItems.append(URLQueryItem(name: "data_\(key)", value: String(describing: value)))
            }
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    private func createBalanceURL(_ balance: AccountBalanceResponse) -> URL? {
        var components = URLComponents()
        components.scheme = "famzoo"
        components.host = "balance"
        
        components.queryItems = [
            URLQueryItem(name: "account", value: balance.accountName),
            URLQueryItem(name: "balance", value: String(describing: balance.balance)),
            URLQueryItem(name: "success", value: String(balance.success))
        ]
        
        return components.url
    }
    
    private func createTransactionURL(_ transaction: Transaction) -> URL? {
        var components = URLComponents()
        components.scheme = "famzoo"
        components.host = "transaction"
        
        components.queryItems = [
            URLQueryItem(name: "id", value: transaction.id),
            URLQueryItem(name: "type", value: transaction.type.rawValue),
            URLQueryItem(name: "amount", value: String(describing: transaction.amount)),
            URLQueryItem(name: "description", value: transaction.description),
            URLQueryItem(name: "status", value: transaction.status.rawValue)
        ]
        
        return components.url
    }
    
    private func createErrorURL(_ error: Error) -> URL? {
        var components = URLComponents()
        components.scheme = "famzoo"
        components.host = "error"
        
        components.queryItems = [
            URLQueryItem(name: "message", value: error.localizedDescription),
            URLQueryItem(name: "type", value: String(describing: type(of: error)))
        ]
        
        return components.url
    }
    
    // MARK: - Message Sending
    
    private func sendMessage(_ message: MSMessage) async throws {
        guard let conversation = conversation else {
            throw MessageSenderError.noConversation
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            conversation.send(message) { error in
                if let error = error {
                    continuation.resume(throwing: MessageSenderError.sendFailed(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Message Parsing
    
    func parseCommandFromMessage(_ message: MSMessage) -> FamZooCommand? {
        guard let url = message.url,
              url.scheme == "famzoo",
              url.host == "command" else {
            return nil
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        let params: [String: String] = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        
        guard let typeString = params["type"],
              let actionString = params["action"],
              let rawText = params["raw"],
              let type = CommandType.from(typeString),
              let action = CommandAction.from(actionString) else {
            return nil
        }
        
        // Parse parameters
        var parameters: [CommandParameter] = []
        var paramIndex = 0
        
        while let paramValue = params["param_\(paramIndex)"],
              let paramTypeString = params["param_\(paramIndex)_type"] {
            // This is a simplified parameter recreation
            let parameter = ParameterBuilder.text(paramValue, name: "param_\(paramIndex)")
            parameters.append(parameter)
            paramIndex += 1
        }
        
        return ConcreteCommand(
            type: type,
            action: action,
            parameters: parameters,
            rawText: rawText
        )
    }
}

enum MessageSenderError: Error, LocalizedError {
    case noConversation
    case sendFailed(Error)
    case invalidMessage
    
    var errorDescription: String? {
        switch self {
        case .noConversation:
            return "No conversation available for sending messages"
        case .sendFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .invalidMessage:
            return "Invalid message format"
        }
    }
}

extension MessageSender {
    // MARK: - Convenience Methods
    
    func sendQuickBalance(accountName: String, balance: Decimal) async throws {
        let balanceResponse = AccountBalanceResponse(
            success: true,
            message: "Balance retrieved",
            balance: balance,
            accountName: accountName
        )
        try await sendBalanceResponse(balanceResponse)
    }
    
    func sendTransactionConfirmation(_ transaction: Transaction) async throws {
        try await sendTransactionResponse(transaction)
    }
    
    func sendCommandFeedback(_ command: FamZooCommand, success: Bool, message: String) async throws {
        let response = BasicCommandResponse(
            success: success,
            message: message,
            data: nil
        )
        try await sendCommandResult(command, result: response)
    }
}