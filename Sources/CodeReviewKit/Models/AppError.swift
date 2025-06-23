import Foundation

/// Custom error types for the CodeReviewKit framework
public enum AppError: Error, LocalizedError, Sendable {
    case gitError(String)
    case invalidInput(String)
    case fileNotFound(String)
    case networkError(String)
    case diffParsingFailed
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .gitError(let message):
            return "Git error: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .fileNotFound(let message):
            return "File not found: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .diffParsingFailed:
            return "Failed to parse diff content"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}