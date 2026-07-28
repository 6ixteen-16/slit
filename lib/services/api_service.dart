/// API Service
///
/// This service handles all HTTP communication with the ESP32 embedded system.
/// It provides methods for making GET and POST requests with automatic
/// retry logic and error handling.
///
/// Purpose: Abstract network operations from the UI layer and provide
/// a clean interface for ESP32 communication.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_light/config/api_constants.dart';
import 'package:smart_light/models/system_status.dart';
import 'package:smart_light/models/event_log.dart';
import 'package:smart_light/models/settings.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// API Service
///
/// Singleton service class for handling all API communications with the ESP32.
///
/// Features:
/// - Automatic retry logic for failed requests
/// - Timeout handling
/// - JSON serialization/deserialization
/// - Connection status monitoring
/// - Error handling with user-friendly messages
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String _host = esp32Host;

  /// ESP32 host currently used for direct control requests.
  String get host => _host;

  /// Changes the direct-controller address. This is intentionally runtime
  /// configurable because the firmware receives its address through DHCP.
  void setHost(String host) {
    final normalized = host.trim().replaceFirst(RegExp(r'^https?://'), '');
    if (normalized.isEmpty ||
        normalized.contains('/') ||
        normalized.contains(' ')) {
      throw ApiException('Enter a valid ESP32 IP address or host name.');
    }
    _host = normalized;
  }

  /// Make a GET request with retry logic
  ///
  /// Performs an HTTP GET request to the specified endpoint with automatic
  /// retry on failure.
  ///
  /// Parameters:
  /// - [endpoint]: API endpoint path (e.g., '/status')
  /// - [retries]: Number of retry attempts (default: from api_constants)
  ///
  /// Returns: HTTP response object
  ///
  /// Throws: ApiException on failure after all retries
  Future<http.Response> _get(String endpoint, {int? retries}) async {
    final retryCount = retries ?? maxRetries;
    int attempt = 0;

    while (attempt < retryCount) {
      try {
        final uri = Uri.parse('${baseUrlForHost(_host)}$endpoint');
        final response = await _client
            .get(uri)
            .timeout(const Duration(milliseconds: connectionTimeout));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else {
          throw ApiException(
            'Request failed with status ${response.statusCode}',
            response.statusCode,
          );
        }
      } on http.ClientException catch (e) {
        attempt++;
        if (attempt >= retryCount) {
          throw ApiException('Connection failed to $_host: ${e.message}');
        }
        await Future.delayed(const Duration(milliseconds: retryDelay));
      } on TimeoutException {
        attempt++;
        if (attempt >= retryCount) {
          throw ApiException(
            'Request timed out connecting to $_host. Check that ESP32 is powered on, IP address is correct, and phone/ESP32 are on the same Wi-Fi.',
          );
        }
        await Future.delayed(const Duration(milliseconds: retryDelay));
      } catch (e) {
        attempt++;
        if (attempt >= retryCount) {
          throw ApiException('Unexpected error connecting to $_host: $e');
        }
        await Future.delayed(const Duration(milliseconds: retryDelay));
      }
    }

    throw ApiException('Max retries exceeded connecting to $_host');
  }

  /// Make a POST request with retry logic
  ///
  /// Performs an HTTP POST request to the specified endpoint with automatic
  /// retry on failure.
  ///
  /// Parameters:
  /// - [endpoint]: API endpoint path (e.g., '/manual')
  /// - [body]: JSON-serializable data to send in request body
  /// - [retries]: Number of retry attempts (default: from api_constants)
  ///
  /// Returns: HTTP response object
  ///
  /// Throws: ApiException on failure after all retries
  Future<http.Response> _post(
    String endpoint,
    Map<String, dynamic> body, {
    int? retries,
  }) async {
    final retryCount = retries ?? maxRetries;
    int attempt = 0;

    while (attempt < retryCount) {
      try {
        final uri = Uri.parse('${baseUrlForHost(_host)}$endpoint');
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(milliseconds: connectionTimeout));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else {
          throw ApiException(
            'Request failed with status ${response.statusCode}',
            response.statusCode,
          );
        }
      } on http.ClientException catch (e) {
        attempt++;
        if (attempt >= retryCount) {
          throw ApiException('Connection failed to $_host: ${e.message}');
        }
        await Future.delayed(const Duration(milliseconds: retryDelay));
      } on TimeoutException {
        attempt++;
        if (attempt >= retryCount) {
          throw ApiException(
            'Request timed out connecting to $_host. Check that ESP32 is powered on, IP address is correct, and phone/ESP32 are on the same Wi-Fi.',
          );
        }
        await Future.delayed(const Duration(milliseconds: retryDelay));
      } catch (e) {
        attempt++;
        if (attempt >= retryCount) {
          throw ApiException('Unexpected error connecting to $_host: $e');
        }
        await Future.delayed(const Duration(milliseconds: retryDelay));
      }
    }

    throw ApiException('Max retries exceeded connecting to $_host');
  }

  /// Get system status
  ///
  /// Fetches the current system status from the ESP32.
  ///
  /// Returns: SystemStatus object with current system state
  ///
  /// Throws: ApiException on communication failure
  Future<SystemStatus> getSystemStatus() async {
    try {
      final response = await _get(endpointStatus);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return SystemStatus.fromJson(jsonData);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to parse system status: $e');
    }
  }

  /// Get event logs
  ///
  /// Fetches the event log history from the ESP32.
  ///
  /// Returns: EventLogList containing all logged events
  ///
  /// Throws: ApiException on communication failure
  Future<EventLogList> getEventLogs() async {
    try {
      final response = await _get(endpointLogs);
      final decoded = jsonDecode(response.body);
      // ESP32 v6 returns {"events": [{"timestampMs": ..., "message": ...}]}.
      // This app's legacy EventLog schema cannot faithfully represent those
      // entries, so accept both response shapes without crashing.
      final rawEntries = decoded is List<dynamic>
          ? decoded
          : (decoded is Map<String, dynamic>
              ? (decoded['events'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
      final jsonData = rawEntries.map((entry) {
        final event = entry as Map<String, dynamic>;
        if (event.containsKey('timestampMs')) {
          // The firmware clock is uptime-based, not a wall clock. Preserve the
          // useful message and give the UI a valid timestamp.
          return <String, dynamic>{
            'id': 'esp32_${event['timestampMs']}',
            'timestamp': DateTime.now().toIso8601String(),
            'event_type': 'system',
            'message': event['message']?.toString() ?? '',
            'details': 'ESP32 uptime: ${event['timestampMs']} ms',
          };
        }
        return event;
      }).toList();
      return EventLogList.fromJson(jsonData);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to parse event logs: $e');
    }
  }

  /// Get statistics
  ///
  /// Fetches daily statistics from the ESP32.
  ///
  /// Returns: Map containing statistics data
  ///
  /// Throws: ApiException on communication failure
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _get(endpointStatistics);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to parse statistics: $e');
    }
  }

  /// Send manual brightness command
  ///
  /// Sends a manual brightness control command to the ESP32.
  ///
  /// Parameters:
  /// - [brightness]: Brightness value (0-100)
  ///
  /// Returns: True if command was successful
  ///
  /// Throws: ApiException on communication failure
  Future<bool> setManualBrightness(int brightness) async {
    try {
      final body = {'brightness': brightness};
      await _post(endpointManual, body);
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to set manual brightness: $e');
    }
  }

  /// Update system settings
  ///
  /// Sends updated settings to the ESP32.
  ///
  /// Parameters:
  /// - [settings]: Settings object with new configuration
  ///
  /// Returns: True if settings were updated successfully
  ///
  /// Throws: ApiException on communication failure
  Future<bool> updateSettings(Settings settings) async {
    try {
      await _post(endpointSettings, settings.toJson());
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to update settings: $e');
    }
  }

  /// Restore the firmware's own default settings.
  Future<bool> restoreDefaults() async {
    try {
      await _post(endpointSettings, {'restoreDefaults': true});
      return true;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to restore default settings: $e');
    }
  }

  /// Set operating mode
  ///
  /// Changes the operating mode of the system.
  ///
  /// Parameters:
  /// - [mode]: Operating mode ('auto' or 'manual')
  ///
  /// Returns: True if mode was changed successfully
  ///
  /// Throws: ApiException on communication failure
  Future<bool> setMode(String mode) async {
    try {
      final body = {'mode': mode};
      await _post(endpointMode, body);
      return true;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to set mode: $e');
    }
  }

  /// Test connection
  ///
  /// Tests connectivity to the ESP32 by fetching system status.
  ///
  /// Returns: True if connection is successful
  ///
  /// Throws: ApiException on connection failure
  Future<bool> testConnection() async {
    try {
      await getSystemStatus();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources
  ///
  /// Closes the HTTP client and releases resources.
  void dispose() {
    _client.close();
  }
}
