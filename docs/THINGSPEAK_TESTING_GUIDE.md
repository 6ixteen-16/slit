# ThingSpeak Integration Testing Guide

## Overview

This guide provides comprehensive testing procedures for the ThingSpeak integration in the Smart Light Flutter application.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Configuration Testing](#configuration-testing)
- [Connection Testing](#connection-testing)
- [Data Retrieval Testing](#data-retrieval-testing)
- [Historical Data Testing](#historical-data-testing)
- [Statistics Testing](#statistics-testing)
- [Logs Testing](#logs-testing)
- [Offline Mode Testing](#offline-mode-testing)
- [Error Handling Testing](#error-handling-testing)
- [Performance Testing](#performance-testing)
- [UI Testing](#ui-testing)
- [Integration Testing](#integration-testing)

---

## Prerequisites

### Before Testing

1. **ThingSpeak Channel Setup**
   - Create a ThingSpeak account
   - Create a channel with 8 fields
   - Note your Channel ID
   - Copy Read API Key and Write API Key

2. **ESP32 Configuration**
   - Ensure ESP32 is uploading data to ThingSpeak
   - Verify field mapping matches ESP32 configuration
   - Confirm data is being sent at regular intervals

3. **Flutter Configuration**
   - Update `lib/config/thingspeak_config.dart` with your credentials
   - Verify dependencies are installed (`flutter pub get`)
   - Ensure device has internet connection

4. **Test Environment**
   - Test on physical device (recommended)
   - Ensure stable internet connection
   - Have Wi-Fi available for offline testing

---

## Configuration Testing

### Test 1: Verify Configuration File

**Objective**: Ensure ThingSpeak configuration is correctly set up.

**Steps**:
1. Open `lib/config/thingspeak_config.dart`
2. Verify the following values:
   - `channelId`: Your ThingSpeak channel ID
   - `readApiKey`: Your Read API Key
   - `writeApiKey`: Your Write API Key
   - `updateInterval`: 15000 (15 seconds)
   - `connectionTimeout`: 10000 (10 seconds)

**Expected Result**: All configuration values are correctly set.

**Failure Indicators**:
- Placeholder values like 'YOUR_CHANNEL_ID'
- Empty strings
- Incorrect API keys

---

## Connection Testing

### Test 2: ThingSpeak Connectivity

**Objective**: Verify the application can connect to ThingSpeak.

**Steps**:
1. Run the application: `flutter run`
2. Navigate to Dashboard screen
3. Observe ThingSpeak status widget in app bar
4. Wait for initial data fetch

**Expected Result**:
- ThingSpeak status widget shows green indicator
- Status text displays "Connected"
- Dashboard displays live data

**Failure Indicators**:
- Red indicator (offline)
- Yellow indicator (connecting)
- "Failed to fetch status" error message

**Troubleshooting**:
- Check internet connection
- Verify API key is correct
- Confirm ThingSpeak service is operational
- Check for rate limiting

### Test 3: Connection Recovery

**Objective**: Verify automatic reconnection after connection loss.

**Steps**:
1. Ensure ThingSpeak is connected
2. Disable device Wi-Fi
3. Wait 10 seconds
4. Re-enable Wi-Fi
5. Observe ThingSpeak status

**Expected Result**:
- Status changes to "Offline" when Wi-Fi disabled
- Status changes to "Connecting" when Wi-Fi re-enabled
- Status changes to "Connected" after successful reconnection

---

## Data Retrieval Testing

### Test 4: Live Data Fetching

**Objective**: Verify live data is fetched from ThingSpeak.

**Steps**:
1. Ensure ThingSpeak is connected
2. Navigate to Dashboard screen
3. Observe sensor cards (Presence, Ambient Light, Brightness, PWM)
4. Wait for 15-30 seconds
5. Verify data updates

**Expected Result**:
- All sensor cards display values
- Values update every 15 seconds
- Presence indicator reflects current state
- Brightness matches ThingSpeak field value

**Failure Indicators**:
- Values remain static
- "Failed to fetch status" error
- Incorrect values displayed

### Test 5: Data Accuracy

**Objective**: Verify fetched data matches ThingSpeak values.

**Steps**:
1. Open ThingSpeak channel in browser
2. Note current field values
3. Compare with Flutter app values
4. Trigger presence detection on ESP32
5. Verify both update simultaneously

**Expected Result**:
- Flutter values match ThingSpeak values
- Updates occur within 15 seconds
- Data types are correct (int, float, bool)

---

## Historical Data Testing

### Test 6: Historical Data Retrieval

**Objective**: Verify historical data can be fetched.

**Steps**:
1. Navigate to Statistics screen
2. Select "Day" time range
3. Wait for data fetch
4. Verify charts display data

**Expected Result**:
- Time distribution chart shows data
- Brightness trend chart displays
- Statistics cards show calculated values

**Failure Indicators**:
- Charts are empty
- "Failed to fetch history" error
- Statistics show zeros

### Test 7: Time Range Selection

**Objective**: Verify different time ranges work correctly.

**Steps**:
1. Navigate to Statistics screen
2. Select "Hour" time range
3. Verify data loads
4. Select "Day" time range
5. Verify data loads
6. Select "Week" time range
7. Verify data loads

**Expected Result**:
- Each time range loads appropriate data
- Charts update with new data
- Statistics recalculate based on range

**Failure Indicators**:
- Time range chips don't respond
- Data doesn't change when range changes
- Error on specific ranges

---

## Statistics Testing

### Test 8: Statistics Calculation

**Objective**: Verify statistics are calculated correctly from ThingSpeak data.

**Steps**:
1. Navigate to Statistics screen
2. Select "Day" time range
3. Note calculated statistics:
   - Average Brightness
   - Presence Events
   - Active Time
   - Idle Time
   - Sleep Time
   - Energy Saving Time
4. Manually calculate from ThingSpeak data
5. Compare with app values

**Expected Result**:
- Average brightness matches calculation
- Presence count matches feed count
- Time estimates are reasonable
- Energy saving time is calculated correctly

**Failure Indicators**:
- Statistics are zero
- Values don't match manual calculation
- Negative time values

### Test 9: Chart Rendering

**Objective**: Verify charts render ThingSpeak data correctly.

**Steps**:
1. Navigate to Statistics screen
2. Observe Time Distribution pie chart
3. Observe Brightness Trend line chart
4. Verify data points are visible
5. Check chart labels and legends

**Expected Result**:
- Pie chart shows time distribution segments
- Line chart shows brightness over time
- Colors match theme
- Labels are readable

**Failure Indicators**:
- Charts are empty
- Colors are incorrect
- Labels are missing
- Chart crashes

---

## Logs Testing

### Test 10: Log Generation

**Objective**: Verify logs are generated from ThingSpeak feeds.

**Steps**:
1. Navigate to Logs screen
2. Wait for logs to load
3. Verify logs are displayed
4. Check log types (presence, brightness, state)
5. Verify timestamps are correct

**Expected Result**:
- Logs display in chronological order
- Event types are correct
- Timestamps match feed timestamps
- Messages are descriptive

**Failure Indicators**:
- Logs screen is empty
- Logs are not chronological
- Event types are incorrect
- Timestamps are wrong

### Test 11: Log Filtering

**Objective**: Verify log filtering works correctly.

**Steps**:
1. Navigate to Logs screen
2. Tap filter icon
3. Select "Presence" filter
4. Verify only presence events show
5. Select "Brightness" filter
6. Verify only brightness events show

**Expected Result**:
- Filter menu displays options
- Selected filter applies correctly
- Only matching events are shown
- Filter can be reset

---

## Offline Mode Testing

### Test 12: Offline Fallback

**Objective**: Verify ESP32 fallback works when offline.

**Steps**:
1. Ensure ESP32 is on local network
2. Enable ThingSpeak in Settings
3. Disable device Wi-Fi
4. Wait for connection timeout
5. Verify data still displays
6. Check connection status

**Expected Result**:
- ThingSpeak status shows "Offline"
- Data continues to display (from ESP32)
- No error messages
- App remains functional

**Failure Indicators**:
- App crashes
- All data disappears
- Error messages displayed
- App becomes unresponsive

### Test 13: Offline to Online Transition

**Objective**: Verify smooth transition from offline to online.

**Steps**:
1. Disable Wi-Fi (offline mode)
2. Verify ESP32 fallback is working
3. Re-enable Wi-Fi
4. Wait for ThingSpeak reconnection
5. Verify ThingSpeak status changes
6. Check data source switches back

**Expected Result**:
- ThingSpeak status changes to "Connecting"
- Then changes to "Connected"
- Data source switches to ThingSpeak
- No data loss during transition

---

## Error Handling Testing

### Test 14: Invalid API Key

**Objective**: Verify handling of invalid API key.

**Steps**:
1. Temporarily set invalid API key in config
2. Run application
3. Observe error handling
4. Restore correct API key

**Expected Result**:
- Error message displayed to user
- ThingSpeak status shows error
- ESP32 fallback attempted
- App doesn't crash

### Test 15: Invalid Channel ID

**Objective**: Verify handling of invalid channel ID.

**Steps**:
1. Temporarily set invalid channel ID in config
2. Run application
3. Observe error handling
4. Restore correct channel ID

**Expected Result**:
- Error message displayed
- "Channel Not Found" error
- ESP32 fallback attempted
- App remains functional

### Test 16: Rate Limit Exceeded

**Objective**: Verify handling of rate limit errors.

**Steps**:
1. Reduce polling interval to 1 second
2. Run application
3. Observe behavior after multiple requests
4. Restore normal interval

**Expected Result**:
- Rate limit error detected
- Retry with backoff
- Error message displayed if persistent
- App doesn't crash

---

## Performance Testing

### Test 17: Polling Performance

**Objective**: Verify polling doesn't impact performance.

**Steps**:
1. Run application with ThingSpeak enabled
2. Monitor CPU and memory usage
3. Observe UI responsiveness
4. Check for lag or stuttering

**Expected Result**:
- CPU usage remains low
- Memory usage is stable
- UI remains smooth
- No noticeable lag

**Failure Indicators**:
- High CPU usage
- Memory leaks
- UI stuttering
- Battery drain

### Test 18: Data Loading Performance

**Objective**: Verify historical data loading performance.

**Steps**:
1. Navigate to Statistics screen
2. Select "Week" time range
3. Measure load time
4. Verify UI remains responsive

**Expected Result**:
- Data loads within 5 seconds
- Loading indicator displays
- UI doesn't freeze
- Charts render smoothly

---

## UI Testing

### Test 19: ThingSpeak Status Widget

**Objective**: Verify ThingSpeak status widget displays correctly.

**Steps**:
1. Run application
2. Check app bar for ThingSpeak widget
3. Verify icon and color
4. Check compact mode
5. Navigate to Dashboard
6. Check full mode widget

**Expected Result**:
- Widget displays in app bar (compact)
- Widget displays on dashboard (full)
- Icon matches status
- Color indicates status (green/yellow/red)
- Text is descriptive

### Test 20: Data Source Toggle

**Objective**: Verify data source toggle works correctly.

**Steps**:
1. Navigate to Settings screen
2. Find Data Source section
3. Toggle ThingSpeak off
4. Verify ESP32 connection is used
5. Toggle ThingSpeak on
6. Verify ThingSpeak is used

**Expected Result**:
- Toggle switch works smoothly
- Status text updates
- Data source changes
- Polling interval adjusts
- No errors during switch

---

## Integration Testing

### Test 21: End-to-End Flow

**Objective**: Verify complete flow from ESP32 to ThingSpeak to Flutter.

**Steps**:
1. Ensure ESP32 is uploading to ThingSpeak
2. Run Flutter application
3. Enable ThingSpeak in Settings
4. Navigate to Dashboard
5. Trigger presence detection on ESP32
6. Wait 15 seconds
7. Verify Flutter app updates
8. Navigate to Statistics
9. Verify historical data includes event
10. Navigate to Logs
11. Verify log entry exists

**Expected Result**:
- ESP32 uploads to ThingSpeak
- Flutter fetches from ThingSpeak
- Dashboard updates with new data
- Statistics include new data
- Logs show event
- Complete flow works smoothly

### Test 22: Multi-Device Sync

**Objective**: Verify data syncs across multiple devices.

**Steps**:
1. Run app on Device A
2. Run app on Device B
3. Enable ThingSpeak on both
4. Trigger presence detection
5. Wait for sync
6. Verify both devices update

**Expected Result**:
- Both devices show same data
- Updates occur within polling interval
- No conflicts or errors
- Consistent state across devices

---

## Test Checklist

Use this checklist to verify all tests pass:

- [ ] Configuration file correctly set up
- [ ] ThingSpeak connectivity established
- [ ] Connection recovery works
- [ ] Live data fetching works
- [ ] Data accuracy verified
- [ ] Historical data retrieval works
- [ ] Time range selection works
- [ ] Statistics calculation correct
- [ ] Chart rendering works
- [ ] Log generation works
- [ ] Log filtering works
- [ ] Offline fallback works
- [ ] Offline to online transition works
- [ ] Invalid API key handled
- [ ] Invalid channel ID handled
- [ ] Rate limit handled
- [ ] Polling performance acceptable
- [ ] Data loading performance acceptable
- [ ] Status widget displays correctly
- [ ] Data source toggle works
- [ ] End-to-end flow works
- [ ] Multi-device sync works

---

## Test Results Template

```
Test Date: ___________
Tester: ___________
Device: ___________
Flutter Version: ___________
ThingSpeak Channel ID: ___________

Test Results:
[ ] Configuration Testing - PASS/FAIL
[ ] Connection Testing - PASS/FAIL
[ ] Data Retrieval Testing - PASS/FAIL
[ ] Historical Data Testing - PASS/FAIL
[ ] Statistics Testing - PASS/FAIL
[ ] Logs Testing - PASS/FAIL
[ ] Offline Mode Testing - PASS/FAIL
[ ] Error Handling Testing - PASS/FAIL
[ ] Performance Testing - PASS/FAIL
[ ] UI Testing - PASS/FAIL
[ ] Integration Testing - PASS/FAIL

Notes:
___________________________________________________________
___________________________________________________________
___________________________________________________________

Issues Found:
___________________________________________________________
___________________________________________________________
___________________________________________________________

Resolution:
___________________________________________________________
___________________________________________________________
___________________________________________________________
```

---

## Common Issues and Solutions

### Issue: ThingSpeak Not Connecting

**Symptoms**: Status shows "Connecting" indefinitely

**Solutions**:
1. Verify internet connection
2. Check API key is correct
3. Verify channel ID is correct
4. Check ThingSpeak service status
5. Increase timeout in config

### Issue: Data Not Updating

**Symptoms**: Values remain static

**Solutions**:
1. Check polling interval
2. Verify ESP32 is uploading
3. Check field mapping
4. Verify ThingSpeak has recent data
5. Clear cache

### Issue: Statistics Incorrect

**Symptoms**: Calculated values are wrong

**Solutions**:
1. Verify historical data fetch
2. Check calculation logic
3. Verify time range
4. Check for null values
5. Verify feed count

### Issue: Logs Not Generated

**Symptoms**: Logs screen empty

**Solutions**:
1. Verify historical data fetch
2. Check log generation logic
3. Verify event detection thresholds
4. Check for sufficient data
5. Verify timestamps

---

## Conclusion

**Following this testing guide ensures the ThingSpeak integration is thoroughly tested and production-ready. Document any issues found and resolutions applied for future reference.**
## the esp32 code
/*
 * ============================================================================
 *  ADAPTIVE INTELLIGENT ENERGY-EFFICIENT LIGHTING SYSTEM (v7 - Enterprise)
 *  BH1750 + LD2410 + XY-MOS PWM + ThingSpeak Telemetry + REST API for Flutter
 * ============================================================================
 *  Key Improvements & Fixes in v7:
 *    1. Non-Blocking WebServer & REST API: Full CORS support (handling OPTIONS)
 *       and zero-latency client request execution. Flutter manual control requests
 *       no longer time out during ThingSpeak HTTP uploads.
 *    2. Smooth Micro-Blink & Pure Ambient Sensing:
 *       - Initial snapshot taken BEFORE turning on LEDs when presence is detected.
 *       - Periodic resample uses a 15ms high-speed low-res pulse every 60s (configurable),
 *         eliminating multi-second flickering while occupied.
 *    3. Multi-Stage Inactivity Dimming: Smooth transitions:
 *       ACTIVE -> DIM_1 (60%) -> DIM_2 (30%) -> DIM_3 (15%) -> SLEEP (0%).
 *    4. Energy Analytics & Savings Calculator: Real-time estimation of active/idle/sleep
 *       time accumulators and energy saved percentage vs 100% baseline.
 *    5. ThingSpeak Telemetry (100% Preserved Mapping):
 *       Field1=presence  Field2=lux  Field3=brightness%  Field4=pwm
 *       Field5=state     Field6=activeTimeMs  Field7=idleTimeMs  Field8=sleepTimeMs
 *
 *  Dependencies (Arduino Library Manager):
 *    - ld2410 by ncmreynolds
 *    - BH1750 by claws
 *    - ThingSpeak by MathWorks
 *    - ArduinoJson by bblanchon (v7.x)
 *    - WiFi.h / WebServer.h ship with ESP32 core
 * ============================================================================
 */

#include <Wire.h>
#include <BH1750.h>
#include <ld2410.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include "ThingSpeak.h"

// ============================================================================
// CREDENTIALS & NETWORK CONFIGURATION
// ============================================================================
const char* WIFI_SSID         = "YOUR_WIFI_SSID";     // Replace with your Wi-Fi SSID
const char* WIFI_PASSWORD     = "YOUR_WIFI_PASSWORD"; // Replace with your Wi-Fi Password
unsigned long TS_CHANNEL_ID   = 3429218;             // Your ThingSpeak channel ID
const char*   TS_WRITE_KEY    = "MRYAEMJXMM8F22S0";  // Your ThingSpeak Write API Key

// ============================================================================
// PIN DEFINITIONS
// ============================================================================
static const uint8_t PIN_MOSFET_PWM = 18;
static const uint8_t PIN_RADAR_RX   = 16;
static const uint8_t PIN_RADAR_TX   = 17;
static const uint8_t PIN_I2C_SDA    = 21;
static const uint8_t PIN_I2C_SCL    = 22;

// ============================================================================
// PWM CONFIGURATION
// ============================================================================
static const uint32_t PWM_FREQUENCY_HZ   = 5000;
static const uint8_t  PWM_RESOLUTION_BIT = 8;     // 0..255 range

// ============================================================================
// THINGSPEAK FIELD MAPPING
// ============================================================================
static const uint8_t TS_FIELD_PRESENCE    = 1;
static const uint8_t TS_FIELD_LUX        = 2;
static const uint8_t TS_FIELD_BRIGHTNESS  = 3;   // 0-100%
static const uint8_t TS_FIELD_PWM        = 4;   // 0-255
static const uint8_t TS_FIELD_STATE      = 5;   // 0=ACTIVE..4=SLEEP
static const uint8_t TS_FIELD_ACTIVE_MS  = 6;
static const uint8_t TS_FIELD_IDLE_MS    = 7;
static const uint8_t TS_FIELD_SLEEP_MS   = 8;

// ============================================================================
// RUNTIME SYSTEM SETTINGS
// ============================================================================
struct SystemSettings {
  float    luxThresholdOff        = 35.0;  // Room is sufficiently bright
  float    luxThresholdOn         = 25.0;  // Room is dark enough for light
  float    luxMin                 = 2.0;   // Minimum ambient lux for max brightness
  uint8_t  activeMinPwm           = 30;    // Minimum active state PWM floor
  float    fadeSpeed              = 5.0;   // Smooth fade interpolation speed
  unsigned long timeBeforeDim1Ms  = 10000UL;  // Active -> Dim Level 1 (10s)
  unsigned long timeBeforeDim2Ms  = 30000UL;  // Dim 1 -> Dim Level 2 (30s)
  unsigned long timeBeforeDim3Ms  = 60000UL;  // Dim 2 -> Dim Level 3 (60s)
  unsigned long timeBeforeOffMs   = 120000UL; // Dim 3 -> Sleep Off (120s)
  unsigned long microBlinkIntervalMs = 60000UL; // Resample ambient lux period
} settings;

static const SystemSettings DEFAULT_SETTINGS = SystemSettings();

static const uint8_t BRIGHTNESS_DIM_LEVEL_1 = 153; // 60% PWM
static const uint8_t BRIGHTNESS_DIM_LEVEL_2 = 76;  // 30% PWM
static const uint8_t BRIGHTNESS_DIM_LEVEL_3 = 38;  // 15% PWM
static const uint8_t BRIGHTNESS_OFF         = 0;   // 0% PWM

// ============================================================================
// RADAR SENSITIVITY CONFIGURATION
// ============================================================================
static const uint8_t  RADAR_MAX_MOVING_GATE           = 1;
static const uint8_t  RADAR_MAX_STATIONARY_GATE       = 1;
static const uint16_t RADAR_INACTIVITY_TIMEOUT_SEC    = 3;
static const uint8_t  RADAR_GATE0_MOVING_THRESHOLD    = 70;
static const uint8_t  RADAR_GATE0_STATIONARY_THRESHOLD = 70;
static const uint8_t  RADAR_GATE1_MOVING_THRESHOLD    = 85;
static const uint8_t  RADAR_GATE1_STATIONARY_THRESHOLD = 85;

// ============================================================================
// TIMING INTERVALS
// ============================================================================
static const unsigned long STATUS_PRINT_INTERVAL_MS   = 1000UL;
static const unsigned long THINGSPEAK_INTERVAL_MS     = 20000UL; // ThingSpeak 20s rate limit

// ============================================================================
// EVENT LOG SYSTEM (Ring Buffer for /logs)
// ============================================================================
static const uint8_t EVENT_LOG_CAPACITY = 40;
struct EventEntry {
  unsigned long timestampMs;
  char message[48];
};
EventEntry eventLog[EVENT_LOG_CAPACITY];
uint8_t eventLogHead  = 0;
uint8_t eventLogCount = 0;

void logEvent(const char* msg) {
  eventLog[eventLogHead].timestampMs = millis();
  strncpy(eventLog[eventLogHead].message, msg, sizeof(eventLog[eventLogHead].message) - 1);
  eventLog[eventLogHead].message[sizeof(eventLog[eventLogHead].message) - 1] = '\0';
  eventLogHead = (eventLogHead + 1) % EVENT_LOG_CAPACITY;
  if (eventLogCount < EVENT_LOG_CAPACITY) eventLogCount++;
  Serial.print(F("[EVENT] ")); Serial.println(msg);
}

// ============================================================================
// STATISTICS & ENERGY ANALYTICS ACCUMULATOR
// ============================================================================
struct Statistics {
  unsigned long activeTimeMs          = 0;
  unsigned long idleTimeMs            = 0;
  unsigned long sleepTimeMs           = 0;
  unsigned long presenceEventCount    = 0;
  float         brightnessSampleSum   = 0;
  unsigned long brightnessSampleCount = 0;
  unsigned long statsStartMs          = 0;
} stats;

// ============================================================================
// SYSTEM STATES & GLOBAL OPERATIONAL VARIABLES
// ============================================================================
enum SystemState    { STATE_ACTIVE = 0, STATE_DIM_LEVEL_1 = 1, STATE_DIM_LEVEL_2 = 2, STATE_DIM_LEVEL_3 = 3, STATE_SLEEP = 4 };
enum OperatingMode  { MODE_AUTO, MODE_MANUAL };

BH1750         lightMeter;
HardwareSerial RadarSerial(2);
ld2410         radar;
WiFiClient     tsClient;
WebServer      server(80);

SystemState   currentState          = STATE_SLEEP;
OperatingMode currentMode           = MODE_AUTO;

bool          presenceDetected      = false;
bool          wasPresentLastLoop    = false;
bool          roomIsDark            = true; // Hysteresis state
unsigned long presenceLostTimestamp = 0;

int           targetBrightness      = 0;    // 0..255 target PWM
float         currentBrightness     = 0.0;  // Current smooth PWM duty
float         currentLux            = 0.0;  // Ambient light in lux
int           manualBrightness      = 0;    // 0..255 manual target PWM

unsigned long lastStatusPrintTime   = 0;
unsigned long lastThingSpeakTime    = 0;
unsigned long lastMicroBlinkTime    = 0;
unsigned long lastStatTickTime      = 0;
unsigned long lastWiFiReconnectAttempt = 0;

// ============================================================================
// PROTOTYPES
// ============================================================================
void  initializeSystem();
void  connectWiFi();
void  checkWiFiConnection();
void  initializePWM();
void  writePwmDuty(uint8_t duty);
void  initializeRadar();
void  initializeWebServer();
float readAmbientLight();
float performMicroBlinkReading();
int   calculateActiveBrightness(float lux);
void  updateStateMachine();
void  fadeToBrightness();
void  updateLighting();
void  updateStatistics();
void  printSystemStatus();
void  sendTelemetryToThingSpeak();
const char* stateToString(SystemState state);
int   stateToInt(SystemState state);
float calculateEnergySavedPercent();

// REST Handlers with CORS
void sendCorsHeaders();
void sendJson(int code, JsonDocument& doc);
void sendError(int code, const char* message);
void handleOptions();
void handleGetStatus();
void handleGetLogs();
void handleGetStatistics();
void handlePostManual();
void handlePostMode();
void handlePostSettings();
void handleNotFound();

// ============================================================================
// SETUP & MAIN LOOP
// ============================================================================
void setup() {
  initializeSystem();
}

void loop() {
  // 1. Process incoming HTTP client requests immediately (Zero latency)
  server.handleClient();

  // 2. Read presence sensor
  radar.read();
  presenceDetected = radar.presenceDetected();

  // 3. Ambient Light Sampling Logic
  unsigned long now = millis();
  if (presenceDetected && currentMode == MODE_AUTO) {
    // Periodic high-speed micro-resample every settings.microBlinkIntervalMs
    if (now - lastMicroBlinkTime >= settings.microBlinkIntervalMs) {
      currentLux = performMicroBlinkReading();
      targetBrightness = calculateActiveBrightness(currentLux);
      lastMicroBlinkTime = now;
    }
  } else if (!presenceDetected) {
    // When room is unoccupied, continuously read true ambient light (LEDs off/dimmed)
    currentLux = readAmbientLight();
    lastMicroBlinkTime = now;
  }

  // 4. Update State Machine, Smooth Fading, Statistics
  updateStateMachine();
  fadeToBrightness();
  updateLighting();
  updateStatistics();
  printSystemStatus();

  // 5. Send Telemetry Non-Blocking
  sendTelemetryToThingSpeak();
}

// ============================================================================
// INITIALIZATION PROCEDURES
// ============================================================================
void initializeSystem() {
  Serial.begin(115200);
  delay(200);
  Serial.println(F("\n=== Smart Light Adaptive System v7 (Enterprise) Booting ==="));

  connectWiFi();
  tsClient.setTimeout(5000);
  ThingSpeak.begin(tsClient);

  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
    Serial.println(F("[INIT] BH1750 Ambient Light Sensor OK."));
  } else {
    Serial.println(F("[INIT] WARNING: BH1750 Light Sensor non-responsive."));
  }

  initializeRadar();
  initializePWM();
  initializeWebServer();

  currentState          = STATE_SLEEP;
  presenceLostTimestamp = millis();
  stats.statsStartMs    = millis();
  lastStatTickTime      = millis();
  lastMicroBlinkTime    = millis();

  logEvent("System booted v7");
  Serial.println(F("=== Init complete. Web server active on port 80 ===\n"));
}

void connectWiFi() {
  Serial.print(F("[WIFI] Connecting to: "));
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 10000) {
    delay(200);
    Serial.print(F("."));
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print(F("[WIFI] Connected. ESP32 Local IP: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("\n[WIFI] Wi-Fi connection pending/offline. WebServer running locally."));
  }
}

void checkWiFiConnection() {
  if (WiFi.status() == WL_CONNECTED) return;

  unsigned long now = millis();
  if (now - lastWiFiReconnectAttempt > 10000UL) {
    lastWiFiReconnectAttempt = now;
    Serial.println(F("[WIFI] Wi-Fi disconnected. Attempting non-blocking reconnect..."));
    WiFi.disconnect();
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  }
}

void writePwmDuty(uint8_t duty) {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(PIN_MOSFET_PWM, duty);
#else
  ledcWrite(0, duty);
#endif
}

void initializePWM() {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  if (!ledcAttach(PIN_MOSFET_PWM, PWM_FREQUENCY_HZ, PWM_RESOLUTION_BIT)) {
    Serial.println(F("[INIT] WARNING: PWM ledcAttach failed."));
  }
#else
  ledcSetup(0, PWM_FREQUENCY_HZ, PWM_RESOLUTION_BIT);
  ledcAttachPin(PIN_MOSFET_PWM, 0);
#endif
  writePwmDuty(0);
}

void initializeRadar() {
  RadarSerial.begin(256000, SERIAL_8N1, PIN_RADAR_RX, PIN_RADAR_TX);
  if (!radar.begin(RadarSerial)) {
    Serial.println(F("[INIT] WARNING: LD2410 Radar sensor not responding."));
    return;
  }
  Serial.println(F("[INIT] LD2410 Radar initialized."));
  delay(200);
  radar.setMaxValues(RADAR_MAX_MOVING_GATE, RADAR_MAX_STATIONARY_GATE, RADAR_INACTIVITY_TIMEOUT_SEC);
  radar.setGateSensitivityThreshold(0, RADAR_GATE0_MOVING_THRESHOLD, RADAR_GATE0_STATIONARY_THRESHOLD);
  radar.setGateSensitivityThreshold(1, RADAR_GATE1_MOVING_THRESHOLD, RADAR_GATE1_STATIONARY_THRESHOLD);
}

void initializeWebServer() {
  // CORS Preflight Handlers
  server.on("/status",     HTTP_OPTIONS, handleOptions);
  server.on("/logs",       HTTP_OPTIONS, handleOptions);
  server.on("/statistics", HTTP_OPTIONS, handleOptions);
  server.on("/manual",     HTTP_OPTIONS, handleOptions);
  server.on("/mode",       HTTP_OPTIONS, handleOptions);
  server.on("/settings",   HTTP_OPTIONS, handleOptions);

  // REST API Endpoint Handlers
  server.on("/status",     HTTP_GET,     handleGetStatus);
  server.on("/logs",       HTTP_GET,     handleGetLogs);
  server.on("/statistics", HTTP_GET,     handleGetStatistics);
  server.on("/manual",     HTTP_POST,    handlePostManual);
  server.on("/mode",       HTTP_POST,    handlePostMode);
  server.on("/settings",   HTTP_POST,    handlePostSettings);
  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println(F("[INIT] REST Web Server online on port 80 with CORS support."));
}

// ============================================================================
// SENSOR & AMBIENT LIGHT LOGIC
// ============================================================================
float readAmbientLight() {
  float lux = lightMeter.readLightLevel();
  return (lux < 0) ? 0.0 : lux;
}

/*
 * performMicroBlinkReading() — Fast 15ms Ultra-High Speed Resample
 * Briefly pauses PWM for 15ms to read pure ambient lux without noticeable blink.
 */
float performMicroBlinkReading() {
  uint8_t prevPwm = (uint8_t)currentBrightness;
  writePwmDuty(0);
  lightMeter.configure(BH1750::ONE_TIME_LOW_RES_MODE);
  delay(15);
  float cleanLux = lightMeter.readLightLevel();
  if (cleanLux < 0) cleanLux = 0.0;
  writePwmDuty(prevPwm);
  lightMeter.configure(BH1750::CONTINUOUS_HIGH_RES_MODE);
  return cleanLux;
}

// ============================================================================
// BRIGHTNESS CALCULATION WITH HYSTERESIS
// ============================================================================
int calculateActiveBrightness(float lux) {
  if (roomIsDark && lux > settings.luxThresholdOff) {
    roomIsDark = false;
  } else if (!roomIsDark && lux < settings.luxThresholdOn) {
    roomIsDark = true;
  }

  if (!roomIsDark) return 0;
  if (lux <= settings.luxMin) return 255;

  float scale = (settings.luxThresholdOff - lux) / (settings.luxThresholdOff - settings.luxMin);
  int targetPwm = settings.activeMinPwm + (int)(scale * (255 - settings.activeMinPwm));
  return constrain(targetPwm, 0, 255);
}

// ============================================================================
// STATE MACHINE & INACTIVITY TIMEOUTS
// ============================================================================
void updateStateMachine() {
  // Manual mode override
  if (currentMode == MODE_MANUAL) {
    currentState     = STATE_ACTIVE;
    targetBrightness = manualBrightness;
    return;
  }

  // Occupied state
  if (presenceDetected) {
    if (!wasPresentLastLoop) {
      // Snapshot ambient BEFORE turning on LEDs (100% pure ambient reading)
      currentLux       = readAmbientLight();
      targetBrightness = calculateActiveBrightness(currentLux);
      stats.presenceEventCount++;
      logEvent("Occupancy detected");
    }
    currentState       = STATE_ACTIVE;
    wasPresentLastLoop = true;
    return;
  }

  // Occupancy lost transition
  if (wasPresentLastLoop) {
    presenceLostTimestamp = millis();
    wasPresentLastLoop    = false;
    logEvent("Occupancy lost");
  }

  // Inactivity multi-stage dimming timeline
  unsigned long elapsed = millis() - presenceLostTimestamp;

  if (elapsed < settings.timeBeforeDim1Ms) {
    currentState     = STATE_ACTIVE;
  } else if (elapsed < settings.timeBeforeDim2Ms) {
    if (currentState != STATE_DIM_LEVEL_1) logEvent("Inactivity: Dim Level 1 (60%)");
    currentState     = STATE_DIM_LEVEL_1;
    targetBrightness = BRIGHTNESS_DIM_LEVEL_1;
  } else if (elapsed < settings.timeBeforeDim3Ms) {
    if (currentState != STATE_DIM_LEVEL_2) logEvent("Inactivity: Dim Level 2 (30%)");
    currentState     = STATE_DIM_LEVEL_2;
    targetBrightness = BRIGHTNESS_DIM_LEVEL_2;
  } else if (elapsed < settings.timeBeforeOffMs) {
    if (currentState != STATE_DIM_LEVEL_3) logEvent("Inactivity: Dim Level 3 (15%)");
    currentState     = STATE_DIM_LEVEL_3;
    targetBrightness = BRIGHTNESS_DIM_LEVEL_3;
  } else {
    if (currentState != STATE_SLEEP) logEvent("Inactivity: Sleep (Off)");
    currentState     = STATE_SLEEP;
    targetBrightness = BRIGHTNESS_OFF;
  }
}

void fadeToBrightness() {
  float diff = targetBrightness - currentBrightness;
  if (abs(diff) > 0.5) {
    currentBrightness += (diff / settings.fadeSpeed);
  } else {
    currentBrightness = (float)targetBrightness;
  }
}

void updateLighting() {
  writePwmDuty((uint8_t)currentBrightness);
}

// ============================================================================
// STATISTICS & ENERGY ANALYTICS
// ============================================================================
void updateStatistics() {
  unsigned long now   = millis();
  unsigned long delta = now - lastStatTickTime;
  lastStatTickTime    = now;

  switch (currentState) {
    case STATE_ACTIVE:      stats.activeTimeMs += delta; break;
    case STATE_DIM_LEVEL_1:
    case STATE_DIM_LEVEL_2:
    case STATE_DIM_LEVEL_3: stats.idleTimeMs   += delta; break;
    case STATE_SLEEP:       stats.sleepTimeMs  += delta; break;
  }
  stats.brightnessSampleSum += currentBrightness;
  stats.brightnessSampleCount++;
}

float calculateEnergySavedPercent() {
  if (stats.brightnessSampleCount == 0) return 0.0;
  float avgPwm = stats.brightnessSampleSum / stats.brightnessSampleCount;
  float energySaved = (1.0 - (avgPwm / 255.0)) * 100.0;
  return constrain(energySaved, 0.0, 100.0);
}

// ============================================================================
// THINGSPEAK UPLOAD (NON-BLOCKING)
// ============================================================================
void sendTelemetryToThingSpeak() {
  unsigned long now = millis();
  if (now - lastThingSpeakTime < THINGSPEAK_INTERVAL_MS) return;
  lastThingSpeakTime = now;

  // Non-blocking WiFi reconnect check
  checkWiFiConnection();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(F("[THINGSPEAK] Upload skipped: Wi-Fi not connected."));
    return;
  }

  ThingSpeak.setField(TS_FIELD_PRESENCE,   (int)presenceDetected);
  ThingSpeak.setField(TS_FIELD_LUX,        currentLux);
  ThingSpeak.setField(TS_FIELD_BRIGHTNESS, (int)((currentBrightness / 255.0) * 100));
  ThingSpeak.setField(TS_FIELD_PWM,        (int)currentBrightness);
  ThingSpeak.setField(TS_FIELD_STATE,      stateToInt(currentState));
  ThingSpeak.setField(TS_FIELD_ACTIVE_MS,  (long)stats.activeTimeMs);
  ThingSpeak.setField(TS_FIELD_IDLE_MS,    (long)stats.idleTimeMs);
  ThingSpeak.setField(TS_FIELD_SLEEP_MS,   (long)stats.sleepTimeMs);

  int code = ThingSpeak.writeFields(TS_CHANNEL_ID, TS_WRITE_KEY);
  if (code == 200) {
    Serial.println(F("[THINGSPEAK] Telemetry upload successful (200 OK)."));
  } else {
    Serial.print(F("[THINGSPEAK] Upload failed with code "));
    Serial.print(code);
    if (code == -401) {
      Serial.println(F(" (Rate limit exceeded: wait >= 15 seconds between updates)"));
    } else if (code == -301) {
      Serial.println(F(" (Failed to connect to ThingSpeak server - Network/DNS error)"));
    } else if (code == -302 || code == -303) {
      Serial.println(F(" (Unable to send data to server)"));
    } else if (code == 0 || code == 404 || code == 400) {
      Serial.println(F(" (Invalid TS_CHANNEL_ID or TS_WRITE_KEY)"));
    } else {
      Serial.println();
    }
  }
}

// ============================================================================
// DIAGNOSTIC LOGGING & HELPERS
// ============================================================================
void printSystemStatus() {
  unsigned long now = millis();
  if (now - lastStatusPrintTime < STATUS_PRINT_INTERVAL_MS) return;
  lastStatusPrintTime = now;

  unsigned long inactiveElapsed = presenceDetected ? 0 : (now - presenceLostTimestamp) / 1000;

  Serial.print(F("Lux: "));         Serial.print(currentLux, 1);
  Serial.print(F(" | Presence: ")); Serial.print(presenceDetected ? "YES" : "NO ");
  Serial.print(F(" | Mode: "));     Serial.print(currentMode == MODE_AUTO ? "AUTO" : "MAN");
  Serial.print(F(" | State: "));    Serial.print(stateToString(currentState));
  Serial.print(F(" | PWM: "));      Serial.print((int)currentBrightness);
  Serial.print(F(" | Inactive: ")); Serial.print(inactiveElapsed);
  Serial.print(F("s | Energy Saved: ")); Serial.print(calculateEnergySavedPercent(), 1);
  Serial.println(F("%"));
}

const char* stateToString(SystemState state) {
  switch (state) {
    case STATE_ACTIVE:      return "ACTIVE";
    case STATE_DIM_LEVEL_1: return "DIM_LEVEL_1";
    case STATE_DIM_LEVEL_2: return "DIM_LEVEL_2";
    case STATE_DIM_LEVEL_3: return "DIM_LEVEL_3";
    case STATE_SLEEP:       return "SLEEP";
  }
  return "UNKNOWN";
}

int stateToInt(SystemState state) {
  return (int)state;
}

// ============================================================================
// REST API HANDLERS WITH FULL CORS SUPPORT
// ============================================================================
void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

void sendJson(int code, JsonDocument& doc) {
  sendCorsHeaders();
  String out;
  serializeJson(doc, out);
  server.send(code, "application/json", out);
}

void sendError(int code, const char* msg) {
  JsonDocument doc;
  doc["error"] = msg;
  sendJson(code, doc);
}

void handleOptions() {
  sendCorsHeaders();
  server.send(204);
}

void handleGetStatus() {
  JsonDocument doc;
  doc["presence"]          = presenceDetected;
  doc["lux"]               = currentLux;
  doc["ambient_light"]     = currentLux;
  doc["brightness"]        = (int)((currentBrightness / 255.0) * 100);
  doc["brightnessPercent"] = (int)((currentBrightness / 255.0) * 100);
  doc["pwm"]               = (int)currentBrightness;
  doc["pwm_value"]         = (int)currentBrightness;
  doc["mode"]              = (currentMode == MODE_AUTO) ? "auto" : "manual";
  doc["state"]             = stateToString(currentState);
  doc["inactiveSeconds"]   = presenceDetected ? 0 : (millis() - presenceLostTimestamp) / 1000;
  doc["uptimeMs"]          = millis();
  doc["energySavedPercent"]= calculateEnergySavedPercent();
  doc["wifiConnected"]     = (WiFi.status() == WL_CONNECTED);
  sendJson(200, doc);
}

void handleGetLogs() {
  JsonDocument doc;
  JsonArray arr = doc["events"].to<JsonArray>();
  uint8_t startIndex = (eventLogCount < EVENT_LOG_CAPACITY) ? 0 : eventLogHead;
  for (uint8_t i = 0; i < eventLogCount; i++) {
    uint8_t idx = (startIndex + i) % EVENT_LOG_CAPACITY;
    JsonObject e = arr.add<JsonObject>();
    e["timestampMs"] = eventLog[idx].timestampMs;
    e["message"]     = eventLog[idx].message;
  }
  sendJson(200, doc);
}

void handleGetStatistics() {
  JsonDocument doc;
  doc["activeTimeMs"]          = stats.activeTimeMs;
  doc["idleTimeMs"]            = stats.idleTimeMs;
  doc["sleepTimeMs"]           = stats.sleepTimeMs;
  doc["presenceEventCount"]    = stats.presenceEventCount;
  doc["averageBrightnessPwm"]  = stats.brightnessSampleCount > 0 ? (stats.brightnessSampleSum / stats.brightnessSampleCount) : 0;
  doc["energySavedPercent"]    = calculateEnergySavedPercent();
  doc["sinceMs"]               = millis() - stats.statsStartMs;
  sendJson(200, doc);
}

void handlePostManual() {
  if (!server.hasArg("plain")) { sendError(400, "Missing HTTP body"); return; }
  JsonDocument doc;
  if (deserializeJson(doc, server.arg("plain"))) { sendError(400, "Invalid JSON"); return; }
  if (!doc["brightness"].is<int>()) { sendError(400, "Missing brightness integer field"); return; }

  int pct = constrain(doc["brightness"].as<int>(), 0, 100);
  manualBrightness = (int)((pct / 100.0) * 255);
  currentMode = MODE_MANUAL;

  char msg[48];
  snprintf(msg, sizeof(msg), "Manual brightness set: %d%%", pct);
  logEvent(msg);

  JsonDocument res;
  res["success"]    = true;
  res["brightness"] = pct;
  sendJson(200, res);
}

void handlePostMode() {
  if (!server.hasArg("plain")) { sendError(400, "Missing HTTP body"); return; }
  JsonDocument doc;
  if (deserializeJson(doc, server.arg("plain"))) { sendError(400, "Invalid JSON"); return; }
  if (!doc["mode"].is<const char*>()) { sendError(400, "Missing mode string field"); return; }

  String mode = doc["mode"].as<String>();
  if (mode == "auto") {
    currentMode = MODE_AUTO;
    logEvent("Mode switched to AUTO");
  } else if (mode == "manual") {
    currentMode = MODE_MANUAL;
    logEvent("Mode switched to MANUAL");
  } else {
    sendError(400, "mode field must be 'auto' or 'manual'");
    return;
  }
  JsonDocument res;
  res["success"] = true;
  res["mode"]    = mode;
  sendJson(200, res);
}

void handlePostSettings() {
  if (!server.hasArg("plain")) { sendError(400, "Missing HTTP body"); return; }
  JsonDocument doc;
  if (deserializeJson(doc, server.arg("plain"))) { sendError(400, "Invalid JSON"); return; }

  if (doc["restoreDefaults"].is<bool>() && doc["restoreDefaults"].as<bool>()) {
    settings = DEFAULT_SETTINGS;
    logEvent("Settings restored to defaults");
  } else {
    if (doc["luxThresholdOff"].is<float>())          settings.luxThresholdOff       = doc["luxThresholdOff"];
    if (doc["luxThresholdOn"].is<float>())           settings.luxThresholdOn        = doc["luxThresholdOn"];
    if (doc["fadeSpeed"].is<float>())                settings.fadeSpeed             = doc["fadeSpeed"];
    if (doc["timeBeforeDim1Ms"].is<unsigned long>()) settings.timeBeforeDim1Ms      = doc["timeBeforeDim1Ms"];
    if (doc["timeBeforeDim2Ms"].is<unsigned long>()) settings.timeBeforeDim2Ms      = doc["timeBeforeDim2Ms"];
    if (doc["timeBeforeDim3Ms"].is<unsigned long>()) settings.timeBeforeDim3Ms      = doc["timeBeforeDim3Ms"];
    if (doc["timeBeforeOffMs"].is<unsigned long>())  settings.timeBeforeOffMs       = doc["timeBeforeOffMs"];
    if (doc["microBlinkIntervalMs"].is<unsigned long>()) settings.microBlinkIntervalMs = doc["microBlinkIntervalMs"];
    logEvent("Settings updated via API");
  }
  JsonDocument res;
  res["success"] = true;
  sendJson(200, res);
}

void handleNotFound() {
  sendCorsHeaders();
  sendError(404, "Endpoint not found");
}


