/// System Status Model
///
/// This model represents the current status of the intelligent lighting system
/// as reported by the ESP32 embedded controller.
///
/// Purpose: Provide a structured representation of system state for
/// type-safe data handling and JSON serialization/deserialization.
library;

import 'package:smart_light/utils/constants.dart';

/// SystemStatus
///
/// Data class containing all current system metrics and state information.
///
/// Fields:
/// - [presence]: Boolean indicating if presence is detected (true) or not (false)
/// - [ambientLight]: Ambient light level in lux (typically 0-65535)
/// - [brightness]: Current brightness percentage (0-100)
/// - [pwmValue]: Current PWM duty cycle value (0-255 or 0-1023 depending on ESP32 configuration)
/// - [mode]: Current operating mode ('auto' or 'manual')
/// - [state]: Current state machine state ('active', 'dim1', 'dim2', 'sleep', 'off')
/// - [lastUpdated]: ISO 8601 timestamp of last status update
/// - [connectionStatus]: Connection status to ESP32 ('connected', 'disconnected', 'connecting')
class SystemStatus {
  final bool presence;
  final double ambientLight;
  final int brightness;
  final int pwmValue;
  final String mode;
  final String state;
  final DateTime lastUpdated;
  final String connectionStatus;

  /// Constructor
  ///
  /// Creates a new SystemStatus instance with the provided values.
  ///
  /// Parameters:
  /// - [presence]: Presence detection state
  /// - [ambientLight]: Ambient light level in lux
  /// - [brightness]: Brightness percentage (0-100)
  /// - [pwmValue]: PWM duty cycle value
  /// - [mode]: Operating mode
  /// - [state]: System state
  /// - [lastUpdated]: Last update timestamp
  /// - [connectionStatus]: Connection status
  const SystemStatus({
    required this.presence,
    required this.ambientLight,
    required this.brightness,
    required this.pwmValue,
    required this.mode,
    required this.state,
    required this.lastUpdated,
    required this.connectionStatus,
  });

