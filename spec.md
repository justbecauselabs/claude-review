Of course. Here is the final, compiled technical specification. It incorporates all the feedback and improvements discussed, presenting a single, comprehensive, and actionable guide for building the "Claude Code Reviewer" application.

---

# **Final Technical Specification: Claude Code Reviewer (macOS App)**

## **0. Overview**

This document provides a complete technical specification for building a native macOS application, "Claude Code Reviewer." The application will enable users to open a local Git repository, review uncommitted changes in a side-by-side diff view, add comments, and compile all feedback into a structured prompt for a large language model.

The project will be generated and managed using **Tuist** for modularity. It will be built using modern, best-practice Apple platform technologies, including **Swift 6 strict concurrency**, the **Swift Observation** framework, and the **Swift Testing** framework. The architecture emphasizes testability through dependency injection and a clear separation of concerns.

## **1. Project & Environment Setup (Tuist)**

The project is structured using Tuist to enforce modularity. All core logic resides in a `CodeReviewKit` framework, which the main `ClaudeCodeReviewer` application target depends on.

#### **`tuist/Package.swift`**

Defines external Swift Package Manager dependencies.

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Packages",
    dependencies: [
        .package(url: "https://github.com/SwiftGit2/SwiftGit2", from: "2.2.0"),
    ]
)
```

#### **`Project.swift`**

The main Tuist manifest defining the project structure, targets, and dependencies.

```swift
import ProjectDescription

let project = Project(
    name: "ClaudeCodeReviewer",
    options: .options(
        automaticSchemesOptions: .enabled(
            targetSchemes: [.app, .framework],
            testSchemes: [.test]
        )
    ),
    packages: [
        .local(path: "Tuist/"),
    ],
    settings: .settings(
        base: [
            // Enforces Swift 6 concurrency checks across the project.
            "SWIFT_STRICT_CONCURRENCY": "complete"
        ],
        configurations: [
            .debug(name: "Debug", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG"]),
            .release(name: "Release", settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "RELEASE"]),
        ]
    ),
    targets: [
        .target(
            name: "ClaudeCodeReviewer",
            destinations: .macOS,
            product: .app,
            bundleId: "com.example.ClaudeCodeReviewer",
            infoPlist: .default,
            sources: ["Sources/App/**"],
            resources: ["Sources/App/Resources/**"],
            dependencies: [
                .target(name: "CodeReviewKit")
            ]
        ),
        .target(
            name: "CodeReviewKit",
            destinations: .macOS,
            product: .framework,
            bundleId: "com.example.CodeReviewKit",
            sources: ["Sources/CodeReviewKit/**"],
            dependencies: [
                .package(product: "SwiftGit2")
            ]
        ),
        .target(
            name: "CodeReviewKitTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.example.CodeReviewKitTests",
            sources: ["Tests/CodeReviewKitTests/**"],
            dependencies: [
                .target(name: "CodeReviewKit")
            ],
            // Correctly enable the Swift Testing framework.
            settings: .settings(base: ["ENABLE_TESTING_FRAMEWORK": "YES"])
        ),
    ]
)
```

## **2. Directory Structure**

Run `tuist generate` to create the Xcode project with the following file structure:

```
.
├── Project.swift
├── Tuist/
│   └── Package.swift
├── Sources/
│   ├── App/
│   │   ├── ClaudeCodeReviewerApp.swift
│   │   ├── ViewModels/
│   │   │   └── AppViewModel.swift
│   │   └── Views/
│   │       ├── ContentView.swift
│   │       ├── DiffView.swift
│   │       └── ... (other views)
│   └── CodeReviewKit/
│       ├── Models/
│       │   ├── AppError.swift
│       │   ├── FileChange.swift
│       │   └── ... (other models)
│       ├── Services/
│       │   └── GitService.swift
│       └── ViewModels/
│           └── DiffViewModel.swift
└── Tests/
    └── CodeReviewKitTests/
        └── GitServiceTests.swift
