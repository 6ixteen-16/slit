/// Settings Model
///
/// This model represents the configuration settings for the intelligent
/// lighting system.
///
/// Purpose: Provide a structured representation of system settings for
/// configuration management and persistence.
library;

import 'package:smart_light/utils/constants.dart';

/// Settings
///
/// Data class containing all configurable system parameters.
///
/// Fields:
/// - [darkThreshold]: Ambient light threshold for dark conditions (lux)
/// - [brightThreshold]: Ambient light threshold for bright conditions (lux)
/// - [dimLevel1Timeout]: Timeout before entering dim level 1 (seconds)
/// - [dimLevel2Timeout]: Timeout before entering dim level 2 (seconds)
/// - [dimLevel3Timeout]: Timeout before entering dim level 3 (seconds)
/// - [sleepTimeout]: Timeout before entering sleep mode (seconds)
/// - [fadeSpeed]: Speed of brightness transitions (arbitrary units)
class Settings {
  final int darkThreshold;
  final int brightThreshold;
  final int dimLevel1Timeout;
  final int dimLevel2Timeout;
  final int dimLevel3Timeout;
  final int sleepTimeout;
  final int fadeSpeed;

  /// Constructor
  ///
  /// Creates a new Settings instance with the provided values.
  ///
  /// Parameters:
  /// - [darkThreshold]: Dark ambient light threshold (lux)
  /// - [brightThreshold]: Bright ambient light threshold (lux)
  /// - [dimLevel1Timeout]: Dim level 1 timeout (seconds)
  /// - [dimLevel2Timeout]: Dim level 2 timeout (seconds)
  /// - [dimLevel3Timeout]: Dim level 3 timeout (seconds)
  /// - [sleepTimeout]: Sleep mode timeout (seconds)
  /// - [fadeSpeed]: Fade transition speed
  const Settings({
    required this.darkThreshold,
    required this.brightThreshold,
    required this.dimLevel1Timeout,
    required this.dimLevel2Timeout,
    required this.dimLevel3Timeout,
    required this.sleepTimeout,
    required this.fadeSpeed,
  });

