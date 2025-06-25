<!-- Generated: 2025-01-25 00:00:00 UTC -->

# Deployment Documentation

## Overview

The Claude Code Reviewer is a native macOS application built with Swift and packaged for distribution using Xcode's build system. The project uses Tuist for project generation and management.

**Key Scripts:**
- `/Users/billy/workspace/claude-review/build.sh` - Main build orchestration
- `/Users/billy/workspace/claude-review/scripts/build-release.sh` - Release builds
- `/Users/billy/workspace/claude-review/scripts/notarize.sh` - App notarization

## Package Types

### Debug Build
- **Target:** Development testing
- **Configuration:** Debug
- **Output:** `/Users/billy/workspace/claude-review/build/Debug/ClaudeCodeReviewer.app`
- **Build Command:** `xcodebuild -scheme ClaudeCodeReviewer -configuration Debug`

### Release Build
- **Target:** Production distribution
- **Configuration:** Release
- **Output:** `/Users/billy/workspace/claude-review/build/Release/ClaudeCodeReviewer.app`
- **Build Command:** `xcodebuild -scheme ClaudeCodeReviewer -configuration Release`
- **Signing:** Developer ID Application certificate required

### Archive Build
- **Target:** App Store submission
- **Output:** `/Users/billy/workspace/claude-review/build/ClaudeCodeReviewer.xcarchive`
- **Export:** `/Users/billy/workspace/claude-review/build/export/ClaudeCodeReviewer.app`

## Platform Deployment

### macOS Direct Distribution
1. **Build Release App:**
   ```bash
   cd /Users/billy/workspace/claude-review
   ./scripts/build-release.sh
   ```

2. **Sign Application:**
   - Certificate: Developer ID Application
   - Entitlements: `/Users/billy/workspace/claude-review/ClaudeCodeReviewer/Entitlements.plist`

3. **Notarize for Gatekeeper:**
   ```bash
   ./scripts/notarize.sh build/Release/ClaudeCodeReviewer.app
   ```

4. **Create DMG Installer:**
   - Input: `/Users/billy/workspace/claude-review/build/Release/ClaudeCodeReviewer.app`
   - Output: `/Users/billy/workspace/claude-review/build/ClaudeCodeReviewer.dmg`

### Mac App Store Distribution
**Future Implementation Requirements:**
1. App Store Connect configuration
2. Sandbox entitlements in `/Users/billy/workspace/claude-review/ClaudeCodeReviewer/Entitlements.plist`
3. Archive and upload via Xcode Organizer

## Reference

### Build Outputs
- **Debug App:** `/Users/billy/workspace/claude-review/build/Debug/ClaudeCodeReviewer.app`
- **Release App:** `/Users/billy/workspace/claude-review/build/Release/ClaudeCodeReviewer.app`
- **Archives:** `/Users/billy/workspace/claude-review/build/*.xcarchive`
- **DMG Installer:** `/Users/billy/workspace/claude-review/build/ClaudeCodeReviewer.dmg`
- **Logs:** `/Users/billy/workspace/claude-review/build/logs/`

### Configuration Files
- **Tuist Config:** `/Users/billy/workspace/claude-review/Tuist/Config.swift`
- **Project.swift:** `/Users/billy/workspace/claude-review/Project.swift`
- **Info.plist:** `/Users/billy/workspace/claude-review/ClaudeCodeReviewer/Info.plist`
- **Entitlements:** `/Users/billy/workspace/claude-review/ClaudeCodeReviewer/Entitlements.plist`

### Requirements
- **Bundle Identifier:** com.example.ClaudeCodeReviewer
- **Minimum macOS:** 12.0
- **Build Tools:** Xcode 14+, Swift 5.7+
- **Dependencies:** Managed via Swift Package Manager in `Project.swift`

### Deployment Scripts
```bash
# Generate Xcode project
tuist generate

# Build for debugging
xcodebuild -scheme ClaudeCodeReviewer -configuration Debug

# Build for release
./scripts/build-release.sh

# Create signed DMG
./scripts/create-dmg.sh

# Notarize app
./scripts/notarize.sh [app-path]
```