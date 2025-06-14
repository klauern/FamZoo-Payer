import Foundation

enum CommandType: String, CaseIterable {
    case account = "account"
    case list = "list"
    case member = "member"
    case shortcut = "shortcut"
    case item = "item"
    
    var abbreviations: [String] {
        switch self {
        case .account: return ["a", "acc"]
        case .list: return ["l", "lists"]
        case .member: return ["m", "mem"]
        case .shortcut: return ["s", "short"]
        case .item: return ["i"]
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .account:
            return "Manage FamZoo accounts - check balances, transfer funds"
        case .list:
            return "Manage todo lists and shared lists"
        case .member:
            return "View and manage family members"
        case .shortcut:
            return "Create and manage command shortcuts"
        case .item:
            return "Manage items in lists - add, complete, modify"
        }
    }
    
    static func from(_ string: String) -> CommandType? {
        let lowercased = string.lowercased()
        
        // Check direct match first
        if let type = CommandType(rawValue: lowercased) {
            return type
        }
        
        // Check abbreviations
        for type in CommandType.allCases {
            if type.abbreviations.contains(lowercased) {
                return type
            }
        }
        
        return nil
    }
    
    var allowedActions: [CommandAction] {
        switch self {
        case .account:
            return [.balance, .credit, .debit, .new, .select, .list]
        case .list:
            return [.list, .show, .create, .add, .share, .new]
        case .member:
            return [.list, .show, .select, .balance]
        case .shortcut:
            return [.list, .create, .add, .show]
        case .item:
            return [.add, .complete, .due, .occurs, .list]
        }
    }
}