  /// Factory constructor for creating Settings from JSON
  ///
  /// Parses a JSON map received from the ESP32 API and creates
  /// a Settings instance.
  ///
  /// Parameters:
  /// - [json]: Map containing JSON data from API response
  ///
  /// Returns: Settings instance
  ///
  /// Supports the legacy app shape if settings are restored locally. The v6
  /// firmware has no GET /settings endpoint; updates use [toJson].
  /// ```json
  /// {
  ///   "dark_threshold": 25,
  ///   "bright_threshold": 35,
  ///   "dim_level_1_timeout": 10,
  ///   "dim_level_2_timeout": 30,
  ///   "dim_level_3_timeout": 60,
  ///   "sleep_timeout": 120,
  ///   "fade_speed": 5
  /// }
  /// ```
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      darkThreshold:
          json['dark_threshold'] as int? ?? DefaultSettings.darkThreshold,
      brightThreshold:
          json['bright_threshold'] as int? ?? DefaultSettings.brightThreshold,
      dimLevel1Timeout: json['dim_level_1_timeout'] as int? ??
          DefaultSettings.dimLevel1Timeout,
      dimLevel2Timeout: json['dim_level_2_timeout'] as int? ??
          DefaultSettings.dimLevel2Timeout,
      dimLevel3Timeout: json['dim_level_3_timeout'] as int? ??
          DefaultSettings.dimLevel3Timeout,
      sleepTimeout:
          json['sleep_timeout'] as int? ?? DefaultSettings.sleepTimeout,
      fadeSpeed: json['fade_speed'] as int? ?? DefaultSettings.fadeSpeed,
    );
  }

  /// Convert Settings to JSON
  ///
  /// Serializes the Settings instance to a JSON map.
  ///
  /// Returns: Map containing serialized data
  Map<String, dynamic> toJson() {
    return {
      // ESP32 v6 accepts camelCase values and all timeouts are milliseconds.
      // The app collects them as seconds for a friendlier UI.
      'luxThresholdOn': darkThreshold,
      'luxThresholdOff': brightThreshold,
      'timeBeforeDim1Ms': dimLevel1Timeout * 1000,
      'timeBeforeDim2Ms': dimLevel2Timeout * 1000,
      'timeBeforeDim3Ms': dimLevel3Timeout * 1000,
      'timeBeforeOffMs': sleepTimeout * 1000,
      'fadeSpeed': fadeSpeed,
    };
  }

  /// Create a copy with updated fields
  ///
  /// Creates a new Settings instance with specified fields updated.
  /// Useful for immutable state updates.
  ///
  /// Parameters:
  /// - [darkThreshold]: Optional new dark threshold
  /// - [brightThreshold]: Optional new bright threshold
  /// - [dimLevel1Timeout]: Optional new dim level 1 timeout
  /// - [dimLevel2Timeout]: Optional new dim level 2 timeout
  /// - [dimLevel3Timeout]: Optional new dim level 3 timeout
  /// - [sleepTimeout]: Optional new sleep timeout
  /// - [fadeSpeed]: Optional new fade speed
  ///
  /// Returns: New Settings instance with updated fields
  Settings copyWith({
    int? darkThreshold,
    int? brightThreshold,
    int? dimLevel1Timeout,
    int? dimLevel2Timeout,
    int? dimLevel3Timeout,
    int? sleepTimeout,
    int? fadeSpeed,
  }) {
    return Settings(
      darkThreshold: darkThreshold ?? this.darkThreshold,
      brightThreshold: brightThreshold ?? this.brightThreshold,
      dimLevel1Timeout: dimLevel1Timeout ?? this.dimLevel1Timeout,
      dimLevel2Timeout: dimLevel2Timeout ?? this.dimLevel2Timeout,
      dimLevel3Timeout: dimLevel3Timeout ?? this.dimLevel3Timeout,
      sleepTimeout: sleepTimeout ?? this.sleepTimeout,
      fadeSpeed: fadeSpeed ?? this.fadeSpeed,
    );
  }

  /// Create default Settings
  ///
  /// Returns a Settings instance with default values.
  ///
  /// Returns: Settings with default values
  static Settings defaultSettings() {
    return const Settings(
      darkThreshold: DefaultSettings.darkThreshold,
      brightThreshold: DefaultSettings.brightThreshold,
      dimLevel1Timeout: DefaultSettings.dimLevel1Timeout,
      dimLevel2Timeout: DefaultSettings.dimLevel2Timeout,
      dimLevel3Timeout: DefaultSettings.dimLevel3Timeout,
      sleepTimeout: DefaultSettings.sleepTimeout,
      fadeSpeed: DefaultSettings.fadeSpeed,
    );
  }

  /// Validate settings
  ///
  /// Checks if all settings values are within valid ranges.
  ///
  /// Returns: Boolean indicating validity
  bool get isValid {
    return darkThreshold >= 0 &&
        darkThreshold <= 65535 &&
        brightThreshold >= 0 &&
        brightThreshold <= 65535 &&
        brightThreshold > darkThreshold &&
        dimLevel1Timeout >= 0 &&
        dimLevel1Timeout <= 86400 &&
        dimLevel2Timeout >= 0 &&
        dimLevel2Timeout <= 86400 &&
        dimLevel2Timeout > dimLevel1Timeout &&
        dimLevel3Timeout >= 0 &&
        dimLevel3Timeout <= 86400 &&
        dimLevel3Timeout > dimLevel2Timeout &&
        sleepTimeout >= 0 &&
        sleepTimeout <= 86400 &&
        sleepTimeout > dimLevel3Timeout &&
        fadeSpeed >= 1 &&
        fadeSpeed <= 100;
  }

  /// Get dim level 1 timeout in minutes
  ///
  /// Returns the dim level 1 timeout converted to minutes.
  ///
  /// Returns: Timeout in minutes
  int get dimLevel1TimeoutMinutes => (dimLevel1Timeout / 60).round();

  /// Get dim level 2 timeout in minutes
  ///
  /// Returns the dim level 2 timeout converted to minutes.
  ///
  /// Returns: Timeout in minutes
  int get dimLevel2TimeoutMinutes => (dimLevel2Timeout / 60).round();

  /// Get sleep timeout in minutes
  ///
  /// Returns the sleep timeout converted to minutes.
  ///
  /// Returns: Timeout in minutes
  int get sleepTimeoutMinutes => (sleepTimeout / 60).round();

  @override
  String toString() {
    return 'Settings(darkThreshold: $darkThreshold, brightThreshold: $brightThreshold, '
        'dimLevel1Timeout: $dimLevel1Timeout, dimLevel2Timeout: $dimLevel2Timeout, '
        'dimLevel3Timeout: $dimLevel3Timeout, sleepTimeout: $sleepTimeout, '
        'fadeSpeed: $fadeSpeed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Settings &&
        other.darkThreshold == darkThreshold &&
        other.brightThreshold == brightThreshold &&
        other.dimLevel1Timeout == dimLevel1Timeout &&
        other.dimLevel2Timeout == dimLevel2Timeout &&
        other.dimLevel3Timeout == dimLevel3Timeout &&
        other.sleepTimeout == sleepTimeout &&
        other.fadeSpeed == fadeSpeed;
  }

  @override
  int get hashCode {
    return darkThreshold.hashCode ^
        brightThreshold.hashCode ^
        dimLevel1Timeout.hashCode ^
        dimLevel2Timeout.hashCode ^
        dimLevel3Timeout.hashCode ^
        sleepTimeout.hashCode ^
        fadeSpeed.hashCode;
  }
}
