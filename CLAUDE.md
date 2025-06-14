# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS Messages Extension app called "FamZoo Payer" built with Swift and UIKit. The project implements a natural language command interface for FamZoo financial operations within iMessage conversations.

**Targets:**
- **Main App Target**: `FamZoo Payer.app` - Container app for the Messages Extension
- **Messages Extension Target**: `FamZoo Payer MessagesExtension.appex` - The actual iMessage app functionality

## Development Commands

### Preferred: Task Runner (Recommended)
The project uses Task for streamlined development commands:

```bash
# Building
task build                    # Build Messages Extension (most common)
task build:main              # Build main app target
task build:device            # Build for device
task build:release           # Release build
task clean                   # Clean build artifacts

# Testing and Analysis
task test:all                # Complete test suite with lint and analysis
task test:parser             # Test command parsing
task test:abbreviations      # Test abbreviation expansion
task analyze                 # Static code analysis
task lint                    # SwiftLint (if installed)

# Messages Extension Testing
task messages:install        # Build and install for testing
task messages:test-guide     # Show testing instructions

# Development Utilities
task dev:info                # Project information
task dev:open                # Open in Xcode
task dev:reset-simulator     # Reset iOS Simulator
task install-deps            # Install development dependencies

# Show all available tasks
task --list
```

### Fallback: Direct Xcode Commands
```bash
# Build Messages Extension for iOS Simulator (most common)
xcodebuild -project "FamZoo Payer.xcodeproj" -scheme "FamZoo Payer MessagesExtension" -destination "platform=iOS Simulator,name=iPhone 16" build

# Note: Only one scheme exists ("FamZoo Payer MessagesExtension")
# The main app is built as part of the extension build process

# List available schemes
xcodebuild -project "FamZoo Payer.xcodeproj" -list
```

### Testing Messages Extensions
Messages Extensions require special testing procedures:
1. Run `task messages:install` or build main app scheme in Xcode (⌘+R)
2. Open Messages app in iOS Simulator
3. Create or open a conversation
4. Tap the App Store icon (⊕) next to text field
5. Find "FamZoo Payer" in app drawer
6. Test both compact and expanded modes

### Debugging
```bash
# Using Task (preferred)
task debug:build-errors      # Show detailed build errors
task dev:reset-xcode         # Reset Xcode caches and derived data
task clean:deep              # Deep clean including Xcode caches

# Direct xcodebuild
xcodebuild -project "FamZoo Payer.xcodeproj" -scheme "FamZoo Payer MessagesExtension" analyze
```

## Core Architecture

### Command Processing Pipeline
The app implements a sophisticated natural language command parser:

1. **CommandParser** - Entry point that tokenizes and validates input
2. **AbbreviationExpander** - Expands shortcuts like "a b" → "account balance"
3. **ParameterParser** - Extracts typed parameters (amounts, dates, members)
4. **FamZooCommand Protocol** - Commands validate, format, and execute themselves

### Key Command Components
- **CommandType**: `account`, `list`, `member`, `shortcut`, `item` with abbreviations
- **CommandAction**: `balance`, `credit`, `debit`, `new`, `select`, `list`, etc.
- **CommandParameter**: Typed parameters (amount, text, date, member, account)
- **ValidationResult**: Comprehensive validation with specific error types

### Messages Extension Architecture
The app supports dual presentation modes with a single controller implementation:

**Compact Mode**: 4 quick action buttons (Balance, Credit, Debit, More)
**Expanded Mode**: Adds text input field for command entry

**Current Implementation:**
- `WorkingMessagesViewController` - Primary controller handling both presentation modes
- `MessageSender` - Handles iMessage integration and URL scheme encoding
- `CommonUIComponents` - Reusable UI components (LoadingView, ErrorView, ResultView)

### Data Models
- **Account**: FamZoo account with balance, type (spending/savings/parent), permissions
- **Member**: Family member with role-based permissions and preferences
- **Transaction**: Financial transactions with status, metadata, and categories

