# Smart Light - Adaptive Intelligent Energy-Efficient Lighting System

## Flutter Mobile Application for ESP32-Based Intelligent Lighting Control

A production-quality Flutter application for monitoring and controlling an adaptive intelligent energy-efficient lighting system using ESP32, HLK-LD2410B presence sensor, BH1750 ambient light sensor, and XY-MOS PWM driver.

---

## Table of Contents

- [Project Overview](#project-overview)
- [System Architecture](#system-architecture)
- [Features](#features)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Installation Guide](#installation-guide)
- [Configuration](#configuration)
- [ThingSpeak Integration](#thingspeak-integration)
- [Running the Application](#running-the-application)
- [Building APK](#building-apk)
- [API Documentation](#api-documentation)
- [Testing Guide](#testing-guide)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Technical Details](#technical-details)
- [Future Improvements](#future-improvements)
- [License](#license)

---

## Project Overview

This Flutter application serves as the intelligent monitoring and remote control interface for an embedded lighting system. The ESP32 acts as the master controller, handling presence detection, ambient light measurement, automatic brightness control, time-based intelligent dimming, and PWM LED control. The Flutter application provides real-time monitoring, manual control, settings configuration, and statistical analysis.

### Key Characteristics

- **Production-Ready**: Scalable, modular, professionally documented code
- **Clean Architecture**: Separation of concerns with SOLID principles
- **Material 3 Design**: Modern UI with light/dark theme support
- **Real-Time Monitoring**: Live updates every second
- **Robust Error Handling**: Graceful handling of network failures
- **State Management**: Provider pattern for reactive state updates

---

## System Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │   Widgets    │  │  Providers   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
│                    ┌───────▼────────┐                       │
│                    │   Services     │                       │
│                    │  - API Service │                       │
│                    │  - Connection   │                       │
│                    └───────┬────────┘                       │
│                            │                                 │
│                    ┌───────▼────────┐                       │
│                    │   Models       │                       │
│                    │  - SystemStatus │                       │
│                    │  - EventLog    │                       │
│                    │  - Settings    │                       │
│                    └───────┬────────┘                       │
└────────────────────────────┼────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Wi-Fi Network │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │     ESP32       │
                    │  - REST API    │
                    │  - Sensors     │
                    │  - PWM Control │
                    └─────────────────┘
```

### Data Flow

1. **ESP32** continuously monitors sensors and updates system state
2. **Flutter App** polls ESP32 via REST API at regular intervals
3. **API Service** handles HTTP communication with retry logic
4. **Connection Service** monitors connectivity and handles reconnection
5. **System Provider** manages application state and notifies UI
6. **UI Components** reactively update based on state changes

---

## Features

### Core Features

- **Splash Screen**: Animated loading with connection check
- **Dashboard**: At-a-glance system overview with animated light bulb
- **Live Monitoring**: Real-time updates every second
- **Manual Control**: Mode switching and brightness slider
- **Settings**: Threshold and timeout configuration
- **Statistics**: Daily usage analytics with charts
- **Event Logs**: Chronological event history with filtering

### Technical Features

- **REST API Integration**: JSON-based communication with ESP32
- **Automatic Reconnection**: Exponential backoff retry logic
- **Connection Monitoring**: Real-time connectivity status
- **Error Handling**: User-friendly error messages
- **Material 3 Design**: Modern, responsive UI
- **Dark/Light Themes**: System theme support
- **Smooth Animations**: Page transitions and state changes
- **Pull-to-Refresh**: Manual refresh on all data screens

---

## Hardware Requirements

### Embedded System Components

- **ESP32 Dev Module**: Microcontroller with Wi-Fi
- **HLK-LD2410B**: mmWave presence sensor
- **BH1750**: Digital ambient light sensor (I2C)
- **XY-MOS**: MOSFET PWM driver module
- **LED Strip**: 12V/24V LED strip
- **Power Supply**: External power for LED strip

### Mobile Device Requirements

- **Android**: 5.0 (API Level 21) or higher
- **iOS**: 11.0 or higher
- **RAM**: Minimum 2GB recommended
- **Storage**: 50MB free space

---

## Software Requirements

### Development Environment

- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Dependencies

See `pubspec.yaml` for complete dependency list:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  http: ^1.1.0              # HTTP requests
  connectivity_plus: ^5.0.2 # Network connectivity
  flutter_svg: ^2.0.9       # SVG support
  fl_chart: ^0.66.0         # Charts
  shimmer: ^3.0.0           # Loading animations
  intl: ^0.18.1             # Internationalization
  shared_preferences: ^2.2.2 # Local storage
  cupertino_icons: ^1.0.6   # iOS-style icons
```

---

## Installation Guide

### Prerequisites

1. Install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Set up your preferred IDE (VS Code, Android Studio, or IntelliJ)
3. Ensure development environment is configured:
   ```bash
   flutter doctor
   ```

### Clone Repository

```bash
git clone <repository-url>
cd smart_light
```

### Install Dependencies

```bash
flutter pub get
```

### Configure ESP32 IP Address

Edit `lib/config/api_constants.dart`:

```dart
const String baseUrl = 'http://YOUR_ESP32_IP_ADDRESS';
```

Replace `YOUR_ESP32_IP_ADDRESS` with your ESP32's actual IP address on your local network.

---

## Configuration

### API Configuration

Located in `lib/config/api_constants.dart`:

- **baseUrl**: ESP32 IP address
- **connectionTimeout**: Request timeout (default: 5000ms)
- **maxRetries**: Maximum retry attempts (default: 3)
- **retryDelay**: Delay between retries (default: 1000ms)
- **pollingInterval**: Live monitoring interval (default: 1000ms)

### Theme Configuration

Located in `lib/utils/constants.dart`:

- **Primary Color**: Deep Blue (#1565C0)
- **Accent Color**: Amber (#FFA000)
- **Success Color**: Green (#4CAF50)
- **Warning Color**: Orange (#FF9800)
- **Error Color**: Red (#F44336)

### Default Settings

Located in `lib/utils/constants.dart`:

- **Dark Threshold**: 50 lux
- **Bright Threshold**: 500 lux
- **Dim Level 1 Timeout**: 300 seconds (5 minutes)
- **Dim Level 2 Timeout**: 600 seconds (10 minutes)
- **Sleep Timeout**: 1800 seconds (30 minutes)
- **Fade Speed**: 10
- **PWM Frequency**: 1000 Hz

---

## ThingSpeak Integration

### Overview

The application now includes ThingSpeak Cloud integration for remote data access and historical analysis. ThingSpeak provides cloud-based data storage and visualization, enabling the application to retrieve live sensor data and historical statistics from the cloud.

### Configuration

Located in `lib/config/thingspeak_config.dart`:

Update the following values with your ThingSpeak channel details:

```dart
static const String channelId = 'YOUR_CHANNEL_ID';
static const String readApiKey = 'YOUR_READ_API_KEY';
static const String writeApiKey = 'YOUR_WRITE_API_KEY';
```

### Field Mapping

Default field mapping (configurable in `thingspeak_config.dart`):

| Field Number | Parameter | Description |
|-------------|-----------|-------------|
| Field 1 | presence | Presence detection status |
| Field 2 | ambient_light | Ambient light level (lux) |
| Field 3 | brightness | Brightness percentage (0-100) |
| Field 4 | pwm_value | PWM duty cycle value |
| Field 5 | system_state | Current system state |
| Field 6 | active_time | Active time accumulator |
| Field 7 | idle_time | Idle time accumulator |
| Field 8 | sleep_time | Sleep time accumulator |

### Features

- **Live Data Fetching**: Automatic polling at configurable intervals (default: 15 seconds)
- **Historical Data**: Time-range selectable historical data (Hour/Day/Week)
- **Offline Support**: Graceful fallback to direct ESP32 connection
- **Connection Monitoring**: Real-time ThingSpeak connectivity status
- **Data Source Toggle**: Switch between ThingSpeak and ESP32 in Settings
- **Statistics Calculation**: Automatic statistics from historical data
- **Log Generation**: Event logs derived from historical feeds

### Getting Started with ThingSpeak

1. **Create ThingSpeak Account**: Visit [thingspeak.com](https://thingspeak.com)
2. **Create Channel**: Create a new channel with 8 fields
3. **Configure ESP32**: Update ESP32 firmware to upload data to ThingSpeak
4. **Update Configuration**: Edit `lib/config/thingspeak_config.dart` with your credentials
5. **Run Application**: The app will automatically use ThingSpeak if enabled

### Data Source Toggle

Navigate to **Settings** screen to toggle between:
- **ThingSpeak Cloud**: Receive data from ThingSpeak (requires internet)
- **ESP32 Direct**: Direct connection to ESP32 (local network only)

### Documentation

For detailed ThingSpeak integration documentation, see:
- [ThingSpeak Integration Guide](docs/THINGSPEAK_INTEGRATION.md)
- [ThingSpeak Testing Guide](docs/THINGSPEAK_TESTING_GUIDE.md)

---

## Running the Application

### Development Mode

#### Android

```bash
# Ensure device is connected
flutter devices

# Run on connected device
flutter run

# Run on specific device
flutter run -d <device-id>
```

#### iOS (macOS only)

```bash
# Ensure simulator or device is connected
flutter devices

# Run on connected device/simulator
flutter run

# Open in Xcode
open ios/Runner.xcworkspace
```

### Release Mode

```bash
# Run in release mode
flutter run --release
```

### Hot Reload

While the app is running, press:
- **r**: Hot reload
- **R**: Hot restart
- **q**: Quit
- **h**: Help

---

## Building APK

### Android APK

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build split APKs (per ABI)
flutter build apk --split-per-abi

# Output location: build/app/outputs/flutter-apk/
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release

# Output location: build/app/outputs/bundle/release/
```

### iOS IPA (macOS only)

```bash
# Build for iOS
flutter build ios --release

# Then use Xcode to archive and distribute
open ios/Runner.xcworkspace
```

---

## API Documentation

### Endpoints

#### GET /status

Retrieves current system status.

**Response:**
```json
{
  "presence": true,
  "ambient_light": 250.5,
  "brightness": 75,
  "pwm_value": 192,
  "mode": "auto",
  "state": "active",
  "last_updated": "2024-01-15T10:30:00Z",
  "connection_status": "connected"
}
```

#### GET /logs

Retrieves event log history.

**Response:**
```json
[
  {
    "id": "evt_12345",
    "timestamp": "2024-01-15T10:30:00Z",
    "event_type": "presence",
    "message": "Presence Detected",
    "details": "Target detected at 2.5m"
  }
]
```

#### GET /statistics

Retrieves daily statistics.

**Response:**
```json
{
  "active_time": 14400,
  "idle_time": 7200,
  "sleep_time": 14400,
  "avg_brightness": 65.5,
  "presence_events": 45,
  "energy_saving_time": 21600
}
```

#### POST /manual

Sends manual brightness command.

**Request:**
```json
{
  "brightness": 75
}
```

#### POST /settings

Updates system settings.

**Request:**
```json
{
  "dark_threshold": 50,
  "bright_threshold": 500,
  "dim_level_1_timeout": 300,
  "dim_level_2_timeout": 600,
  "sleep_timeout": 1800,
  "fade_speed": 10,
  "pwm_frequency": 1000
}
```

#### POST /mode

Changes operating mode.

**Request:**
```json
{
  "mode": "auto"
}
```

#### POST /calibrate

Triggers ambient light calibration.

**Request:**
```json
{}
```

For detailed API documentation, see [API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md).

---

## Testing Guide

### Connection Testing

1. Ensure ESP32 is powered and connected to Wi-Fi
2. Verify ESP32 IP address in network settings
3. Update `baseUrl` in `api_constants.dart`
4. Run application and observe splash screen
5. Verify connection status indicator shows "Connected"

### Live Monitoring Testing

1. Navigate to Live Monitor screen
2. Observe real-time updates every second
3. Trigger presence detection near sensor
4. Verify presence indicator updates
5. Cover ambient light sensor
6. Verify ambient light value changes

### Manual Mode Testing

1. Navigate to Manual Control screen
2. Switch to Manual Mode
3. Adjust brightness slider
4. Verify LED brightness changes
5. Test quick preset buttons (25%, 50%, 75%, 100%)
6. Switch back to Auto Mode
7. Verify slider is disabled

### Auto Mode Testing

1. Ensure system is in Auto Mode
2. Trigger presence detection
3. Observe automatic brightness adjustment
4. Wait for dim level timeout
5. Verify brightness decreases
6. Wait for sleep timeout
7. Verify system enters sleep mode

### Settings Testing

1. Navigate to Settings screen
2. Modify dark threshold
3. Tap "Save Settings"
4. Verify success message
5. Test "Restore Defaults"
6. Verify confirmation dialog
7. Confirm restoration
8. Test "Calibrate Ambient Light"
9. Verify calibration success

### API Error Testing

1. Disconnect ESP32 from power
2. Run application
3. Observe error handling
4. Verify "Disconnected" status
5. Reconnect ESP32
6. Verify automatic reconnection

### Offline Mode Testing

1. Disable device Wi-Fi
2. Run application
3. Observe offline behavior
4. Verify graceful degradation
5. Re-enable Wi-Fi
6. Verify automatic recovery

---

## Troubleshooting

### Connection Issues

**Problem**: Application shows "Disconnected" status

**Solutions**:
1. Verify ESP32 is powered on
2. Check ESP32 Wi-Fi connection
3. Confirm ESP32 IP address is correct
4. Ensure device and ESP32 are on same network
5. Check firewall settings
6. Try pinging ESP32 IP from device

**Debug Commands**:
```bash
# Ping ESP32
ping <ESP32_IP>

# Check network connectivity
flutter pub run connectivity_plus
```

### API Timeout Issues

**Problem**: Requests timing out frequently

**Solutions**:
1. Increase `connectionTimeout` in `api_constants.dart`
2. Increase `maxRetries` count
3. Check ESP32 response time
4. Verify Wi-Fi signal strength
5. Reduce polling interval

### Build Errors

**Problem**: Flutter build fails

**Solutions**:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Update Flutter SDK: `flutter upgrade`
4. Clear Gradle cache (Android): `cd android && ./gradlew clean`
5. Clear Pod cache (iOS): `cd ios && pod deintegrate && pod install`

### Theme Issues

**Problem**: Dark mode not working correctly

**Solutions**:
1. Verify theme configuration in `main.dart`
2. Check color constants in `constants.dart`
3. Ensure Material 3 is enabled
4. Test on different devices

### Chart Rendering Issues

**Problem**: Statistics charts not displaying

**Solutions**:
1. Verify `fl_chart` dependency version
2. Check statistics data format
3. Ensure data values are within valid ranges
4. Test with sample data

---

## Project Structure

```
lib/
│
├── main.dart                      # Application entry point
│
├── config/                        # Configuration files
│   └── api_constants.dart         # API endpoints and constants
│
├── models/                        # Data models
│   ├── system_status.dart         # System status model
│   ├── event_log.dart             # Event log model
│   └── settings.dart              # Settings model
│
├── services/                      # Business logic services
│   ├── api_service.dart           # HTTP API communication
│   └── connection_service.dart   # Connection management
│
├── providers/                     # State management
│   └── system_provider.dart      # System state provider
│
├── screens/                       # UI screens
│   ├── splash_screen.dart         # Splash/loading screen
│   ├── dashboard_screen.dart      # Main dashboard
│   ├── live_monitor_screen.dart   # Live monitoring
│   ├── manual_control_screen.dart # Manual control
│   ├── settings_screen.dart       # Settings configuration
│   ├── statistics_screen.dart     # Statistics and charts
│   └── logs_screen.dart           # Event logs
│
├── widgets/                       # Reusable widgets
│   ├── sensor_card.dart           # Sensor data card
│   ├── brightness_card.dart       # Brightness display card
│   ├── state_indicator.dart       # State indicator widget
│   ├── connection_status.dart    # Connection status widget
│   ├── animated_light.dart       # Animated light bulb
│   ├── custom_button.dart        # Custom button component
│   └── custom_slider.dart        # Custom slider component
│
└── utils/                         # Utilities
    ├── constants.dart            # App constants
    └── helpers.dart              # Helper functions
```

---

## Technical Details

### Architecture Pattern

The application follows **Clean Architecture** principles:

- **Presentation Layer**: Screens and Widgets
- **Business Logic Layer**: Providers and Services
- **Data Layer**: Models and API Service
- **Utility Layer**: Constants and Helpers

### State Management

Uses the **Provider** pattern for reactive state management:

- **SystemProvider**: Central state management
- **ChangeNotifier**: Notifies UI of state changes
- **Consumer**: Consumes state in UI components

### Networking

- **HTTP Client**: Dart `http` package
- **Retry Logic**: Exponential backoff
- **Timeout Handling**: Configurable timeouts
- **Error Handling**: Custom ApiException

### Design System

- **Material 3**: Latest Material Design
- **Color Palette**: Consistent theming
- **Typography**: Roboto font family
- **Spacing**: Consistent spacing system
- **Animations**: Smooth transitions

### Code Quality

- **SOLID Principles**: Single responsibility, Open/closed, etc.
- **DRY**: Don't repeat yourself
- **Documentation**: Comprehensive code comments
- **Type Safety**: Strong typing with Dart
- **Null Safety**: Dart null safety enabled

---

## Future Improvements

### Planned Features

- [ ] Push notifications for system alerts
- [ ] Multiple ESP32 support
- [ ] Cloud synchronization
- [ ] User authentication
- [ ] Scheduling and automation
- [ ] Energy consumption analytics
- [ ] Historical data export
- [ ] Widget support (home screen widgets)
- [ ] Voice control integration
- [ ] Multi-language support

### Technical Improvements

- [ ] WebSocket support for real-time updates
- [ ] Offline data caching
- [ ] Background service for monitoring
- [ ] Unit and integration tests
- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] Custom theming support

---

## License

This project is developed as a final-year Computer Science embedded systems project.

**Project Title**: Adaptive Intelligent Energy-Efficient Lighting System Using ESP32, HLK-LD2410B Presence Sensor, BH1750 Ambient Light Sensor, XY-MOS Driver Module, and Flutter Mobile Application

**Version**: 1.0.0

**Date**: 2024

---

## Contact

For questions or support regarding this project, please refer to the project documentation or contact the development team.

---

## Acknowledgments

- Flutter team for the excellent framework
- ESP32 community for hardware support
- HLK-LD2410B sensor documentation
- BH1750 sensor datasheet
- Material Design guidelines

---

**Note**: This application is designed to work with a specific embedded system implementation. Ensure your ESP32 firmware implements the required REST API endpoints as documented in the API documentation.
