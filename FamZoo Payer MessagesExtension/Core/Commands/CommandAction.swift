import Foundation

enum CommandAction: String, CaseIterable {
    // Account actions
    case balance = "balance"
    case credit = "credit"
    case debit = "debit"
    case new = "new"
    case select = "select"
    
    // List actions
    case list = "list"
    case show = "show"
    case create = "create"
    case add = "add"
    case share = "share"
    
    // Item actions
    case complete = "complete"
    case due = "due"
    case occurs = "occurs"
    
    var abbreviations: [String] {
        switch self {
        case .balance: return ["b", "bal"]
        case .credit: return ["c", "cre", "+"]
        case .debit: return ["d", "deb", "-"]
        case .select: return ["sel", "s"]
        case .list: return ["ls"]
        case .show: return ["sh"]
        case .create: return ["cr", "mk", "make"]
        case .add: return ["+", "a"]
        case .complete: return ["done", "finish", "x"]
        default: return []
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .balance:
            return "Show account balance"
        case .credit:
            return "Add money to account"
        case .debit:
            return "Remove money from account"
        case .new:
            return "Create new item"
        case .select:
            return "Select/switch to item"
        case .list:
            return "List items"
        case .show:
            return "Show details"
        case .create:
            return "Create new item"
        case .add:
            return "Add item to list"
        case .share:
            return "Share with others"
        case .complete:
            return "Mark as complete"
        case .due:
            return "Set due date"
        case .occurs:
            return "Set recurring schedule"
        }
    }
    
    static func from(_ string: String) -> CommandAction? {
        let lowercased = string.lowercased()
        
        // Check direct match first
        if let action = CommandAction(rawValue: lowercased) {
            return action
        }
        
        // Check abbreviations
        for action in CommandAction.allCases {
            if action.abbreviations.contains(lowercased) {
                return action
            }
        }
        
        return nil
    }
    
    var requiresParameters: Bool {
        switch self {
        case .credit, .debit, .add, .due, .occurs, .new, .create:
            return true
        case .balance, .list, .show, .select, .complete, .share:
            return false
        }
    }
    
    var requiredParameterTypes: [CommandParameterType] {
        switch self {
        case .credit, .debit:
            return [.amount]
        case .add:
            return [.text]
        case .due:
            return [.date]
        case .occurs:
            return [.text]
        case .new, .create:
            return [.text]
        default:
            return []
        }
    }
}