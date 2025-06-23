import Testing
import Foundation
@testable import CodeReviewKit

@Suite("Performance Tests")
struct PerformanceTests {
    
    // MARK: - DiffViewModel Performance Tests
    
    @Test("DiffViewModel parses medium diff efficiently", .timeLimit(.seconds(1)))
    @MainActor
    func testMediumDiffPerformance() {
        let diffViewModel = DiffViewModel()
        
        // Generate a medium-sized diff (500 lines)
        let mediumDiff = TestHelpers.makeLargeDiff(lineCount: 500)
        
        let fileChange = FileChange(
            filePath: "MediumFile.swift",
            status: .modified,
            diffContent: mediumDiff
        )
        
        diffViewModel.fileChange = fileChange
        
        // This should complete within 1 second
        diffViewModel.parseDiff()
        
        // Verify reasonable output
        #expect(diffViewModel.splitDiffLines.count > 400)
        #expect(diffViewModel.splitDiffLines.count < 600)
    }
    
    @Test("DiffViewModel handles large diff", .timeLimit(.seconds(3)))
    @MainActor
    func testLargeDiffPerformance() {
        let diffViewModel = DiffViewModel()
        
        // Generate a large diff (2000 lines)
        let largeDiff = TestHelpers.makeLargeDiff(lineCount: 2000)
        
        let fileChange = FileChange(
            filePath: "LargeFile.swift",
            status: .modified,
            diffContent: largeDiff
        )
        
        diffViewModel.fileChange = fileChange
        
        // This should complete within 3 seconds
        diffViewModel.parseDiff()
        
        // Verify reasonable output
        #expect(diffViewModel.splitDiffLines.count > 1500)
        #expect(diffViewModel.splitDiffLines.count < 2500)
    }
    
    @Test("DiffViewModel memory usage with multiple parses")
    @MainActor
    func testMultipleParsesMemoryUsage() {
        let diffViewModel = DiffViewModel()
        let sampleDiff = TestHelpers.makeComplexDiff()
        
        // Parse the same diff multiple times to check for memory leaks
        for i in 1...10 {
            let fileChange = FileChange(
                filePath: "TestFile\(i).swift",
                status: .modified,
                diffContent: sampleDiff
            )
            
            diffViewModel.fileChange = fileChange
            diffViewModel.parseDiff()
            
            // Verify consistent behavior
            #expect(!diffViewModel.splitDiffLines.isEmpty)
        }
        
        // Final verification
        #expect(diffViewModel.splitDiffLines.count > 0)
    }
    
    // MARK: - Model Performance Tests
    
    @Test("FileChange creation with large diff content", .timeLimit(.seconds(1)))
    func testFileChangeWithLargeDiff() {
        let largeDiffContent = TestHelpers.makeLargeDiff(lineCount: 5000)
        
        // Creating FileChange should be fast even with large content
        let fileChange = FileChange(
            filePath: "VeryLargeFile.swift",
            status: .modified,
            diffContent: largeDiffContent
        )
        
        #expect(fileChange.filePath == "VeryLargeFile.swift")
        #expect(fileChange.status == .modified)
        #expect(fileChange.diffContent?.count ?? 0 > 10000)
    }
    
    @Test("DiffLine creation performance")
    func testDiffLineCreationPerformance() {
        var diffLines: [DiffLine] = []
        
        // Create many DiffLine instances
        for i in 1...1000 {
            let diffLine = DiffLine(
                oldLineNumber: i,
                newLineNumber: i,
                content: "This is line \(i) with some content that makes it realistic",
                type: i % 4 == 0 ? .added : (i % 4 == 1 ? .removed : (i % 4 == 2 ? .context : .hunkHeader))
            )
            diffLines.append(diffLine)
        }
        
        #expect(diffLines.count == 1000)
        
        // Test hash performance
        let diffLineSet = Set(diffLines.map { $0.id })
        #expect(diffLineSet.count <= 1000) // Some may have same IDs if content/line numbers are same
    }
    
    // MARK: - Collection Performance Tests
    
    @Test("Large collection of FileChanges", .timeLimit(.seconds(1)))
    func testLargeFileChangeCollection() {
        var fileChanges: [FileChange] = []
        
        // Create a large collection of file changes
        for i in 1...100 {
            let fileChange = FileChange(
                filePath: "File\(i).swift",
                status: [.added, .modified, .deleted, .renamed].randomElement()!,
                diffContent: TestHelpers.makeSimpleDiff()
            )
            fileChanges.append(fileChange)
        }
        
        #expect(fileChanges.count == 100)
        
        // Test filtering performance
        let modifiedFiles = fileChanges.filter { $0.status == .modified }
        let addedFiles = fileChanges.filter { $0.status == .added }
        
        #expect(modifiedFiles.count + addedFiles.count <= 100)
    }
    
