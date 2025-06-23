import Testing
import Foundation
@testable import CodeReviewKit

@Suite("DiffViewModel Tests")
@MainActor
struct DiffViewModelTests {
    
    @Test("DiffViewModel initializes correctly")
    func testDiffViewModelInitialization() {
        let diffViewModel = DiffViewModel()
        
        #expect(diffViewModel.fileChange == nil)
        #expect(diffViewModel.splitDiffLines.isEmpty)
    }
    
    @Test("parseDiff handles nil fileChange")
    func testParseDiffWithNilFileChange() {
        let diffViewModel = DiffViewModel()
        
        diffViewModel.parseDiff()
        
        #expect(diffViewModel.splitDiffLines.isEmpty)
    }
    
    @Test("parseDiff handles fileChange with nil diff content")
    func testParseDiffWithNilDiffContent() {
        let diffViewModel = DiffViewModel()
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: nil)
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(diffViewModel.splitDiffLines.isEmpty)
    }
    
    @Test("parseDiff handles simple addition")
    func testParseDiffSimpleAddition() {
        let diffViewModel = DiffViewModel()
        let diffContent = """
        @@ -1,3 +1,4 @@
         import Foundation
        +import SwiftUI
         
         func main() {
        """
        
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: diffContent)
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Should have hunk header
        let firstLine = diffViewModel.splitDiffLines.first
        #expect(firstLine?.leftLine?.type == .hunkHeader)
        #expect(firstLine?.rightLine?.type == .hunkHeader)
        
        // Find the addition line
        let additionLine = diffViewModel.splitDiffLines.first { line in
            line.rightLine?.type == .added
        }
        #expect(additionLine != nil)
        #expect(additionLine?.rightLine?.content == "import SwiftUI")
        #expect(additionLine?.leftLine == nil) // No corresponding left line for addition
    }
    
    @Test("parseDiff handles simple deletion")
    func testParseDiffSimpleDeletion() {
        let diffViewModel = DiffViewModel()
        let diffContent = """
        @@ -1,4 +1,3 @@
         import Foundation
        -import SwiftUI
         
         func main() {
        """
        
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: diffContent)
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Find the deletion line
        let deletionLine = diffViewModel.splitDiffLines.first { line in
            line.leftLine?.type == .removed
        }
        #expect(deletionLine != nil)
        #expect(deletionLine?.leftLine?.content == "import SwiftUI")
        #expect(deletionLine?.rightLine == nil) // No corresponding right line for deletion
    }
    
    @Test("parseDiff handles context lines")
    func testParseDiffContextLines() {
        let diffViewModel = DiffViewModel()
        let diffContent = """
        @@ -1,5 +1,5 @@
         import Foundation
         
        -let oldVar = "old"
        +let newVar = "new"
         
         func main() {
        """
        
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: diffContent)
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Find context lines
        let contextLines = diffViewModel.splitDiffLines.filter { line in
            line.leftLine?.type == .context && line.rightLine?.type == .context
        }
        #expect(!contextLines.isEmpty)
        
        // Should have "import Foundation" as context
        let importLine = contextLines.first { line in
            line.leftLine?.content == "import Foundation"
        }
        #expect(importLine != nil)
        #expect(importLine?.rightLine?.content == "import Foundation")
    }
    
    @Test("parseDiff handles mixed additions and deletions")
    func testParseDiffMixedChanges() {
        let diffViewModel = DiffViewModel()
        let diffContent = """
        @@ -1,6 +1,6 @@
         import Foundation
        -import UIKit
        +import SwiftUI
         
        -class OldClass {
        +struct NewStruct {
             func method() {}
         }
        """
        
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: diffContent)
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        let deletions = diffViewModel.splitDiffLines.filter { $0.leftLine?.type == .removed }
        let additions = diffViewModel.splitDiffLines.filter { $0.rightLine?.type == .added }
        
        #expect(deletions.count == 2) // "import UIKit" and "class OldClass {"
        #expect(additions.count == 2) // "import SwiftUI" and "struct NewStruct {"
    }
    
    @Test("parseDiff handles hunk headers correctly")
    func testParseDiffHunkHeaders() {
        let diffViewModel = DiffViewModel()
        let diffContent = """
        @@ -1,3 +1,4 @@
         line 1
        +line 2
         line 3
        @@ -10,2 +11,3 @@
         line 10
        +line 11
         line 12
        """
        
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: diffContent)
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        let hunkHeaders = diffViewModel.splitDiffLines.filter { line in
            line.leftLine?.type == .hunkHeader
        }
        #expect(hunkHeaders.count == 2)
        
        #expect(hunkHeaders[0].leftLine?.content.contains("@@ -1,3 +1,4 @@") == true)
        #expect(hunkHeaders[1].leftLine?.content.contains("@@ -10,2 +11,3 @@") == true)
    }
    
    @Test("parseDiff ignores file headers")
    func testParseDiffIgnoresFileHeaders() {
        let diffViewModel = DiffViewModel()
        let diffContent = """
        --- a/test.swift
        +++ b/test.swift
        @@ -1,2 +1,3 @@
         import Foundation
        +import SwiftUI
         func main() {}
        """
        
        let fileChange = FileChange(filePath: "test.swift", status: .modified, diffContent: diffContent)
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Should not include --- or +++ lines in the parsed result
        let fileHeaderLines = diffViewModel.splitDiffLines.filter { line in
            line.leftLine?.content.hasPrefix("---") == true || 
            line.leftLine?.content.hasPrefix("+++") == true ||
            line.rightLine?.content.hasPrefix("---") == true || 
            line.rightLine?.content.hasPrefix("+++") == true
        }
        #expect(fileHeaderLines.isEmpty)
    }
    
    @Test("SplitDiffLine structure is correct")
    func testSplitDiffLineStructure() {
        let leftLine = DiffLine(
            oldLineNumber: 1,
            newLineNumber: nil,
            content: "old content",
            type: .removed
        )
        
        let rightLine = DiffLine(
            oldLineNumber: nil,
            newLineNumber: 1,
            content: "new content", 
            type: .added
        )
        
        let splitLine = DiffViewModel.SplitDiffLine(
            leftLine: leftLine,
            rightLine: rightLine
        )
        
        #expect(splitLine.leftLine?.oldLineNumber == 1)
        #expect(splitLine.leftLine?.content == "old content")
        #expect(splitLine.leftLine?.type == .removed)
        
        #expect(splitLine.rightLine?.newLineNumber == 1)
        #expect(splitLine.rightLine?.content == "new content")
        #expect(splitLine.rightLine?.type == .added)
    }
    
    @Test("DiffLine types are correct")
    func testDiffLineTypes() {
        let contextLine = DiffLine(oldLineNumber: 1, newLineNumber: 1, content: "context", type: .context)
        let additionLine = DiffLine(oldLineNumber: nil, newLineNumber: 2, content: "added", type: .added)
        let deletionLine = DiffLine(oldLineNumber: 3, newLineNumber: nil, content: "deleted", type: .removed)
        let hunkLine = DiffLine(content: "@@ -1,3 +1,4 @@", type: .hunkHeader)
        
        #expect(contextLine.type == .context)
        #expect(additionLine.type == .added)
        #expect(deletionLine.type == .removed)
        #expect(hunkLine.type == .hunkHeader)
        #expect(hunkLine.oldLineNumber == nil) // Hunk headers don't have line numbers
        #expect(hunkLine.newLineNumber == nil) // Hunk headers don't have line numbers
    }
}