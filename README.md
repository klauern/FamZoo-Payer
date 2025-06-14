# FamZoo Payer

A sophisticated iOS Messages Extension that provides a natural language command interface for FamZoo financial operations within iMessage conversations.

[![iOS](https://img.shields.io/badge/iOS-18.5+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-16.0+-blue.svg)](https://developer.apple.com/xcode/)

## Overview

FamZoo Payer transforms family financial management by bringing FamZoo's powerful account management directly into iMessage. Users can check balances, make transfers, and manage family finances using natural language commands without leaving their conversations.

### Key Features

- 🗣 **Natural Language Processing**: Type commands like "account balance" or "credit $25 to Sarah's account"
- ⚡ **Quick Actions**: Four-button interface for instant access to common operations
- 📱 **Dual Interface**: Compact mode for quick actions, expanded mode for full command input
- 🔄 **Smart Abbreviations**: "a b" expands to "account balance", "acc c 25.00" becomes "account credit 25.00"
- 🔐 **Secure Authentication**: Biometric security with keychain storage
- 🏗 **Robust Architecture**: Modular command parsing system with comprehensive error handling

## Architecture

### Project Structure

```
FamZoo Payer/
├── FamZoo Payer/                    # Main app target (container only)
├── FamZoo Payer MessagesExtension/  # Messages Extension (core functionality)
│   ├── Core/
│   │   ├── Commands/               # Command system
│   │   │   ├── CommandType.swift
│   │   │   ├── CommandAction.swift
│   │   │   ├── CommandParameter.swift
│   │   │   ├── CommandProtocol.swift
│   │   │   └── SimpleCommand.swift
│   │   ├── Models/                 # Data models
│   │   │   ├── Account.swift
│   │   │   ├── Member.swift
│   │   │   └── Transaction.swift
│   │   ├── Networking/             # API and messaging
│   │   │   ├── FamZooAPIClient.swift
│   │   │   ├── MessageSender.swift
│   │   │   └── NetworkError.swift
│   │   ├── Parser/                 # Command parsing engine
│   │   │   ├── CommandParser.swift
│   │   │   ├── AbbreviationExpander.swift
│   │   │   └── ParameterParser.swift
│   │   ├── Storage/                # Secure storage
│   │   │   └── KeychainManager.swift
│   │   └── UI/                     # Shared UI components
│   │       └── CommonUIComponents.swift
│   ├── Features/                   # Feature modules
│   │   ├── CommandBuilder/
│   │   ├── CommandHistory/
│   │   ├── QuickActions/
│   │   ├── ResponseDisplay/
│   │   └── Settings/
│   ├── UI/                         # UI framework
│   │   ├── Components/
│   │   ├── Extensions/
│   │   └── Styles/
│   ├── Utilities/
│   └── WorkingMessagesViewController.swift
└── CLAUDE.md                       # Development documentation
```

### Command Processing Pipeline

The app implements a sophisticated natural language command parser:

1. **CommandParser** - Entry point that tokenizes and validates input
2. **AbbreviationExpander** - Expands shortcuts like "a b" → "account balance"
3. **ParameterParser** - Extracts typed parameters (amounts, dates, members)
4. **FamZooCommand Protocol** - Commands validate, format, and execute themselves

### Supported Commands

#### Account Operations
- `account balance` / `a b` - Check account balance
- `account credit $25.00` / `acc c 25` - Add money to account
- `account debit $10.50` / `acc d 10.50` - Remove money from account
- `account new savings "College Fund"` - Create new account

#### List Management
- `list add "grocery shopping"` / `l add grocery shopping` - Add to shopping list
- `list show` / `l s` - Show current list items
- `list complete 3` / `l c 3` - Mark item as complete

#### Member Operations
- `member select Sarah` / `m s Sarah` - Switch to family member
- `member list` / `m l` - Show all family members
- `member new child "Alex" --allowance 20` - Add new family member

#### Parameter Types
- **Amounts**: `$25.00`, `25`, `25.50`
- **Dates**: `today`, `tomorrow`, `2024-01-15`, relative dates
- **Flags**: `--urgent`, `-f`, boolean parameters
- **Quoted Strings**: `"grocery shopping"`, `'College Fund'`

## Development

### Prerequisites

- Xcode 16.0 or later
- iOS 18.5+ deployment target
- Swift 5.0
- Task runner (optional, for CLI operations)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd "FamZoo Payer"
   ```

2. **Open in Xcode**
   ```bash
   open "FamZoo Payer.xcodeproj"
   ```

3. **Install Task runner** (optional)
   ```bash
   brew install go-task/tap/go-task
   # or
   go install github.com/go-task/task/v3/cmd/task@latest
   ```

### Building

#### Using Task (Recommended)
```bash
# Build Messages Extension
task build

# Build for device
task build:device

# Clean build
task clean

# Analyze code
task analyze

# List all available tasks
task --list
```

#### Using Xcode Build System
```bash
# Build Messages Extension for iOS Simulator
xcodebuild -project "FamZoo Payer.xcodeproj" \
           -scheme "FamZoo Payer MessagesExtension" \
           -destination "platform=iOS Simulator,name=iPhone 16" \
           build

# Build main app
xcodebuild -project "FamZoo Payer.xcodeproj" \
           -scheme "FamZoo Payer" \
           -destination "platform=iOS Simulator,name=iPhone 16" \
           build

# List available schemes
xcodebuild -project "FamZoo Payer.xcodeproj" -list
```

### Testing Messages Extensions

Messages Extensions require special testing procedures:

1. **Run the main app scheme** in Xcode (⌘+R)
2. **Open Messages app** in the iOS Simulator
3. **Create or open a conversation**
4. **Tap the App Store icon** (⊕) next to the text field
5. **Find "FamZoo Payer"** in the app drawer
6. **Test functionality** in both compact and expanded modes

### Development Workflow

#### Command Development
```bash
# Create new command type
task dev:new-command

# Test command parsing
task test:parser

# Validate abbreviations
task test:abbreviations
```

#### UI Development
```bash
# Launch UI components in isolation
task dev:ui-preview

# Test responsive layouts
task test:layouts
```

#### API Integration
```bash
# Test API connectivity
task test:api

# Validate network error handling
task test:network-errors
```

### Project Configuration

- **Bundle Identifiers**:
  - Main App: `com.klauer.FamZoo-Payer`
  - Messages Extension: `com.klauer.FamZoo-Payer.MessagesExtension`
- **iOS Deployment Target**: iOS 18.5
- **Swift Version**: 5.0

## Usage

### Quick Actions (Compact Mode)

The app provides four quick action buttons when running in compact mode:

- **💰 Balance** - Check account balance
- **➕ Credit** - Add money to account  
- **➖ Debit** - Remove money from account
- **⚙️ More** - Access additional features

### Natural Language Commands (Expanded Mode)

In expanded mode, users can type natural language commands:

```
// Check balance
account balance
a b

// Transfer money
credit $25 to Sarah's account
acc c 25 Sarah

// Manage lists
list add grocery shopping
l add milk, bread, eggs

// Account management
account new savings "College Fund"
member select Alex --switch-context
```

### Abbreviation System

The app supports extensive abbreviations for faster input:

| Full Command | Abbreviation | Description |
|-------------|-------------|-------------|
| `account balance` | `a b` | Check account balance |
| `account credit 25.00` | `acc c 25` | Credit $25 to account |
| `list add grocery shopping` | `l add grocery` | Add to shopping list |
| `member select Sarah` | `m s Sarah` | Switch to family member |

## API Integration

### FamZoo API Client

The app integrates with FamZoo's REST API:

- **Authentication**: OAuth 2.0 with refresh token handling
- **Retry Logic**: Automatic retry with exponential backoff
- **Error Handling**: Comprehensive error categorization and user-friendly messages
- **Offline Support**: Graceful degradation when network unavailable

### Message Persistence

Commands and responses are encoded into iMessage URLs for persistence:

```swift
// Example URL scheme
famzoo://command?type=account&action=balance&member=sarah&response=encoded_data
```

## Security

### Authentication
- **Biometric Authentication**: Face ID / Touch ID for app access
- **Keychain Storage**: Secure credential storage using iOS Keychain
- **Token Management**: Automatic token refresh and secure storage

### Data Protection
- **No Local Storage**: Sensitive data never stored locally
- **Encrypted Transit**: All API communications use TLS 1.3
- **Minimal Permissions**: App requests only necessary permissions

## Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean build directory
task clean

# Show detailed build errors
task build:verbose

# Reset Xcode caches
task dev:reset-xcode
```

#### Messages Extension Not Appearing
1. Ensure main app target is built and installed
2. Check that Messages Extension is properly embedded
3. Restart Messages app and iOS Simulator
4. Verify bundle identifiers match between targets

#### Command Parsing Issues
```bash
# Test command parser
task test:parser

# Debug abbreviation expansion
task debug:abbreviations "a b"

# Validate parameter parsing
task debug:parameters "credit $25 to Sarah"
```

### Debugging

#### Enable Debug Logging
```swift
// Add to WorkingMessagesViewController.swift
#if DEBUG
CommandParser.enableDebugLogging = true
#endif
```

#### View Network Requests
```bash
# Monitor API calls
task debug:network

# Test API endpoints
task test:api-endpoints
```

## Contributing

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Maintain comprehensive inline documentation
- Write unit tests for all new functionality

### Development Process
1. Create feature branch from `main`
2. Implement functionality with tests
3. Run full test suite: `task test:all`
4. Submit pull request with detailed description

### Architecture Guidelines
- **Separation of Concerns**: Keep UI, business logic, and data layers separate
- **Protocol-Oriented Design**: Use protocols for testability and flexibility
- **Error Handling**: Implement comprehensive error handling with user-friendly messages
- **Performance**: Optimize for Messages Extension memory constraints

## License

This project is proprietary software. All rights reserved.

## Support

For development questions or issues:
- Check the [Troubleshooting](#troubleshooting) section
- Review `CLAUDE.md` for detailed development guidelines
- Create an issue in the project repository

---

*Built with ❤️ for family financial management*