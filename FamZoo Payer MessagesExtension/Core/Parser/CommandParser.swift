import Foundation

class CommandParser {
    private let abbreviationExpander = AbbreviationExpander()
    private let parameterParser = ParameterParser()
    
    func parse(_ input: String) -> FamZooCommand? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return nil }
        
        let components = parameterParser.parseQuotedString(trimmedInput)
        guard components.count >= 2 else { return nil }
        
        guard let type = abbreviationExpander.expandType(components[0]),
              let action = abbreviationExpander.expandAction(components[1]) else {
            return nil
        }
        
        guard type.allowedActions.contains(action) else {
            return nil
        }
        
        let parameterComponents = Array(components.dropFirst(2))
        let parameters = parameterParser.parseParameters(
            from: parameterComponents,
            for: (type: type, action: action)
        )
        
        return ConcreteCommand(
            type: type,
            action: action,
            parameters: parameters,
            rawText: trimmedInput
        )
    }
    
    func validate(_ input: String) -> ValidationResult {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(.emptyCommand)
        }
        
        guard let command = parse(input) else {
            return .invalid(.unknownCommand)
        }
        
        return command.validate()
    }
    
    func suggestCompletions(for input: String) -> [String] {
        let components = input.components(separatedBy: " ").filter { !$0.isEmpty }
        
        if components.isEmpty {
            return CommandType.allCases.map { $0.rawValue }
        }
        
        if components.count == 1 {
            return abbreviationExpander.suggestionsFor(components[0])
        }
        
        if components.count == 2 {
            guard let type = abbreviationExpander.expandType(components[0]) else {
                return []
            }
            
            let actionSuggestions = type.allowedActions
                .filter { $0.rawValue.hasPrefix(components[1].lowercased()) }
                .map { $0.rawValue }
            
            return actionSuggestions
        }
        
        return []
    }
}

struct ConcreteCommand: FamZooCommand {
    let type: CommandType
    let action: CommandAction
    let parameters: [CommandParameter]
    let rawText: String
    
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        
        for parameter in parameters {
            let result = parameter.validate()
            if !result.isValid {
                errors.append(contentsOf: result.errors)
            }
        }
        
        let requiredTypes = action.requiredParameterTypes
        let providedTypes = parameters.map { $0.type }
        
        for requiredType in requiredTypes {
            if !providedTypes.contains(requiredType) {
                errors.append(.missingRequiredParameter(String(describing: requiredType)))
            }
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    func format() -> String {
        let parameterStrings = parameters.map { parameter in
            switch parameter.type {
            case .amount:
                if let decimal = parameter.decimalValue {
                    return NumberFormatter.currency.string(from: decimal as NSDecimalNumber) ?? parameter.stringValue
                }
                return parameter.stringValue
            case .date:
                if let date = parameter.dateValue {
                    return DateFormatter.commandDate.string(from: date)
                }
                return parameter.stringValue
            default:
                return parameter.stringValue
            }
        }
        
        let components = [type.rawValue, action.rawValue] + parameterStrings
        return components.joined(separator: " ")
    }
    
    func execute() async throws -> CommandResponse {
        switch (type, action) {
        case (.account, .balance):
            return try await executeAccountBalance()
        case (.account, .credit):
            return try await executeAccountCredit()
        case (.account, .debit):
            return try await executeAccountDebit()
        case (.list, .list):
            return try await executeListCommand()
        case (.list, .add):
            return try await executeListAdd()
        default:
            return BasicCommandResponse(
                success: false,
                message: "Command not yet implemented: \(type.rawValue) \(action.rawValue)",
                data: nil
            )
        }
    }
    
    private func executeAccountBalance() async throws -> CommandResponse {
        return AccountBalanceResponse(
            success: true,
            message: "Account balance retrieved",
            balance: 125.50,
            accountName: "John's Spending"
        )
    }
    
    private func executeAccountCredit() async throws -> CommandResponse {
        guard let amountParam = parameters.first(where: { $0.type == .amount }),
              let amount = amountParam.decimalValue else {
            return BasicCommandResponse(
                success: false,
                message: "Invalid amount specified",
                data: nil
            )
        }
        
        return BasicCommandResponse(
            success: true,
            message: "Successfully credited \(NumberFormatter.currency.string(from: amount as NSDecimalNumber) ?? "$0.00")",
            data: ["amount": amount]
        )
    }
    
    private func executeAccountDebit() async throws -> CommandResponse {
        guard let amountParam = parameters.first(where: { $0.type == .amount }),
              let amount = amountParam.decimalValue else {
            return BasicCommandResponse(
                success: false,
                message: "Invalid amount specified",
                data: nil
            )
        }
        
        return BasicCommandResponse(
            success: true,
            message: "Successfully debited \(NumberFormatter.currency.string(from: amount as NSDecimalNumber) ?? "$0.00")",
            data: ["amount": amount]
        )
    }
    
    private func executeListCommand() async throws -> CommandResponse {
        return BasicCommandResponse(
            success: true,
            message: "List retrieved successfully",
            data: ["items": ["Buy groceries", "Walk the dog", "Finish homework"]]
        )
    }
    
    private func executeListAdd() async throws -> CommandResponse {
        guard let textParam = parameters.first(where: { $0.type == .text }) else {
            return BasicCommandResponse(
                success: false,
                message: "No item text specified",
                data: nil
            )
        }
        
        return BasicCommandResponse(
            success: true,
            message: "Added '\(textParam.stringValue)' to list",
            data: ["item": textParam.stringValue]
        )
    }
}