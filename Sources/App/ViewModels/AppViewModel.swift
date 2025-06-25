import SwiftUI
import AppKit
import CodeReviewKit

@MainActor
@Observable
class AppViewModel {
    // MARK: - Properties
    var fileChanges: [FileChange] = []
    var comments: [ReviewComment] = []
    var selectedFileChange: FileChange?
    var isLoading = false
    var errorMessage: String?
    var repositoryPath: String?
    var repository: Repository?
    
    // MARK: - Private Properties
    private let gitService: GitService
    
    // MARK: - Initialization
    init(gitService: GitService = GitService()) {
        self.gitService = gitService
    }
    
    // MARK: - Public Methods
    
    /// Opens a repository using file dialog
    func openRepository() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a Git repository"
        openPanel.prompt = "Open"
        
        openPanel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = openPanel.url {
                Task { @MainActor [weak self] in
                    await self?.loadRepository(at: url.path)
                }
            } else if response == .cancel {
                Task { @MainActor [weak self] in
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    /// Loads repository at the specified path
    func loadRepository(at path: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Open the repository
            repository = try await gitService.openRepository(at: path)
            repositoryPath = path
            
            guard let repo = repository else {
                throw AppError.gitError("Failed to open repository")
            }
            
            // Get unstaged changes
            let changes = try await getUnstagedChanges(in: repo)
            
            // Check if there are no unstaged changes
            if changes.isEmpty {
                errorMessage = "No unstaged changes found. Make changes to files in the repository to see them here."
                fileChanges = []
                comments = []
                selectedFileChange = nil
                repositoryPath = nil
                repository = nil
                isLoading = false
                return
            }
            
            fileChanges = changes
            
            // Clear comments when loading new repository
            comments = []
            selectedFileChange = nil
            
        } catch {
            // Provide more specific error messages
            if let appError = error as? AppError {
                switch appError {
                case .gitError(let message):
                    if message.contains("Not a git repository") {
                        errorMessage = "The selected folder is not a Git repository. Please select a folder that contains a .git directory."
                    } else if message.contains("Path does not exist") {
                        errorMessage = "The selected path does not exist. Please try again."
                    } else if message.contains("Git diff failed") {
                        errorMessage = "Failed to get unstaged changes from Git. Make sure the repository is in a valid state."
                    } else {
                        errorMessage = "Git error: \(message)"
                    }
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
            
            fileChanges = []
            comments = []
            selectedFileChange = nil
            repositoryPath = nil
            repository = nil
        }
        
        isLoading = false
    }
    
    /// Gets unstaged changes from the repository
    private func getUnstagedChanges(in repository: Repository) async throws -> [FileChange] {
        return try await gitService.getUnstagedChanges(in: repository)
    }
    
    /// Refreshes the current repository
    func refreshRepository() async {
        guard let path = repositoryPath else { return }
        await loadRepository(at: path)
    }
    
    /// Adds a comment to the selected file
    func addComment(_ comment: ReviewComment) {
        comments.append(comment)
    }
    
    /// Updates an existing comment
    func updateComment(_ comment: ReviewComment) {
        if let index = comments.firstIndex(where: { 
            $0.filePath == comment.filePath && $0.startLine == comment.startLine 
        }) {
            comments[index] = comment
        }
    }
    
    /// Deletes a comment
    func deleteComment(_ comment: ReviewComment) {
        comments.removeAll { $0.filePath == comment.filePath && $0.startLine == comment.startLine }
    }
    
    /// Generates the review prompt for Claude
    func generateReviewPrompt() -> String {        
        // Only include user comments with line numbers, file names, and code lines
        var commentsOnly = ""
        
        for change in fileChanges {
            let fileComments = comments.filter { $0.filePath == change.filePath }
            guard !fileComments.isEmpty else { continue }
            
            for comment in fileComments {
                let fileName = URL(fileURLWithPath: change.filePath).lastPathComponent
                let codeLines = extractCodeLines(from: change.diffContent, 
                                               startLine: comment.startLine,
                                               endLine: comment.endLine)
                
                commentsOnly += "\(fileName):\(comment.startLine): \(comment.text)\n"
                if !codeLines.isEmpty {
                    commentsOnly += "\(codeLines)\n"
                }
                commentsOnly += "\n"
            }
        }
        
        return commentsOnly.isEmpty ? "No comments to review." : commentsOnly
    }
    
    /// Extracts specific lines of code from diff content
    private func extractCodeLines(from diffContent: String?, startLine: Int, endLine: Int?) -> String {
        guard let diffContent = diffContent else { return "" }
        
        let lines = diffContent.split(separator: "\n", omittingEmptySubsequences: false)
        var extractedLines: [String] = []
        var currentNewLine = 0
        let targetEndLine = endLine ?? startLine
        
        // Parse diff to find the actual code lines
        for line in lines {
            let lineString = String(line)
            
            // Skip file headers and other metadata
            guard !lineString.hasPrefix("diff --git") && 
                  !lineString.hasPrefix("index ") &&
                  !lineString.hasPrefix("+++") &&
                  !lineString.hasPrefix("---") else {
                continue
            }
            
            // Handle hunk headers to track line numbers
            if lineString.hasPrefix("@@") {
                let hunkPattern = /@@\s+-\d+(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s+@@/
                if let match = try? hunkPattern.firstMatch(in: lineString),
                   let newStart = Int(match.1) {
                    currentNewLine = newStart - 1 // Will be incremented for first actual line
                }
                continue
            }
            
            // Handle actual diff lines
            if lineString.hasPrefix("+") {
                currentNewLine += 1
                if currentNewLine >= startLine && currentNewLine <= targetEndLine {
                    extractedLines.append(String(lineString.dropFirst()))
                }
            } else if lineString.hasPrefix(" ") {
                currentNewLine += 1
                if currentNewLine >= startLine && currentNewLine <= targetEndLine {
                    extractedLines.append(String(lineString.dropFirst()))
                }
            }
            // Skip removed lines (they don't contribute to new line numbers)
        }
        
        return extractedLines.joined(separator: "\n")
    }
    
    /// Copies the review prompt to clipboard
    func copyReviewPrompt() {
        let prompt = generateReviewPrompt()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt, forType: .string)
    }
    
    /// Selects a file change
    func selectFileChange(_ fileChange: FileChange?) {
        selectedFileChange = fileChange
    }
}
