/// Helper Functions
/// 
/// This file contains utility functions and helper methods used
/// throughout the application.
/// 
/// Purpose: Provide reusable utility functions for common operations
/// such as formatting, validation, and data transformation.

import 'dart:async';
import 'package:intl/intl.dart';

/// Format duration in seconds to human-readable format
/// 
/// Converts a duration in seconds to a formatted string.
/// 
/// Parameters:
/// - [seconds]: Duration in seconds
/// 
/// Returns: Formatted string (e.g., "2h 30m" or "45m")
String formatDuration(int seconds) {
  if (seconds <= 0) return '0m';

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}

/// Format timestamp to time string
/// 
/// Converts a DateTime to a formatted time string.
/// 
/// Parameters:
/// - [dateTime]: DateTime to format
/// 
/// Returns: Formatted time string (HH:mm:ss)
String formatTime(DateTime dateTime) {
  return DateFormat('HH:mm:ss').format(dateTime);
}

/// Format timestamp to date string
/// 
/// Converts a DateTime to a formatted date string.
/// 
/// Parameters:
/// - [dateTime]: DateTime to format
/// 
/// Returns: Formatted date string (dd/MM/yyyy)
String formatDate(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy').format(dateTime);
}

/// Format timestamp to date and time string
/// 
/// Converts a DateTime to a formatted date and time string.
/// 
/// Parameters:
/// - [dateTime]: DateTime to format
/// 
/// Returns: Formatted date and time string (dd/MM/yyyy HH:mm:ss)
String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
}

/// Format timestamp to relative time string
/// 
/// Converts a DateTime to a relative time string (e.g., "2 minutes ago").
/// 
/// Parameters:
/// - [dateTime]: DateTime to format
/// 
/// Returns: Relative time string
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else {
    return formatDate(dateTime);
  }
}

/// Validate IP address format
/// 
/// Validates if a string is a valid IPv4 address.
/// 
/// Parameters:
/// - [ip]: IP address string to validate
/// 
/// Returns: True if valid IP address
bool isValidIpAddress(String ip) {
  final regex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );
  return regex.hasMatch(ip);
}

/// Clamp value between min and max
/// 
/// Clamps a numeric value between minimum and maximum bounds.
/// 
/// Parameters:
/// - [value]: Value to clamp
/// - [min]: Minimum value
/// - [max]: Maximum value
/// 
/// Returns: Clamped value
double clampValue(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Map value from one range to another
/// 
/// Maps a value from one range to another range.
/// 
/// Parameters:
/// - [value]: Value to map
/// - [inMin]: Input range minimum
/// - [inMax]: Input range maximum
/// - [outMin]: Output range minimum
/// - [outMax]: Output range maximum
/// 
/// Returns: Mapped value
double mapValue(
  double value,
  double inMin,
  double inMax,
  double outMin,
  double outMax,
) {
  return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
}

/// Calculate percentage
/// 
/// Calculates percentage of value relative to total.
/// 
/// Parameters:
/// - [value]: Current value
/// - [total]: Total value
/// 
/// Returns: Percentage (0-100)
double calculatePercentage(double value, double total) {
  if (total == 0) return 0.0;
  return (value / total) * 100;
}

/// Format number with decimal places
/// 
/// Formats a number with specified decimal places.
/// 
/// Parameters:
/// - [value]: Number to format
/// - [decimalPlaces]: Number of decimal places
/// 
/// Returns: Formatted string
String formatNumber(double value, {int decimalPlaces = 1}) {
  return value.toStringAsFixed(decimalPlaces);
}

/// Truncate string with ellipsis
/// 
/// Truncates a string to specified length and adds ellipsis.
/// 
/// Parameters:
/// - [text]: String to truncate
/// - [maxLength]: Maximum length
/// 
/// Returns: Truncated string
String truncateString(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Capitalize first letter of string
/// 
/// Capitalizes the first letter of a string.
/// 
/// Parameters:
/// - [text]: String to capitalize
/// 
/// Returns: Capitalized string
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

/// Convert brightness percentage to PWM value
/// 
/// Converts brightness percentage (0-100) to PWM value (0-255).
/// 
/// Parameters:
/// - [brightness]: Brightness percentage (0-100)
/// 
/// Returns: PWM value (0-255)
int brightnessToPwm(int brightness) {
  return (brightness * 2.55).round().clamp(0, 255);
}

/// Convert PWM value to brightness percentage
/// 
/// Converts PWM value (0-255) to brightness percentage (0-100).
/// 
/// Parameters:
/// - [pwm]: PWM value (0-255)
/// 
/// Returns: Brightness percentage (0-100)
int pwmToBrightness(int pwm) {
  return (pwm / 2.55).round().clamp(0, 100);
}

/// Check if value is within range
/// 
/// Checks if a value is within the specified range.
/// 
/// Parameters:
/// - [value]: Value to check
/// - [min]: Minimum value
/// - [max]: Maximum value
/// 
/// Returns: True if value is within range
bool isInRange(double value, double min, double max) {
  return value >= min && value <= max;
}

/// Debounce function
/// 
/// Creates a debounced version of a function.
/// 
/// Parameters:
/// - [function]: Function to debounce
/// - [milliseconds]: Debounce delay in milliseconds
/// 
/// Returns: Debounced function
Function debounce(Function function, int milliseconds) {
  Timer? timer;
  return () {
    if (timer != null) timer!.cancel();
    timer = Timer(Duration(milliseconds: milliseconds), () {
      function();
    });
  };
}

/// Throttle function
/// 
/// Creates a throttled version of a function.
/// 
/// Parameters:
/// - [function]: Function to throttle
/// - [milliseconds]: Throttle delay in milliseconds
/// 
/// Returns: Throttled function
Function throttle(Function function, int milliseconds) {
  bool isThrottled = false;
  return () {
    if (isThrottled) return;
    isThrottled = true;
    function();
    Future.delayed(Duration(milliseconds: milliseconds), () {
      isThrottled = false;
    });
  };
}
