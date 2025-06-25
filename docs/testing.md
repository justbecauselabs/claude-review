# Testing Documentation

<!-- Generated: 2025-06-25 16:22:00 UTC -->

## Overview

The project uses **Swift Testing framework** for comprehensive testing of the CodeReviewKit module. Test files are organized in `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/` with structured test suites covering unit tests, integration tests, and performance testing.

The testing architecture employs dependency injection with mock implementations and factory methods provided by `TestHelpers.swift` for consistent test data generation.

## Test Types

### Unit Tests

**File: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/DiffViewModelTests.swift`**
- Tests DiffViewModel initialization and parsing logic
- Uses `@Suite("DiffViewModel Tests")` with `@MainActor` annotation
- Tests diff parsing with various input scenarios

**File: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/GitServiceTests.swift`**
- Contains `MockGitService` actor implementing `GitServiceProtocol`
- Tests repository operations and staged changes retrieval
- Includes call count tracking and error simulation

**File: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/ModelTests.swift`**
- Tests data models: `FileChange`, `ReviewComment`, `DiffLine`, `AppError`
- Validates model initialization and property behavior

### Integration Tests

**File: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/IntegrationTests.swift`**
- End-to-end testing of component interactions
- Tests service layer integration with view models
- Validates complete workflow scenarios

### Performance Tests

**File: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/PerformanceTests.swift`**
- Benchmarks critical operations like diff parsing
- Tests large file handling performance
- Memory usage validation

### Test Utilities

**File: `/Users/billy/workspace/claude-review/Tests/CodeReviewKitTests/TestHelpers.swift`**
- Factory methods for creating test data:
  - `makeFileChange()` - Creates FileChange instances with various statuses
  - `makeReviewComment()` - Generates ReviewComment with different severities
  - `makeDiffLine()` - Creates DiffLine instances for various types
  - `makeSimpleDiff()` / `makeComplexDiff()` - Sample diff content generators
- Mock service configuration helpers
- Test extensions for convenience initializers

## Running Tests

### Command Line Testing

```bash
# Run all tests
cd /Users/billy/workspace/claude-review
tuist test

# Run specific test target
tuist test CodeReviewKitTests

# Run with verbose output
tuist test --verbose
```

### Xcode Testing

```bash
# Generate and open Xcode project
tuist generate
open ClaudeCodeReviewer.xcodeproj

# Test via Xcode shortcuts:
# Cmd+U - Run all tests
# Cmd+Ctrl+U - Run tests without building
```

### Expected Test Output

```
Test Suite 'CodeReviewKitTests' started
Test Suite 'DiffViewModel Tests' started
✓ DiffViewModel initializes correctly
✓ parseDiff handles nil fileChange
✓ parseDiff handles fileChange with nil diff content
Test Suite 'DiffViewModel Tests' passed

Test Suite 'GitService Tests' started
✓ MockGitService openRepository success
✓ MockGitService getStagedChanges success
✓ MockGitService error simulation
Test Suite 'GitService Tests' passed

All tests passed (X tests in Y.Z seconds)
```

## Reference

### Test File Organization

```
Tests/CodeReviewKitTests/
├── DiffViewModelTests.swift      # View model unit tests
├── GitServiceTests.swift         # Service layer tests with mocks
├── IntegrationTests.swift        # End-to-end integration tests
├── ModelTests.swift              # Data model validation tests
├── PerformanceTests.swift        # Performance benchmarking
└── TestHelpers.swift             # Test utilities and factories
```

### Build System Test Target

**Target Configuration (`/Users/billy/workspace/claude-review/Project.swift`):**
```swift
.target(
    name: "CodeReviewKitTests",
    destinations: .macOS,
    product: .unitTests,
    bundleId: "com.example.CodeReviewKitTests",
    sources: ["Tests/CodeReviewKitTests/**"],
    dependencies: [
        .target(name: "CodeReviewKit")
    ],
    settings: .settings(base: ["ENABLE_TESTING_FRAMEWORK": "YES"])
)
```

### Key Testing Patterns

- **Swift Testing Framework**: Uses `@Test` and `@Suite` annotations instead of XCTest
- **Actor-based Mocks**: `MockGitService` as actor for thread-safe testing
- **Factory Pattern**: `TestHelpers` provides consistent test data creation
- **Error Simulation**: Mock services support error injection for failure testing
- **Async Testing**: Proper async/await support in test methods
- **MainActor Testing**: UI components tested with `@MainActor` annotation

### Test Data Factories Available

- File changes: Added, modified, deleted, renamed, copied
- Review comments: Error, warning, suggestion, note severities
- Diff lines: Addition, deletion, context, hunk headers
- Sample diffs: Simple, complex, and large diff generators
- Error conditions: All AppError types with realistic scenarios