import Testing
import Foundation
@testable import CodeReviewKit

@Suite("Integration Tests")
struct IntegrationTests {
    
    // MARK: - GitService + DiffViewModel Integration
    
    @Test("DiffViewModel can parse output from MockGitService")
    @MainActor
    func testGitServiceDiffViewModelIntegration() async {
        let mockService = MockGitService()
        
        // Configure mock with realistic diff content
        let mockFileChanges = [
            FileChange(
                filePath: "ViewModels/UserViewModel.swift",
                status: .modified,
                diffContent: """
                @@ -1,8 +1,10 @@
                 import Foundation
                +import Combine
                 
                 class UserViewModel {
                -    var users: [User] = []
                +    @Published var users: [User] = []
                +    private var cancellables = Set<AnyCancellable>()
                     
                     func loadUsers() {
                -        // TODO: Load users
                +        // Load users from service
                +        userService.fetchUsers()
                     }
                 }
                """
            )
        ]
        
        await mockService.configureMockFileChanges(mockFileChanges)
        
        // Get the file change and parse it with DiffViewModel
        let fileChanges = await mockService.mockFileChanges
        #expect(!fileChanges.isEmpty)
        
        let fileChange = fileChanges.first!
        let diffViewModel = DiffViewModel()
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        // Verify the diff was parsed correctly
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Should have additions
        let additions = diffViewModel.splitDiffLines.filter { $0.rightLine?.type == .added }
        #expect(additions.count >= 3) // "import Combine", "@Published", "private var cancellables", etc.
        
        // Should have deletions
        let deletions = diffViewModel.splitDiffLines.filter { $0.leftLine?.type == .removed }
        #expect(deletions.count >= 2) // Old var declaration, old TODO comment
        
        // Should have context lines
        let contextLines = diffViewModel.splitDiffLines.filter { 
            $0.leftLine?.type == .context && $0.rightLine?.type == .context 
        }
        #expect(!contextLines.isEmpty)
    }
    
    // MARK: - Error Handling Integration
    
