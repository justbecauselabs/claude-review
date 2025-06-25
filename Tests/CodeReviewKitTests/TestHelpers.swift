import Foundation
@testable import CodeReviewKit

/// Test helpers and factory methods for creating test data
enum TestHelpers {
    
    // MARK: - FileChange Factory Methods
    
    static func makeFileChange(
        filePath: String = "test.swift",
        status: FileChange.GitStatus = .modified,
        diffContent: String? = nil
    ) -> FileChange {
        return FileChange(
            filePath: filePath,
            status: status,
            diffContent: diffContent ?? makeSimpleDiff()
        )
    }
    
    static func makeAddedFileChange() -> FileChange {
        return FileChange(
            filePath: "NewFeature.swift",
            status: .added,
            diffContent: """
            @@ -0,0 +1,10 @@
            +import Foundation
            +
            +struct NewFeature {
            +    let name: String
            +    
            +    func execute() {
            +        print("Executing \\(name)")
            +    }
            +}
            """
        )
    }
    
    static func makeDeletedFileChange() -> FileChange {
        return FileChange(
            filePath: "ObsoleteClass.swift",
            status: .deleted,
            diffContent: """
            @@ -1,8 +0,0 @@
            -import Foundation
            -
            -class ObsoleteClass {
            -    func oldMethod() {
            -        // This is no longer needed
            -    }
            -}
            """
        )
    }
    
    static func makeModifiedFileChange() -> FileChange {
        return FileChange(
            filePath: "UserService.swift",
            status: .modified,
            diffContent: """
            @@ -1,10 +1,12 @@
             import Foundation
            +import Combine
             
             class UserService {
            -    var users: [User] = []
            +    @Published var users: [User] = []
            +    private var cancellables = Set<AnyCancellable>()
                 
                 func loadUsers() {
            -        // TODO: Implement
            +        userRepository.fetchUsers()
            +            .sink { self.users = $0 }
            +            .store(in: &cancellables)
                 }
             }
            """
        )
    }
    
    // MARK: - ReviewComment Factory Methods
    
    static func makeReviewComment(
        filePath: String = "test.swift",
        startLine: Int = 10,
        endLine: Int? = nil,
        text: String = "Test comment"
    ) -> ReviewComment {
        return ReviewComment(
            filePath: filePath,
            startLine: startLine,
            endLine: endLine,
            text: text
        )
    }
    
    static func makeErrorComment() -> ReviewComment {
        return ReviewComment(
            filePath: "BuggyClass.swift",
            startLine: 25,
            text: "Error: This will cause a runtime crash. The variable can be nil here."
        )
    }
    
    static func makeWarningComment() -> ReviewComment {
        return ReviewComment(
            filePath: "PerformanceIssue.swift",
            startLine: 42,
            text: "Warning: This loop could be optimized using functional programming approaches."
        )
    }
    
    static func makeSuggestionComment() -> ReviewComment {
        return ReviewComment(
            filePath: "CodeStyle.swift",
            startLine: 15,
            text: "Suggestion: Consider using a computed property instead of a method for this simple getter."
        )
    }
    
    static func makeNoteComment() -> ReviewComment {
        return ReviewComment(
            filePath: "Documentation.swift",
            startLine: 5,
            text: "Note: This is a good implementation. Well done!"
        )
    }
    
    // MARK: - DiffLine Factory Methods
    
    static func makeDiffLine(
        content: String = "test content",
        oldLineNumber: Int? = 1,
        newLineNumber: Int? = 1,
        type: DiffLine.LineType = .context
    ) -> DiffLine {
        return DiffLine(
            oldLineNumber: oldLineNumber,
            newLineNumber: newLineNumber,
            content: content,
            type: type
        )
    }
    
    static func makeAdditionLine(_ content: String, newLineNumber: Int) -> DiffLine {
        return DiffLine(oldLineNumber: nil, newLineNumber: newLineNumber, content: content, type: .added)
    }
    
    static func makeDeletionLine(_ content: String, oldLineNumber: Int) -> DiffLine {
        return DiffLine(oldLineNumber: oldLineNumber, newLineNumber: nil, content: content, type: .removed)
    }
    
    static func makeContextLine(_ content: String, oldLineNumber: Int, newLineNumber: Int) -> DiffLine {
        return DiffLine(oldLineNumber: oldLineNumber, newLineNumber: newLineNumber, content: content, type: .context)
    }
    
    static func makeHunkHeaderLine(_ content: String) -> DiffLine {
        return DiffLine(content: content, type: .hunkHeader)
    }
    
    // MARK: - Sample Diff Content
    
