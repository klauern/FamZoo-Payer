import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noInternetConnection
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case requestTimeout
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noInternetConnection:
            return "No internet connection available"
        case .unauthorized:
            return "Authentication required"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error (\(code))"
        case .requestTimeout:
            return "Request timed out"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .requestTimeout, .serverError:
            return true
        case .unauthorized, .forbidden, .notFound, .invalidURL, .invalidResponse, .decodingError, .encodingError:
            return false
        case .unknown:
            return false
        }
    }
    
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .requestTimeout
            case .badURL:
                return .invalidURL
            default:
                return .unknown(urlError)
            }
        }
        
        return .unknown(error)
    }
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
    let message: String?
    let timestamp: Date
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case success, data, error, message, timestamp
        case requestId = "request_id"
    }
}

struct APIError: Codable, Error {
    let code: String
    let message: String
    let details: [String: String]?
    
    var localizedDescription: String {
        return message
    }
}

class NetworkRetryManager {
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    init(maxRetries: Int = 3, retryDelay: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                let networkError = NetworkError.from(error)
                
                if attempt < maxRetries && networkError.isRetryable {
                    let delay = retryDelay * Double(attempt + 1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    throw networkError
                }
            }
        }
        
        throw NetworkError.from(lastError ?? NetworkError.unknown(NSError(domain: "RetryManager", code: -1, userInfo: nil)))
    }
}

extension URLResponse {
    var httpStatusCode: Int? {
        return (self as? HTTPURLResponse)?.statusCode
    }
    
    var isSuccessful: Bool {
        guard let statusCode = httpStatusCode else { return false }
        return 200...299 ~= statusCode
    }
}

extension HTTPURLResponse {
    var networkError: NetworkError? {
        switch statusCode {
        case 200...299:
            return nil
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 408:
            return .requestTimeout
        case 500...599:
            return .serverError(statusCode)
        default:
            return .unknown(NSError(domain: "HTTPError", code: statusCode, userInfo: nil))
        }
    }
}