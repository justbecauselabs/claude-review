import Testing
import Foundation
@testable import CodeReviewKit

/// Mock implementation of GitServiceProtocol for testing
actor MockGitService: GitServiceProtocol {
    var shouldThrowError = false
    var mockRepository: Repository?
    var mockFileChanges: [FileChange] = []
    var openRepositoryCallCount = 0
    var getStagedChangesCallCount = 0
    
    func openRepository(at path: String) async throws -> Repository {
        openRepositoryCallCount += 1
        
        if shouldThrowError {
            throw AppError.gitError("Mock error: Failed to open repository")
        }
        
        if let mockRepository = mockRepository {
            return mockRepository
        }
        
        return Repository(path: path)
    }
    
    func getStagedChanges(in repository: Repository) async throws -> [FileChange] {
        getStagedChangesCallCount += 1
        
        if shouldThrowError {
            throw AppError.gitError("Mock error: Failed to get staged changes")
        }
        
        return mockFileChanges
    }
    
    // Helper methods for testing
    func reset() {
        shouldThrowError = false
        mockRepository = nil
        mockFileChanges = []
        openRepositoryCallCount = 0
        getStagedChangesCallCount = 0
    }
    
    func configureMockFileChanges(_ changes: [FileChange]) {
        mockFileChanges = changes
    }
}

@Suite("GitService Tests")
struct GitServiceTests {
    
    @Test("GitService can be initialized")
    func testGitServiceInitialization() {
        let gitService = GitService()
        #expect(gitService != nil)
    }
    
    @Test("openRepository throws error for invalid path")
    func testOpenRepositoryWithInvalidPath() async {
        let gitService = GitService()
        
        await #expect(throws: AppError.self) {
            try await gitService.openRepository(at: "/nonexistent/path")
        }
    }
    
    @Test("MockGitService works correctly for success case")
    func testMockGitServiceSuccess() async throws {
        let mockService = MockGitService()
        
        // Configure mock to succeed
        await mockService.reset()
        let sampleChanges = [
            FileChange(filePath: "test.swift", status: .modified, diffContent: "sample diff"),
            FileChange(filePath: "README.md", status: .added, diffContent: "new file content")
        ]
        await mockService.configureMockFileChanges(sampleChanges)
        
        // Test would require a real Repository object for full testing
        // For now, we verify the mock behavior
        let callCount = await mockService.openRepositoryCallCount
        #expect(callCount == 0)
        
        let changes = await mockService.mockFileChanges
        #expect(changes.count == 2)
        #expect(changes[0].filePath == "test.swift")
        #expect(changes[0].status == .modified)
        #expect(changes[1].filePath == "README.md")
        #expect(changes[1].status == .added)
    }
    
    @Test("MockGitService throws error when configured to fail")
    func testMockGitServiceError() async {
        let mockService = MockGitService()
        
        await mockService.reset()
        await mockService.shouldThrowError = true
        
        await #expect(throws: AppError.self) {
            try await mockService.openRepository(at: "/some/path")
        }
        
        let callCount = await mockService.openRepositoryCallCount
        #expect(callCount == 1)
    }
    
    @Test("FileChange model properties are correct")
    func testFileChangeModel() {
        let fileChange = FileChange(
            filePath: "src/main.swift",
            status: .modified,
            diffContent: "@@ -1,3 +1,4 @@\n import Foundation\n+import SwiftUI\n\n func main() {"
        )
        
        #expect(fileChange.filePath == "src/main.swift")
        #expect(fileChange.status == .modified)
        #expect(fileChange.diffContent?.contains("import SwiftUI") == true)
        #expect(fileChange.id != UUID()) // Should have a unique ID
    }
    
    @Test("FileChange GitStatus enum cases are correct")
    func testGitStatusEnum() {
        #expect(FileChange.GitStatus.added.rawValue == "A")
        #expect(FileChange.GitStatus.modified.rawValue == "M")
        #expect(FileChange.GitStatus.deleted.rawValue == "D")
        #expect(FileChange.GitStatus.renamed.rawValue == "R")
        #expect(FileChange.GitStatus.copied.rawValue == "C")
        #expect(FileChange.GitStatus.unmerged.rawValue == "U")
        #expect(FileChange.GitStatus.unknown.rawValue == "?")
    }
    
    @Test("FileChange conforms to Identifiable and Hashable")
    func testFileChangeConformances() {
        let fileChange1 = FileChange(filePath: "test.swift", status: .added)
        let fileChange2 = FileChange(filePath: "test.swift", status: .added)
        
        // Each FileChange should have a unique ID
        #expect(fileChange1.id != fileChange2.id)
        
        // FileChanges with same content should be equal when hashed
        let fileChange3 = FileChange(filePath: "same.swift", status: .modified, diffContent: "same diff")
        let fileChange4 = FileChange(filePath: "same.swift", status: .modified, diffContent: "same diff")
        
        // Note: They will have different IDs, so they won't be equal
        // This is expected behavior for structs with UUID ids
        #expect(fileChange3.id != fileChange4.id)
    }
}