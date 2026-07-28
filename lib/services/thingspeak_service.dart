/// ThingSpeak + ESP32 Smart Lighting Service
///
/// Handles:
/// - ThingSpeak telemetry fetching
/// - ESP32 REST API communication
/// - Manual brightness control
/// - Auto/manual mode switching
/// - Runtime settings updates
/// - Statistics and event logs


import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_light/config/thingspeak_config.dart';
import 'package:smart_light/models/thingspeak_feed.dart' as models;

class ThingSpeakException implements Exception {
  final String message;
  final int? statusCode;

  ThingSpeakException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ThingSpeakService {
  static final ThingSpeakService _instance = ThingSpeakService._internal();

  factory ThingSpeakService() => _instance;

  ThingSpeakService._internal();

  final http.Client _client = http.Client();

  models.ThingSpeakFeed? _cache;
  DateTime? _cacheTime;

  bool _connected = false;
  String? _error;
  String esp32Address = '192.168.10.100';

  bool get isConnected => _connected;
  String? get lastError => _error;

  // ===============================================================
  // THINGSPEAK
  // ===============================================================

  Future<models.ThingSpeakFeed> getLatestFeed() async {
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inMilliseconds <
            ThingSpeakConfig.cacheDuration) {
      return _cache!;
    }

    final url = ThingSpeakEndpoints.getLatestFeed(
      ThingSpeakConfig.channelId,
      ThingSpeakConfig.readApiKey,
    );

    try {
      final data = await _get(url);
      final feed = models.ThingSpeakFeed.fromJson(data);

      _cache = feed;
      _cacheTime = DateTime.now();
      _connected = true;
      _error = null;

      return feed;
    } catch (e) {
      _connected = false;
      _error = e.toString();

      if (_cache != null) {
        return _cache!;
      }

      rethrow;
    }
  }

  Future<models.ThingSpeakFeedResponse> getChannelFeedWithTimeRange({
    int? results,
    String? start,
    String? end,
  }) async {
    final url = ThingSpeakEndpoints.getChannelFeedWithTimeRange(
      ThingSpeakConfig.channelId,
      ThingSpeakConfig.readApiKey,
      results: results,
      start: start,
      end: end,
    );

    final data = await _get(url);
    return models.ThingSpeakFeedResponse.fromJson(data);
  }

  Future<models.ThingSpeakFeedResponse> getChannelFeed({
    int results = 100,
  }) async {
    final url = ThingSpeakEndpoints.getChannelFeed(
      ThingSpeakConfig.channelId,
      ThingSpeakConfig.readApiKey,
      results: results,
    );

    final data = await _get(url);
    return models.ThingSpeakFeedResponse.fromJson(data);
  }

  Future<models.ThingSpeakFieldFeed> getFieldFeed(
    int field, {
    int results = 100,
  }) async {
    final url = ThingSpeakEndpoints.getFieldFeed(
      ThingSpeakConfig.channelId,
      ThingSpeakConfig.readApiKey,
      field,
      results: results,
    );

    final data = await _get(url);
    return models.ThingSpeakFieldFeed.fromJson(data);
  }

  Future<bool> testConnection() async {
    try {
      await getLatestFeed();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===============================================================
  // ESP32 LOCAL REST API
  // ===============================================================

  void setESP32Address(String ip) {
    esp32Address = ip;
  }

  Future<models.ESP32Status> getESP32Status() async {
    final response =
        await _client.get(Uri.parse('http://$esp32Address/status'));

    if (response.statusCode != 200) {
      throw ThingSpeakException('ESP32 status failed');
    }

    return models.ESP32Status.fromJson(jsonDecode(response.body));
  }

  Future<models.ESP32Statistics> getStatistics() async {
    final response =
        await _client.get(Uri.parse('http://$esp32Address/statistics'));
    return models.ESP32Statistics.fromJson(jsonDecode(response.body));
  }

  Future<models.ESP32LogsResponse> getLogs() async {
    final response = await _client.get(Uri.parse('http://$esp32Address/logs'));
    return models.ESP32LogsResponse.fromJson(jsonDecode(response.body));
  }

  // ===============================================================
  // ESP32 COMMANDS
  // ===============================================================

  Future<bool> setManualBrightness(int percentage) async {
    final response = await _client.post(
      Uri.parse('http://$esp32Address/manual'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'brightness': percentage}),
    );

    return response.statusCode == 200;
  }

  Future<bool> setMode(String mode) async {
    final response = await _client.post(
      Uri.parse('http://$esp32Address/mode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mode': mode}),
    );

    return response.statusCode == 200;
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    final response = await _client.post(
      Uri.parse('http://$esp32Address/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(settings),
    );

    return response.statusCode == 200;
  }

  Future<bool> restoreDefaults() async {
    return updateSettings({'restoreDefaults': true});
  }

  // ===============================================================
  // HTTP ENGINE
  // ===============================================================

  Future<Map<String, dynamic>> _get(String url) async {
    final response = await _client.get(Uri.parse(url)).timeout(
        const Duration(milliseconds: ThingSpeakConfig.connectionTimeout));

    if (response.statusCode != 200) {
      throw ThingSpeakException(
        'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  void dispose() {
    _client.close();
  }
}
