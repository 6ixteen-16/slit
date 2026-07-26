# ThingSpeak Integration Documentation

## Overview

This document describes the integration of ThingSpeak Cloud into the Smart Light Flutter application. ThingSpeak provides cloud-based data storage and visualization for IoT devices, enabling remote monitoring and historical data analysis.

---

## Table of Contents

- [Integration Overview](#integration-overview)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Field Mapping](#field-mapping)
- [API Service](#api-service)
- [Data Models](#data-models)
- [Provider Integration](#provider-integration)
- [UI Updates](#ui-updates)
- [Offline Handling](#offline-handling)
- [Error Handling](#error-handling)
- [Performance](#performance)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Integration Overview

### Purpose

The ThingSpeak integration allows the Flutter application to:

- Retrieve live sensor data from ThingSpeak Cloud
- Access historical data for statistics and analytics
- Display event logs derived from historical feeds
- Provide offline fallback to direct ESP32 connection
- Support configurable data source switching

### Key Features

- **Live Data Fetching**: Automatic polling at configurable intervals
- **Historical Data**: Time-range selectable historical data retrieval
- **Offline Support**: Graceful fallback to ESP32 direct connection
- **Connection Monitoring**: Real-time ThingSpeak connectivity status
- **Caching**: Response caching to reduce API calls
- **Retry Logic**: Automatic retry with exponential backoff
- **Error Handling**: Comprehensive error handling with user feedback

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   UI Layer                            │  │
│  │  - Dashboard (ThingSpeak Status Widget)             │  │
│  │  - Statistics (Time Range Selector)                 │  │
│  │  - Settings (Data Source Toggle)                     │  │
│  │  - Logs (Generated from ThingSpeak Feeds)            │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              SystemProvider                           │  │
│  │  - ThingSpeak Service Integration                    │  │
│  │  - Data Source Management                            │  │
│  │  - Offline Fallback Logic                             │  │
│  │  - Statistics Calculation                             │  │
│  │  - Log Generation                                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            ThingSpeakService                          │  │
│  │  - API Communication                                  │  │
│  │  - JSON Parsing                                       │  │
│  │  - Retry Logic                                        │  │
│  │  - Caching                                            │  │
│  │  - Error Handling                                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                    ┌───────▼──────┐
                    │ ThingSpeak   │
                    │   Cloud API  │
                    └──────────────┘
```

### Data Flow

1. **User opens app** → SystemProvider initializes
2. **Network check** → Connectivity status determined
3. **ThingSpeak enabled** → Fetch latest feed from ThingSpeak
4. **Data received** → Parse JSON to ThingSpeakFeed model
5. **Convert to SystemStatus** → Map to existing SystemStatus model
6. **Notify UI** → Provider notifies listeners
7. **UI updates** → Screens display live data
8. **Polling continues** → Automatic refresh at configured interval

---

## Configuration

### Configuration File

Location: `lib/config/thingspeak_config.dart`

### Required Configuration

Update the following values with your ThingSpeak channel details:

```dart
class ThingSpeakConfig {
  /// ThingSpeak Base URL
  static const String baseUrl = 'https://api.thingspeak.com';

  /// ThingSpeak Channel ID
  static const String channelId = 'YOUR_CHANNEL_ID';

  /// ThingSpeak Read API Key
  static const String readApiKey = 'YOUR_READ_API_KEY';

  /// ThingSpeak Write API Key
  static const String writeApiKey = 'YOUR_WRITE_API_KEY';

  /// Update Interval (milliseconds)
  static const int updateInterval = 15000; // 15 seconds

  /// Connection Timeout (milliseconds)
  static const int connectionTimeout = 10000; // 10 seconds

  /// Maximum Retry Attempts
  static const int maxRetries = 3;

  /// Retry Delay (milliseconds)
  static const int retryDelay = 2000; // 2 seconds

  /// Cache Duration (milliseconds)
  static const int cacheDuration = 5000; // 5 seconds
}
```

### Field Mapping Configuration

Default field mapping (configurable):

```dart
static const FieldMapping fieldMapping = FieldMapping(
  presence: 1,
  ambientLight: 2,
  brightness: 3,
  pwmValue: 4,
  systemState: 5,
  activeTime: 6,
  idleTime: 7,
  sleepTime: 8,
);
```

### Getting ThingSpeak Credentials

1. **Create ThingSpeak Account**: Visit [thingspeak.com](https://thingspeak.com)
2. **Create Channel**: Create a new channel for your lighting system
3. **Configure Fields**: Add 8 fields with appropriate names
4. **Get API Keys**: Copy Read API Key and Write API Key from channel settings
5. **Note Channel ID**: Note your channel ID from the channel URL

---

## Field Mapping

### Default Mapping

| Field Number | Parameter | Description | Data Type |
|-------------|-----------|-------------|-----------|
| Field 1 | presence | Presence detection status | Boolean |
| Field 2 | ambient_light | Ambient light level in lux | Float |
| Field 3 | brightness | Brightness percentage (0-100) | Integer |
| Field 4 | pwm_value | PWM duty cycle value | Integer |
| Field 5 | system_state | Current system state | String |
| Field 6 | active_time | Active time accumulator | Integer |
| Field 7 | idle_time | Idle time accumulator | Integer |
| Field 8 | sleep_time | Sleep time accumulator | Integer |

### Customizing Field Mapping

Edit `lib/config/thingspeak_config.dart` to customize field mapping:

```dart
static const FieldMapping fieldMapping = FieldMapping(
  presence: 1,        // Change to your field number
  ambientLight: 2,     // Change to your field number
  brightness: 3,       // Change to your field number
  pwmValue: 4,         // Change to your field number
  systemState: 5,      // Change to your field number
  activeTime: 6,       // Change to your field number
  idleTime: 7,         // Change to your field number
  sleepTime: 8,        // Change to your field number
);
```

---

## API Service

### ThingSpeakService

Location: `lib/services/thingspeak_service.dart`

### Methods

#### getLatestFeed()

Fetches the most recent feed entry from ThingSpeak.

```dart
Future<ThingSpeakFeed> getLatestFeed() async
```

**Returns**: ThingSpeakFeed with latest data

**Throws**: ThingSpeakException on failure

**Features**:
- Response caching (5 seconds)
- Automatic retry (3 attempts)
- Timeout handling (10 seconds)

#### getChannelFeed()

Fetches multiple feed entries from ThingSpeak.

```dart
Future<ThingSpeakFeedResponse> getChannelFeed({int results = 100}) async
```

**Parameters**:
- `results`: Number of results to retrieve (default: 100)

**Returns**: ThingSpeakFeedResponse with channel info and feeds

#### getChannelFeedWithTimeRange()

Fetches feed entries within a specified time range.

```dart
Future<ThingSpeakFeedResponse> getChannelFeedWithTimeRange({
  int? results,
  String? start,
  String? end,
}) async
```

**Parameters**:
- `results`: Maximum number of results
- `start`: Start datetime (ISO 8601 format)
- `end`: End datetime (ISO 8601 format)

#### getFieldFeed()

Fetches feed entries for a specific field only.

```dart
Future<ThingSpeakFieldFeed> getFieldFeed(
  int field, {
  int results = 100,
}) async
```

**Parameters**:
- `field`: Field number (1-8)
- `results`: Number of results to retrieve

#### getChannelStatus()

Retrieves current channel status information.

```dart
Future<ThingSpeakStatus> getChannelStatus() async
```

**Returns**: ThingSpeakStatus with channel status

#### testConnection()

Tests ThingSpeak connectivity.

```dart
Future<bool> testConnection() async
```

**Returns**: True if connected

---

## Data Models

### ThingSpeakFeed

Represents a single feed entry from ThingSpeak.

```dart
class ThingSpeakFeed {
  final int? entryId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> fields;
}
```

### Key Methods

- `getField(String parameter)`: Get field value by parameter name
- `getFieldAsString(String parameter)`: Get field as string
- `getFieldAsInt(String parameter)`: Get field as integer
- `getFieldAsDouble(String parameter)`: Get field as double
- `getFieldAsBool(String parameter)`: Get field as boolean
- `toSystemStatus()`: Convert to SystemStatus model

### ThingSpeakFeedResponse

Complete response containing channel info and feeds.

```dart
class ThingSpeakFeedResponse {
  final ThingSpeakChannel channel;
  final List<ThingSpeakFeed> feeds;
}
```

### ThingSpeakChannel

Channel information including metadata and field definitions.

```dart
class ThingSpeakChannel {
  final int id;
  final String name;
  final String? description;
  final Map<String, String> fieldNames;
}
```

---

## Provider Integration

### SystemProvider Updates

Location: `lib/providers/system_provider.dart`

### New State Variables

```dart
// ThingSpeak state
ThingSpeakFeed? _thingSpeakFeed;
ThingSpeakFeedResponse? _thingSpeakHistory;
bool _useThingSpeak = true;
bool _isThingSpeakConnected = false;
bool _isOffline = false;
```

### New Methods

#### refreshHistory()

Fetches historical data from ThingSpeak.

```dart
Future<void> refreshHistory({
  int results = 100,
  String? start,
  String? end,
}) async
```

#### toggleThingSpeak()

Enables or disables ThingSpeak integration.

```dart
void toggleThingSpeak(bool enabled)
```

#### _checkThingSpeakConnection()

Tests ThingSpeak connectivity.

```dart
Future<void> _checkThingSpeakConnection() async
```

#### _generateLogsFromThingSpeak()

Generates event logs from ThingSpeak feeds.

```dart
EventLogList _generateLogsFromThingSpeak(List<ThingSpeakFeed> feeds)
```

#### _calculateStatisticsFromThingSpeak()

Calculates statistics from ThingSpeak historical data.

```dart
Map<String, dynamic> _calculateStatisticsFromThingSpeak(List<ThingSpeakFeed> feeds)
```

### Modified Methods

#### refreshStatus()

Now fetches from ThingSpeak if enabled, with fallback to ESP32.

#### refreshLogs()

Generates logs from ThingSpeak historical data if enabled.

#### refreshStatistics()

Calculates statistics from ThingSpeak historical data if enabled.

#### startPolling()

Uses ThingSpeak update interval when ThingSpeak is enabled.

---

## UI Updates

### ThingSpeak Status Widget

Location: `lib/widgets/thingspeak_status.dart`

Displays ThingSpeak connection status with visual indicators.

**Features**:
- Compact mode for app bar
- Full mode for dashboard
- Color-coded status (green=connected, yellow=connecting, red=offline)
- Offline indicator
- Disabled state indicator

### Dashboard Screen Updates

Location: `lib/screens/dashboard_screen.dart`

**Changes**:
- Added ThingSpeak status widget to app bar
- Added ThingSpeak status card to dashboard
- Displays ThingSpeak connection status

### Statistics Screen Updates

Location: `lib/screens/statistics_screen.dart`

**Changes**:
- Added time range selector (Hour/Day/Week)
- Fetches historical data based on selected range
- Calculates statistics from ThingSpeak data

### Settings Screen Updates

Location: `lib/screens/settings_screen.dart`

**Changes**:
- Added data source toggle (ThingSpeak vs ESP32)
- Allows switching between data sources
- Displays current data source status

---

## Offline Handling

### Network Connectivity Monitoring

The application monitors network connectivity using `connectivity_plus`:

```dart
_connectivitySubscription = connectivity.onConnectivityChanged.listen(
  (ConnectivityResult result) {
    _isOffline = result == ConnectivityResult.none;
    if (_isOffline) {
      _isThingSpeakConnected = false;
    } else {
      _checkThingSpeakConnection();
    }
    notifyListeners();
  },
);
```

### Fallback Logic

When ThingSpeak is unavailable:

1. **Offline**: Automatically uses ESP32 direct connection
2. **ThingSpeak Error**: Attempts fallback to ESP32
3. **Both Fail**: Displays error message to user

### Caching

Latest feed is cached for 5 seconds to reduce API calls:

```dart
bool _isCacheValid() {
  if (_cachedFeed == null || _cacheTimestamp == null) {
    return false;
  }
  
  final age = DateTime.now().difference(_cacheTimestamp!);
  return age.inMilliseconds < ThingSpeakConfig.cacheDuration;
}
```

---

## Error Handling

### ThingSpeakException

Custom exception for ThingSpeak API errors.

```dart
class ThingSpeakException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
}
```

### Error Scenarios

| Scenario | Handling |
|-----------|----------|
| No Internet | Offline mode, ESP32 fallback |
| ThingSpeak Timeout | Retry with exponential backoff |
| Invalid API Key | Display error message, ESP32 fallback |
| Channel Not Found | Display error message, ESP32 fallback |
| Rate Limit Exceeded | Wait and retry, ESP32 fallback |
| Invalid JSON | Display error message, ESP32 fallback |

### User Feedback

Errors are displayed to users through:
- SnackBar messages
- Status indicators
- Error cards
- Connection status widgets

---

## Performance

### API Call Optimization

- **Caching**: Latest feed cached for 5 seconds
- **Polling Interval**: Configurable (default: 15 seconds)
- **Batch Requests**: Historical data fetched in single request
- **Retry Logic**: Exponential backoff reduces server load

### Memory Management

- **Stream Disposal**: All streams disposed in provider dispose
- **Timer Cancellation**: Polling timer cancelled when not needed
- **Service Disposal**: HTTP client closed on dispose

### Widget Rebuilds

- **Selective Updates**: Only relevant widgets rebuild on state change
- **Consumer Pattern**: Consumers only rebuild when accessed data changes
- **Const Widgets**: Static widgets marked as const

---

## Testing

### Manual Testing

#### 1. ThingSpeak Configuration

1. Update `lib/config/thingspeak_config.dart` with your credentials
2. Verify channel ID and API keys are correct
3. Ensure ESP32 is uploading data to ThingSpeak

#### 2. Connection Testing

1. Run application
2. Check Dashboard for ThingSpeak status widget
3. Verify green indicator (connected)
4. Check data is updating

#### 3. Offline Testing

1. Disable device Wi-Fi
2. Observe ThingSpeak status changes to offline
3. Verify ESP32 fallback is working
4. Re-enable Wi-Fi
5. Verify ThingSpeak reconnects automatically

#### 4. Historical Data Testing

1. Navigate to Statistics screen
2. Select different time ranges (Hour/Day/Week)
3. Verify charts update with historical data
4. Check statistics calculations

#### 5. Log Generation Testing

1. Navigate to Logs screen
2. Verify logs are generated from ThingSpeak data
3. Check event types (presence, brightness, state)
4. Verify timestamps are correct

#### 6. Data Source Toggle Testing

1. Navigate to Settings screen
2. Toggle ThingSpeak on/off
3. Verify data source changes
4. Check polling interval changes

### Automated Testing

#### Unit Tests

Test ThingSpeakService methods:

```dart
test('ThingSpeakService should parse feed correctly', () {
  final json = {
    'created_at': '2024-01-15T10:30:00Z',
    'field1': '1',
    'field2': '250.5',
    // ...
  };
  final feed = ThingSpeakFeed.fromJson(json);
  expect(feed.getFieldAsBool('presence'), true);
});
```

#### Widget Tests

Test ThingSpeak status widget:

```dart
testWidgets('ThingSpeakStatusWidget shows connected status', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => SystemProvider(),
        child: const ThingSpeakStatusWidget(),
      ),
    ),
  );
  expect(find.text('Connected'), findsOneWidget);
});
```

---

## Troubleshooting

### ThingSpeak Not Connecting

**Symptoms**: Status shows "Connecting" or "Offline"

**Solutions**:
1. Verify internet connection
2. Check channel ID and API key in config
3. Verify ThingSpeak service is operational
4. Check for rate limiting (ThingSpeak free tier: 1 req/sec)
5. Increase timeout in configuration

### Data Not Updating

**Symptoms**: Data remains static

**Solutions**:
1. Check polling interval (default: 15 seconds)
2. Verify ESP32 is uploading to ThingSpeak
3. Check field mapping matches ESP32 configuration
4. Verify ThingSpeak channel has recent data
5. Check cache duration (default: 5 seconds)

### Invalid Data Displayed

**Symptoms**: Values are incorrect or missing

**Solutions**:
1. Verify field mapping configuration
2. Check ESP32 field assignments
3. Verify data types match expected types
4. Check ThingSpeak field names
5. Review JSON parsing in models

### Statistics Incorrect

**Symptoms**: Statistics calculations are wrong

**Solutions**:
1. Verify historical data is being fetched
2. Check time range selection
3. Verify calculation logic in provider
4. Check for missing or null values
5. Verify feed count and interval calculations

### Logs Not Generated

**Symptoms**: Logs screen is empty

**Solutions**:
1. Verify historical data is being fetched
2. Check log generation logic in provider
3. Verify event detection thresholds
4. Check for sufficient historical data
5. Verify feed timestamps are valid

### Rate Limit Errors

**Symptoms**: "Rate Limit Exceeded" errors

**Solutions**:
1. Increase polling interval (minimum: 15 seconds)
2. Reduce number of concurrent requests
3. Implement request queuing
4. Consider ThingSpeak paid tier for higher limits

---

## Future Enhancements

### Planned Features

- **WebSocket Support**: Real-time push notifications
- **Multiple Channels**: Support for multiple ThingSpeak channels
- **Data Export**: Export historical data to CSV
- **Custom Charts**: Additional chart types and configurations
- **Alerts**: Configurable alerts for threshold violations
- **Cloud Sync**: Firebase synchronization for multi-device support

### Architecture Improvements

- **Repository Pattern**: Add repository layer for data access
- **Dependency Injection**: Use get_it for service injection
- **BLoC Pattern**: Consider BLoC for complex state management
- **Local Database**: SQLite for offline data persistence

---

## Summary

The ThingSpeak integration provides a robust, production-ready solution for cloud-based data retrieval and historical analysis. The integration maintains the existing application architecture while adding cloud capabilities with proper error handling, offline support, and user feedback.

### Key Benefits

- **Remote Monitoring**: Access data from anywhere
- **Historical Analysis**: View trends and patterns
- **Offline Support**: Graceful fallback to direct connection
- **Configurable**: Easy to customize field mapping and settings
- **Production-Ready**: Comprehensive error handling and retry logic

### Files Modified/Created

**Created**:
- `lib/config/thingspeak_config.dart`
- `lib/models/thingspeak_feed.dart`
- `lib/services/thingspeak_service.dart`
- `lib/widgets/thingspeak_status.dart`

**Modified**:
- `lib/providers/system_provider.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/statistics_screen.dart`
- `lib/screens/settings_screen.dart`

---

## References

- [ThingSpeak Documentation](https://www.mathworks.com/help/thingspeak/)
- [ThingSpeak API](https://thingspeak.com/docs/channels)
- [Flutter Provider](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)
