import Foundation

/// Represents a single line in a diff
public struct DiffLine: Identifiable, Hashable, Sendable {
    // Use a stable, computed identifier to prevent SwiftUI rendering issues.
    public var id: String { "\(oldLineNumber ?? 0)-\(newLineNumber ?? 0)-\(content.hashValue)" }
    public let oldLineNumber: Int?
    public let newLineNumber: Int?
    public let content: String
    public let type: LineType
    
    public enum LineType: Sendable {
        case added
        case removed
        case context
        case hunkHeader
    }
    
    public init(oldLineNumber: Int? = nil, newLineNumber: Int? = nil, content: String, type: LineType) {
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.content = content
        self.type = type
    }
}