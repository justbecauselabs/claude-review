# Claude Code Reviewer

A native macOS application for reviewing Git repository changes with AI-powered assistance. Built with Swift 6, SwiftUI, and Tuist.

## Features

- **Git Integration**: Open any local Git repository and view uncommitted changes
- **Side-by-Side Diff View**: Clean, readable diff interface with syntax highlighting
- **Comment System**: Add review comments to specific lines of code
- **AI Prompt Generation**: Compile all feedback into a structured prompt for Claude
- **Modern Architecture**: Swift 6 strict concurrency, Observation framework, Swift Testing

## Architecture

The project uses Tuist for modularity and follows modern Swift best practices:

- **CodeReviewKit Framework**: Core business logic, models, and services
- **ClaudeCodeReviewer App**: SwiftUI-based user interface
- **Dependency Injection**: Protocol-based design for testability
- **Actor-Based Concurrency**: Thread-safe Git operations

## Directory Structure

```
.
├── Project.swift                 # Tuist project manifest
├── tuist/
│   └── Package.swift            # Dependencies (SwiftGit2)
├── Sources/
│   ├── App/                     # Main application
│   │   ├── ClaudeCodeReviewerApp.swift
│   │   ├── ViewModels/
│   │   │   └── AppViewModel.swift
│   │   └── Views/
│   │       ├── ContentView.swift
│   │       ├── WelcomeView.swift
│   │       ├── MainReviewView.swift
│   │       ├── FileListView.swift
│   │       ├── DiffView.swift
│   │       └── ReviewSummaryView.swift
│   └── CodeReviewKit/           # Core framework
│       ├── Models/
│       │   ├── AppError.swift
│       │   ├── FileChange.swift
│       │   ├── ReviewComment.swift
│       │   └── DiffLine.swift
│       ├── Services/
│       │   └── GitService.swift
│       └── ViewModels/
│           └── DiffViewModel.swift
└── Tests/
    └── CodeReviewKitTests/      # Comprehensive test suite
        ├── GitServiceTests.swift
        ├── DiffViewModelTests.swift
        ├── ModelTests.swift
        ├── IntegrationTests.swift
        ├── PerformanceTests.swift
        └── TestHelpers.swift
```

## Setup

### Prerequisites

1. **Xcode 15+** with Swift 6 support
2. **Tuist** - Install from [tuist.io](https://tuist.io)
3. **libgit2** - Required by SwiftGit2:
   ```bash
   brew install libgit2
   ```

### Build Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd claude-review
   ```

2. Fetch dependencies:
   ```bash
   tuist fetch
   ```

3. Generate Xcode project:
   ```bash
   tuist generate
   ```

4. Open in Xcode:
   ```bash
   open ClaudeCodeReviewer.xcodeproj
   ```

## Usage

### Opening a Repository

1. Launch the app
2. Click "Open Repository" or use **Cmd+O**
3. Select a Git repository folder
4. The app will automatically load staged changes

### Reviewing Code

1. **File List**: View all changed files in the sidebar
2. **Diff View**: Click a file to see side-by-side diff
3. **Add Comments**: Click line numbers to add review comments
4. **Generate Review**: Click "Generate Review" to create an AI prompt

### AI Prompt

The generated prompt includes:
- Summary of changes by file
- All review comments organized by file and line
- Structured format optimized for Claude

## Technical Details

### Core Components

- **GitService**: Actor-based Git operations using SwiftGit2
- **DiffViewModel**: Parses Git diff format into UI-friendly structure
- **AppViewModel**: Manages application state and user interactions
- **Models**: Sendable data structures for concurrent operations

### Concurrency

- **Swift 6 Strict Concurrency**: Full actor isolation
- **MainActor ViewModels**: UI-safe state management
- **Async/Await**: Modern asynchronous programming

### Testing

- **53 comprehensive tests** using Swift Testing framework
- **Mock implementations** for isolated testing
- **Performance benchmarks** for large repositories
- **Integration tests** for component interaction

## Contributing

This project follows Swift best practices:

- **Protocol-based design** for dependency injection
- **Sendable conformance** for data models
- **Actor isolation** for thread safety
- **Comprehensive testing** with Swift Testing framework

## License

[Add your license here]