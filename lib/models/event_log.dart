/// Event Log Model
/// 
/// This model represents a single event log entry from the intelligent
/// lighting system's event history.
/// 
/// Purpose: Provide a structured representation of system events for
/// chronological display and analysis.
library;

/// EventLog
/// 
/// Data class containing information about a single system event.
/// 
/// Fields:
/// - [id]: Unique identifier for the event
/// - [timestamp]: ISO 8601 timestamp when the event occurred
/// - [eventType]: Type of event ('presence', 'brightness', 'state', 'mode', 'system')
/// - [message]: Human-readable event description
/// - [details]: Additional event details (optional)
class EventLog {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final String message;
  final String? details;

  /// Constructor
  /// 
  /// Creates a new EventLog instance with the provided values.
  /// 
  /// Parameters:
  /// - [id]: Unique event identifier
  /// - [timestamp]: Event timestamp
  /// - [eventType]: Type of event
  /// - [message]: Event description
  /// - [details]: Optional additional details
  EventLog({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.message,
    this.details,
  });

  /// Factory constructor for creating EventLog from JSON
  /// 
  /// Parses a JSON map received from the ESP32 API and creates
  /// an EventLog instance.
  /// 
  /// Parameters:
  /// - [json]: Map containing JSON data from API response
  /// 
  /// Returns: EventLog instance
  /// 
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "id": "evt_12345",
  ///   "timestamp": "2024-01-15T10:30:00Z",
  ///   "event_type": "presence",
  ///   "message": "Presence Detected",
  ///   "details": "Target detected at 2.5m"
  /// }
  /// ```
  factory EventLog.fromJson(Map<String, dynamic> json) {
    return EventLog(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      eventType: json['event_type'] as String? ?? 'system',
      message: json['message'] as String? ?? '',
      details: json['details'] as String?,
    );
  }

  /// Convert EventLog to JSON
  /// 
  /// Serializes the EventLog instance to a JSON map.
  /// 
  /// Returns: Map containing serialized data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'event_type': eventType,
      'message': message,
      if (details != null) 'details': details,
    };
  }

  /// Create a copy with updated fields
  /// 
  /// Creates a new EventLog instance with specified fields updated.
  /// 
  /// Parameters:
  /// - [id]: Optional new ID
  /// - [timestamp]: Optional new timestamp
  /// - [eventType]: Optional new event type
  /// - [message]: Optional new message
  /// - [details]: Optional new details
  /// 
  /// Returns: New EventLog instance with updated fields
  EventLog copyWith({
    String? id,
    DateTime? timestamp,
    String? eventType,
    String? message,
    String? details,
  }) {
    return EventLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      message: message ?? this.message,
      details: details ?? this.details,
    );
  }

  /// Get formatted time string
  /// 
  /// Returns a formatted time string (HH:MM) for display.
  /// 
  /// Returns: Formatted time string
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date string
  /// 
  /// Returns a formatted date string for display.
  /// 
  /// Returns: Formatted date string
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Get event type icon
  /// 
  /// Returns an emoji representing the event type.
  /// 
  /// Returns: Emoji string
  String get eventTypeIcon {
    switch (eventType.toLowerCase()) {
      case 'presence':
        return '👤';
      case 'brightness':
        return '💡';
      case 'state':
        return '🔄';
      case 'mode':
        return '⚙️';
      case 'system':
        return '🔧';
      default:
        return '📌';
    }
  }

  @override
  String toString() {
    return 'EventLog(id: $id, timestamp: $timestamp, eventType: $eventType, '
        'message: $message, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventLog &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.eventType == eventType &&
        other.message == message &&
        other.details == details;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        timestamp.hashCode ^
        eventType.hashCode ^
        message.hashCode ^
        details.hashCode;
  }
}

/// Event Log List
/// 
/// A collection of EventLog objects with utility methods for
/// filtering and sorting.
class EventLogList {
  final List<EventLog> logs;

  EventLogList(this.logs);

  /// Factory constructor for creating EventLogList from JSON
  /// 
  /// Parses a JSON list received from the ESP32 API and creates
  /// an EventLogList instance.
  /// 
  /// Parameters:
  /// - [json]: List containing JSON data from API response
  /// 
  /// Returns: EventLogList instance
  factory EventLogList.fromJson(List<dynamic> json) {
    return EventLogList(
      json.map((e) => EventLog.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Convert EventLogList to JSON
  /// 
  /// Serializes the EventLogList instance to a JSON list.
  /// 
  /// Returns: List containing serialized data
  List<Map<String, dynamic>> toJson() {
    return logs.map((log) => log.toJson()).toList();
  }

  /// Filter logs by event type
  /// 
  /// Returns a new EventLogList containing only logs of the specified type.
  /// 
  /// Parameters:
  /// - [eventType]: Event type to filter by
  /// 
  /// Returns: Filtered EventLogList
  EventLogList filterByType(String eventType) {
    return EventLogList(
      logs.where((log) => log.eventType == eventType).toList(),
    );
  }

  /// Filter logs by date range
  /// 
  /// Returns a new EventLogList containing only logs within the date range.
  /// 
  /// Parameters:
  /// - [start]: Start date
  /// - [end]: End date
  /// 
  /// Returns: Filtered EventLogList
  EventLogList filterByDateRange(DateTime start, DateTime end) {
    return EventLogList(
      logs.where((log) => log.timestamp.isAfter(start) && log.timestamp.isBefore(end)).toList(),
    );
  }

  /// Get recent logs
  /// 
  /// Returns the most recent N logs.
  /// 
  /// Parameters:
  /// - [count]: Number of recent logs to return
  /// 
  /// Returns: EventLogList with recent logs
  EventLogList recent(int count) {
    final sorted = List<EventLog>.from(logs);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return EventLogList(sorted.take(count).toList());
  }

  /// Get log count
  /// 
  /// Returns the total number of logs.
  /// 
  /// Returns: Number of logs
  int get length => logs.length;

  /// Check if logs list is empty
  /// 
  /// Returns true if there are no logs.
  /// 
  /// Returns: Boolean indicating emptiness
  bool get isEmpty => logs.isEmpty;

  /// Check if logs list is not empty
  /// 
  /// Returns true if there are logs.
  /// 
  /// Returns: Boolean indicating non-emptiness
  bool get isNotEmpty => logs.isNotEmpty;
}
