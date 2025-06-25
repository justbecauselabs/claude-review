<!-- Generated: 2025-06-25 09:45:00 UTC -->

# Build System Documentation

## Overview

ClaudeCodeReviewer uses **Tuist 4.39.1** for build management and project generation. The build system is defined in `/Users/billy/workspace/claude-review/Project.swift` with Swift 6 strict concurrency enabled across all targets.

### Core Configuration Files
- **Project Definition**: `/Users/billy/workspace/claude-review/Project.swift`
- **Package Dependencies**: `/Users/billy/workspace/claude-review/tuist/Package.swift`
- **Generated Project**: `/Users/billy/workspace/claude-review/ClaudeCodeReviewer.xcodeproj/`
- **Generated Workspace**: `/Users/billy/workspace/claude-review/ClaudeCodeReviewer.xcworkspace/`

## Build Workflows

### Project Generation
```bash
# Generate Xcode project files
tuist generate

# Clean generated files
tuist clean
```

### Building
```bash
# Build all targets
tuist build

# Build specific target
tuist build ClaudeCodeReviewer
tuist build CodeReviewKit
```

### Testing
```bash
# Run all tests
tuist test

# Run specific test target
tuist test CodeReviewKitTests
```

### Dependency Management
```bash
# Fetch dependencies
tuist fetch

# Update dependencies
tuist update
```

## Build Targets

### ClaudeCodeReviewer (App)
- **Type**: macOS Application
- **Bundle ID**: `com.example.ClaudeCodeReviewer`
- **Sources**: `/Users/billy/workspace/claude-review/Sources/App/**`
- **Resources**: `/Users/billy/workspace/claude-review/Sources/App/Resources/**`
- **Dependencies**: CodeReviewKit framework
- **Info.plist**: `/Users/billy/workspace/claude-review/Derived/InfoPlists/ClaudeCodeReviewer-Info.plist`

### CodeReviewKit (Framework)
- **Type**: Dynamic Framework
- **Bundle ID**: `com.example.CodeReviewKit`
- **Sources**: `/Users/billy/workspace/claude-review/Sources/CodeReviewKit/**`
- **Info.plist**: `/Users/billy/workspace/claude-review/Derived/InfoPlists/CodeReviewKit-Info.plist`
- **Missing Dependency**: SwiftGit2 (needs to be added to `/Users/billy/workspace/claude-review/tuist/Package.swift`)

### CodeReviewKitTests (Unit Tests)
- **Type**: Unit Test Bundle
- **Bundle ID**: `com.example.CodeReviewKitTests`
- **Sources**: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/**`
- **Framework**: Swift Testing (enabled via `ENABLE_TESTING_FRAMEWORK`)
- **Dependencies**: CodeReviewKit framework

## Build Settings

### Global Settings
- **Swift Strict Concurrency**: `complete` (Swift 6 mode)
- **Platform**: macOS only
- **Automatic Schemes**: Enabled

### Configuration Profiles
- **Debug**: `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG`
- **Release**: `SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE`

## Platform Setup

### macOS Requirements
- **Xcode**: 15.0+ (Swift 6 support)
- **macOS**: 14.0+ (deployment target)
- **Tuist**: 4.39.1 (install via `curl -Ls https://install.tuist.io | bash`)

### Environment Setup
```bash
# Install Tuist
curl -Ls https://install.tuist.io | bash

# Verify installation
tuist version  # Should output: 4.39.1

# Generate project
tuist generate
```

## Quick Reference

### Common Commands
| Task | Command | Notes |
|------|---------|-------|
| Generate project | `tuist generate` | Creates `.xcodeproj` and `.xcworkspace` |
| Build all | `tuist build` | Builds all targets |
| Run tests | `tuist test` | Runs CodeReviewKitTests |
| Clean | `tuist clean` | Removes generated files |
| Edit manifest | `tuist edit` | Opens Project.swift in Xcode |

### Build Artifacts
- **Derived Data**: Xcode default location
- **Info Plists**: `/Users/billy/workspace/claude-review/Derived/InfoPlists/`
- **Build Products**: Inside Xcode's DerivedData

### Troubleshooting

**Missing SwiftGit2 Dependency**
Add to `/Users/billy/workspace/claude-review/tuist/Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "1.0.0")
]
```

**Project Generation Fails**
```bash
# Clear cache and regenerate
tuist clean
rm -rf .tuist-bin
tuist generate
```

**Build Errors with Swift 6**
Check strict concurrency violations in:
- Async/await usage
- Actor isolation
- Sendable conformance