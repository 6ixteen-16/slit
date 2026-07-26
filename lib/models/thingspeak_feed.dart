/// ThingSpeak Feed Models
///
/// Data models for ThingSpeak API responses including feeds,
/// channel information, and field data.
///
/// Purpose: Provide strongly-typed models for ThingSpeak JSON
/// responses with serialization support.
library;

import 'package:smart_light/config/thingspeak_config.dart';

/// ThingSpeak Feed
///
/// Represents a single feed entry from ThingSpeak containing
/// timestamp and field values.
class ThingSpeakFeed {
  final int? entryId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> fields;

  const ThingSpeakFeed({
    this.entryId,
    required this.createdAt,
    this.updatedAt,
    required this.fields,
  });

  /// Create ThingSpeakFeed from JSON
  factory ThingSpeakFeed.fromJson(Map<String, dynamic> json) {
    final fields = <String, dynamic>{};

    // Parse field1 through field8
    for (int i = 1; i <= 8; i++) {
      final fieldName = 'field$i';
      if (json.containsKey(fieldName) && json[fieldName] != null) {
        final paramName = ThingSpeakConfig.fieldMapping.getParameterForField(i);
        if (paramName != null) {
          fields[paramName] = json[fieldName];
        }
      }
    }

    return ThingSpeakFeed(
      entryId: json['entry_id'] as int?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      fields: fields,
    );
  }

  /// Parse ThingSpeak datetime format
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // ThingSpeak format: 2024-01-15T10:30:00Z
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Get field value by parameter name
  dynamic getField(String parameter) {
    return fields[parameter];
  }

  /// Get field value as string
  String getFieldAsString(String parameter, [String defaultValue = '']) {
    final value = getField(parameter);
    return value?.toString() ?? defaultValue;
  }

  /// Get field value as int
  int getFieldAsInt(String parameter, [int defaultValue = 0]) {
    final value = getField(parameter);
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get field value as double
  double getFieldAsDouble(String parameter, [double defaultValue = 0.0]) {
    final value = getField(parameter);
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get field value as bool
  bool getFieldAsBool(String parameter, [bool defaultValue = false]) {
    final value = getField(parameter);
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return defaultValue;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      ...fields,
    };
  }

  /// Convert to SystemStatus
  ///
  /// Maps ThingSpeak feed to existing SystemStatus model.
  Map<String, dynamic> toSystemStatus() {
    return {
      'presence': getFieldAsBool('presence'),
      'ambient_light': getFieldAsDouble('ambient_light'),
      'brightness': getFieldAsInt('brightness'),
      'pwm_value': getFieldAsInt('pwm_value'),
      'mode': 'auto', // Default mode, can be derived from state
      // Firmware uploads an integer: ACTIVE=0, DIM1=1, DIM2=2,
      // DIM3=3, SLEEP=4. SystemStatus normalises it for the UI.
      'state': getField('system_state') ?? 4,
      'last_updated': createdAt.toIso8601String(),
      'connection_status': 'connected',
    };
  }
}

/// ThingSpeak Channel
///
/// Represents ThingSpeak channel information including metadata
/// and field definitions.
class ThingSpeakChannel {
  final int id;
  final String name;
  final String? description;
  final String? latitude;
  final String? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastEntryAt;
  final Map<String, String> fieldNames;

  const ThingSpeakChannel({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.lastEntryAt,
    required this.fieldNames,
  });

  /// Create ThingSpeakChannel from JSON
  factory ThingSpeakChannel.fromJson(Map<String, dynamic> json) {
    final fieldNames = <String, String>{};

    // Parse field names (field1, field2, etc.)
    for (int i = 1; i <= 8; i++) {
      final fieldName = 'field$i';
      if (json.containsKey(fieldName)) {
        fieldNames[fieldName] = json[fieldName] as String;
      }
    }

    return ThingSpeakChannel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      lastEntryAt: _parseDateTime(json['last_entry_at']),
      fieldNames: fieldNames,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_entry_at': lastEntryAt?.toIso8601String(),
      ...fieldNames,
    };
  }
}

/// ThingSpeak Feed Response
///
/// Complete response from ThingSpeak containing channel info
/// and array of feeds.
class ThingSpeakFeedResponse {
  final ThingSpeakChannel channel;
  final List<ThingSpeakFeed> feeds;

  const ThingSpeakFeedResponse({
    required this.channel,
    required this.feeds,
  });

  /// Create ThingSpeakFeedResponse from JSON
  factory ThingSpeakFeedResponse.fromJson(Map<String, dynamic> json) {
    final channelJson = json['channel'] as Map<String, dynamic>?;
    final feedsJson = json['feeds'] as List<dynamic>?;

    final channel = channelJson != null
        ? ThingSpeakChannel.fromJson(channelJson)
        : const ThingSpeakChannel(
            id: 0,
            name: 'Unknown',
            fieldNames: {},
          );

    final feeds = feedsJson != null
        ? feedsJson
            .map(
                (feed) => ThingSpeakFeed.fromJson(feed as Map<String, dynamic>))
            .toList()
        : <ThingSpeakFeed>[];

    return ThingSpeakFeedResponse(
      channel: channel,
      feeds: feeds,
    );
  }

  /// Get latest feed
  ThingSpeakFeed? get latestFeed => feeds.isNotEmpty ? feeds.first : null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'channel': channel.toJson(),
      'feeds': feeds.map((feed) => feed.toJson()).toList(),
    };
  }
}

/// ThingSpeak Field Feed
///
/// Represents a feed for a specific field only.
class ThingSpeakFieldFeed {
  final List<ThingSpeakFieldEntry> entries;

  const ThingSpeakFieldFeed({required this.entries});

