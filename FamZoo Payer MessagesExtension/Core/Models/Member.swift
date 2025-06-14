import Foundation

struct Member: Codable, Identifiable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let role: MemberRole
    let familyId: String
    let parentId: String?
    let dateOfBirth: Date?
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    let avatarURL: String?
    let preferences: MemberPreferences
    
    enum MemberRole: String, Codable, CaseIterable {
        case parent = "parent"
        case child = "child"
        case teen = "teen"
        case admin = "admin"
        
        var displayName: String {
            switch self {
            case .parent: return "Parent"
            case .child: return "Child"
            case .teen: return "Teen"
            case .admin: return "Administrator"
            }
        }
        
        var permissions: [Permission] {
            switch self {
            case .admin, .parent:
                return Permission.allCases
            case .teen:
                return [.viewAccounts, .manageOwnAccount, .createLists, .manageLists, .viewTransactions]
            case .child:
                return [.viewAccounts, .manageOwnAccount, .createLists]
            }
        }
    }
    
    enum Permission: String, Codable, CaseIterable {
        case viewAccounts = "view_accounts"
        case manageOwnAccount = "manage_own_account"
        case manageAllAccounts = "manage_all_accounts"
        case createLists = "create_lists"
        case manageLists = "manage_lists"
        case viewTransactions = "view_transactions"
        case manageTransactions = "manage_transactions"
        case manageFamilyMembers = "manage_family_members"
        case manageSettings = "manage_settings"
        
        var displayName: String {
            switch self {
            case .viewAccounts: return "View Accounts"
            case .manageOwnAccount: return "Manage Own Account"
            case .manageAllAccounts: return "Manage All Accounts"
            case .createLists: return "Create Lists"
            case .manageLists: return "Manage Lists"
            case .viewTransactions: return "View Transactions"
            case .manageTransactions: return "Manage Transactions"
            case .manageFamilyMembers: return "Manage Family Members"
            case .manageSettings: return "Manage Settings"
            }
        }
    }
    
    init(id: String = UUID().uuidString,
         firstName: String,
         lastName: String,
         email: String? = nil,
         phone: String? = nil,
         role: MemberRole,
         familyId: String,
         parentId: String? = nil,
         dateOfBirth: Date? = nil,
         avatarURL: String? = nil,
         preferences: MemberPreferences = MemberPreferences()) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.role = role
        self.familyId = familyId
        self.parentId = parentId
        self.dateOfBirth = dateOfBirth
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
        self.avatarURL = avatarURL
        self.preferences = preferences
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return "\(fullName) (\(role.displayName))"
    }
    
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }
    
    func hasPermission(_ permission: Permission) -> Bool {
        return role.permissions.contains(permission)
    }
    
    func canManageAccount(_ account: Account) -> Bool {
        return hasPermission(.manageAllAccounts) || 
               (hasPermission(.manageOwnAccount) && account.ownerId == id)
    }
    
    func canViewAccount(_ account: Account) -> Bool {
        return hasPermission(.viewAccounts) && 
               (hasPermission(.manageAllAccounts) || account.ownerId == id)
    }
}

struct MemberPreferences: Codable, Equatable {
    let notificationsEnabled: Bool
    let emailNotifications: Bool
    let smsNotifications: Bool
    let currency: String
    let timezone: String
    let language: String
    let theme: String
    let compactMode: Bool
    
    init(notificationsEnabled: Bool = true,
         emailNotifications: Bool = true,
         smsNotifications: Bool = false,
         currency: String = "USD",
         timezone: String = TimeZone.current.identifier,
         language: String = "en",
         theme: String = "auto",
         compactMode: Bool = false) {
        self.notificationsEnabled = notificationsEnabled
        self.emailNotifications = emailNotifications
        self.smsNotifications = smsNotifications
        self.currency = currency
        self.timezone = timezone
        self.language = language
        self.theme = theme
        self.compactMode = compactMode
    }
}

extension Member {
    static let sampleMembers = [
        Member(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            role: .parent,
            familyId: "family1"
        ),
        Member(
            firstName: "Sarah",
            lastName: "Doe",
            email: "sarah@example.com",
            role: .teen,
            familyId: "family1",
            parentId: "parent1",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -15, to: Date())
        ),
        Member(
            firstName: "Tommy",
            lastName: "Doe",
            role: .child,
            familyId: "family1",
            parentId: "parent1",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -8, to: Date())
        )
    ]
}