### Networking Layer
- **FamZooAPIClient** - RESTful API client with retry logic and authentication
- **KeychainManager** - Secure credential storage with biometric support (uses synchronous Security framework calls)
- **NetworkError** - Comprehensive error handling with retry strategies

## Configuration Details

- **iOS Deployment Target**: iOS 18.5
- **Swift Version**: 6.2 (recently upgraded from 5.0, README.md may show outdated 5.0)
- **Bundle Identifiers**:
  - Main App: `com.klauer.FamZoo-Payer`
  - Messages Extension: `com.klauer.FamZoo-Payer.MessagesExtension`
- **Swift 6 Compatibility**: Project uses `@MainActor` for UI operations following Swift 6 concurrency model

## Development Patterns

### Command Creation Pattern
```swift
// Simple commands for basic functionality
let command = SimpleCommand(
    type: .account,
    action: .balance,
    rawText: "account balance"
)

// Full commands use the protocol (parsed via CommandParser)
let parsedCommand = CommandParser().parse("account balance")
```

### Messages Extension Lifecycle
- `willBecomeActive(with:)` - Initialize for conversation
- `didTransition(to:)` - Handle compact ↔ expanded mode switches
- `didStartSending(_:conversation:)` - Execute command when user sends
- Message encoding via custom URL schemes for data persistence

### Abbreviation System
Commands support extensive abbreviations via `AbbreviationExpander`:
- "a b" → "account balance"
- "l add grocery shopping" → "list add grocery shopping"
- "acc c 25.00" → "account credit 25.00"
- System uses pattern matching and context-aware expansion

### Parameter Parsing
`ParameterParser` handles complex input parsing with typed parameters:
- **Amounts**: `$25.00`, `25`, `25.50` (parsed as Decimal)
- **Dates**: `today`, `tomorrow`, `2024-01-15`, relative dates
- **Flags**: `--urgent`, `-f`, boolean parameters
- **Quoted Strings**: Preserves spaces and special characters
- **Member References**: Context-aware family member selection

### Swift 6 Concurrency Considerations
- **UI Operations**: All `displayView()` methods marked with `@MainActor`
- **Command Execution**: Uses `async/await` pattern for API calls
- **Error Handling**: Comprehensive `ValidationResult` system with typed errors

## Current Implementation Status

### Working Components
- **Command Parsing System**: Full implementation with abbreviation expansion and parameter extraction
- **API Client**: Complete REST client with authentication and retry logic (`FamZooAPIClient`)
- **Message Integration**: Sophisticated URL scheme encoding for iMessage persistence (`MessageSender`)
- **UI Framework**: Basic 4-button interface with dual presentation modes (`WorkingMessagesViewController`)
- **Security Layer**: Biometric authentication and keychain storage (`KeychainManager`)
- **Swift 6 Compatibility**: All UI operations properly isolated with `@MainActor`

### Architecture Strengths
- **Protocol-Oriented Design**: `FamZooCommand` protocol enables extensible command system
- **Type Safety**: Comprehensive parameter validation with `ValidationResult`
- **Modular Structure**: Clear separation between parsing, networking, and UI layers
- **Feature Organization**: Structured `/Features` directory for future expansion

### Integration Opportunities
- **UI ↔ Command System**: Rich parsing system ready for UI integration
- **Feature Modules**: `/Features` directories prepared for implementation
- **Testing Infrastructure**: Taskfile includes comprehensive testing commands
- **Documentation**: Auto-generation support via SourceDocs

### Development Notes
- **Messages Extension Context**: App runs within Messages app, not standalone
- **Dual UI Modes**: Must handle both compact (strip) and expanded (full screen) presentation
- **Single Scheme**: Only "FamZoo Payer MessagesExtension" scheme exists
- **Task-Driven Workflow**: Prefer `task` commands over direct xcodebuild
- **Swift 6 Ready**: Project fully compatible with Swift 6.2 concurrency model