import Foundation

/// Simple repository representation
public struct Repository: Sendable {
    public let path: String
    
    public init(path: String) {
        self.path = path
    }
}

/// Protocol defining Git operations for dependency injection
public protocol GitServiceProtocol: Actor {
    /// Opens a repository at the specified path
    /// - Parameter path: The file path to the Git repository
    /// - Returns: Repository object
    /// - Throws: AppError if the repository cannot be opened
    func openRepository(at path: String) async throws -> Repository
    
    /// Gets staged changes from the repository
    /// - Parameter repository: The repository to get changes from
    /// - Returns: An array of file changes
    /// - Throws: AppError if changes cannot be retrieved
    func getStagedChanges(in repository: Repository) async throws -> [FileChange]
}

/// Actor responsible for Git operations
public actor GitService: GitServiceProtocol {
    
    public init() {}
    
    /// Opens a repository at the specified path
    /// - Parameter path: The file path to the Git repository
    /// - Returns: Repository object
    /// - Throws: AppError if the repository cannot be opened
    public func openRepository(at path: String) async throws -> Repository {
        // Check if the path exists and is a git repository
        let fileManager = FileManager.default
        let gitPath = (path as NSString).appendingPathComponent(".git")
        
        guard fileManager.fileExists(atPath: path) else {
            throw AppError.gitError("Path does not exist: \(path)")
        }
        
        guard fileManager.fileExists(atPath: gitPath) else {
            throw AppError.gitError("Not a git repository: \(path)")
        }
        
        return Repository(path: path)
    }
    
    /// Gets staged changes from the repository
    /// - Parameter repository: The repository to get changes from
    /// - Returns: An array of file changes
    /// - Throws: AppError if changes cannot be retrieved
    public func getStagedChanges(in repository: Repository) async throws -> [FileChange] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["diff", "--cached"]
        process.currentDirectoryURL = URL(fileURLWithPath: repository.path)
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if process.terminationStatus != 0 {
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw AppError.gitError("Git diff failed: \(errorOutput)")
            }
            
            let diffOutput = String(data: data, encoding: .utf8) ?? ""
            return try await parseChanges(from: diffOutput)
        } catch {
            throw AppError.gitError("Failed to execute git diff: \(error.localizedDescription)")
        }
    }
    
    /// Parses git diff output into FileChange objects
    /// - Parameter diffOutput: Raw git diff output
    /// - Returns: An array of file changes parsed from the diff
    /// - Throws: AppError if diff cannot be parsed
    private func parseChanges(from diffOutput: String) async throws -> [FileChange] {
        var fileChanges: [FileChange] = []
        let lines = diffOutput.components(separatedBy: .newlines)
        
        var currentFile: String?
        var currentStatus: FileChange.GitStatus = .modified
        var currentDiffContent: [String] = []
        
        for line in lines {
            if line.hasPrefix("diff --git") {
                // Save previous file if exists
                if let filePath = currentFile {
                    let fileChange = FileChange(
                        filePath: filePath,
                        status: currentStatus,
                        diffContent: currentDiffContent.joined(separator: "\n")
                    )
                    fileChanges.append(fileChange)
                }
                
                // Parse new file path from "diff --git a/path b/path"
                let components = line.components(separatedBy: " ")
                if components.count >= 4 {
                    currentFile = String(components[3].dropFirst(2)) // Remove "b/" prefix
                }
                currentDiffContent = [line]
                currentStatus = .modified
            } else if line.hasPrefix("new file mode") {
                currentStatus = .added
                currentDiffContent.append(line)
            } else if line.hasPrefix("deleted file mode") {
                currentStatus = .deleted
                currentDiffContent.append(line)
            } else if line.hasPrefix("rename from") || line.hasPrefix("rename to") {
                currentStatus = .renamed
                currentDiffContent.append(line)
            } else if currentFile != nil {
                currentDiffContent.append(line)
            }
        }
        
        // Add the last file
        if let filePath = currentFile {
            let fileChange = FileChange(
                filePath: filePath,
                status: currentStatus,
                diffContent: currentDiffContent.joined(separator: "\n")
            )
            fileChanges.append(fileChange)
        }
        
        return fileChanges
    }
}