```

## **3. Core Architecture**

*   **Service Layer (`actor`):** The `GitService` actor encapsulates all `SwiftGit2` logic, ensuring thread-safe, concurrent access to the file system and Git repository. It conforms to a protocol (`GitServiceProtocol`) to allow for dependency injection and mocking.
*   **ViewModel Layer (`@MainActor @Observable`):** ViewModels orchestrate application state and logic. They run on the `MainActor` to safely interact with the UI and call the service layer using `async/await`.
*   **View Layer (`View`):** SwiftUI views are declarative and driven by the state in the ViewModels.
*   **Model Layer (`struct`, `Sendable`):** Plain `struct`s represent the application's data. They are `Sendable` to be safely passed across concurrency domains.

## **4. Core Library: `CodeReviewKit`**

This framework contains all business logic, data models, and view-agnostic state management, making it independently testable.

#### **`Sources/CodeReviewKit/Models/`**

Create separate files for each of these public, `Sendable` models.

```swift
// AppError.swift
import Foundation
public enum AppError: Error, LocalizedError { /* ... */ }

// FileChange.swift
import Foundation
public struct FileChange: Identifiable, Hashable, Sendable { /*...*/ }

// ReviewComment.swift
import Foundation
public struct ReviewComment: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let filePath: String
    public let startLine: Int // Line number relative to the NEW file.
    public let endLine: Int?  // Optional end line, also relative to the NEW file.
    public let text: String
}

// DiffLine.swift
import Foundation
public struct DiffLine: Identifiable, Hashable, Sendable {
    // Use a stable, computed identifier to prevent SwiftUI rendering issues.
    public var id: String { "\(oldLineNumber ?? 0)-\(newLineNumber ?? 0)-\(content.hashValue)" }
    public var oldLineNumber: Int?, newLineNumber: Int?, content: String, type: LineType
    public enum LineType: Sendable { case added, removed, context, hunkHeader }
}
```

#### **`Sources/CodeReviewKit/Services/GitService.swift`**

This `actor` handles all Git operations and conforms to a protocol to allow for mocking.

```swift
import Foundation
import SwiftGit2
import CodeReviewKit

// Define a protocol for dependency injection.
public protocol GitServiceProtocol {
    func openRepository(at url: URL) async throws -> Repository
    func fetchChanges(in repo: Repository) async throws -> [FileChange]
}

public actor GitService: GitServiceProtocol {
    public init() {}

    public func openRepository(at url: URL) async throws -> Repository { /* ... */ }

    // This implementation avoids the N+1 performance issue.
    public func fetchChanges(in repo: Repository) async throws -> [FileChange] {
        let diff = try repo.diff(.workdir, to: .head).get()
        let patches = try diff.patches().get()

        return try patches.map { patch in
            guard let filePath = patch.delta.newFile?.path else { throw AppError.diffParsingFailed }
            let status: GitStatus = /* ... map patch.delta.status ... */
            let content = try patch.text().get()
            return FileChange(filePath: filePath, status: status, diffContent: content)
        }
    }
}
```

#### **`Sources/CodeReviewKit/ViewModels/DiffViewModel.swift`**

Moved to `CodeReviewKit` for testability.

```swift
import Foundation
import CodeReviewKit

@MainActor
@Observable
public class DiffViewModel {
    public let fileChange: FileChange
    public var splitDiffLines: [(left: DiffLine?, right: DiffLine?)] = []

    public init(fileChange: FileChange) {
        self.fileChange = fileChange
        parseDiff()
    }

    private func parseDiff() {
        // Implement the detailed diff parsing algorithm here, using Swift Regex
        // to identify hunk headers and line types (+, -, ' '). This method
        // populates `splitDiffLines` by aligning added and removed lines.
    }
}
```

## **5. Main Application: `ClaudeCodeReviewer`**

This is the UI layer of the application.

#### **`Sources/App/ClaudeCodeReviewerApp.swift`**

```swift
import SwiftUI
import CodeReviewKit

@main
struct ClaudeCodeReviewerApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(appViewModel)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") { appViewModel.openRepository() }
                    .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
```

#### **`Sources/App/ViewModels/AppViewModel.swift`**

Uses dependency injection for testability.

```swift
import SwiftUI
import CodeReviewKit

@MainActor
@Observable
class AppViewModel {
    private let gitService: GitServiceProtocol
    private var repositoryURL: URL?

    var fileChanges: [FileChange] = []
    var comments: [ReviewComment] = []
    var selectedFileID: FileChange.ID?
    var isLoading = false
    var error: AppError?
    var isShowingSummary = false

    var selectedFile: FileChange? { fileChanges.first { $0.id == selectedFileID } }

    init(gitService: GitServiceProtocol = GitService()) {
        self.gitService = gitService
    }
    
    func openRepository() { /* ... NSOpenPanel logic ... */ }
    
    func refreshChanges() { /* ... re-load from stored repositoryURL ... */ }

