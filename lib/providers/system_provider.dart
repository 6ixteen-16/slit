/// System Provider
///
/// This provider manages the application state for the intelligent lighting system.
/// It acts as the central state management layer using the Provider pattern.
///
/// Purpose: Centralize state management, coordinate between services,
/// and provide reactive state updates to the UI layer.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_light/models/system_status.dart';
import 'package:smart_light/models/event_log.dart';
import 'package:smart_light/models/settings.dart';
import 'package:smart_light/models/thingspeak_feed.dart';
import 'package:smart_light/services/api_service.dart';
import 'package:smart_light/services/connection_service.dart';
import 'package:smart_light/services/thingspeak_service.dart';
import 'package:smart_light/config/api_constants.dart';
import 'package:smart_light/config/thingspeak_config.dart';
import 'package:smart_light/utils/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// System Provider
///
/// ChangeNotifier class that manages system state and coordinates
/// between API and connection services.
///
/// Managed State:
/// - Current system status
/// - Event logs
/// - System settings
/// - Statistics
/// - Connection status
/// - Loading states
/// - Error messages
/// - ThingSpeak integration
class SystemProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ConnectionService _connectionService = ConnectionService();
  final ThingSpeakService _thingSpeakService = ThingSpeakService();

  // State variables
  SystemStatus _systemStatus = SystemStatus.disconnected();
  EventLogList _eventLogs = EventLogList([]);
  Settings _settings = Settings.defaultSettings();
  Map<String, dynamic> _statistics = {};
  String _connectionStatus = ConnectionStatus.disconnected;
  String? _errorMessage;

  // ThingSpeak state
  ThingSpeakFeed? _thingSpeakFeed;
  ThingSpeakFeedResponse? _thingSpeakHistory;
  bool _useThingSpeak = true;
  bool _isThingSpeakConnected = false;
  bool _isOffline = false;
  // ThingSpeak carries telemetry only; the firmware does not upload the
  // operating mode. Keep the last mode confirmed by the ESP32 so a cloud
  // refresh never makes a newly selected manual mode look like auto mode.
  String _lastConfirmedMode = 'auto';

  // Theme state
  ThemeMode _themeMode = ThemeMode.system;

  // Loading states
  bool _isLoadingStatus = false;
  bool _isLoadingLogs = false;
  bool _isLoadingStatistics = false;
  bool _isLoadingSettings = false;
  bool _isLoadingHistory = false;

  // Timers
  Timer? _pollingTimer;

  // Stream subscriptions
  StreamSubscription<String>? _connectionStatusSubscription;
  StreamSubscription<String?>? _errorSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Current system status
  SystemStatus get systemStatus => _systemStatus;

  /// Event logs
  EventLogList get eventLogs => _eventLogs;

  /// System settings
  Settings get settings => _settings;

  /// Statistics
  Map<String, dynamic> get statistics => _statistics;

  /// Connection status
  String get connectionStatus => _connectionStatus;

  /// Error message (if any)
  String? get errorMessage => _errorMessage;

  /// Theme mode
  ThemeMode get themeMode => _themeMode;

  /// Loading states
  bool get isLoadingStatus => _isLoadingStatus;
  bool get isLoadingLogs => _isLoadingLogs;
  bool get isLoadingStatistics => _isLoadingStatistics;
  bool get isLoadingSettings => _isLoadingSettings;
  bool get isLoadingHistory => _isLoadingHistory;

  /// ThingSpeak state getters
  ThingSpeakFeed? get thingSpeakFeed => _thingSpeakFeed;
  ThingSpeakFeedResponse? get thingSpeakHistory => _thingSpeakHistory;
  bool get useThingSpeak => _useThingSpeak;
  bool get isThingSpeakConnected => _isThingSpeakConnected;
  bool get isOffline => _isOffline;
  String get esp32Host => _apiService.host;

  /// Check if system is connected
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;

  /// Check if system is in auto mode
  bool get isAutoMode => _systemStatus.isAutoMode;

  /// Check if system is in manual mode
  bool get isManualMode => _systemStatus.isManualMode;

  /// Initialize provider
  ///
  /// Sets up connection monitoring and initial data fetch.
  ///
  /// Parameters:
  /// - [autoPoll]: Whether to automatically poll for updates (default: true)
  Future<void> initialize({bool autoPoll = true}) async {
    // The ESP32 receives its local address from DHCP. Restore the last address
    // selected by the user before the connection monitor starts.
    final preferences = await SharedPreferences.getInstance();
    final savedHost = preferences.getString('esp32_host');
    if (savedHost != null && savedHost.isNotEmpty) {
      _apiService.setHost(savedHost);
      _thingSpeakService.setESP32Address(_apiService.host);
    }

    // Initialize connection service
    _connectionService.initialize(autoConnect: true);

    // Subscribe to connection status updates
    _connectionStatusSubscription = _connectionService.statusStream.listen(
      (status) {
        _connectionStatus = status;
        _systemStatus = _systemStatus.copyWith(
          connectionStatus: status,
        );
        notifyListeners();
      },
    );

    // Subscribe to error messages
    _errorSubscription = _connectionService.errorStream.listen(
      (error) {
        _errorMessage = error;
        notifyListeners();
      },
    );

    // Monitor network connectivity for ThingSpeak
    final connectivity = Connectivity();
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

    // Check initial connectivity
    final connectivityResult = await connectivity.checkConnectivity();
    _isOffline = connectivityResult == ConnectivityResult.none;

    // Fetch initial data
    await refreshAll();

    // Start polling if enabled
    if (autoPoll) {
      startPolling();
    }
  }

  /// Start polling for updates
  ///
  /// Begins periodic polling of system status from ThingSpeak or ESP32.
  void startPolling() {
    _pollingTimer?.cancel();
    final interval =
        _useThingSpeak ? ThingSpeakConfig.updateInterval : pollingInterval;
    _pollingTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => refreshStatus(),
    );
  }

  /// Stop polling
  ///
  /// Stops periodic polling of system status.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh all data
  ///
  /// Fetches all data from ESP32 (status, logs, statistics, settings).
  Future<void> refreshAll() async {
    await refreshStatus();
    if (_useThingSpeak && !_isOffline) {
      await refreshHistory(results: 100);
      final feeds = _thingSpeakHistory?.feeds ?? const <ThingSpeakFeed>[];
      _eventLogs = _generateLogsFromThingSpeak(feeds);
      _statistics = _calculateStatisticsFromThingSpeak(feeds);
      notifyListeners();
    } else {
      await Future.wait([refreshLogs(), refreshStatistics()]);
    }
    await refreshSettings();
  }

  /// Refresh system status
  ///
  /// Fetches current system status from ThingSpeak or ESP32.
  Future<void> refreshStatus() async {
    _isLoadingStatus = true;
    notifyListeners();

    try {
      if (_useThingSpeak && !_isOffline) {
        // Fetch from ThingSpeak
        _thingSpeakFeed = await _thingSpeakService.getLatestFeed();
        _isThingSpeakConnected = true;

        // Convert ThingSpeak feed to SystemStatus
        final statusMap = _thingSpeakFeed!.toSystemStatus();
        _systemStatus = SystemStatus.fromJson(statusMap).copyWith(
          mode: _lastConfirmedMode,
        );
        _errorMessage = null;
      } else {
        // Fallback to ESP32 direct connection
        _systemStatus = await _apiService.getSystemStatus();
        _errorMessage = null;
      }
    } catch (e) {
      _isThingSpeakConnected = false;
      _errorMessage = 'Failed to fetch status: $e';

      // Try fallback to ESP32 if ThingSpeak fails
      if (_useThingSpeak) {
        try {
          _systemStatus = await _apiService.getSystemStatus();
          _errorMessage = null;
        } catch (e2) {
          _errorMessage = 'Failed to fetch from both ThingSpeak and ESP32: $e2';
        }
      }
    } finally {
      _isLoadingStatus = false;
      notifyListeners();
    }
  }

  /// Refresh event logs
  ///
  /// Fetches event logs from ThingSpeak or ESP32.
  Future<void> refreshLogs() async {
    _isLoadingLogs = true;
    notifyListeners();

    try {
      if (_useThingSpeak && !_isOffline) {
        // Generate logs from ThingSpeak historical data
        await refreshHistory(results: 50);
        if (_thingSpeakHistory != null) {
          _eventLogs = _generateLogsFromThingSpeak(_thingSpeakHistory!.feeds);
        } else {
          _eventLogs = EventLogList([]);
        }
        _errorMessage = null;
      } else {
        // Fallback to ESP32
        _eventLogs = await _apiService.getEventLogs();
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch logs: $e';

      // Try fallback to ESP32 if ThingSpeak fails
      if (_useThingSpeak) {
        try {
          _eventLogs = await _apiService.getEventLogs();
          _errorMessage = null;
        } catch (e2) {
          _errorMessage = 'Failed to fetch logs from both sources: $e2';
        }
      }
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  /// Refresh statistics
  ///
  /// Fetches statistics from ThingSpeak or ESP32.
  Future<void> refreshStatistics({bool fetchHistory = true}) async {
    _isLoadingStatistics = true;
    notifyListeners();

    try {
      if (_useThingSpeak && !_isOffline) {
        // Calculate statistics from ThingSpeak historical data
        if (fetchHistory) {
          await refreshHistory(results: 100);
        }
        if (_thingSpeakHistory != null) {
          _statistics =
              _calculateStatisticsFromThingSpeak(_thingSpeakHistory!.feeds);
        } else {
          _statistics = {};
        }
        _errorMessage = null;
      } else {
        // Fallback to ESP32
        _statistics = await _apiService.getStatistics();
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch statistics: $e';

      // Try fallback to ESP32 if ThingSpeak fails
      if (_useThingSpeak) {
        try {
          _statistics = await _apiService.getStatistics();
          _errorMessage = null;
        } catch (e2) {
          _errorMessage = 'Failed to fetch statistics from both sources: $e2';
        }
      }
    } finally {
      _isLoadingStatistics = false;
      notifyListeners();
    }
  }

  /// Refresh settings
  ///
  /// Fetches current settings from ESP32.
  Future<void> refreshSettings() async {
    _isLoadingSettings = true;
    notifyListeners();

    try {
      // Note: ESP32 should provide a GET /settings endpoint
      // For now, we'll use default settings
      _settings = Settings.defaultSettings();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch settings: $e';
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  /// Set manual brightness
  ///
  /// Sends manual brightness command to ESP32 and updates operating mode to manual.
  ///
  /// Parameters:
  /// - [brightness]: Brightness value (0-100)
  ///
  /// Returns: True if successful
  Future<bool> setManualBrightness(int brightness) async {
    final previousMode = _lastConfirmedMode;
    final previousStatus = _systemStatus;

    // Setting manual brightness automatically switches to manual mode
    _lastConfirmedMode = OperatingMode.manual;
    _systemStatus = _systemStatus.copyWith(
      mode: OperatingMode.manual,
      brightness: brightness,
    );
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.setManualBrightness(brightness);
      try {
        final directStatus = await _apiService.getSystemStatus();
        _systemStatus = directStatus.copyWith(mode: OperatingMode.manual);
      } catch (_) {
        // Direct status update failed; keep optimistic state
      }
      _lastConfirmedMode = OperatingMode.manual;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastConfirmedMode = previousMode;
      _systemStatus = previousStatus;
      _errorMessage = 'Failed to set brightness: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update settings
  ///
  /// Sends updated settings to ESP32.
  ///
  /// Parameters:
  /// - [settings]: Settings object with new values
  ///
  /// Returns: True if successful
  Future<bool> updateSettings(Settings settings) async {
    try {
      await _apiService.updateSettings(settings);
      _settings = settings;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update settings: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set operating mode
  ///
  /// Changes the operating mode of the system.
  ///
  /// Parameters:
  /// - [mode]: Operating mode ('auto' or 'manual')
  ///
  /// Returns: True if successful
  Future<bool> setMode(String mode) async {
    final previousMode = _lastConfirmedMode;
    final previousStatus = _systemStatus;

    // Optimistically update local mode state so UI responds instantly
    _lastConfirmedMode = mode;
    _systemStatus = _systemStatus.copyWith(mode: mode);
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.setMode(mode);
      try {
        final directStatus = await _apiService.getSystemStatus();
        _systemStatus = directStatus.copyWith(mode: mode);
      } catch (_) {
        // If direct status check fails, keep optimistic state with confirmed mode
      }
      _lastConfirmedMode = mode;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // Revert if command request fails
      _lastConfirmedMode = previousMode;
      _systemStatus = previousStatus;
      _errorMessage = 'Failed to set mode: $e';
      notifyListeners();
      return false;
    }
  }

  /// Restore default settings
  ///
  /// Resets settings to default values and sends to ESP32.
  ///
  /// Returns: True if successful
  Future<bool> restoreDefaultSettings() async {
    try {
      await _apiService.restoreDefaults();
      _settings = Settings.defaultSettings();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to restore default settings: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  ///
  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Manual connection attempt
  ///
  /// Manually attempts to connect to ESP32.
  ///
  /// Returns: True if connection successful
  Future<bool> connect() async {
    return _connectionService.connect();
  }

  /// Saves and verifies the local ESP32 address used for all control actions.
  Future<bool> setEsp32Host(String host) async {
    try {
      _apiService.setHost(host);
      _thingSpeakService.esp32Address = _apiService.host;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('esp32_host', _apiService.host);
      final connected = await _apiService.testConnection();
      _connectionStatus = connected
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected;
      _errorMessage =
          connected ? null : 'ESP32 did not respond at ${_apiService.host}.';
      notifyListeners();
      return connected;
    } catch (e) {
      _errorMessage = 'Invalid ESP32 address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect
  ///
  /// Manually disconnects from ESP32.
  void disconnect() {
    _connectionService.disconnect();
    stopPolling();
  }

  /// Refresh historical data from ThingSpeak
  ///
  /// Fetches historical feed data from ThingSpeak.
  ///
  /// Parameters:
  /// - [results]: Number of results to fetch
  /// - [start]: Start datetime (ISO 8601 format)
  /// - [end]: End datetime (ISO 8601 format)
  Future<void> refreshHistory({
    int results = 100,
    String? start,
    String? end,
  }) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      if (_useThingSpeak && !_isOffline) {
        _thingSpeakHistory =
            await _thingSpeakService.getChannelFeedWithTimeRange(
          results: results,
          start: start,
          end: end,
        );
        _isThingSpeakConnected = true;
        _errorMessage = null;
      } else {
        _thingSpeakHistory = null;
      }
    } catch (e) {
      _isThingSpeakConnected = false;
      _errorMessage = 'Failed to fetch history: $e';
      _thingSpeakHistory = null;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Toggle ThingSpeak integration
  ///
  /// Enables or disables ThingSpeak integration.
  ///
  /// Parameters:
  /// - [enabled]: Whether to enable ThingSpeak
  void toggleThingSpeak(bool enabled) {
    _useThingSpeak = enabled;
    if (enabled) {
      startPolling();
    } else {
      stopPolling();
      startPolling();
    }
    notifyListeners();
  }

  /// Check ThingSpeak connection
  ///
  /// Tests connectivity to ThingSpeak.
  Future<void> _checkThingSpeakConnection() async {
    if (_useThingSpeak && !_isOffline) {
      _isThingSpeakConnected = await _thingSpeakService.testConnection();
    } else {
      _isThingSpeakConnected = false;
    }
  }

  /// Generate event logs from ThingSpeak feeds
  ///
  /// Converts ThingSpeak feed data to EventLog objects.
  EventLogList _generateLogsFromThingSpeak(List<ThingSpeakFeed> feeds) {
    final logs = <EventLog>[];

    for (int i = 0; i < feeds.length; i++) {
      final feed = feeds[i];
      final prevFeed = i > 0 ? feeds[i - 1] : null;

      // Detect state changes
      final currentState = SystemStatus.fromJson(feed.toSystemStatus()).state;
      final prevState = prevFeed == null
          ? null
          : SystemStatus.fromJson(prevFeed.toSystemStatus()).state;

      if (currentState != prevState && prevState != null) {
        logs.add(EventLog(
          id: 'evt_${feed.entryId}_state',
          timestamp: feed.createdAt,
          eventType: 'state',
          message: 'State Changed to $currentState',
          details: 'Previous: $prevState',
        ));
      }

      // Detect presence changes
      final currentPresence = feed.getFieldAsBool('presence');
      final prevPresence = prevFeed?.getFieldAsBool('presence');

      if (currentPresence != prevPresence && prevPresence != null) {
        logs.add(EventLog(
          id: 'evt_${feed.entryId}_presence',
          timestamp: feed.createdAt,
          eventType: 'presence',
          message: currentPresence ? 'Presence Detected' : 'No Presence',
          details: null,
        ));
      }

      // Detect significant brightness changes
      final currentBrightness = feed.getFieldAsInt('brightness');
      final prevBrightness = prevFeed?.getFieldAsInt('brightness');

      if (prevBrightness != null &&
          (currentBrightness - prevBrightness).abs() > 10) {
        logs.add(EventLog(
          id: 'evt_${feed.entryId}_brightness',
          timestamp: feed.createdAt,
          eventType: 'brightness',
          message: 'Brightness $currentBrightness%',
          details: 'Previous: $prevBrightness%',
        ));
      }
    }

    return EventLogList(logs);
  }

  /// Calculate statistics from ThingSpeak feeds
  ///
  /// Calculates statistics from ThingSpeak historical data.
  Map<String, dynamic> _calculateStatisticsFromThingSpeak(
      List<ThingSpeakFeed> feeds) {
    if (feeds.isEmpty) {
      return {
        'active_time': 0,
        'idle_time': 0,
        'sleep_time': 0,
        'avg_brightness': 0.0,
        'presence_events': 0,
        'energy_saving_time': 0,
      };
    }

    final brightnessValues = feeds
        .map((f) => f.getFieldAsDouble('brightness'))
        .where((v) => v > 0)
        .toList();

    final avgBrightness = brightnessValues.isNotEmpty
        ? brightnessValues.reduce((a, b) => a + b) / brightnessValues.length
        : 0.0;

    final presenceCount =
        feeds.where((f) => f.getFieldAsBool('presence')).length;

    // Fields 6-8 are cumulative milliseconds supplied by the ESP32. Use the
    // most recent values instead of estimating from feed count.
    final latest = feeds.last;
    final activeTime = latest.getFieldAsInt('active_time') ~/ 1000;
    final idleTime = latest.getFieldAsInt('idle_time') ~/ 1000;
    final sleepTime = latest.getFieldAsInt('sleep_time') ~/ 1000;
    final energySavingTime = sleepTime + idleTime;

    return {
      'active_time': activeTime,
      'idle_time': idleTime,
      'sleep_time': sleepTime,
      'avg_brightness': avgBrightness,
      'presence_events': presenceCount,
      'energy_saving_time': energySavingTime,
    };
  }

  /// Toggle Theme Mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system, switch to the opposite of current system brightness (we don't have direct access here easily, so we just default to dark if toggled from system)
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    _connectionStatusSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _connectionService.dispose();
    _thingSpeakService.dispose();
    super.dispose();
  }
}
