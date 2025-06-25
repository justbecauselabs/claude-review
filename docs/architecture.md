<!-- Generated: 2025-06-25 10:45:00 UTC -->

# Claude Code Reviewer Architecture

## Overview

Claude Code Reviewer is a native macOS application built with SwiftUI and modular architecture using Tuist. The system follows MVVM pattern with clear separation between UI (App target) and business logic (CodeReviewKit framework). The architecture leverages Swift 6 concurrency features with actor-based isolation for Git operations and Observable macro for reactive state management. The app provides a streamlined interface for reviewing staged Git changes, annotating code with comments, and generating comprehensive review prompts for Claude AI.

The modular design enables testability and reusability. CodeReviewKit framework encapsulates all core business logic including Git interactions, diff parsing, and data models, while the App target focuses purely on presentation layer with SwiftUI views and view models. This separation allows the business logic to be potentially reused in other contexts like command-line tools or extensions.

## Component Map

### App Target (`/Sources/App/`)
- **Entry Point**: `ClaudeCodeReviewerApp.swift` - Main app struct with scene configuration
- **Root View**: `ContentView.swift` - Navigation controller between welcome and review states
- **View Models**: `ViewModels/AppViewModel.swift` - Main state management with `@Observable`
- **Views**:
  - `Views/WelcomeView.swift` - Initial repository selection interface
  - `Views/MainReviewView.swift` - Primary review interface with split view layout
  - `Views/FileListView.swift` - Sidebar showing staged file changes
  - `Views/DiffView.swift` - Side-by-side diff visualization
  - `Views/ReviewSummaryView.swift` - Review prompt generation and export

### CodeReviewKit Framework (`/Sources/CodeReviewKit/`)
- **Services**: `Services/GitService.swift` - Actor-based Git operations with `GitServiceProtocol`
- **Models**:
  - `Models/FileChange.swift` - Represents file modifications with Git status
  - `Models/DiffLine.swift` - Individual diff line with type and line numbers
  - `Models/ReviewComment.swift` - User annotations on code changes
  - `Models/AppError.swift` - Typed error handling
- **View Models**: `ViewModels/DiffViewModel.swift` - Diff parsing and alignment logic

### Build Configuration (`/`)
- `Project.swift` - Tuist project definition with Swift 6 strict concurrency
- `tuist/Package.swift` - External dependencies (currently empty)

## Key Files

### `/Sources/App/ClaudeCodeReviewerApp.swift`
Main app entry point defining window configuration, scene management, and command menu. Sets up `AppViewModel` as environment object for global state access.

### `/Sources/App/ViewModels/AppViewModel.swift`
Central state container using `@Observable` and `@MainActor`. Manages repository loading, file change tracking, comment management, and review prompt generation. Coordinates with `GitService` actor for async operations.

### `/Sources/CodeReviewKit/Services/GitService.swift`
Actor providing thread-safe Git operations. Implements `GitServiceProtocol` for dependency injection. Executes git commands via `Process` and parses diff output into structured `FileChange` objects.

### `/Sources/CodeReviewKit/ViewModels/DiffViewModel.swift`
Processes raw diff content into aligned side-by-side view data. Parses hunk headers, identifies line types (added/removed/context), and maintains line number tracking for accurate display.

### `/Sources/CodeReviewKit/Models/FileChange.swift`
Core data model representing a single file's changes. Includes `GitStatus` enum for change types (added/modified/deleted/renamed) and stores raw diff content. Conforms to `Sendable` for concurrent access.

### `/Sources/App/Views/MainReviewView.swift`
Primary review interface using `HSplitView` for file list and diff viewer. Manages toolbar actions for refresh and review generation. Coordinates selection state between file list and diff display.

## Data Flow

1. **Repository Loading**: User selects folder → `AppViewModel.openRepository()` shows NSOpenPanel → Path passed to `AppViewModel.loadRepository()` → Calls `GitService.openRepository()` to validate Git repo → Returns `Repository` object

2. **Change Detection**: `AppViewModel.loadRepository()` → `GitService.getStagedChanges()` executes `git diff --cached` → `GitService.parseChanges()` transforms output → Returns array of `FileChange` objects → Updates `AppViewModel.fileChanges`

3. **File Selection**: User clicks file in `FileListView` → `AppViewModel.selectFileChange()` updates selection → `MainReviewView` observes change → `DiffView` receives new `FileChange` → `DiffViewModel.parseDiff()` processes content

4. **Diff Rendering**: `DiffViewModel` receives diff content → Parses into `DiffLine` objects with regex → `alignDiffLines()` pairs deletions/additions → Returns `SplitDiffLine` array → `DiffView` renders side-by-side comparison

5. **Review Generation**: User clicks "Generate Review" → `ReviewSummaryView` shown → `AppViewModel.generateReviewPrompt()` aggregates all changes and comments → Formatted prompt displayed → `copyReviewPrompt()` writes to system clipboard via `NSPasteboard`

6. **Error Handling**: All async operations wrapped in do-catch → `AppError` provides typed errors → `AppViewModel` translates to user-friendly messages → UI displays via `errorMessage` property with specific guidance

7. **State Synchronization**: `@Observable` macro on view models → SwiftUI automatically tracks property access → Changes trigger view updates → `@Environment` propagates `AppViewModel` through view hierarchy → Actor isolation ensures thread safety for Git operations