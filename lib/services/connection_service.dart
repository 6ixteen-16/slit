/// Connection Service
/// 
/// This service monitors the connection status to the ESP32 and provides
/// real-time connection state updates to the application.
/// 
/// Purpose: Manage connection state, handle reconnection logic, and
/// provide connection status to the UI layer.
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:smart_light/config/api_constants.dart';
import 'package:smart_light/services/api_service.dart';

/// Connection Status
/// 
/// Enumeration of possible connection states.
class ConnectionStatus {
  static const String connected = 'connected';
  static const String disconnected = 'disconnected';
  static const String connecting = 'connecting';
  static const String error = 'error';
}

/// Connection Service
/// 
/// Singleton service class for monitoring and managing ESP32 connection.
/// 
/// Features:
/// - Periodic connection health checks
/// - Network connectivity monitoring
/// - Automatic reconnection attempts
/// - Connection status broadcasting via Stream
/// - Error handling and recovery
class ConnectionService {
  // Singleton pattern
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();

  // Connection state
  String _currentStatus = ConnectionStatus.disconnected;
  String? _errorMessage;
  Timer? _healthCheckTimer;
  Timer? _reconnectTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Status stream controller
  final _statusController = StreamController<String>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  /// Stream of connection status updates
  Stream<String> get statusStream => _statusController.stream;

  /// Stream of connection error messages
  Stream<String?> get errorStream => _errorController.stream;

  /// Current connection status
  String get currentStatus => _currentStatus;

  /// Current error message (if any)
  String? get errorMessage => _errorMessage;

  /// Initialize connection service
  /// 
  /// Starts monitoring network connectivity and begins health checks.
  /// 
  /// Parameters:
  /// - [autoConnect]: Whether to automatically attempt connection (default: true)
  void initialize({bool autoConnect = true}) {
    _currentStatus = ConnectionStatus.disconnected;
    _statusController.add(_currentStatus);

    // Monitor network connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _onConnectivityChanged([result]);
      },
    );

    if (autoConnect) {
      startHealthCheck();
    }
  }

  /// Handle connectivity changes
  /// 
  /// Called when network connectivity state changes.
  /// 
  /// Parameters:
  /// - [results]: List of current connectivity results
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.mobile);

    if (!hasConnection) {
      _updateStatus(ConnectionStatus.disconnected, 'Network unavailable');
    } else if (_currentStatus == ConnectionStatus.disconnected) {
      // Network available but not connected to ESP32, attempt reconnection
      _attemptReconnection();
    }
  }

  /// Start health check timer
  /// 
  /// Begins periodic connection health checks to ESP32.
  void startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(milliseconds: pollingInterval * 5),
      (_) => _performHealthCheck(),
    );
  }

  /// Stop health check timer
  /// 
  /// Stops periodic connection health checks.
  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Perform health check
  /// 
  /// Tests connection to ESP32 and updates status accordingly.
  Future<void> _performHealthCheck() async {
    try {
      final isConnected = await _apiService.testConnection();
      if (isConnected) {
        _updateStatus(ConnectionStatus.connected);
      } else {
        _updateStatus(ConnectionStatus.disconnected, 'ESP32 unreachable');
      }
    } catch (e) {
      _updateStatus(ConnectionStatus.disconnected, 'Health check failed: $e');
    }
  }

  /// Attempt reconnection
  /// 
  /// Initiates reconnection attempt with exponential backoff.
  void _attemptReconnection() {
    _reconnectTimer?.cancel();
    _updateStatus(ConnectionStatus.connecting);

    int retryCount = 0;
    const maxRetries = 5;

    void attemptConnection() {
      if (retryCount >= maxRetries) {
        _updateStatus(ConnectionStatus.disconnected, 'Max reconnection attempts reached');
        return;
      }

      _apiService.testConnection().then((isConnected) {
        if (isConnected) {
          _updateStatus(ConnectionStatus.connected);
          _reconnectTimer?.cancel();
        } else {
          retryCount++;
          final delay = Duration(milliseconds: retryDelay * retryCount);
          _reconnectTimer = Timer(delay, attemptConnection);
        }
      }).catchError((error) {
        retryCount++;
        final delay = Duration(milliseconds: retryDelay * retryCount);
        _reconnectTimer = Timer(delay, attemptConnection);
      });
    }

    attemptConnection();
  }

  /// Manual connection attempt
  /// 
  /// Manually triggers a connection attempt to the ESP32.
  /// 
  /// Returns: True if connection successful
  Future<bool> connect() async {
    _updateStatus(ConnectionStatus.connecting);

    try {
      final isConnected = await _apiService.testConnection();
      if (isConnected) {
        _updateStatus(ConnectionStatus.connected);
        startHealthCheck();
        return true;
      } else {
        _updateStatus(ConnectionStatus.disconnected, 'Connection failed');
        return false;
      }
    } catch (e) {
      _updateStatus(ConnectionStatus.disconnected, 'Connection error: $e');
      return false;
    }
  }

  /// Disconnect
  /// 
  /// Manually disconnects from the ESP32 and stops health checks.
  void disconnect() {
    stopHealthCheck();
    _reconnectTimer?.cancel();
    _updateStatus(ConnectionStatus.disconnected, 'Disconnected by user');
  }

  /// Update connection status
  /// 
  /// Updates the current connection status and notifies listeners.
  /// 
  /// Parameters:
  /// - [status]: New connection status
  /// - [error]: Optional error message
  void _updateStatus(String status, [String? error]) {
    _currentStatus = status;
    _errorMessage = error;
    _statusController.add(status);
    _errorController.add(error);
  }

  /// Check if currently connected
  /// 
  /// Returns true if connected to ESP32.
  /// 
  /// Returns: Boolean indicating connection status
  bool get isConnected => _currentStatus == ConnectionStatus.connected;

  /// Check if currently connecting
  /// 
  /// Returns true if connection attempt is in progress.
  /// 
  /// Returns: Boolean indicating connecting state
  bool get isConnecting => _currentStatus == ConnectionStatus.connecting;

  /// Dispose of resources
  /// 
  /// Cancels timers and subscriptions, closes streams.
  void dispose() {
    _healthCheckTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
    _errorController.close();
  }
}