  /// Create ThingSpeakFieldFeed from JSON
  factory ThingSpeakFieldFeed.fromJson(dynamic json) {
    if (json is List) {
      final entries = json
          .map((entry) =>
              ThingSpeakFieldEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
      return ThingSpeakFieldFeed(entries: entries);
    }

    if (json is Map<String, dynamic>) {
      final feedsJson = json['feeds'] as List<dynamic>?;
      if (feedsJson != null) {
        final entries = feedsJson
            .map((entry) =>
                ThingSpeakFieldEntry.fromJson(entry as Map<String, dynamic>))
            .toList();
        return ThingSpeakFieldFeed(entries: entries);
      }
    }

    return const ThingSpeakFieldFeed(entries: []);
  }

  /// Get latest entry
  ThingSpeakFieldEntry? get latestEntry =>
      entries.isNotEmpty ? entries.first : null;

  /// Calculate average value
  double get averageValue {
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold<double>(
      0,
      (sum, entry) => sum + (entry.value ?? 0),
    );
    return sum / entries.length;
  }

  /// Get maximum value
  double get maxValue {
    if (entries.isEmpty) return 0.0;
    return entries.map((e) => e.value ?? 0).reduce((a, b) => a > b ? a : b);
  }

  /// Get minimum value
  double get minValue {
    if (entries.isEmpty) return 0.0;
    return entries.map((e) => e.value ?? 0).reduce((a, b) => a < b ? a : b);
  }
}

/// ThingSpeak Field Entry
///
/// Represents a single entry in a field feed.
class ThingSpeakFieldEntry {
  final DateTime createdAt;
  final double? value;

  const ThingSpeakFieldEntry({
    required this.createdAt,
    this.value,
  });

  /// Create ThingSpeakFieldEntry from JSON
  factory ThingSpeakFieldEntry.fromJson(Map<String, dynamic> json) {
    return ThingSpeakFieldEntry(
      createdAt: _parseDateTime(json['created_at']),
      value: _parseDouble(json['field_value'] ?? json['value']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      'value': value,
    };
  }
}

/// ThingSpeak Status
///
/// Represents ThingSpeak channel status.
class ThingSpeakStatus {
  final int channelId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastEntryAt;
  final Map<String, dynamic> fieldStatus;

  const ThingSpeakStatus({
    required this.channelId,
    this.createdAt,
    this.updatedAt,
    this.lastEntryAt,
    required this.fieldStatus,
  });

  /// Create ThingSpeakStatus from JSON
  factory ThingSpeakStatus.fromJson(Map<String, dynamic> json) {
    return ThingSpeakStatus(
      channelId: json['channel_id'] as int,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      lastEntryAt: _parseDateTime(json['last_entry_at']),
      fieldStatus: json.map((key, value) => MapEntry(key, value)),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_entry_at': lastEntryAt?.toIso8601String(),
      ...fieldStatus,
    };
  }
}

/// ESP32 status response.
class ESP32Status {
  final bool? presence;
  final double? ambientLight;
  final int? brightness;
  final int? pwmValue;
  final String? mode;
  final String? state;
  final String? connectionStatus;
  final DateTime? lastUpdated;

  const ESP32Status({
    this.presence,
    this.ambientLight,
    this.brightness,
    this.pwmValue,
    this.mode,
    this.state,
    this.connectionStatus,
    this.lastUpdated,
  });

  factory ESP32Status.fromJson(Map<String, dynamic> json) {
    return ESP32Status(
      presence: _parseBool(json['presence']),
      ambientLight: _parseDouble(json['ambient_light'] ?? json['ambientLight']),
      brightness: _parseInt(json['brightness']),
      pwmValue: _parseInt(json['pwm_value'] ?? json['pwmValue']),
      mode: json['mode']?.toString(),
      state: json['state']?.toString(),
      connectionStatus: json['connection_status']?.toString(),
      lastUpdated: _parseDateTime(json['last_updated']),
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// ESP32 statistics response.
class ESP32Statistics {
  final Map<String, dynamic> data;

  const ESP32Statistics({required this.data});

  factory ESP32Statistics.fromJson(Map<String, dynamic> json) {
    return ESP32Statistics(data: Map<String, dynamic>.from(json));
  }
}

/// ESP32 log entry.
class ESP32LogEntry {
  final DateTime? timestamp;
  final String? eventType;
  final String? message;
  final String? details;

  const ESP32LogEntry({
    this.timestamp,
    this.eventType,
    this.message,
    this.details,
  });

  factory ESP32LogEntry.fromJson(Map<String, dynamic> json) {
    return ESP32LogEntry(
      timestamp:
          ESP32Status._parseDateTime(json['timestamp'] ?? json['created_at']),
      eventType: json['event_type']?.toString() ?? json['type']?.toString(),
      message: json['message']?.toString(),
      details: json['details']?.toString(),
    );
  }
}

/// ESP32 logs response.
class ESP32LogsResponse {
  final List<ESP32LogEntry> logs;

  const ESP32LogsResponse({required this.logs});

  factory ESP32LogsResponse.fromJson(dynamic json) {
    if (json is List) {
      return ESP32LogsResponse(
        logs: json
            .whereType<Map<String, dynamic>>()
            .map(ESP32LogEntry.fromJson)
            .toList(),
      );
    }

    if (json is Map<String, dynamic>) {
      final rawLogs = json['logs'] ?? json['data'];
      if (rawLogs is List) {
        return ESP32LogsResponse(
          logs: rawLogs
              .whereType<Map<String, dynamic>>()
              .map(ESP32LogEntry.fromJson)
              .toList(),
        );
      }
    }

    return const ESP32LogsResponse(logs: []);
  }
}
