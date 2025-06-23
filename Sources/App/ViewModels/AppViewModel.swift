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
            
            // Get staged changes
            let changes = try await getStagedChanges(in: repo)
            
            // Check if there are no staged changes
            if changes.isEmpty {
                errorMessage = "No staged changes found. Use 'git add <files>' to stage changes for review."
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
                        errorMessage = "Failed to get staged changes from Git. Make sure the repository is in a valid state."
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
    
    /// Gets staged changes from the repository
    private func getStagedChanges(in repository: Repository) async throws -> [FileChange] {
        return try await gitService.getStagedChanges(in: repository)
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
        var prompt = """
        Please review the following code changes and provide feedback:
        
        """
        
        // Add file changes
        for change in fileChanges {
            prompt += """
            
            File: \(change.filePath)
            Status: \(change.status.rawValue)
            
            """
            
            if let diff = change.diffContent {
                prompt += """
                Changes:
                \(diff)
                
                """
            }
            
            // Add comments for this file
            let fileComments = comments.filter { $0.filePath == change.filePath }
            if !fileComments.isEmpty {
                prompt += "Comments for this file:\n"
                for comment in fileComments {
                    prompt += "- Line \(comment.startLine): \(comment.text)\n"
                    if let endLine = comment.endLine {
                        prompt += "  End Line: \(endLine)\n"
                    }
                }
                prompt += "\n"
            }
        }
        
        prompt += """
        
        Please provide:
        1. A summary of the changes
        2. Any potential issues or improvements
        3. Best practices that could be applied
        4. Security concerns if any
        """
        
        return prompt
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
