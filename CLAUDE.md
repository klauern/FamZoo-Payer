# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS Messages Extension app called "FamZoo Payer" built with Swift and UIKit. The project implements a natural language command interface for FamZoo financial operations within iMessage conversations.

**Targets:**
- **Main App Target**: `FamZoo Payer.app` - Container app for the Messages Extension
- **Messages Extension Target**: `FamZoo Payer MessagesExtension.appex` - The actual iMessage app functionality

## Development Commands

### Building the Project
```bash
# Build Messages Extension for iOS Simulator (most common)
xcodebuild -project "FamZoo Payer.xcodeproj" -scheme "FamZoo Payer MessagesExtension" -destination "platform=iOS Simulator,name=iPhone 16" build

# Build main app (includes extension)
xcodebuild -project "FamZoo Payer.xcodeproj" -scheme "FamZoo Payer" -destination "platform=iOS Simulator,name=iPhone 16" build

# List available schemes
xcodebuild -project "FamZoo Payer.xcodeproj" -list
```

### Testing Messages Extensions
Messages Extensions can only be tested within the Messages app:
1. Run the main app scheme in Xcode (⌘+R)
2. Open Messages app in simulator
3. Create/open conversation
4. Tap App Store icon next to text field
5. Find "FamZoo Payer" in app drawer

### Debugging
```bash
# Code analysis
xcodebuild -project "FamZoo Payer.xcodeproj" -scheme "FamZoo Payer" analyze
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
The app supports dual presentation modes:

**Compact Mode**: Quick action buttons for common commands
**Expanded Mode**: Full command builder with text input and templates

**Entry Points:**
- `WorkingMessagesViewController` - Current functional implementation
- `MessagesViewController` - Advanced implementation (may have compilation issues)
- Multiple test controllers available for different complexity levels

### UI Controller Hierarchy
- **QuickActionsViewController** - Compact mode interface with preset buttons
- **CommandBuilderViewController** - Expanded mode with text input and suggestions
- **MessageSender** - Handles iMessage integration and URL scheme encoding

### Data Models
- **Account**: FamZoo account with balance, type (spending/savings/parent), permissions
- **Member**: Family member with role-based permissions and preferences
- **Transaction**: Financial transactions with status, metadata, and categories

### Networking Layer
- **FamZooAPIClient** - RESTful API client with retry logic and authentication
- **KeychainManager** - Secure credential storage with biometric support
- **NetworkError** - Comprehensive error handling with retry strategies

## Configuration Details

- **iOS Deployment Target**: iOS 18.5
- **Swift Version**: 5.0
- **Bundle Identifiers**:
  - Main App: `com.klauer.FamZoo-Payer`
  - Messages Extension: `com.klauer.FamZoo-Payer.MessagesExtension`

## Development Patterns

### Command Creation Pattern
```swift
// Commands implement FamZooCommand protocol
let command = ConcreteCommand(
    type: .account,
    action: .balance,
    parameters: [],
    rawText: "account balance"
)
```

### Messages Extension Lifecycle
- `willBecomeActive(with:)` - Initialize for conversation
- `didTransition(to:)` - Handle compact ↔ expanded mode switches
- `didStartSending(_:conversation:)` - Execute command when user sends
- Message encoding via custom URL schemes for data persistence

### Abbreviation System
Commands support extensive abbreviations:
- "a b" → "account balance"
- "l add grocery shopping" → "list add grocery shopping"
- "acc c 25.00" → "account credit 25.00"

### Parameter Parsing
Supports quoted strings, flags, and typed parameters:
- Amounts: `$25.00`, `25`, `25.50`
- Dates: `today`, `tomorrow`, `2024-01-15`, relative dates
- Flags: `--urgent`, `-f`, boolean parameters

## Messages Extension Notes

- Extensions run within Messages app context, not standalone
- UI must handle both compact (strip) and expanded (full screen) modes
- All functionality resides in Messages Extension target
- Main app target serves only as container for App Store