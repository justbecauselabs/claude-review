import Foundation

/// Represents a code review comment on a specific file and line
public struct ReviewComment: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let filePath: String
    public let startLine: Int // Line number relative to the NEW file.
    public let endLine: Int?  // Optional end line, also relative to the NEW file.
    public let text: String
    
    public init(filePath: String, startLine: Int, endLine: Int? = nil, text: String) {
        self.filePath = filePath
        self.startLine = startLine
        self.endLine = endLine
        self.text = text
    }
}