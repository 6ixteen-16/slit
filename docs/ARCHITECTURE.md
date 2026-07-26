# Architecture Documentation

## Smart Light Flutter Application Architecture

This document provides a comprehensive overview of the Flutter application architecture, design patterns, and technical decisions.

---

## Table of Contents

- [Overview](#overview)
- [Architecture Principles](#architecture-principles)
- [System Architecture](#system-architecture)
- [Layered Architecture](#layered-architecture)
- [Design Patterns](#design-patterns)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [State Management](#state-management)
- [Networking](#networking)
- [Error Handling](#error-handling)
- [Testing Strategy](#testing-strategy)
- [Performance Considerations](#performance-considerations)
- [Security Considerations](#security-considerations)
- [Scalability](#scalability)

---

## Overview

The Smart Light Flutter application follows a clean, layered architecture that separates concerns and promotes maintainability, testability, and scalability. The architecture is based on SOLID principles and industry best practices for Flutter applications.

### Key Architectural Goals

1. **Separation of Concerns**: Each layer has a specific responsibility
2. **Testability**: Components can be tested in isolation
3. **Maintainability**: Code is organized and easy to understand
4. **Scalability**: Architecture supports future growth
5. **Reusability**: Components are designed for reuse across the application

---

## Architecture Principles

### SOLID Principles

#### Single Responsibility Principle (SRP)
Each class and module has a single reason to change. For example:
- `ApiService` handles only HTTP communication
- `ConnectionService` handles only connection management
- `SystemProvider` handles only state management

#### Open/Closed Principle (OCP)
Software entities are open for extension but closed for modification. The application uses:
- Abstract interfaces for services
- Dependency injection through Provider
- Strategy pattern for different button variants

#### Liskov Substitution Principle (LSP)
Derived classes can substitute their base classes. Implemented through:
- Consistent interfaces across models
- Polymorphic widget components
- Interchangeable service implementations

#### Interface Segregation Principle (ISP)
Clients depend only on interfaces they use. The application:
- Provides focused service interfaces
- Separates read and write operations
- Uses specific widget props

#### Dependency Inversion Principle (DIP)
High-level modules don't depend on low-level modules. Both depend on abstractions:
- Services depend on abstract HTTP client
- UI depends on Provider abstractions
- Models define data contracts

### DRY Principle (Don't Repeat Yourself)

Code duplication is minimized through:
- Reusable widget components
- Shared utility functions
- Centralized constants
- Common styling patterns

### KISS Principle (Keep It Simple, Stupid)

Complexity is avoided through:
- Straightforward implementations
- Clear naming conventions
- Minimal dependencies
- Simple data flow

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  Presentation Layer                    │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │ Screens  │  │ Widgets  │  │  Themes  │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                Business Logic Layer                   │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │Providers │  │ Services │  │  Utils   │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   Data Layer                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │ Models   │  │  Config  │  │ Constants │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Network    │
                    │  Layer      │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   ESP32     │
                    │  Hardware   │
                    └─────────────┘
```

### Component Interaction

```
User Input → Screen Widget → System Provider → API Service → ESP32
     ↑                                                            ↓
     └────────────────── UI Update ←──────────────────────────────┘
```

---

## Layered Architecture

### 1. Presentation Layer

**Purpose**: Handle user interface and user interactions

**Components**:
- **Screens**: Full-screen UI components
- **Widgets**: Reusable UI components
- **Themes**: Visual styling and theming

**Responsibilities**:
- Display data to users
- Capture user input
- Navigate between screens
- Provide visual feedback

**Key Files**:
- `lib/screens/*.dart`
- `lib/widgets/*.dart`
- `lib/main.dart` (theme configuration)

### 2. Business Logic Layer

**Purpose**: Implement application logic and state management

**Components**:
- **Providers**: State management with Provider pattern
- **Services**: Business logic and external communication
- **Utils**: Helper functions and utilities

**Responsibilities**:
- Manage application state
- Coordinate between layers
- Implement business rules
- Handle data transformation

**Key Files**:
- `lib/providers/system_provider.dart`
- `lib/services/api_service.dart`
- `lib/services/connection_service.dart`
- `lib/utils/helpers.dart`

### 3. Data Layer

**Purpose**: Define data structures and configuration

**Components**:
- **Models**: Data models with serialization
- **Config**: Application configuration
- **Constants**: Application-wide constants

**Responsibilities**:
- Define data structures
- Provide type safety
- Centralize configuration
- Ensure data consistency

**Key Files**:
- `lib/models/*.dart`
- `lib/config/api_constants.dart`
- `lib/utils/constants.dart`

---

## Design Patterns

### 1. Provider Pattern

**Purpose**: State management and dependency injection

**Implementation**:
```dart
class SystemProvider with ChangeNotifier {
  // State
  SystemStatus _systemStatus;
  
  // Getters
  SystemStatus get systemStatus => _systemStatus;
  
  // Methods
  Future<void> refreshStatus() async {
    // Update state
    _systemStatus = await _apiService.getSystemStatus();
    notifyListeners();
  }
}
```

**Usage**:
```dart
// In widget tree
ChangeNotifierProvider(
  create: (_) => SystemProvider(),
  child: MyApp(),
)

// In widget
Consumer<SystemProvider>(
  builder: (context, provider, child) {
    return Text('${provider.systemStatus.brightness}%');
  },
)
```

### 2. Singleton Pattern

**Purpose**: Ensure single instance of services

**Implementation**:
```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
}
```

### 3. Repository Pattern

**Purpose**: Abstract data access logic

**Implementation**:
- `ApiService` acts as a repository for ESP32 data
- Provides clean interface for data operations
- Handles caching and error recovery

### 4. Observer Pattern

**Purpose**: React to state changes

**Implementation**:
- Provider's `notifyListeners()` notifies observers
- Widgets rebuild when state changes
- Streams for connection status updates

### 5. Factory Pattern

**Purpose**: Create objects with complex initialization

**Implementation**:
```dart
factory SystemStatus.fromJson(Map<String, dynamic> json) {
  return SystemStatus(
    presence: json['presence'] as bool,
    // ... other fields
  );
}
```

### 6. Strategy Pattern

**Purpose**: Define interchangeable algorithms

**Implementation**:
- Different button variants (primary, secondary, outline)
- Different slider configurations
- Theme strategies (light/dark)

---

## Component Architecture

### Screen Architecture

Each screen follows a consistent structure:

```dart
class ScreenName extends StatefulWidget {
  const ScreenName({super.key});

  @override
  State<ScreenName> createState() => _ScreenNameState();
}

class _ScreenNameState extends State<ScreenName> {
  // State variables
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Title')),
      body: Consumer<SystemProvider>(
        builder: (context, provider, child) {
          // UI implementation
        },
      ),
    );
  }
}
```

### Widget Architecture

Reusable widgets are designed for:

- **Single Responsibility**: Each widget does one thing well
- **Reusability**: Can be used in multiple contexts
- **Customizability**: Accept parameters for customization
- **Composition**: Can be composed of other widgets

Example:
```dart
class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color? color;

  const SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Widget implementation
  }
}
```

### Service Architecture

Services are designed to be:

- **Stateless**: No internal state (except connection service)
- **Testable**: Can be mocked for testing
- **Independent**: Minimal dependencies
- **Reliable**: Handle errors gracefully

Example:
```dart
class ApiService {
  final http.Client _client;

  Future<SystemStatus> getSystemStatus() async {
    try {
      final response = await _get(endpointStatus);
      return SystemStatus.fromJson(jsonDecode(response.body));
    } catch (e) {
      throw ApiException('Failed to fetch status: $e');
    }
  }
}
```

---

## Data Flow

### Read Data Flow

```
1. User opens screen
2. Screen requests data from Provider
3. Provider checks if data exists
4. If not, Provider calls API Service
5. API Service makes HTTP request to ESP32
6. ESP32 returns JSON response
7. API Service parses JSON to Model
8. API Service returns Model to Provider
9. Provider updates state
10. Provider notifies listeners
11. Screen rebuilds with new data
```

### Write Data Flow

```
1. User performs action (e.g., changes brightness)
2. Screen calls Provider method
3. Provider validates input
4. Provider calls API Service
5. API Service makes HTTP POST to ESP32
6. ESP32 processes request
7. ESP32 returns success/error response
8. API Service returns result to Provider
9. Provider updates local state
10. Provider notifies listeners
11. Screen shows success/error feedback
```

### Error Flow

```
1. Error occurs at any layer
2. Error is caught and wrapped in ApiException
3. Error message is stored in Provider
4. Provider notifies listeners
5. Screen displays error to user
6. User can retry or dismiss
```

---

## State Management

### State Management Strategy

The application uses the **Provider** pattern for state management:

**Advantages**:
- Simple and easy to understand
- Built-in Flutter support
- Good performance with selective rebuilding
- Easy to test

### State Hierarchy

```
SystemProvider (Root)
├── SystemStatus
├── EventLogs
├── Settings
├── Statistics
├── ConnectionStatus
└── LoadingStates
```

### State Updates

State updates follow this pattern:

```dart
// 1. Update state
_currentStatus = newStatus;

// 2. Notify listeners
notifyListeners();

// 3. UI rebuilds automatically
```

### State Persistence

Currently, state is not persisted. Future improvements:
- Use `shared_preferences` for settings
- Use local database for logs
- Implement cloud sync

---

## Networking

### Network Architecture

The networking layer is designed with:

- **Abstraction**: HTTP client is abstracted
- **Retry Logic**: Automatic retry with exponential backoff
- **Timeout Handling**: Configurable timeouts
- **Error Handling**: Custom exception types

### Request Flow

```
1. Provider calls API Service method
2. API Service validates parameters
3. API Service creates HTTP request
4. Request is sent with timeout
5. Response received or timeout occurs
6. If timeout, retry with backoff
7. If success, parse JSON
8. If error, throw ApiException
9. Provider handles error
```

### Retry Strategy

```dart
int attempt = 0;
while (attempt < maxRetries) {
  try {
    return await _client.get(uri).timeout(timeout);
  } catch (e) {
    attempt++;
    if (attempt >= maxRetries) throw;
    await Future.delayed(retryDelay * attempt);
  }
}
```

---

## Error Handling

### Error Handling Strategy

Errors are handled at multiple levels:

1. **Network Level**: HTTP errors, timeouts
2. **Service Level**: API errors, parsing errors
3. **Provider Level**: Business logic errors
4. **UI Level**: User-friendly error messages

### Error Types

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
}
```

### Error Display

Errors are displayed to users through:
- SnackBar messages
- Error cards
- Status indicators
- Dialog boxes

---

## Testing Strategy

### Unit Testing

Test individual components in isolation:

```dart
test('SystemStatus.fromJson should parse correctly', () {
  final json = {
    'presence': true,
    'ambient_light': 250.5,
    'brightness': 75,
    // ...
  };
  final status = SystemStatus.fromJson(json);
  expect(status.presence, true);
});
```

### Widget Testing

Test UI components:

```dart
testWidgets('SensorCard displays correct data', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SensorCard(
        icon: Icons.light_mode,
        label: 'Ambient Light',
        value: '250.5',
        unit: 'lux',
      ),
    ),
  );
  expect(find.text('250.5'), findsOneWidget);
});
```

### Integration Testing

Test component interactions:

```dart
testWidgets('Manual control updates brightness', (tester) async {
  // Test full flow from UI to provider
});
```

### Mock Services

Mock services for testing:

```dart
class MockApiService extends Mock implements ApiService {}
```

---

## Performance Considerations

### Rendering Performance

- **Const Widgets**: Use `const` where possible
- **Lazy Loading**: Load data on demand
- **Image Caching**: Cache network images
- **ListView.builder**: Use for long lists

### Network Performance

- **Polling Interval**: Optimize polling frequency
- **Request Batching**: Batch multiple requests
- **Compression**: Enable response compression
- **Caching**: Cache API responses

### Memory Management

- **Dispose Resources**: Properly dispose timers and streams
- **Image Optimization**: Use optimized image formats
- **Memory Leaks**: Monitor for memory leaks
- **Object Pooling**: Reuse objects where possible

---

## Security Considerations

### Current Security

- No authentication (local network only)
- HTTP (not HTTPS)
- No input encryption

### Recommended Security

1. **Authentication**: Implement API keys
2. **Encryption**: Use HTTPS/TLS
3. **Input Validation**: Validate all inputs
4. **Rate Limiting**: Prevent abuse
5. **Data Encryption**: Encrypt sensitive data at rest

---

## Scalability

### Horizontal Scalability

- **Multiple ESP32s**: Support multiple devices
- **Cloud Backend**: Add cloud synchronization
- **User Accounts**: Multi-user support

### Vertical Scalability

- **Feature Modules**: Add new features as modules
- **Plugin System**: Support plugins/extensions
- **Configuration**: Externalize configuration

### Code Scalability

- **Modular Architecture**: Easy to add new modules
- **Clear Interfaces**: Well-defined boundaries
- **Documentation**: Comprehensive documentation
- **Testing**: High test coverage

---

## Future Architecture Improvements

### Planned Enhancements

1. **BLoC Pattern**: Consider BLoC for complex state
2. **Repository Pattern**: Add repository layer
3. **Dependency Injection**: Use get_it or injectable
4. **Clean Architecture**: Move to full clean architecture
5. **Microservices**: Split into microservices if needed

### Technology Upgrades

1. **Flutter 3.0+**: Latest Flutter features
2. **Null Safety**: Full null safety migration
3. **Web Support**: Add web platform support
4. **Desktop Support**: Add desktop platform support

---

## Conclusion

The Smart Light Flutter application architecture is designed to be maintainable, scalable, and testable. By following SOLID principles, industry best practices, and Flutter conventions, the application provides a solid foundation for current functionality and future enhancements.

The layered architecture ensures clear separation of concerns, while the Provider pattern offers simple and effective state management. The modular design allows for easy addition of new features and adaptation to changing requirements.

---

## References

- [Flutter Architecture](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)
- [Provider Package](https://pub.dev/packages/provider)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
