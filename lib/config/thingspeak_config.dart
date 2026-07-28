/// ThingSpeak Configuration
///
/// Configuration file for ThingSpeak Cloud integration.
///
/// Purpose: Centralize ThingSpeak channel credentials, API keys,
/// and field mappings for easy configuration and maintenance.

/// ThingSpeak Configuration
///
/// Contains all configuration parameters for ThingSpeak integration.
/// Update these values with your ThingSpeak channel details.
class ThingSpeakConfig {
  /// ThingSpeak Base URL
  static const String baseUrl = 'https://api.thingspeak.com';

  /// ThingSpeak Channel ID
  ///
  /// Replace with your actual ThingSpeak channel ID.
  static const String channelId = '3429218';

  /// ThingSpeak Read API Key
  ///
  /// Replace with your actual Read API Key from ThingSpeak.
  static const String readApiKey = 'CH5YHY7GCSI4HDNF';

  /// ThingSpeak Write API Key
  ///
  /// Replace with your actual Write API Key from ThingSpeak.
  /// Required only if command functionality is implemented.
  static const String writeApiKey = 'MRYAEMJXMM8F22S0';

  /// Update Interval (milliseconds)
  ///
  /// How often to fetch data from ThingSpeak.
  /// ThingSpeak free tier allows 1 update per second (1000ms).
  static const int updateInterval = 15000; // 15 seconds

  /// Connection Timeout (milliseconds)
  static const int connectionTimeout = 10000; // 10 seconds

  /// Maximum Retry Attempts
  static const int maxRetries = 3;

  /// Retry Delay (milliseconds)
  static const int retryDelay = 2000; // 2 seconds

  /// Cache Duration (milliseconds)
  ///
  /// How long to cache the latest successful response.
  static const int cacheDuration = 5000; // 5 seconds

  /// Field Mapping Configuration
  ///
  /// Maps ThingSpeak fields to system parameters.
  /// These can be customized based on your ESP32 firmware.
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

  /// Historical Data Configuration
  static const HistoricalConfig historicalConfig = HistoricalConfig(
    defaultResults: 100,
    maxResults: 8000, // ThingSpeak limit
    timeRanges: {
      'hour': 60,
      'day': 1440,
      'week': 10080,
    },
  );
}

/// Field Mapping
///
/// Maps ThingSpeak field numbers to system parameters.
class FieldMapping {
  final int presence;
  final int ambientLight;
  final int brightness;
  final int pwmValue;
  final int systemState;
  final int activeTime;
  final int idleTime;
  final int sleepTime;

  const FieldMapping({
    required this.presence,
    required this.ambientLight,
    required this.brightness,
    required this.pwmValue,
    required this.systemState,
    required this.activeTime,
    required this.idleTime,
    required this.sleepTime,
  });

  /// Get field number for a given parameter
  int getFieldForParameter(String parameter) {
    switch (parameter.toLowerCase()) {
      case 'presence':
        return presence;
      case 'ambient_light':
      case 'ambientlight':
        return ambientLight;
      case 'brightness':
        return brightness;
      case 'pwm':
      case 'pwm_value':
        return pwmValue;
      case 'state':
      case 'system_state':
        return systemState;
      case 'active_time':
      case 'activetime':
        return activeTime;
      case 'idle_time':
      case 'idletime':
        return idleTime;
      case 'sleep_time':
      case 'sleeptime':
        return sleepTime;
      default:
        return 1;
    }
  }

  /// Get parameter name for a given field number
  String? getParameterForField(int field) {
    if (field == presence) return 'presence';
    if (field == ambientLight) return 'ambient_light';
    if (field == brightness) return 'brightness';
    if (field == pwmValue) return 'pwm_value';
    if (field == systemState) return 'system_state';
    if (field == activeTime) return 'active_time';
    if (field == idleTime) return 'idle_time';
    if (field == sleepTime) return 'sleep_time';
    return null;
  }
}

/// Historical Data Configuration
///
/// Configuration for fetching historical data from ThingSpeak.
class HistoricalConfig {
  final int defaultResults;
  final int maxResults;
  final Map<String, int> timeRanges;

  const HistoricalConfig({
    required this.defaultResults,
    required this.maxResults,
    required this.timeRanges,
  });

  /// Get number of results for a given time range
  int getResultsForTimeRange(String range) {
    return timeRanges[range.toLowerCase()] ?? defaultResults;
  }
}

/// ThingSpeak API Endpoints
///
/// Predefined API endpoints for ThingSpeak operations.
class ThingSpeakEndpoints {
  /// Get latest feed from channel
  static String getLatestFeed(String channelId, String readApiKey) {
    return '${ThingSpeakConfig.baseUrl}/channels/$channelId/feeds/last.json?api_key=$readApiKey';
  }

  /// Get channel feed with specified number of results
  static String getChannelFeed(
    String channelId,
    String readApiKey, {
    int results = 100,
  }) {
    return '${ThingSpeakConfig.baseUrl}/channels/$channelId/feeds.json?api_key=$readApiKey&results=$results';
  }

  /// Get channel feed with time range
  static String getChannelFeedWithTimeRange(
    String channelId,
    String readApiKey, {
    int? results,
    String? start,
    String? end,
  }) {
    final buffer = StringBuffer(
        '${ThingSpeakConfig.baseUrl}/channels/$channelId/feeds.json?api_key=$readApiKey');
    if (results != null) buffer.write('&results=$results');
    if (start != null) buffer.write('&start=$start');
    if (end != null) buffer.write('&end=$end');
    return buffer.toString();
  }

  /// Get field feed for a specific field
  static String getFieldFeed(
    String channelId,
    String readApiKey,
    int field, {
    int results = 100,
  }) {
    return '${ThingSpeakConfig.baseUrl}/channels/$channelId/field/$field.json?api_key=$readApiKey&results=$results';
  }

  /// Get channel status
  static String getChannelStatus(String channelId, String readApiKey) {
    return '${ThingSpeakConfig.baseUrl}/channels/$channelId/status/last.json?api_key=$readApiKey';
  }

  /// Update channel (POST request)
  static String updateChannel(String channelId, String writeApiKey) {
    return '${ThingSpeakConfig.baseUrl}/update?api_key=$writeApiKey';
  }
}

/// ThingSpeak Status Codes
///
/// Common ThingSpeak API status codes and messages.
class ThingSpeakStatusCodes {
  static const String success = '0';
  static const String invalidApiKey = '-1';
  static const String channelNotFound = '-2';
  static const String invalidParameter = '-3';
  static const String rateLimitExceeded = '-4';
  static const String serverError = '-5';

  static String getStatusMessage(String code) {
    switch (code) {
      case success:
        return 'Success';
      case invalidApiKey:
        return 'Invalid API Key';
      case channelNotFound:
        return 'Channel Not Found';
      case invalidParameter:
        return 'Invalid Parameter';
      case rateLimitExceeded:
        return 'Rate Limit Exceeded';
      case serverError:
        return 'Server Error';
      default:
        return 'Unknown Error';
    }
  }
}
