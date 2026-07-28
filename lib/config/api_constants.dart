/// API Constants
///
/// This file contains all API endpoint constants and configuration
/// for communication with the ESP32 embedded system.
///
/// Purpose: Centralize API endpoint definitions to ensure consistency
/// and ease of maintenance across the application.

/// Base URL for the ESP32 REST API
///
/// This should be configured to match your ESP32's IP address on the local network.
/// Default: 192.168.10.100 (the address used by the ESP32 setup in
/// `docs/THINGSPEAK_TESTING_GUIDE.md`). Override it at build time when your
/// ESP32 receives a different DHCP address:
/// `flutter run --dart-define=ESP32_HOST=192.168.x.x`
///
/// Usage: Modify this value to match your ESP32's actual IP address.
const String esp32Host =
    String.fromEnvironment('ESP32_HOST', defaultValue: '192.168.10.100');
String baseUrlForHost(String host) => 'http://$host';

/// API Endpoints
///
/// These constants define all available REST API endpoints exposed by the ESP32.
/// All endpoints return JSON responses.

/// GET /status
///
/// Retrieves the current system status including:
/// - Presence detection state
/// - Ambient light level (lux)
/// - Current brightness percentage
/// - PWM value
/// - Operating mode (auto/manual)
/// - Current state machine state
/// - Last updated timestamp
const String endpointStatus = '/status';

/// GET /logs
///
/// Retrieves the event log history containing:
/// - Timestamped events
/// - State changes
/// - Presence detection events
/// - Brightness adjustments
/// - Mode changes
const String endpointLogs = '/logs';

/// GET /statistics
///
/// Retrieves daily statistics including:
/// - Active time
/// - Idle time
/// - Sleep time
/// - Average brightness
/// - Number of presence events
/// - Total energy saving time
const String endpointStatistics = '/statistics';

/// POST /manual
///
/// Sends manual brightness control command to ESP32.
///
/// Request body (JSON):
/// ```json
/// {
///   "brightness": 75  // Value between 0-100
/// }
/// ```
///
/// Only valid when operating in manual mode.
const String endpointManual = '/manual';

/// POST /settings
///
/// Updates system configuration settings on ESP32.
///
/// Request body (JSON):
/// Firmware v6 expects `luxThresholdOn`, `luxThresholdOff`, `fadeSpeed`, and
/// the millisecond timeout fields `timeBeforeDim1Ms`, `timeBeforeDim2Ms`,
/// `timeBeforeDim3Ms`, and `timeBeforeOffMs`.
const String endpointSettings = '/settings';

/// POST /mode
///
/// Changes the operating mode of the system.
///
/// Request body (JSON):
/// ```json
/// {
///   "mode": "auto"  // or "manual"
/// }
/// ```
const String endpointMode = '/mode';

/// Network Configuration
///
/// Connection timeout and retry settings for API requests.

/// Request timeout in milliseconds
///
/// If no response is received within this time, the request is cancelled.
const int connectionTimeout = 10000;

/// Number of retry attempts for failed requests
///
/// The application will automatically retry failed requests this many times.
const int maxRetries = 3;

/// Delay between retry attempts in milliseconds
///
/// Wait time before attempting a retry after a failed request.
const int retryDelay = 1000;

/// Polling interval for live monitoring in milliseconds
///
/// The live monitoring screen will fetch updates at this interval.
const int pollingInterval = 1000;
