# Files Catalog

<!-- Generated: 2025-06-25 20:15:00 UTC -->

## Overview

This catalog documents all files in the Claude Code Reviewer project, a native macOS application for Git repository code review with AI-powered assistance. The project uses Tuist for modular architecture, separating core business logic (`CodeReviewKit` framework) from the SwiftUI interface (`ClaudeCodeReviewer` app). The architecture emphasizes Swift 6 strict concurrency, protocol-based dependency injection, and comprehensive testing using the Swift Testing framework.

The codebase follows modern Apple platform development practices with actor-based services for thread-safe Git operations, `@Observable` ViewModels for reactive UI state management, and `Sendable` data models for safe concurrent access. All source files are organized by functional domains to support maintainability and testing isolation.

## Core Source Files

### Application Entry Point
- `Sources/App/ClaudeCodeReviewerApp.swift` - Main SwiftUI app with window management and menu commands
- `Sources/App/ContentView.swift` - Root view controller switching between welcome and review interfaces

### ViewModels (State Management)
- `Sources/App/ViewModels/AppViewModel.swift` - Primary application state, repository management, comment system
- `Sources/CodeReviewKit/ViewModels/DiffViewModel.swift` - Diff parsing and split-view line alignment logic

### User Interface Views
- `Sources/App/Views/WelcomeView.swift` - Initial repository selection interface
- `Sources/App/Views/MainReviewView.swift` - Split-view layout with file list and diff display
- `Sources/App/Views/FileListView.swift` - Sidebar showing changed files with status indicators
- `Sources/App/Views/DiffView.swift` - Side-by-side diff viewer with comment interaction
- `Sources/App/Views/ReviewSummaryView.swift` - AI prompt generation and display modal

### Core Business Logic
- `Sources/CodeReviewKit/Services/GitService.swift` - Actor-based Git operations using SwiftGit2

## Platform Implementation

### Data Models (Sendable Structs)
- `Sources/CodeReviewKit/Models/FileChange.swift` - Git file change representation with diff content
- `Sources/CodeReviewKit/Models/DiffLine.swift` - Individual diff line with line numbers and type classification
- `Sources/CodeReviewKit/Models/ReviewComment.swift` - User comments with file and line positioning
- `Sources/CodeReviewKit/Models/AppError.swift` - Structured error handling for Git and parsing operations

### Protocol Interfaces
- Git service protocol in `GitService.swift` enables dependency injection and testing isolation

## Build System

### Tuist Configuration
- `Project.swift` - Main project manifest defining targets, dependencies, and Swift 6 concurrency settings
- `tuist/Package.swift` - External dependency specification (SwiftGit2 for Git operations)

### Xcode Generated Files
- `ClaudeCodeReviewer.xcodeproj/project.pbxproj` - Xcode project structure and build settings
- `ClaudeCodeReviewer.xcworkspace/contents.xcworkspacedata` - Workspace configuration for multi-target builds
- `ClaudeCodeReviewer.xcodeproj/xcshareddata/xcschemes/` - Build and run scheme configurations

### Info Plists
- `Derived/InfoPlists/ClaudeCodeReviewer-Info.plist` - Main app metadata and capabilities
- `Derived/InfoPlists/CodeReviewKit-Info.plist` - Framework bundle information
- `Derived/InfoPlists/CodeReviewKitTests-Info.plist` - Test target configuration

## Configuration

### Documentation
- `README.md` - Project overview, setup instructions, and usage guide
- `spec.md` - Comprehensive technical specification and implementation requirements
- `docs/project-overview.md` - High-level project description and goals
- `docs/architecture.md` - System design and component relationships
- `docs/build-system.md` - Tuist configuration and build process details
- `docs/testing.md` - Testing strategy and framework usage
- `docs/development.md` - Development workflow and contribution guidelines
- `docs/deployment.md` - Distribution and deployment procedures

## Reference

### Test Infrastructure
- `Tests/CodeReviewKitTests/TestHelpers.swift` - Shared testing utilities and mock implementations
- `Tests/CodeReviewKitTests/ModelTests.swift` - Data model validation and Sendable conformance tests
- `Tests/CodeReviewKitTests/GitServiceTests.swift` - Actor service testing with dependency injection
- `Tests/CodeReviewKitTests/DiffViewModelTests.swift` - Diff parsing logic and line alignment validation
- `Tests/CodeReviewKitTests/IntegrationTests.swift` - End-to-end workflow testing
- `Tests/CodeReviewKitTests/PerformanceTests.swift` - Large repository and diff performance benchmarks

### File Organization Patterns
- **Functional Grouping**: Files organized by domain (Models, Services, ViewModels, Views)
- **Framework Separation**: Core logic in `CodeReviewKit`, UI in `App` target
- **Test Mirroring**: Test files parallel source structure for easy navigation
- **Protocol Suffixes**: Service protocols enable dependency injection (`GitServiceProtocol`)

### Naming Conventions
- **ViewModels**: `*ViewModel.swift` suffix, `@Observable @MainActor` classes
- **Models**: Plain struct names, `Sendable` conformance required
- **Services**: `*Service.swift` suffix, actor implementation with protocol
- **Views**: SwiftUI view names matching UI component purpose

### Dependency Relationships
- **App → CodeReviewKit**: UI layer depends on business logic framework
- **CodeReviewKit → SwiftGit2**: Git operations through external library
- **Tests → Target**: Test modules depend on corresponding source targets
- **ViewModels → Services**: Async/await calls to actor services for data operations