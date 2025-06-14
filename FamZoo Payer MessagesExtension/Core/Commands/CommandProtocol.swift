import Foundation
import UIKit

protocol FamZooCommand {
    var type: CommandType { get }
    var action: CommandAction { get }
    var parameters: [CommandParameter] { get }
    var rawText: String { get }
    
    func validate() -> ValidationResult
    func format() -> String
    func execute() async throws -> CommandResponse
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    
    static let valid = ValidationResult(isValid: true, errors: [])
    
    static func invalid(_ errors: [ValidationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors)
    }
    
    static func invalid(_ error: ValidationError) -> ValidationResult {
        return ValidationResult(isValid: false, errors: [error])
    }
}

enum ValidationError: Error, LocalizedError {
    case missingRequiredParameter(String)
    case invalidParameterFormat(String)
    case insufficientPermissions
    case invalidAccount
    case invalidMember
    case invalidAmount
    case emptyCommand
    case unknownCommand
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidParameterFormat(let param):
            return "Invalid format for parameter: \(param)"
        case .insufficientPermissions:
            return "Insufficient permissions to execute this command"
        case .invalidAccount:
            return "Invalid or unknown account"
        case .invalidMember:
            return "Invalid or unknown member"
        case .invalidAmount:
            return "Invalid amount format"
        case .emptyCommand:
            return "Command cannot be empty"
        case .unknownCommand:
            return "Unknown command"
        }
    }
}

protocol CommandResponse {
    var success: Bool { get }
    var message: String { get }
    var data: [String: Any]? { get }
    
    @MainActor func displayView() -> UIView
}

struct BasicCommandResponse: CommandResponse {
    let success: Bool
    let message: String
    let data: [String: Any]?
    
    @MainActor func displayView() -> UIView {
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }
}

struct AccountBalanceResponse: CommandResponse, Codable {
    let success: Bool
    let message: String
    let balance: Decimal
    let accountName: String
    let data: [String: Any]?
    
    init(success: Bool, message: String, balance: Decimal, accountName: String) {
        self.success = success
        self.message = message
        self.balance = balance
        self.accountName = accountName
        self.data = ["balance": balance, "accountName": accountName]
    }
    
    // Custom Codable implementation since [String: Any] isn't Codable
    enum CodingKeys: String, CodingKey {
        case success, message, balance, accountName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decode(String.self, forKey: .message)
        balance = try container.decode(Decimal.self, forKey: .balance)
        accountName = try container.decode(String.self, forKey: .accountName)
        data = ["balance": balance, "accountName": accountName]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encode(message, forKey: .message)
        try container.encode(balance, forKey: .balance)
        try container.encode(accountName, forKey: .accountName)
    }
    
    @MainActor func displayView() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        
        let accountLabel = UILabel()
        accountLabel.text = accountName
        accountLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        let balanceLabel = UILabel()
        balanceLabel.text = NumberFormatter.currency.string(from: balance as NSDecimalNumber)
        balanceLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        
        stackView.addArrangedSubview(accountLabel)
        stackView.addArrangedSubview(balanceLabel)
        
        return stackView
    }
}

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}