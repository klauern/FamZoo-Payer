import Foundation

class FamZooAPIClient {
    private let baseURL: URL
    private let session: URLSession
    private let retryManager: NetworkRetryManager
    private let keychain: KeychainManager
    
    init(baseURL: String = AppConfig.apiBaseURL,
         session: URLSession = .shared,
         keychain: KeychainManager = KeychainManager()) {
        self.baseURL = URL(string: baseURL)!
        self.session = session
        self.retryManager = NetworkRetryManager()
        self.keychain = keychain
    }
    
    // MARK: - Authentication
    
    func authenticate(username: String, password: String) async throws -> AuthenticationResponse {
        let request = AuthenticationRequest(username: username, password: password)
        let response: APIResponse<AuthenticationResponse> = try await post("/auth/login", body: request)
        
        if let authData = response.data {
            try keychain.storeAuthToken(authData.accessToken)
            try keychain.storeRefreshToken(authData.refreshToken)
            return authData
        } else {
            throw NetworkError.invalidResponse
        }
    }
    
    func refreshToken() async throws -> AuthenticationResponse {
        guard let refreshToken = try keychain.getRefreshToken() else {
            throw NetworkError.unauthorized
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let response: APIResponse<AuthenticationResponse> = try await post("/auth/refresh", body: request)
        
        if let authData = response.data {
            try keychain.storeAuthToken(authData.accessToken)
            try keychain.storeRefreshToken(authData.refreshToken)
            return authData
        } else {
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - Account Operations
    
    func getAccounts() async throws -> [Account] {
        let response: APIResponse<[Account]> = try await get("/accounts")
        return response.data ?? []
    }
    
    func getAccount(_ accountId: String) async throws -> Account {
        let response: APIResponse<Account> = try await get("/accounts/\(accountId)")
        guard let account = response.data else {
            throw NetworkError.notFound
        }
        return account
    }
    
    func getAccountBalance(_ accountId: String) async throws -> AccountBalanceResponse {
        let response: APIResponse<AccountBalanceResponse> = try await get("/accounts/\(accountId)/balance")
        guard let balance = response.data else {
            throw NetworkError.invalidResponse
        }
        return balance
    }
    
    func creditAccount(_ accountId: String, amount: Decimal, description: String) async throws -> Transaction {
        let request = TransactionRequest(
            type: .credit,
            amount: amount,
            description: description,
            toAccountId: accountId
        )
        let response: APIResponse<Transaction> = try await post("/accounts/\(accountId)/credit", body: request)
        guard let transaction = response.data else {
            throw NetworkError.invalidResponse
        }
        return transaction
    }
    
    func debitAccount(_ accountId: String, amount: Decimal, description: String) async throws -> Transaction {
        let request = TransactionRequest(
            type: .debit,
            amount: amount,
            description: description,
            fromAccountId: accountId
        )
        let response: APIResponse<Transaction> = try await post("/accounts/\(accountId)/debit", body: request)
        guard let transaction = response.data else {
            throw NetworkError.invalidResponse
        }
        return transaction
    }
    
    // MARK: - Member Operations
    
    func getMembers() async throws -> [Member] {
        let response: APIResponse<[Member]> = try await get("/members")
        return response.data ?? []
    }
    
    func getMember(_ memberId: String) async throws -> Member {
        let response: APIResponse<Member> = try await get("/members/\(memberId)")
        guard let member = response.data else {
            throw NetworkError.notFound
        }
        return member
    }
    
    // MARK: - Transaction Operations
    
    func getTransactions(accountId: String? = nil, limit: Int = 50) async throws -> [Transaction] {
        var path = "/transactions?limit=\(limit)"
        if let accountId = accountId {
            path += "&account_id=\(accountId)"
        }
        
        let response: APIResponse<[Transaction]> = try await get(path)
        return response.data ?? []
    }
    
    func createTransaction(_ request: TransactionRequest) async throws -> Transaction {
        let response: APIResponse<Transaction> = try await post("/transactions", body: request)
        guard let transaction = response.data else {
            throw NetworkError.invalidResponse
        }
        return transaction
    }
    
    // MARK: - HTTP Methods
    
    private func get<T: Codable>(_ path: String) async throws -> APIResponse<T> {
        return try await retryManager.execute {
            try await self.performGetRequest(method: "GET", path: path)
        }
    }
    
    private func post<T: Codable, U: Codable>(_ path: String, body: U) async throws -> APIResponse<T> {
        return try await retryManager.execute {
            try await self.performPostRequest(method: "POST", path: path, body: body)
        }
    }
    
    private func performGetRequest<T: Codable>(
        method: String,
        path: String
    ) async throws -> APIResponse<T> {
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header
        if let token = try keychain.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Perform the request
        let (data, response) = try await session.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           let error = httpResponse.networkError {
            throw error
        }
        
        // Decode the response
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(APIResponse<T>.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    private func performPostRequest<T: Codable, U: Codable>(
        method: String,
        path: String,
        body: U
    ) async throws -> APIResponse<T> {
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header
        if let token = try keychain.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body for POST requests
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        } catch {
            throw NetworkError.encodingError(error)
        }
        
        // Perform the request
        let (data, response) = try await session.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           let error = httpResponse.networkError {
            throw error
        }
        
        // Decode the response
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(APIResponse<T>.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - Request/Response Models

struct AuthenticationRequest: Codable {
    let username: String
    let password: String
}

struct AuthenticationResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: Member
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct TransactionRequest: Codable {
    let type: Transaction.TransactionType
    let amount: Decimal
    let description: String
    let fromAccountId: String?
    let toAccountId: String?
    let category: Transaction.TransactionCategory?
    let tags: [String]?
    let metadata: TransactionMetadata?
    
    enum CodingKeys: String, CodingKey {
        case type, amount, description, category, tags, metadata
        case fromAccountId = "from_account_id"
        case toAccountId = "to_account_id"
    }
    
    init(type: Transaction.TransactionType,
         amount: Decimal,
         description: String,
         fromAccountId: String? = nil,
         toAccountId: String? = nil,
         category: Transaction.TransactionCategory? = nil,
         tags: [String]? = nil,
         metadata: TransactionMetadata? = nil) {
        self.type = type
        self.amount = amount
        self.description = description
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.category = category
        self.tags = tags
        self.metadata = metadata
    }
}