    static func makeSimpleDiff() -> String {
        return """
        @@ -1,5 +1,6 @@
         import Foundation
        +import SwiftUI
         
         func hello() {
        -    print("Hello, World!")
        +    print("Hello, Swift!")
         }
        """
    }
    
    static func makeComplexDiff() -> String {
        return """
        @@ -1,15 +1,20 @@
         import Foundation
         import SwiftUI
        +import Combine
         
        -struct ContentView: View {
        -    @State private var text = ""
        +struct ContentView: View {
        +    @StateObject private var viewModel = ContentViewModel()
        +    @State private var isPresented = false
             
             var body: some View {
                 VStack {
        -            Text("Hello, World!")
        -            TextField("Enter text", text: $text)
        +            Text("Welcome!")
        +            TextField("Enter text", text: $viewModel.text)
        +            Button("Action") { 
        +                viewModel.performAction()
        +                isPresented = true
        +            }
                 }
        +        .sheet(isPresented: $isPresented) { DetailView() }
             }
         }
        @@ -20,6 +25,10 @@
         
         extension ContentView {
             private func setupUI() {
        -        // TODO: Setup
        +        // Enhanced setup
        +        withAnimation {
        +            // Animation code
        +        }
             }
        +    
        +    private func handleTap() { /* New method */ }
         }
        """
    }
    
    static func makeLargeDiff(lineCount: Int = 100) -> String {
        var diff = "@@ -1,\(lineCount) +1,\(lineCount + 10) @@\n"
        
        for i in 1...lineCount {
            if i % 10 == 0 {
                diff += "-// Old comment \(i)\n"
                diff += "+// New comment \(i)\n"
            } else if i % 7 == 0 {
                diff += "+// Added line \(i)\n"
            } else {
                diff += " // Context line \(i)\n"
            }
        }
        
        return diff
    }
    
    // MARK: - Error Factory Methods
    
    static func makeGitError(_ message: String = "Test git error") -> AppError {
        return .gitError(message)
    }
    
    static func makeInvalidInputError(_ message: String = "Test invalid input") -> AppError {
        return .invalidInput(message)
    }
    
    static func makeFileNotFoundError(_ path: String = "/test/path") -> AppError {
        return .fileNotFound(path)
    }
    
    static func makeNetworkError(_ message: String = "Test network error") -> AppError {
        return .networkError(message)
    }
    
    static func makeUnknownError(_ message: String = "Test unknown error") -> AppError {
        return .unknown(message)
    }
    
    // MARK: - Collection Factory Methods
    
    static func makeFileChangeCollection() -> [FileChange] {
        return [
            makeAddedFileChange(),
            makeModifiedFileChange(),
            makeDeletedFileChange(),
            makeFileChange(filePath: "AnotherFile.swift", status: .renamed),
            makeFileChange(filePath: "CopiedFile.swift", status: .copied)
        ]
    }
    
    static func makeReviewCommentCollection() -> [ReviewComment] {
        return [
            makeErrorComment(),
            makeWarningComment(),
            makeSuggestionComment(),
            makeNoteComment()
        ]
    }
    
    // MARK: - Async Test Helpers
    
    /// Creates a mock GitService configured for success scenarios
    static func makeMockGitService(with fileChanges: [FileChange]) -> MockGitService {
        let mockService = MockGitService()
        Task {
            await mockService.configureMockFileChanges(fileChanges)
        }
        return mockService
    }
    
    /// Creates a mock GitService configured to throw errors
    static func makeFailingMockGitService() async -> MockGitService {
        let mockService = MockGitService()
        await mockService.reset()
        await mockService.setThrowsError(true)
        return mockService
    }
}

// MARK: - Test Extensions

extension FileChange {
    /// Convenience initializer for tests with default diff content
    static func testFileChange(
        path: String = "test.swift",
        status: GitStatus = .modified
    ) -> FileChange {
        return FileChange(
            filePath: path,
            status: status,
            diffContent: TestHelpers.makeSimpleDiff()
        )
    }
}

extension ReviewComment {
    /// Convenience initializer for tests
    static func testComment(
        filePath: String = "test.swift",
        startLine: Int = 10,
        endLine: Int? = nil,
        text: String = "Test comment"
    ) -> ReviewComment {
        return ReviewComment(
            filePath: filePath,
            startLine: startLine,
            endLine: endLine,
            text: text
        )
    }
}

extension DiffLine {
    /// Convenience initializer for tests
    static func testDiffLine(
        content: String = "test content",
        oldLineNumber: Int? = 1,
        newLineNumber: Int? = 1,
        type: LineType = .context
    ) -> DiffLine {
        return DiffLine(
            oldLineNumber: oldLineNumber,
            newLineNumber: newLineNumber,
            content: content,
            type: type
        )
    }
}