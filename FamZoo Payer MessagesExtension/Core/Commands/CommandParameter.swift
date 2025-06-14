import Foundation

enum CommandParameterType {
    case amount
    case text
    case date
    case member
    case account
    case boolean
    case number
}

struct CommandParameter {
    let type: CommandParameterType
    let name: String
    let value: Any
    let isRequired: Bool
    
    init(type: CommandParameterType, name: String, value: Any, isRequired: Bool = true) {
        self.type = type
        self.name = name
        self.value = value
        self.isRequired = isRequired
    }
    
    var stringValue: String {
        return String(describing: value)
    }
    
    var decimalValue: Decimal? {
        if let decimal = value as? Decimal {
            return decimal
        }
        if let string = value as? String {
            return Decimal(string: string)
        }
        if let double = value as? Double {
            return Decimal(double)
        }
        return nil
    }
    
    var dateValue: Date? {
        if let date = value as? Date {
            return date
        }
        if let string = value as? String {
            return DateFormatter.commandDate.date(from: string)
        }
        return nil
    }
    
    var boolValue: Bool {
        if let bool = value as? Bool {
            return bool
        }
        if let string = value as? String {
            let lowercased = string.lowercased()
            return lowercased == "true" || lowercased == "yes" || lowercased == "1"
        }
        return false
    }
    
    func validate() -> ValidationResult {
        switch type {
        case .amount:
            guard decimalValue != nil else {
                return .invalid(.invalidParameterFormat("amount"))
            }
            guard let amount = decimalValue, amount > 0 else {
                return .invalid(.invalidAmount)
            }
        case .date:
            guard dateValue != nil else {
                return .invalid(.invalidParameterFormat("date"))
            }
        case .text:
            guard !stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .invalid(.invalidParameterFormat("text"))
            }
        case .member, .account:
            guard !stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .invalid(.invalidParameterFormat(name))
            }
        case .boolean:
            break
        case .number:
            guard Double(stringValue) != nil else {
                return .invalid(.invalidParameterFormat("number"))
            }
        }
        
        return .valid
    }
}

extension DateFormatter {
    static let commandDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let commandDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ParameterBuilder {
    static func amount(_ value: Any, name: String = "amount") -> CommandParameter {
        return CommandParameter(type: .amount, name: name, value: value)
    }
    
    static func text(_ value: String, name: String = "text") -> CommandParameter {
        return CommandParameter(type: .text, name: name, value: value)
    }
    
    static func date(_ value: Any, name: String = "date") -> CommandParameter {
        return CommandParameter(type: .date, name: name, value: value)
    }
    
    static func member(_ value: String, name: String = "member") -> CommandParameter {
        return CommandParameter(type: .member, name: name, value: value)
    }
    
    static func account(_ value: String, name: String = "account") -> CommandParameter {
        return CommandParameter(type: .account, name: name, value: value)
    }
    
    static func boolean(_ value: Bool, name: String = "enabled") -> CommandParameter {
        return CommandParameter(type: .boolean, name: name, value: value)
    }
    
    static func number(_ value: Any, name: String = "number") -> CommandParameter {
        return CommandParameter(type: .number, name: name, value: value)
    }
}