    func generateReviewPrompt() -> String {
        var prompt = "Please review the following code changes based on my comments...\n\n"
        let commentsByFile = Dictionary(grouping: comments, by: { $0.filePath })

        for (filePath, fileComments) in commentsByFile {
            prompt += "---\n\n### File: `\(filePath)`\n\n"
            for comment in fileComments {
                let lineRange = /* ... format line range ... */
                prompt += "**\(lineRange):**\n> \(comment.text)\n\n"
            }
        }
        return prompt
    }
    // ... other methods
}
```

#### **`Sources/App/Views/`**

All views are declarative and driven by the state in the ViewModels.

```swift
// ContentView.swift
struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    var body: some View {
        if viewModel.fileChanges.isEmpty { WelcomeView() }
        else { MainReviewView() }
    }
}

// MainReviewView.swift
struct MainReviewView: View {
    @Environment(AppViewModel.self) private var viewModel
    var body: some View {
        NavigationSplitView { FileListView() } detail: { /* DiffView or placeholder */ }
            .toolbar { /* ... Refresh and Generate Review buttons ... */ }
            .sheet(isPresented: $viewModel.isShowingSummary) { ReviewSummaryView() }
    }
}

// DiffView.swift
import CodeReviewKit
struct DiffView: View {
    let fileChange: FileChange
    @State private var diffViewModel: DiffViewModel

    init(fileChange: FileChange) {
        self.fileChange = fileChange
        _diffViewModel = State(initialValue: DiffViewModel(fileChange: fileChange))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) { /* ... ForEach ... */ }
        }
        .onChange(of: fileChange) { diffViewModel = DiffViewModel(fileChange: fileChange) }
    }
}
```

## **6. Core User Flows**

#### **Opening a Repository**
1.  User selects **File > Open Repository...** or clicks the button on the `WelcomeView`.
2.  `AppViewModel.openRepository()` presents an `NSOpenPanel`.
3.  On selection, `AppViewModel` calls `gitService.fetchChanges()` asynchronously.
4.  The UI updates to show a `ProgressView` while loading, then displays the `MainReviewView`.

#### **Adding a Comment**
1.  User hovers over a line in the right (new file) pane of the `DiffView`.
2.  A `+` button appears next to the line number.
3.  User clicks the `+` button.
4.  An inline `CommentEditorView` (with a `TextEditor` and Save/Cancel buttons) appears below the selected line.
5.  User types a comment and clicks "Save."
6.  `appViewModel.addComment()` is called, persisting the comment.
7.  The editor is replaced by a read-only `CommentView` displaying the new comment.

#### **Generating the Final Prompt**
1.  After adding one or more comments, the "Generate Review" button in the toolbar becomes enabled.
2.  User clicks the button.
3.  `viewModel.isShowingSummary` is set to `true`, presenting the `ReviewSummaryView` as a sheet.
4.  The sheet displays the fully formatted prompt from `viewModel.generateReviewPrompt()`.
5.  The user can copy the prompt to the clipboard or dismiss the sheet.

## **7. Testing Strategy**

All tests will be written using the **Swift Testing** framework.

#### **`CodeReviewKitTests`**
*   **ViewModel Tests:** Test the `DiffViewModel`'s parsing logic with various diff string inputs. Use `@Test` and `#expect` to validate the `splitDiffLines` output.
*   **Service Tests:** Test the `GitService` actor by creating a mock implementation that conforms to `GitServiceProtocol`. Inject this mock into `AppViewModel` during tests to verify that the view model behaves correctly based on the service's output (success or failure) without touching the file system.

## **8. Advanced Features & Future Considerations**

*   **Syntax Highlighting:** This is a critical usability feature. Plan to integrate a library like **Highlightr** (a Swift wrapper for highlight.js) into the `DiffPaneView`. This will replace the simple `Text` view with a more complex view capable of rendering attributed strings.
*   **App Sandboxing:** For future distribution (e.g., Mac App Store), the app must be sandboxed. This will require persisting the security-scoped bookmark granted by `NSOpenPanel` to retain access to the repository directory across app launches.
*   **Large File Performance:** For exceptionally large diffs, the `DiffViewModel` could be enhanced to only parse hunks that are about to enter the `ScrollView`'s viewport, reducing initial memory load.
*   **Binary Dependencies:** The development environment requires `libgit2`. This should be documented in a `README.md` file, with installation instructions (e.g., `brew install libgit2`).