    @Test("Error propagation from GitService to client code")
    func testErrorPropagation() async {
        let mockService = MockGitService()
        
        // Configure mock to throw errors
        await mockService.setThrowsError(true)
        
        // Test repository opening error
        do {
            _ = try await mockService.openRepository(at: "/invalid/path")
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as AppError {
            switch error {
            case .gitError(let message):
                #expect(message.contains("Mock error"))
            default:
                #expect(Bool(false), "Should be a gitError")
            }
        } catch {
            #expect(Bool(false), "Should throw AppError, got \(type(of: error))")
        }
    }
    
    // MARK: - Complex Diff Parsing
    
    @Test("DiffViewModel handles complex real-world diff")
    @MainActor
    func testComplexDiffParsing() {
        let diffViewModel = DiffViewModel()
        
        // Complex diff with multiple hunks, file renames, and various change types
        let complexDiff = """
        @@ -1,12 +1,15 @@
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
        +            Text("Welcome to the App!")
        +            TextField("Enter text", text: $viewModel.text)
        +            Button("Show Details") { isPresented = true }
                 }
        +        .sheet(isPresented: $isPresented) { DetailView() }
             }
         }
        @@ -20,8 +23,12 @@
         
         extension ContentView {
             private func setupUI() {
        -        // Basic setup
        +        // Enhanced setup with animations
        +        withAnimation(.easeInOut) {
        +            // Setup code here
        +        }
             }
        +    
        +    private func handleAction() { /* New method */ }
         }
        """
        
        let fileChange = FileChange(
            filePath: "Views/ContentView.swift",
            status: .modified,
            diffContent: complexDiff
        )
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Should have two hunk headers
        let hunkHeaders = diffViewModel.splitDiffLines.filter { $0.leftLine?.type == .hunkHeader }
        #expect(hunkHeaders.count == 2)
        
        // Verify specific changes
        let addedCombineImport = diffViewModel.splitDiffLines.first { line in
            line.rightLine?.content.contains("import Combine") == true && 
            line.rightLine?.type == .added
        }
        #expect(addedCombineImport != nil)
        
        let deletedHelloWorld = diffViewModel.splitDiffLines.first { line in
            line.leftLine?.content.contains("Hello, World!") == true && 
            line.leftLine?.type == .removed
        }
        #expect(deletedHelloWorld != nil)
        
        let addedWelcomeText = diffViewModel.splitDiffLines.first { line in
            line.rightLine?.content.contains("Welcome to the App!") == true && 
            line.rightLine?.type == .added
        }
        #expect(addedWelcomeText != nil)
    }
    
    // MARK: - Edge Cases
    
    @Test("DiffViewModel handles empty diff")
    @MainActor
    func testEmptyDiffHandling() {
        let diffViewModel = DiffViewModel()
        
        let fileChange = FileChange(
            filePath: "empty.swift",
            status: .modified,
            diffContent: ""
        )
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(diffViewModel.splitDiffLines.isEmpty)
    }
    
    @Test("DiffViewModel handles diff with only file headers")
    @MainActor
    func testDiffWithOnlyFileHeaders() {
        let diffViewModel = DiffViewModel()
        
        let fileChange = FileChange(
            filePath: "headers_only.swift",
            status: .renamed,
            diffContent: """
            --- a/old_name.swift
            +++ b/new_name.swift
            """
        )
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        // Should not include file headers in output
        #expect(diffViewModel.splitDiffLines.isEmpty)
    }
    
    @Test("DiffViewModel handles single line changes")
    @MainActor
    func testSingleLineChanges() {
        let diffViewModel = DiffViewModel()
        
        let fileChange = FileChange(
            filePath: "single_line.swift",
            status: .modified,
            diffContent: """
            @@ -1 +1 @@
            -let version = "1.0.0"
            +let version = "1.0.1"
            """
        )
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        let deletion = diffViewModel.splitDiffLines.first { $0.leftLine?.type == .removed }
        let addition = diffViewModel.splitDiffLines.first { $0.rightLine?.type == .added }
        
        #expect(deletion?.leftLine?.content.contains("1.0.0") == true)
        #expect(addition?.rightLine?.content.contains("1.0.1") == true)
    }
    
    // MARK: - Performance Tests
    
    @Test("DiffViewModel handles large diff efficiently", .timeLimit(.minutes(1)))
    @MainActor
    func testLargeDiffPerformance() {
        let diffViewModel = DiffViewModel()
        
        // Generate a large diff (1000 lines of changes)
        var largeDiff = "@@ -1,1000 +1,1000 @@\n"
        for i in 1...500 {
            largeDiff += " line \(i) context\n"
            largeDiff += "-old line \(i)\n"
            largeDiff += "+new line \(i)\n"
        }
        
        let fileChange = FileChange(
            filePath: "large_file.swift",
            status: .modified,
            diffContent: largeDiff
        )
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        // Should complete within time limit and produce reasonable output
        #expect(diffViewModel.splitDiffLines.count > 1000)
    }
    
    // MARK: - Memory Management
    
    @Test("No retain cycles in DiffViewModel")
    @MainActor
    func testDiffViewModelMemoryManagement() {
        weak var weakViewModel: DiffViewModel?
        
        do {
            let viewModel = DiffViewModel()
            weakViewModel = viewModel
            
            let fileChange = FileChange(
                filePath: "memory_test.swift",
                status: .added,
                diffContent: "@@ -0,0 +1,3 @@\n+line 1\n+line 2\n+line 3"
            )
            
            viewModel.fileChange = fileChange
            viewModel.parseDiff()
            
            #expect(weakViewModel != nil)
        }
        
        // After scope ends, view model should be deallocated
        #expect(weakViewModel == nil)
    }
}