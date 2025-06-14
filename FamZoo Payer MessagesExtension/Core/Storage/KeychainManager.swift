import Foundation
import Security

class KeychainManager {
    private let service: String
    private let accessGroup: String?
    
    init(service: String = AppConfig.keychainService, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    // MARK: - Authentication Tokens
    
    func storeAuthToken(_ token: String) throws {
        try store(token, forKey: "auth_token")
    }
    
    func getAuthToken() throws -> String? {
        return try retrieve(forKey: "auth_token")
    }
    
    func storeRefreshToken(_ token: String) throws {
        try store(token, forKey: "refresh_token")
    }
    
    func getRefreshToken() throws -> String? {
        return try retrieve(forKey: "refresh_token")
    }
    
    func clearAuthTokens() throws {
        try delete(forKey: "auth_token")
        try delete(forKey: "refresh_token")
    }
    
    // MARK: - User Credentials
    
    func storeCredentials(username: String, password: String) throws {
        try store(username, forKey: "username")
        try store(password, forKey: "password")
    }
    
    func getStoredUsername() throws -> String? {
        return try retrieve(forKey: "username")
    }
    
    func getStoredPassword() throws -> String? {
        return try retrieve(forKey: "password")
    }
    
    func clearCredentials() throws {
        try delete(forKey: "username")
        try delete(forKey: "password")
    }
    
    // MARK: - Generic Keychain Operations
    
    private func store(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item if it exists
        try delete(forKey: key)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    private func retrieve(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
    
    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // It's okay if the item doesn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Bulk Operations
    
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    func hasStoredCredentials() throws -> Bool {
        let username = try getStoredUsername()
        let password = try getStoredPassword()
        return username != nil && password != nil
    }
    
    func hasValidAuthToken() throws -> Bool {
        let token = try getAuthToken()
        return token != nil && !token!.isEmpty
    }
}

enum KeychainError: Error, LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
    case itemNotFound
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store item in keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete item from keychain (status: \(status))"
        case .invalidData:
            return "Invalid data retrieved from keychain"
        case .itemNotFound:
            return "Item not found in keychain"
        }
    }
}

extension KeychainManager {
    // MARK: - Biometric Authentication Support
    
    func storeWithBiometrics(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        )
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access as Any
        ]
        
        // Delete existing item if it exists
        try delete(forKey: key)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    func retrieveWithBiometrics(forKey key: String, prompt: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: prompt
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
}