import Foundation

struct Account: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: AccountType
    let balance: Decimal
    let currency: String
    let ownerId: String
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    let parentAccountId: String?
    
    enum AccountType: String, Codable, CaseIterable {
        case spending = "spending"
        case savings = "savings"
        case parent = "parent"
        case allowance = "allowance"
        case chores = "chores"
        
        var displayName: String {
            switch self {
            case .spending: return "Spending Account"
            case .savings: return "Savings Account"
            case .parent: return "Parent Account"
            case .allowance: return "Allowance Account"
            case .chores: return "Chores Account"
            }
        }
        
        var canDebit: Bool {
            switch self {
            case .spending, .parent: return true
            case .savings, .allowance, .chores: return false
            }
        }
        
        var canCredit: Bool {
            return true
        }
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         type: AccountType,
         balance: Decimal = 0,
         currency: String = AppConfig.defaultCurrency,
         ownerId: String,
         parentAccountId: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currency = currency
        self.ownerId = ownerId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
        self.parentAccountId = parentAccountId
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: balance as NSDecimalNumber) ?? "$0.00"
    }
    
    var displayName: String {
        return "\(name) (\(type.displayName))"
    }
    
    func canPerformTransaction(_ type: Transaction.TransactionType) -> Bool {
        switch type {
        case .credit:
            return self.type.canCredit
        case .debit:
            return self.type.canDebit && balance >= 0
        case .transfer:
            return true
        }
    }
    
    func withUpdatedBalance(_ newBalance: Decimal) -> Account {
        var updated = self
        updated = Account(
            id: id,
            name: name,
            type: type,
            balance: newBalance,
            currency: currency,
            ownerId: ownerId,
            parentAccountId: parentAccountId
        )
        return updated
    }
}

extension Account {
    static let sampleAccounts = [
        Account(
            name: "John's Spending",
            type: .spending,
            balance: 125.50,
            ownerId: "user1"
        ),
        Account(
            name: "Sarah's Savings",
            type: .savings,
            balance: 75.25,
            ownerId: "user2"
        ),
        Account(
            name: "Parent Account",
            type: .parent,
            balance: 1000.00,
            ownerId: "parent1"
        )
    ]
}