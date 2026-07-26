import 'package:flutter_test/flutter_test.dart';
import 'package:smart_light/models/system_status.dart';
import 'package:smart_light/models/thingspeak_feed.dart';

void main() {
  test('parses the ESP32 v6 status response', () {
    final status = SystemStatus.fromJson({
      'presence': true,
      'lux': 12.5,
      'brightnessPercent': 75,
      'pwm': 191,
      'mode': 'manual',
      'state': 'DIM_LEVEL_2',
    });

    expect(status.presence, isTrue);
    expect(status.ambientLight, 12.5);
    expect(status.brightness, 75);
    expect(status.pwmValue, 191);
    expect(status.mode, 'manual');
    expect(status.state, 'dim2');
    expect(status.connectionStatus, 'connected');
  });

  test('maps numeric ThingSpeak state values to the UI state', () {
    final feed = ThingSpeakFeed.fromJson({
      'entry_id': 1,
      'created_at': '2026-01-01T00:00:00Z',
      'field1': '1',
      'field2': '10.4',
      'field3': '50',
      'field4': '127',
      'field5': '4',
    });

    final status = SystemStatus.fromJson(feed.toSystemStatus());
    expect(status.presence, isTrue);
    expect(status.ambientLight, 10.4);
    expect(status.brightness, 50);
    expect(status.pwmValue, 127);
    expect(status.state, 'sleep');
  });
}
