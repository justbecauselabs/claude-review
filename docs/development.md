# Development Guide

<!-- Generated: 2025-06-25 12:00:00 UTC -->

## Overview

ClaudeCodeReviewer is a modern Swift 6 macOS application designed for Git code review workflows. The project implements strict concurrency patterns using Swift 6's complete concurrency checking, ensuring thread-safe operations throughout the codebase.

The architecture follows MVVM patterns with @Observable ViewModels for reactive UI updates, actor-based services for concurrent operations, and protocol-based dependency injection for testability. All models implement Sendable for safe cross-actor communication, supporting both staged change analysis and interactive diff viewing with comment capabilities.

The codebase is organized into two main targets: the main macOS app (`Sources/App/`) and a reusable framework (`Sources/CodeReviewKit/`) containing core business logic, enabling clear separation of concerns and potential code reuse.

## Code Style

### Swift 6 Concurrency

The project enforces strict concurrency through `SWIFT_STRICT_CONCURRENCY: "complete"` in `/Users/billy/workspace/claude-review/Project.swift`:

```swift
settings: .settings(
    base: [
        "SWIFT_STRICT_CONCURRENCY": "complete"
    ]
)
```

All models implement `Sendable` for thread-safe cross-actor communication:

```swift
// Sources/CodeReviewKit/Models/FileChange.swift
public struct FileChange: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let filePath: String
    public let status: GitStatus
    public let diffContent: String?
    
    public enum GitStatus: String, Sendable {
        case added = "A"
        case modified = "M"
        case deleted = "D"
        // ...
    }
}
```

### ViewModels with @Observable

ViewModels use `@MainActor` and `@Observable` for UI thread safety:

```swift
// Sources/CodeReviewKit/ViewModels/DiffViewModel.swift
@MainActor
@Observable
public final class DiffViewModel {
    public var fileChange: FileChange?
    public private(set) var splitDiffLines: [SplitDiffLine] = []
    
    public init() {}
    
    public func parseDiff() {
        // Implementation...
    }
}
```

### Actor-Based Services

Services are implemented as actors for thread-safe operations:

```swift
// Sources/CodeReviewKit/Services/GitService.swift
public actor GitService: GitServiceProtocol {
    public init() {}
    
    public func openRepository(at path: String) async throws -> Repository {
        // Thread-safe implementation
    }
    
    public func getStagedChanges(in repository: Repository) async throws -> [FileChange] {
        // Async implementation
    }
}
```

### Error Handling

Centralized error handling using custom enum with `LocalizedError`:

```swift
// Sources/CodeReviewKit/Models/AppError.swift
public enum AppError: Error, LocalizedError, Sendable {
    case gitError(String)
    case invalidInput(String)
    case fileNotFound(String)
    case networkError(String)
    case diffParsingFailed
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .gitError(let message):
            return "Git error: \(message)"
        // ... other cases
        }
    }
}
```

## Common Patterns

### Protocol-Based Dependency Injection

Services are defined with protocols for testability:

```swift
// Sources/CodeReviewKit/Services/GitService.swift
public protocol GitServiceProtocol: Actor {
    func openRepository(at path: String) async throws -> Repository
    func getStagedChanges(in repository: Repository) async throws -> [FileChange]
}

// Implementation in AppViewModel
// Sources/App/ViewModels/AppViewModel.swift
@MainActor
@Observable
class AppViewModel {
    private let gitService: GitService
    
    init(gitService: GitService = GitService()) {
        self.gitService = gitService
    }
}
```

### Async/Await Pattern

All asynchronous operations use async/await with proper error handling:

```swift
// Sources/App/ViewModels/AppViewModel.swift
func loadRepository(at path: String) async {
    isLoading = true
    errorMessage = nil
    
    do {
        repository = try await gitService.openRepository(at: path)
        let changes = try await getStagedChanges(in: repo)
        fileChanges = changes
    } catch {
        errorMessage = handleError(error)
    }
    
    isLoading = false
}
```

### Split View Architecture

The diff view implements a split-pane pattern for side-by-side comparison:

