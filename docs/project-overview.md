<!-- Generated: 2025-06-25 12:00:00 UTC -->

# Claude Code Reviewer - Project Overview

## Overview

Claude Code Reviewer is a native macOS application designed to streamline code review workflows by integrating AI assistance directly into the Git review process. Built with Swift 6 and SwiftUI, it provides a modern interface for reviewing staged Git changes while leveraging AI to provide intelligent feedback on code quality, potential issues, and best practices.

The application fills a critical gap in the developer workflow by offering a desktop-native solution that connects Git repositories with Claude AI. Unlike web-based tools, it operates directly on local repositories, maintaining security and privacy while providing instant access to AI-powered code analysis. The modular architecture ensures maintainability and extensibility through the CodeReviewKit framework.

## Key Files

### Main Entry Points
- `/Users/billy/workspace/claude-review/Sources/App/ClaudeCodeReviewerApp.swift` - Main application entry point with window configuration
- `/Users/billy/workspace/claude-review/Sources/App/ContentView.swift` - Root content view managing navigation
- `/Users/billy/workspace/claude-review/Sources/App/ViewModels/AppViewModel.swift` - Central state management and business logic

### Core Configuration
- `/Users/billy/workspace/claude-review/Project.swift` - Tuist project configuration defining targets and dependencies
- `/Users/billy/workspace/claude-review/tuist/Package.swift` - Swift Package Manager dependencies (currently empty, SwiftGit2 to be added)

### Framework Components
- `/Users/billy/workspace/claude-review/Sources/CodeReviewKit/Services/GitService.swift` - Actor-based Git operations using Process API
- `/Users/billy/workspace/claude-review/Sources/CodeReviewKit/Models/FileChange.swift` - Core model for Git file changes
- `/Users/billy/workspace/claude-review/Sources/CodeReviewKit/ViewModels/DiffViewModel.swift` - Diff parsing and presentation logic

## Technology Stack

### Core Technologies
- **Swift 6** with strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete` in `/Users/billy/workspace/claude-review/Project.swift`)
- **SwiftUI** for declarative UI (`/Users/billy/workspace/claude-review/Sources/App/Views/`)
- **Tuist** for project generation and management
- **Actor-based concurrency** for thread-safe Git operations (`/Users/billy/workspace/claude-review/Sources/CodeReviewKit/Services/GitService.swift`)

### Architecture Patterns
- **MVVM** with `@Observable` ViewModels (`/Users/billy/workspace/claude-review/Sources/App/ViewModels/AppViewModel.swift`)
- **Protocol-oriented design** with `GitServiceProtocol` for testability
- **Modular framework architecture** separating UI (App target) from business logic (CodeReviewKit framework)

### Testing Infrastructure
- **Swift Testing Framework** enabled (`ENABLE_TESTING_FRAMEWORK: YES`)
- Test files in `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/`

## Platform Support

### Requirements
- **macOS-only** application (`destinations: .macOS` in all targets)
- **Git** command-line tool required (uses `/usr/bin/git` via Process API)
- **File system access** for repository operations via `NSOpenPanel`

### Platform-Specific Features
- Native macOS window styling (`.windowStyle(.hiddenTitleBar)`)
- AppKit integration for file dialogs (`/Users/billy/workspace/claude-review/Sources/App/ViewModels/AppViewModel.swift:29`)
- Clipboard support via `NSPasteboard` for copying review prompts
- Custom window sizing and keyboard shortcuts (⌘O for opening repositories)