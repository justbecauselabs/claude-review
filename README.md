<!-- Generated: 2025-06-25 12:30:00 UTC -->

# Claude Code Reviewer

Native macOS application for AI-assisted Git code reviews. Integrates staged Git changes with Claude AI for intelligent code analysis and review feedback.

## Quick Start

**Prerequisites**: macOS, Xcode 15+, Tuist 4.x

```bash
# Install Tuist
curl -Ls https://install.tuist.io | bash

# Generate project
tuist generate

# Open in Xcode
open ClaudeCodeReviewer.xcworkspace
```

## Key Files

**Entry Points**
- `Sources/App/ClaudeCodeReviewerApp.swift` - Main application entry
- `Sources/App/ViewModels/AppViewModel.swift` - Central state management
- `Sources/CodeReviewKit/Services/GitService.swift` - Git operations actor

**Configuration**
- `Project.swift` - Tuist build configuration (Swift 6 strict concurrency)
- `tuist/Package.swift` - External dependencies

## Build Commands

```bash
tuist fetch        # Fetch dependencies
tuist generate     # Generate Xcode project
tuist build        # Build all targets
tuist test         # Run Swift Testing suite
```

## Architecture

**Modular Design**: Tuist-based separation between UI (`ClaudeCodeReviewer` app) and business logic (`CodeReviewKit` framework)

**Concurrency**: Swift 6 actor-based Git operations with `@Observable` ViewModels for UI state

**Testing**: Swift Testing framework with 53 comprehensive tests and mock implementations

## Documentation

- **[Project Overview](docs/project-overview.md)** - Purpose, key files, technology stack
- **[Architecture](docs/architecture.md)** - System design, components, data flow patterns
- **[Build System](docs/build-system.md)** - Tuist configuration, build workflows, troubleshooting
- **[Testing](docs/testing.md)** - Test organization, running tests, mock implementations
- **[Development](docs/development.md)** - Code style, patterns, workflows, file organization
- **[Deployment](docs/deployment.md)** - Packaging, distribution, macOS app signing
- **[Files](docs/files.md)** - Complete file catalog and organization reference

Each doc contains specific file paths and concrete examples for LLM-friendly navigation.