```swift
// Sources/App/Views/DiffView.swift
struct DiffView: View {
    @State private var diffViewModel = DiffViewModel()
    
    private var diffContentView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(diffViewModel.splitDiffLines.enumerated()), id: \.offset) { index, splitLine in
                    DiffLineView(
                        splitLine: splitLine,
                        comments: commentsForLine(splitLine),
                        onAddComment: { lineNumber in
                            selectedLineForComment = lineNumber
                            showingCommentPopover = true
                        }
                    )
                }
            }
        }
    }
}
```

### State Management

App state is managed through @Observable ViewModels with computed properties:

```swift
// Sources/App/ViewModels/AppViewModel.swift
@MainActor
@Observable
class AppViewModel {
    var fileChanges: [FileChange] = []
    var comments: [ReviewComment] = []
    var isLoading = false
    var errorMessage: String?
    
    func selectFileChange(_ fileChange: FileChange?) {
        selectedFileChange = fileChange
    }
}
```

## Workflows

### Repository Loading

1. User selects repository through `NSOpenPanel` in `/Users/billy/workspace/claude-review/Sources/App/ViewModels/AppViewModel.swift`
2. `GitService` validates path and opens repository
3. Service retrieves staged changes using `git diff --cached`
4. Changes are parsed into `FileChange` models
5. UI updates reactively through `@Observable`

### Diff Parsing

1. Raw diff content processed in `/Users/billy/workspace/claude-review/Sources/CodeReviewKit/ViewModels/DiffViewModel.swift`
2. Regex patterns extract hunk headers and line changes
3. Lines are split into left/right pairs for side-by-side view
4. Alignment algorithm handles additions/deletions properly

### Comment System

1. User clicks line numbers in `/Users/billy/workspace/claude-review/Sources/App/Views/DiffView.swift`
2. Popover presents comment form
3. Comments stored in `AppViewModel.comments` array
4. Comments filtered by file path and line number for display

### Testing Integration

Test files in `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/` include:
- `ModelTests.swift` - Model validation
- `DiffViewModelTests.swift` - Diff parsing logic
- `GitServiceTests.swift` - Service layer testing
- `IntegrationTests.swift` - End-to-end workflows
- `PerformanceTests.swift` - Performance benchmarks

## Reference

### File Organization

```
Sources/
├── App/                          # Main macOS application
│   ├── ClaudeCodeReviewerApp.swift    # App entry point
│   ├── ContentView.swift              # Root view
│   ├── ViewModels/
│   │   └── AppViewModel.swift         # Main app state
│   └── Views/
│       ├── WelcomeView.swift          # Initial screen
│       ├── MainReviewView.swift       # Main interface
│       ├── FileListView.swift         # File change list
│       ├── DiffView.swift             # Split diff viewer
│       └── ReviewSummaryView.swift    # Summary generation
└── CodeReviewKit/                # Reusable framework
    ├── Models/
    │   ├── FileChange.swift           # Git change model
    │   ├── DiffLine.swift             # Diff line representation
    │   ├── ReviewComment.swift        # Comment model
    │   └── AppError.swift             # Error handling
    ├── Services/
    │   └── GitService.swift           # Git operations
    └── ViewModels/
        └── DiffViewModel.swift        # Diff parsing logic
```

### Naming Conventions

- **Models**: Noun-based, `Sendable` structs (e.g., `FileChange`, `ReviewComment`)
- **Services**: `Service` suffix, actor-based (e.g., `GitService`)
- **ViewModels**: `ViewModel` suffix, `@Observable` classes (e.g., `AppViewModel`, `DiffViewModel`)
- **Views**: `View` suffix, SwiftUI structs (e.g., `DiffView`, `WelcomeView`)
- **Protocols**: `Protocol` suffix for services (e.g., `GitServiceProtocol`)

### Common Issues

**Concurrency Warnings**: Ensure all cross-actor operations use `await` and proper actor isolation.

**Git Path Validation**: Always validate repository paths in `/Users/billy/workspace/claude-review/Sources/CodeReviewKit/Services/GitService.swift` before operations.

**Memory Management**: Use `[weak self]` in async closures in `/Users/billy/workspace/claude-review/Sources/App/ViewModels/AppViewModel.swift` to prevent retain cycles.

**Error Boundaries**: Handle all async operations with proper do-catch blocks and user-friendly error messages.

**State Consistency**: Keep UI state synchronized between ViewModels using `@Observable` property updates.