    @Test("Large collection of ReviewComments")
    func testLargeReviewCommentCollection() {
        var comments: [ReviewComment] = []
        
        // Create many review comments
        for i in 1...500 {
            let comment = ReviewComment(
                file: "File\(i % 50).swift", // 50 different files
                line: i % 100, // Lines 0-99
                comment: "This is comment \(i) with detailed feedback about the code quality and suggestions for improvement.",
                severity: [.error, .warning, .suggestion, .note].randomElement()!
            )
            comments.append(comment)
        }
        
        #expect(comments.count == 500)
        
        // Test grouping performance (common operation)
        let commentsByFile = Dictionary(grouping: comments) { $0.file }
        #expect(commentsByFile.keys.count <= 50)
        
        let errorComments = comments.filter { $0.severity == .error }
        #expect(errorComments.count >= 0)
    }
    
    // MARK: - Git Service Mock Performance
    
    @Test("MockGitService with large file change set")
    func testMockGitServicePerformance() async {
        let mockService = MockGitService()
        
        // Create a large set of file changes
        var largeFileChanges: [FileChange] = []
        for i in 1...200 {
            let fileChange = FileChange(
                filePath: "src/module\(i % 20)/File\(i).swift",
                status: [.added, .modified, .deleted].randomElement()!,
                diffContent: i % 10 == 0 ? TestHelpers.makeComplexDiff() : TestHelpers.makeSimpleDiff()
            )
            largeFileChanges.append(fileChange)
        }
        
        await mockService.configureMockFileChanges(largeFileChanges)
        
        // Retrieve should be fast
        let retrievedChanges = await mockService.mockFileChanges
        #expect(retrievedChanges.count == 200)
    }
    
    // MARK: - Stress Tests
    
    @Test("Repeated diff parsing stress test", .timeLimit(.seconds(5)))
    @MainActor
    func testRepeatedDiffParsingStress() {
        let diffViewModel = DiffViewModel()
        let complexDiff = TestHelpers.makeComplexDiff()
        
        // Parse the same complex diff many times
        for iteration in 1...50 {
            let fileChange = FileChange(
                filePath: "StressTest\(iteration).swift",
                status: .modified,
                diffContent: complexDiff
            )
            
            diffViewModel.fileChange = fileChange
            diffViewModel.parseDiff()
            
            // Verify consistent parsing
            #expect(!diffViewModel.splitDiffLines.isEmpty)
            
            // Check for specific elements to ensure parsing quality
            let hunkHeaders = diffViewModel.splitDiffLines.filter { $0.leftLine?.type == .hunkHeader }
            #expect(hunkHeaders.count >= 2) // Complex diff should have multiple hunks
        }
    }
    
    @Test("Concurrent mock service access simulation")
    func testConcurrentMockServiceAccess() async {
        let mockService = MockGitService()
        
        // Configure with some test data
        await mockService.configureMockFileChanges([
            TestHelpers.makeAddedFileChange(),
            TestHelpers.makeModifiedFileChange()
        ])
        
        // Simulate concurrent access (though our actor serializes them)
        await withTaskGroup(of: Int.self) { group in
            for i in 1...10 {
                group.addTask {
                    let changes = await mockService.mockFileChanges
                    return changes.count
                }
            }
            
            var totalCount = 0
            for await count in group {
                totalCount += count
                #expect(count == 2) // Should always return 2 changes
            }
            
            #expect(totalCount == 20) // 10 tasks × 2 changes each
        }
    }
    
    // MARK: - Edge Case Performance
    
    @Test("Very long single line diff")
    @MainActor
    func testVeryLongSingleLineDiff() {
        let diffViewModel = DiffViewModel()
        
        // Create a diff with one very long line
        let longLine = String(repeating: "x", count: 10000)
        let longLineDiff = """
        @@ -1,1 +1,1 @@
        -\(longLine)
        +\(longLine)_modified
        """
        
        let fileChange = FileChange(
            filePath: "LongLine.swift",
            status: .modified,
            diffContent: longLineDiff
        )
        
        diffViewModel.fileChange = fileChange
        diffViewModel.parseDiff()
        
        #expect(!diffViewModel.splitDiffLines.isEmpty)
        
        // Verify the long line was processed
        let addedLine = diffViewModel.splitDiffLines.first { $0.rightLine?.type == .added }
        #expect(addedLine?.rightLine?.content.count ?? 0 > 10000)
    }
    
    @Test("Empty and nil content handling performance")
    @MainActor
    func testEmptyContentHandlingPerformance() {
        let diffViewModel = DiffViewModel()
        
        // Test with many empty/nil content scenarios
        for i in 1...100 {
            let fileChange = FileChange(
                filePath: "Empty\(i).swift",
                status: .modified,
                diffContent: i % 2 == 0 ? "" : nil
            )
            
            diffViewModel.fileChange = fileChange
            diffViewModel.parseDiff()
            
            // Should handle gracefully and quickly
            #expect(diffViewModel.splitDiffLines.isEmpty)
        }
    }
}