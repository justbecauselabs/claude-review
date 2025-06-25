import Testing
import Foundation
@testable import CodeReviewKit

@Suite("Model Tests")
struct ModelTests {
    
    // MARK: - AppError Tests
    
    @Test("AppError gitError has correct description")
    func testAppErrorGitError() {
        let error = AppError.gitError("Repository not found")
        #expect(error.localizedDescription == "Git error: Repository not found")
    }
    
    @Test("AppError invalidInput has correct description")
    func testAppErrorInvalidInput() {
        let error = AppError.invalidInput("Invalid file path")
        #expect(error.localizedDescription == "Invalid input: Invalid file path")
    }
    
    @Test("AppError fileNotFound has correct description")
    func testAppErrorFileNotFound() {
        let error = AppError.fileNotFound("/path/to/missing/file")
        #expect(error.localizedDescription == "File not found: /path/to/missing/file")
    }
    
    @Test("AppError networkError has correct description")
    func testAppErrorNetworkError() {
        let error = AppError.networkError("Connection timeout")
        #expect(error.localizedDescription == "Network error: Connection timeout")
    }
    
    @Test("AppError unknown has correct description")
    func testAppErrorUnknown() {
        let error = AppError.unknown("Something went wrong")
        #expect(error.localizedDescription == "Unknown error: Something went wrong")
    }
    
    @Test("AppError conforms to Error and Sendable")
    func testAppErrorConformances() {
        let error = AppError.gitError("test")
        
        // Should be throwable as Error
        func throwError() throws {
            throw error
        }
        
        #expect(throws: AppError.self) {
            try throwError()
        }
        
        // Should be Sendable (compile-time check, no runtime assertion needed)
        let _: any Sendable = error
    }
    
    // MARK: - ReviewComment Tests
    
    @Test("ReviewComment initializes correctly")
    func testReviewCommentInitialization() {
        let comment = ReviewComment(
            filePath: "src/main.swift",
            startLine: 42,
            text: "This could be improved"
        )
        
        #expect(comment.filePath == "src/main.swift")
        #expect(comment.startLine == 42)
        #expect(comment.text == "This could be improved")
        #expect(comment.endLine == nil)
    }
    
    @Test("ReviewComment supports line ranges")
    func testReviewCommentWithEndLine() {
        let comment = ReviewComment(
            filePath: "src/main.swift",
            startLine: 42,
            endLine: 45,
            text: "This entire function could be improved"
        )
        
        #expect(comment.filePath == "src/main.swift")
        #expect(comment.startLine == 42)
        #expect(comment.endLine == 45)
        #expect(comment.text == "This entire function could be improved")
    }
    
    @Test("ReviewComment conforms to Sendable")
    func testReviewCommentSendable() {
        let comment = ReviewComment(
            filePath: "test.swift",
            startLine: 1,
            text: "Test comment"
        )
        
        // Should be Sendable (compile-time check)
        let _: any Sendable = comment
    }
    
    // MARK: - DiffLine Tests
    
    @Test("DiffLine initializes correctly with line numbers")
    func testDiffLineWithLineNumbers() {
        let diffLine = DiffLine(
            oldLineNumber: nil,
            newLineNumber: 1,
            content: "import Foundation",
            type: .added
        )
        
        #expect(diffLine.content == "import Foundation")
        #expect(diffLine.oldLineNumber == nil)
        #expect(diffLine.newLineNumber == 1)
        #expect(diffLine.type == .added)
    }
    
    @Test("DiffLine initializes correctly without line numbers")
    func testDiffLineWithoutLineNumbers() {
        let diffLine = DiffLine(
            content: "@@ -1,3 +1,4 @@",
            type: .hunkHeader
        )
        
        #expect(diffLine.content == "@@ -1,3 +1,4 @@")
        #expect(diffLine.oldLineNumber == nil)
        #expect(diffLine.newLineNumber == nil)
        #expect(diffLine.type == .hunkHeader)
    }
    
    @Test("DiffLine LineType enum cases are correct")
    func testDiffLineTypeEnum() {
        let addition = DiffLine(content: "added", type: .added)
        let deletion = DiffLine(content: "deleted", type: .removed)
        let context = DiffLine(content: "context", type: .context)
        let header = DiffLine(content: "header", type: .hunkHeader)
        
        #expect(addition.type == .added)
        #expect(deletion.type == .removed)
        #expect(context.type == .context)
        #expect(header.type == .hunkHeader)
    }
    
    @Test("DiffLine conforms to Sendable")
    func testDiffLineSendable() {
        let diffLine = DiffLine(
            oldLineNumber: 5,
            newLineNumber: 5,
            content: "test content",
            type: .context
        )
        
        // Should be Sendable (compile-time check)
        let _: any Sendable = diffLine
    }
    
    // MARK: - FileChange Integration Tests
    
    @Test("FileChange works with all GitStatus values")
    func testFileChangeWithAllGitStatuses() {
        let statuses: [FileChange.GitStatus] = [.added, .modified, .deleted, .renamed, .copied, .unmerged, .unknown]
        
        for status in statuses {
            let fileChange = FileChange(
                filePath: "test_\(status.rawValue).swift",
                status: status,
                diffContent: "diff content for \(status.rawValue)"
            )
            
            #expect(fileChange.status == status)
            #expect(fileChange.filePath.contains(status.rawValue))
            #expect(fileChange.diffContent?.contains(status.rawValue) == true)
        }
    }
    
    @Test("Models work together in a realistic scenario")
    func testModelsIntegration() {
        // Create a file change
        let fileChange = FileChange(
            filePath: "src/UserService.swift",
            status: .modified,
            diffContent: """
            @@ -10,5 +10,6 @@
             class UserService {
                 func fetchUser() {
            -        // TODO: Implement
            +        // Fetch user from API
            +        apiClient.fetchUser()
                 }
             }
            """
        )
        
        // Create a review comment for this change
        let comment = ReviewComment(
            filePath: fileChange.filePath,
            startLine: 12,
            text: "Good improvement! Consider adding error handling for the API call."
        )
        
        // Create a diff line that might be parsed from the file change
        let diffLine = DiffLine(
            oldLineNumber: nil,
            newLineNumber: 13,
            content: "apiClient.fetchUser()",
            type: .added
        )
        
        // Verify everything works together
        #expect(fileChange.filePath == comment.filePath)
        #expect(fileChange.status == .modified)
        #expect(comment.text.contains("improvement"))
        #expect(diffLine.type == .added)
        #expect(diffLine.content.contains("fetchUser"))
        
        // Verify they're all Sendable
        let sendableFileChange: any Sendable = fileChange
        let sendableComment: any Sendable = comment
        let sendableDiffLine: any Sendable = diffLine
        
        #expect(sendableFileChange as? FileChange != nil)
        #expect(sendableComment as? ReviewComment != nil)
        #expect(sendableDiffLine as? DiffLine != nil)
    }
}