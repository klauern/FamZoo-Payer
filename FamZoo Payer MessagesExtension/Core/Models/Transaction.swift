import Foundation

struct Transaction: Codable, Identifiable, Equatable {
    let id: String
    let type: TransactionType
    let amount: Decimal
    let currency: String
    let description: String
    let fromAccountId: String?
    let toAccountId: String?
    let memberId: String
    let status: TransactionStatus
    let createdAt: Date
    let processedAt: Date?
    let metadata: TransactionMetadata?
    let category: TransactionCategory?
    let tags: [String]
    
    enum TransactionType: String, Codable, CaseIterable {
        case credit = "credit"
        case debit = "debit"
        case transfer = "transfer"
        
        var displayName: String {
            switch self {
            case .credit: return "Credit"
            case .debit: return "Debit"
            case .transfer: return "Transfer"
            }
        }
        
        var symbol: String {
            switch self {
            case .credit: return "+"
            case .debit: return "-"
            case .transfer: return "→"
            }
        }
    }
    
    enum TransactionStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .processing: return "Processing"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .cancelled: return "Cancelled"
            }
        }
        
        var isComplete: Bool {
            return self == .completed
        }
        
        var isFinal: Bool {
            return [.completed, .failed, .cancelled].contains(self)
        }
    }
    
    enum TransactionCategory: String, Codable, CaseIterable {
        case allowance = "allowance"
        case chores = "chores"
        case savings = "savings"
        case spending = "spending"
        case gift = "gift"
        case penalty = "penalty"
        case bonus = "bonus"
        case transfer = "transfer"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .allowance: return "Allowance"
            case .chores: return "Chores"
            case .savings: return "Savings"
            case .spending: return "Spending"
            case .gift: return "Gift"
            case .penalty: return "Penalty"
            case .bonus: return "Bonus"
            case .transfer: return "Transfer"
            case .other: return "Other"
            }
        }
        
        var emoji: String {
            switch self {
            case .allowance: return "💰"
            case .chores: return "🧹"
            case .savings: return "🏦"
            case .spending: return "💳"
            case .gift: return "🎁"
            case .penalty: return "⚠️"
            case .bonus: return "⭐"
            case .transfer: return "↔️"
            case .other: return "📝"
            }
        }
    }
    
    init(id: String = UUID().uuidString,
         type: TransactionType,
         amount: Decimal,
         currency: String = "USD",
         description: String,
         fromAccountId: String? = nil,
         toAccountId: String? = nil,
         memberId: String,
         status: TransactionStatus = .pending,
         category: TransactionCategory? = nil,
         tags: [String] = [],
         metadata: TransactionMetadata? = nil) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
        self.description = description
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.memberId = memberId
        self.status = status
        self.createdAt = Date()
        self.processedAt = status.isComplete ? Date() : nil
        self.category = category
        self.tags = tags
        self.metadata = metadata
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let formattedValue = formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
        
        switch type {
        case .credit:
            return "+\(formattedValue)"
        case .debit:
            return "-\(formattedValue)"
        case .transfer:
            return formattedValue
        }
    }
    
    var displayDescription: String {
        if let category = category {
            return "\(category.emoji) \(description)"
        }
        return description
    }
    
    var isTransfer: Bool {
        return type == .transfer && fromAccountId != nil && toAccountId != nil
    }
    
    func withStatus(_ newStatus: TransactionStatus) -> Transaction {
        var updated = self
        return Transaction(
            id: id,
            type: type,
            amount: amount,
            currency: currency,
            description: description,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            memberId: memberId,
            status: newStatus,
            category: category,
            tags: tags,
            metadata: metadata
        )
    }
}

struct TransactionMetadata: Codable, Equatable {
    let source: String?
    let reference: String?
    let location: String?
    let notes: String?
    let parentTransactionId: String?
    let recurringScheduleId: String?
    let commandText: String?
    
    init(source: String? = nil,
         reference: String? = nil,
         location: String? = nil,
         notes: String? = nil,
         parentTransactionId: String? = nil,
         recurringScheduleId: String? = nil,
         commandText: String? = nil) {
        self.source = source
        self.reference = reference
        self.location = location
        self.notes = notes
        self.parentTransactionId = parentTransactionId
        self.recurringScheduleId = recurringScheduleId
        self.commandText = commandText
    }
}

extension Transaction {
    static let sampleTransactions = [
        Transaction(
            type: .credit,
            amount: 10.00,
            description: "Weekly allowance",
            toAccountId: "account1",
            memberId: "user1",
            status: .completed,
            category: .allowance
        ),
        Transaction(
            type: .debit,
            amount: 5.50,
            description: "Lunch money",
            fromAccountId: "account1",
            memberId: "user1",
            status: .completed,
            category: .spending
        ),
        Transaction(
            type: .transfer,
            amount: 25.00,
            description: "Transfer to savings",
            fromAccountId: "account1",
            toAccountId: "account2",
            memberId: "user1",
            status: .pending,
            category: .savings
        )
    ]
}