  /// Factory constructor for creating SystemStatus from JSON
  ///
  /// Parses a JSON map received from the ESP32 API and creates
  /// a SystemStatus instance.
  ///
  /// Parameters:
  /// - [json]: Map containing JSON data from API response
  ///
  /// Returns: SystemStatus instance
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "presence": true,
  ///   "ambient_light": 250.5,
  ///   "brightness": 75,
  ///   "pwm_value": 192,
  ///   "mode": "auto",
  ///   "state": "active",
  ///   "last_updated": "2024-01-15T10:30:00Z"
  /// }
  /// ```
  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      presence: _asBool(json['presence']),
      // ESP32 /status uses `lux`; ThingSpeak uses `ambient_light`.
      ambientLight: _asDouble(json['ambient_light'] ?? json['lux']),
      // ESP32 /status reports a percentage as `brightnessPercent`.
      brightness: _asInt(json['brightness'] ?? json['brightnessPercent']),
      pwmValue: _asInt(json['pwm_value'] ?? json['pwm']),
      mode: json['mode'] as String? ?? OperatingMode.auto,
      state: _normaliseState(json['state']),
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      // A successful direct /status response is itself proof of connection.
      connectionStatus: json['connection_status'] as String? ?? 'connected',
    );
  }

  static bool _asBool(dynamic value) => value is bool
      ? value
      : value is num
          ? value != 0
          : value?.toString().toLowerCase() == 'true' ||
              value?.toString() == '1';

  static double _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.0;

  static int _asInt(dynamic value) => value is num
      ? value.round()
      : (double.tryParse(value?.toString() ?? '') ?? 0).round();

  static String _normaliseState(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case '0':
      case 'active':
        return 'active';
      case '1':
      case 'dim_level_1':
      case 'dim1':
        return 'dim1';
      case '2':
      case 'dim_level_2':
      case 'dim2':
        return 'dim2';
      case '3':
      case 'dim_level_3':
      case 'dim3':
        return 'dim3';
      case '4':
      case 'sleep':
        return 'sleep';
      default:
        return SystemState.off;
    }
  }

  /// Convert SystemStatus to JSON
  ///
  /// Serializes the SystemStatus instance to a JSON map.
  ///
  /// Returns: Map containing serialized data
  Map<String, dynamic> toJson() {
    return {
      'presence': presence,
      'ambient_light': ambientLight,
      'brightness': brightness,
      'pwm_value': pwmValue,
      'mode': mode,
      'state': state,
      'last_updated': lastUpdated.toIso8601String(),
      'connection_status': connectionStatus,
    };
  }

  /// Create a copy with updated fields
  ///
  /// Creates a new SystemStatus instance with specified fields updated.
  /// Useful for immutable state updates.
  ///
  /// Parameters:
  /// - [presence]: Optional new presence value
  /// - [ambientLight]: Optional new ambient light value
  /// - [brightness]: Optional new brightness value
  /// - [pwmValue]: Optional new PWM value
  /// - [mode]: Optional new mode value
  /// - [state]: Optional new state value
  /// - [lastUpdated]: Optional new timestamp
  /// - [connectionStatus]: Optional new connection status
  ///
  /// Returns: New SystemStatus instance with updated fields
  SystemStatus copyWith({
    bool? presence,
    double? ambientLight,
    int? brightness,
    int? pwmValue,
    String? mode,
    String? state,
    DateTime? lastUpdated,
    String? connectionStatus,
  }) {
    return SystemStatus(
      presence: presence ?? this.presence,
      ambientLight: ambientLight ?? this.ambientLight,
      brightness: brightness ?? this.brightness,
      pwmValue: pwmValue ?? this.pwmValue,
      mode: mode ?? this.mode,
      state: state ?? this.state,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  /// Create default/disconnected SystemStatus
  ///
  /// Returns a SystemStatus instance representing a disconnected state
  /// with default values.
  ///
  /// Returns: SystemStatus with default disconnected values
  static SystemStatus disconnected() {
    return SystemStatus(
      presence: false,
      ambientLight: 0.0,
      brightness: 0,
      pwmValue: 0,
      mode: OperatingMode.auto,
      state: SystemState.off,
      lastUpdated: DateTime.now(),
      connectionStatus: 'disconnected',
    );
  }

  /// Check if system is connected
  ///
  /// Returns true if connection status is 'connected'.
  ///
  /// Returns: Boolean indicating connection status
  bool get isConnected => connectionStatus == 'connected';

  /// Check if system is in auto mode
  ///
  /// Returns true if operating mode is 'auto'.
  ///
  /// Returns: Boolean indicating auto mode
  bool get isAutoMode => mode == OperatingMode.auto;

  /// Check if system is in manual mode
  ///
  /// Returns true if operating mode is 'manual'.
  ///
  /// Returns: Boolean indicating manual mode
  bool get isManualMode => mode == OperatingMode.manual;

  @override
  String toString() {
    return 'SystemStatus(presence: $presence, ambientLight: $ambientLight, '
        'brightness: $brightness, pwmValue: $pwmValue, mode: $mode, '
        'state: $state, lastUpdated: $lastUpdated, '
        'connectionStatus: $connectionStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SystemStatus &&
        other.presence == presence &&
        other.ambientLight == ambientLight &&
        other.brightness == brightness &&
        other.pwmValue == pwmValue &&
        other.mode == mode &&
        other.state == state &&
        other.lastUpdated == lastUpdated &&
        other.connectionStatus == connectionStatus;
  }

  @override
  int get hashCode {
    return presence.hashCode ^
        ambientLight.hashCode ^
        brightness.hashCode ^
        pwmValue.hashCode ^
        mode.hashCode ^
        state.hashCode ^
        lastUpdated.hashCode ^
        connectionStatus.hashCode;
  }
}
