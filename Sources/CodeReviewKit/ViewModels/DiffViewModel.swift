import Foundation
import Observation

@MainActor
@Observable
public final class DiffViewModel {
    // MARK: - Properties
    
    public var fileChange: FileChange?
    public private(set) var splitDiffLines: [SplitDiffLine] = []
    
    // MARK: - Types
    
    public struct SplitDiffLine {
        public let leftLine: DiffLine?
        public let rightLine: DiffLine?
        
        public init(leftLine: DiffLine?, rightLine: DiffLine?) {
            self.leftLine = leftLine
            self.rightLine = rightLine
        }
    }
    
    // MARK: - Public Methods
    
    public init() {}
    
    public func parseDiff() {
        guard let fileChange = fileChange,
              let diff = fileChange.diffContent else {
            splitDiffLines = []
            return
        }
        
        let lines = diff.split(separator: "\n", omittingEmptySubsequences: false)
        var parsedLines: [SplitDiffLine] = []
        
        var leftLineNumber = 1
        var rightLineNumber = 1
        
        // Regex patterns for diff parsing
        let hunkHeaderPattern = /^@@\s+-(\d+)(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s+@@/
        
        for line in lines {
            let lineString = String(line)
            
            // Check if it's a hunk header
            if let match = try? hunkHeaderPattern.firstMatch(in: lineString) {
                // Extract line numbers from hunk header
                if let leftStart = Int(match.1),
                   let rightStart = Int(match.2) {
                    leftLineNumber = leftStart
                    rightLineNumber = rightStart
                }
                
                // Add hunk header to both sides
                let hunkLine = DiffLine(
                    oldLineNumber: nil,
                    newLineNumber: nil,
                    content: lineString,
                    type: .hunkHeader
                )
                parsedLines.append(SplitDiffLine(
                    leftLine: hunkLine,
                    rightLine: hunkLine
                ))
                continue
            }
            
            // Parse regular diff lines
            if lineString.hasPrefix("+") && !lineString.hasPrefix("+++") {
                // Addition line
                let content = String(lineString.dropFirst())
                let diffLine = DiffLine(
                    oldLineNumber: nil,
                    newLineNumber: rightLineNumber,
                    content: content,
                    type: .added
                )
                parsedLines.append(SplitDiffLine(
                    leftLine: nil,
                    rightLine: diffLine
                ))
                rightLineNumber += 1
            } else if lineString.hasPrefix("-") && !lineString.hasPrefix("---") {
                // Deletion line
                let content = String(lineString.dropFirst())
                let diffLine = DiffLine(
                    oldLineNumber: leftLineNumber,
                    newLineNumber: nil,
                    content: content,
                    type: .removed
                )
                parsedLines.append(SplitDiffLine(
                    leftLine: diffLine,
                    rightLine: nil
                ))
                leftLineNumber += 1
            } else if lineString.hasPrefix(" ") || 
                      (!lineString.hasPrefix("---") && 
                       !lineString.hasPrefix("+++") && 
                       !lineString.hasPrefix("\\")) {
                // Context line (starts with space or is a regular line)
                let content = lineString.hasPrefix(" ") ? String(lineString.dropFirst()) : lineString
                let leftDiffLine = DiffLine(
                    oldLineNumber: leftLineNumber,
                    newLineNumber: nil,
                    content: content,
                    type: .context
                )
                let rightDiffLine = DiffLine(
                    oldLineNumber: nil,
                    newLineNumber: rightLineNumber,
                    content: content,
                    type: .context
                )
                parsedLines.append(SplitDiffLine(
                    leftLine: leftDiffLine,
                    rightLine: rightDiffLine
                ))
                leftLineNumber += 1
                rightLineNumber += 1
            }
            // Skip file header lines (---, +++, \)
        }
        
        // Align the diff lines for side-by-side view
        splitDiffLines = alignDiffLines(parsedLines)
    }
    
    // MARK: - Private Methods
    
    private func alignDiffLines(_ lines: [SplitDiffLine]) -> [SplitDiffLine] {
        var aligned: [SplitDiffLine] = []
        var pendingDeletions: [DiffLine] = []
        var pendingAdditions: [DiffLine] = []
        
        for line in lines {
            if let leftLine = line.leftLine, leftLine.type == .removed {
                pendingDeletions.append(leftLine)
            } else if let rightLine = line.rightLine, rightLine.type == .added {
                pendingAdditions.append(rightLine)
            } else {
                // Process any pending deletions and additions
                while !pendingDeletions.isEmpty || !pendingAdditions.isEmpty {
                    let left = pendingDeletions.isEmpty ? nil : pendingDeletions.removeFirst()
                    let right = pendingAdditions.isEmpty ? nil : pendingAdditions.removeFirst()
                    aligned.append(SplitDiffLine(leftLine: left, rightLine: right))
                }
                
                // Add the current context or hunk header line
                aligned.append(line)
            }
        }
        
        // Process any remaining pending lines
        while !pendingDeletions.isEmpty || !pendingAdditions.isEmpty {
            let left = pendingDeletions.isEmpty ? nil : pendingDeletions.removeFirst()
            let right = pendingAdditions.isEmpty ? nil : pendingAdditions.removeFirst()
            aligned.append(SplitDiffLine(leftLine: left, rightLine: right))
        }
        
        return aligned
    }
}