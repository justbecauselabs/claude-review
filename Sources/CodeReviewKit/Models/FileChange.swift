import Foundation

/// Represents a change to a file in a Git repository
public struct FileChange: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let filePath: String
    public let status: GitStatus
    public let diffContent: String?
    
    public enum GitStatus: String, Sendable {
        case added = "A"
        case modified = "M"
        case deleted = "D"
        case renamed = "R"
        case copied = "C"
        case unmerged = "U"
        case unknown = "?"
    }
    
    public init(filePath: String, status: GitStatus, diffContent: String? = nil) {
        self.filePath = filePath
        self.status = status
        self.diffContent = diffContent
    }
}