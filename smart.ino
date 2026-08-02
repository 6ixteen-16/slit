/*
 * ============================================================================
 *  ADAPTIVE INTELLIGENT ENERGY-EFFICIENT LIGHTING SYSTEM (v5 - Micro-Blink)
 *  BH1750 (I2C lux) + HLK-LD2410B (UART presence) + MOSFET PWM + Wi-Fi Telemetry
 * ============================================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <BH1750.h>
#include <ld2410.h>
#include <WiFi.h>
#include <WiFiClient.h>
#include <WebServer.h>
#include "ThingSpeak.h"

// NETWORK AND THINGSPEAK CREDENTIALS
const char* ssid = "\u67e5\u745c\u5b81\u7684\u4e09\u661fS\u5341\u6b63";
const char* pass = "@#6ixteen";     
unsigned long myChannelNumber = 3429218;
const char* myWriteAPIKey = "MRYAEMJXMM8F22S0";

// AUTOMATIC IP CONFIGURATION
// Using DHCP instead of static IP

// PIN CONFIGURATION
static const uint8_t PIN_MOSFET_PWM = 18;
static const uint8_t PIN_RADAR_RX   = 16;  // ESP32 RX2 <- LD2410 TX
static const uint8_t PIN_RADAR_TX   = 17;  // ESP32 TX2 -> LD2410 RX
static const uint8_t PIN_I2C_SDA    = 21;
static const uint8_t PIN_I2C_SCL    = 22;

// PWM CONFIGURATION
static const uint32_t PWM_FREQUENCY_HZ   = 5000;
static const uint8_t  PWM_RESOLUTION_BIT = 8;  // 0-255

// AMBIENT LIGHT THRESHOLDS (lux)
static const float LUX_THRESHOLD = 30.0;
static const float LUX_MIN       = 2.0;
static const uint8_t ACTIVE_MIN_PWM = 30;

// ENERGY ESTIMATION
static const float MAX_LED_POWER_W = 5.0; // 5W estimate for the strip

// RADAR RANGE / SENSITIVITY
static const uint8_t RADAR_MAX_MOVING_GATE     = 0;
static const uint8_t RADAR_MAX_STATIONARY_GATE = 0;
static const uint16_t RADAR_INACTIVITY_TIMEOUT_SEC = 5;
static const uint8_t RADAR_GATE0_MOVING_THRESHOLD     = 75; // Increased to 75 to only detect strong close-range reflections (inside 12cm box)
static const uint8_t RADAR_GATE0_STATIONARY_THRESHOLD = 75; // Increased to 75
static const uint8_t RADAR_GATE1_MOVING_THRESHOLD     = 100;
static const uint8_t RADAR_GATE1_STATIONARY_THRESHOLD = 100;

// Ignore a presence dropout shorter than this - treat it as the same
// occupancy session instead of a fresh entry. This is what stops the
// disco-blink: the LD2410 can flicker true/false a few times right as
// someone walks in, and each flicker was re-triggering a full micro-blink.
static const unsigned long PRESENCE_REENTRY_DEBOUNCE_MS = 1500UL;

// TIME-BASED DIMMING
static const unsigned long TIME_BEFORE_DIM_1_MS = 10000UL;
static const unsigned long TIME_BEFORE_DIM_2_MS = 30000UL;
static const unsigned long TIME_BEFORE_DIM_3_MS = 60000UL;
static const unsigned long TIME_BEFORE_OFF_MS   = 120000UL;

static const uint8_t BRIGHTNESS_DIM_LEVEL_1 = 153; // 60%
static const uint8_t BRIGHTNESS_DIM_LEVEL_2 = 76;  // 30%
static const uint8_t BRIGHTNESS_DIM_LEVEL_3 = 38;  // 15%
static const uint8_t BRIGHTNESS_OFF         = 0;

// FADE & TELEMETRY TIMING
static const float FADE_SPEED = 5.0;
static const unsigned long FADE_INTERVAL_MS = 15UL; // Fixed interval for smooth fading
static const unsigned long STATUS_PRINT_INTERVAL_MS = 500UL;
static const unsigned long THINGSPEAK_INTERVAL_MS = 20000UL; 

static const unsigned long MICRO_BLINK_INTERVAL_DEFAULT_MS = 5000UL;
unsigned long microBlinkIntervalMs = MICRO_BLINK_INTERVAL_DEFAULT_MS;
unsigned long lastMicroBlinkTime = 0;

// STATE MACHINE & SYSTEM VARIABLES
enum SystemState { STATE_ACTIVE, STATE_DIM_LEVEL_1, STATE_DIM_LEVEL_2, STATE_DIM_LEVEL_3, STATE_SLEEP };

BH1750 lightMeter;
HardwareSerial RadarSerial(2);
ld2410 radar;
WiFiClient client;
WebServer server(80);

SystemState currentState = STATE_SLEEP;
bool presenceDetected = false;
unsigned long presenceLostTimestamp = 0;

int   targetBrightness  = 0;
float currentBrightness = 0.0;
float currentLux = 0.0;

unsigned long lastStatusPrintTime = 0;
unsigned long lastThingSpeakTime = 0;

unsigned long totalActiveTimeMs = 0;
unsigned long totalIdleTimeMs = 0;
unsigned long totalSleepTimeMs = 0;
unsigned long lastTimeUpdate = 0;
float totalEnergyWattSeconds = 0.0;

String operatingMode = "auto";
int manualBrightness = 0; // 0-100

// PROTOTYPES
void initializeSystem();
void connectWiFi();
void setupWebServer();
void handleStatus();
void handleStatistics();
void handleLogs();
void handleMode();
void handleManual();
void handleSettings();
void initializePWM();
void initializeRadar();
float readAmbientLight();
float performMicroBlinkReading();
int calculateActiveBrightness(float lux);
void updateStateMachine();
void fadeToBrightness();
void updateLighting();
void printSystemStatus();
void sendTelemetryToThingSpeak();
const char* stateToString(SystemState state);

void setup() {
  initializeSystem();
}

void loop() {
  radar.read();
  bool rawPresence = radar.presenceDetected();
  unsigned long now = millis();

  if (rawPresence) {
    presenceLostTimestamp = now;
  }
  
  presenceDetected = (now - presenceLostTimestamp <= PRESENCE_REENTRY_DEBOUNCE_MS);

  if (presenceDetected) {
    // If the LED is completely OFF, we can freely measure true ambient light without a micro-blink!
    if (currentBrightness == 0.0) {
      currentLux = readAmbientLight();
      lastMicroBlinkTime = now; // Reset timer so we don't immediately blink if it turns on
    } else if (now - lastMicroBlinkTime >= microBlinkIntervalMs && operatingMode != "manual") {
      currentLux = performMicroBlinkReading();
      lastMicroBlinkTime = now; // Refresh timestamp after blocking micro-blink
    }
  } else {
    // When unoccupied, only update ambient light if the light is completely off
    // so we don't accidentally measure our own fade-out glow.
    if (currentBrightness == 0.0) {
      currentLux = readAmbientLight();
    }
    lastMicroBlinkTime = now; 
  }

  updateStateMachine();

  unsigned long timeNow = millis();
  unsigned long dt = timeNow - lastTimeUpdate;
  lastTimeUpdate = timeNow;
  
  if (currentState == STATE_ACTIVE) {
    totalActiveTimeMs += dt;
  } else if (currentState == STATE_SLEEP) {
    totalSleepTimeMs += dt;
  } else {
    totalIdleTimeMs += dt;
  }

  // Energy Calculation
  float currentPowerW = MAX_LED_POWER_W * (currentBrightness / 255.0);
  totalEnergyWattSeconds += currentPowerW * (dt / 1000.0);

  fadeToBrightness();
  updateLighting();
  server.handleClient();
  printSystemStatus();
  sendTelemetryToThingSpeak();
}

void initializeSystem() {
  Serial.begin(115200);
  delay(300);
  Serial.println(F("\n=== Adaptive Lighting System v5 - Booting ==="));

  connectWiFi();
  ThingSpeak.begin(client);

  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE)) {
    Serial.println(F("[INIT] BH1750 OK."));
    delay(200); // Give BH1750 time to complete its first continuous high-res reading
    currentLux = readAmbientLight();
  } else {
    Serial.println(F("[INIT] WARNING: BH1750 not responding."));
  }

  initializeRadar();
  initializePWM();
  setupWebServer();

  currentState = STATE_SLEEP;
  // Initialize to simulate an old presence loss so it starts turned off
  presenceLostTimestamp = millis() - TIME_BEFORE_OFF_MS;
  lastTimeUpdate = millis();
  Serial.println(F("=== Init complete ===\n"));
}

void connectWiFi() {
  Serial.print(F("[WIFI] Connecting to SSID: "));
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  // Force clearing of any previously saved static IP in NVS to ensure DHCP is used
  WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE, INADDR_NONE);
  WiFi.begin(ssid, pass);
  
  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 15000) {
    delay(500);
    Serial.print(F("."));
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(F("\n[WIFI] Connected successfully!"));
    Serial.print(F("[WIFI] IP Address: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("\n[WIFI] Connection failed. Running system in offline fallback mode."));
  }
}

void initializePWM() {
  if (!ledcAttach(PIN_MOSFET_PWM, PWM_FREQUENCY_HZ, PWM_RESOLUTION_BIT)) {
    Serial.println(F("[INIT] WARNING: ledcAttach failed."));
  }
  ledcWrite(PIN_MOSFET_PWM, 0);
}

void initializeRadar() {
  // Expand RX buffer to prevent buffer overflow/dropouts while ThingSpeak blocks
  RadarSerial.setRxBufferSize(1024);
  RadarSerial.begin(256000, SERIAL_8N1, PIN_RADAR_RX, PIN_RADAR_TX);
  if (!radar.begin(RadarSerial)) {
    Serial.println(F("[INIT] WARNING: LD2410 did not respond."));
    return;
  }
  Serial.println(F("[INIT] LD2410 radar initialized."));
  delay(500);

  radar.setMaxValues(RADAR_MAX_MOVING_GATE, RADAR_MAX_STATIONARY_GATE, RADAR_INACTIVITY_TIMEOUT_SEC);
  radar.setGateSensitivityThreshold(0, RADAR_GATE0_MOVING_THRESHOLD, RADAR_GATE0_STATIONARY_THRESHOLD);
  radar.setGateSensitivityThreshold(1, RADAR_GATE1_MOVING_THRESHOLD, RADAR_GATE1_STATIONARY_THRESHOLD);
  Serial.println(F("[INIT] Radar range/sensitivity reconfigured for box demo."));
}

float readAmbientLight() {
  float lux = lightMeter.readLightLevel();
  if (lux < 0) lux = 0.0;
  return lux;
}

float performMicroBlinkReading() {
  Serial.println(F("[MICRO-BLINK] Triggering true background environmental sample..."));
  
  ledcWrite(PIN_MOSFET_PWM, 0); 
  
  lightMeter.configure(BH1750::ONE_TIME_LOW_RES_MODE);
  
  delay(24); 
  
  float cleanLux = lightMeter.readLightLevel();
  if (cleanLux < 0) cleanLux = 0.0;
  
  ledcWrite(PIN_MOSFET_PWM, (uint8_t)currentBrightness); 
  
  lightMeter.configure(BH1750::CONTINUOUS_HIGH_RES_MODE);
  
  Serial.print(F("[MICRO-BLINK] Finished. Pure Environment Lux: "));
  Serial.println(cleanLux, 1);
  
  return cleanLux;
}

int calculateActiveBrightness(float lux) {
  if (lux >= LUX_THRESHOLD) return 0;
  if (lux <= LUX_MIN) return 255;

  float scale = (LUX_THRESHOLD - lux) / (LUX_THRESHOLD - LUX_MIN);
  int brightness = ACTIVE_MIN_PWM + (int)(scale * (255 - ACTIVE_MIN_PWM));
  return constrain(brightness, 0, 255);
}

void updateStateMachine() {
  if (operatingMode == "manual") {
    targetBrightness = (manualBrightness * 255) / 100;
    // When manual, we skip auto dimming timers and ambient light overrides.
    // However, we still update the presenceLostTimestamp so it doesn't instantly sleep when going back to auto
    if (presenceDetected) {
      presenceLostTimestamp = millis();
    }
    return;
  }

  unsigned long inactiveElapsed = millis() - presenceLostTimestamp;

  int activeTarget = calculateActiveBrightness(currentLux);

  if (inactiveElapsed < TIME_BEFORE_DIM_1_MS) {
    currentState = STATE_ACTIVE; 
    targetBrightness = activeTarget;
  } else if (inactiveElapsed < TIME_BEFORE_DIM_2_MS) {
    currentState = STATE_DIM_LEVEL_1;
    targetBrightness = min(activeTarget, (int)BRIGHTNESS_DIM_LEVEL_1);
  } else if (inactiveElapsed < TIME_BEFORE_DIM_3_MS) {
    currentState = STATE_DIM_LEVEL_2;
    targetBrightness = min(activeTarget, (int)BRIGHTNESS_DIM_LEVEL_2);
  } else if (inactiveElapsed < TIME_BEFORE_OFF_MS) {
    currentState = STATE_DIM_LEVEL_3;
    targetBrightness = min(activeTarget, (int)BRIGHTNESS_DIM_LEVEL_3);
  } else {
    currentState = STATE_SLEEP;
    targetBrightness = BRIGHTNESS_OFF;
  }

  // The dim-out schedule is only meant to fade gracefully in a DARK room after
  // someone leaves. It should never light up (or keep lit) a room that's
  // already bright enough on its own - lux always overrides the timer.
  if (currentLux >= LUX_THRESHOLD) {
    targetBrightness = BRIGHTNESS_OFF;
    currentState = STATE_SLEEP;
  }
}

void fadeToBrightness() {
  static unsigned long lastFadeTime = 0;
  unsigned long now = millis();
  
  // Decouple fading speed from raw CPU loop speed using a fixed timer interval.
  if (now - lastFadeTime >= FADE_INTERVAL_MS) {
    float diff = targetBrightness - currentBrightness;
    if (abs(diff) > 0.5) {
      currentBrightness += (diff / FADE_SPEED);
    } else {
      currentBrightness = targetBrightness;
    }
    lastFadeTime = now;
  }
}

void updateLighting() {
  // Only push I/O commands to the PWM peripheral when the value actually changes
  static uint8_t lastPWM = 255; 
  uint8_t newPWM = (uint8_t)currentBrightness;
  
  if (newPWM != lastPWM) {
    ledcWrite(PIN_MOSFET_PWM, newPWM);
    lastPWM = newPWM;
  }
}

void sendTelemetryToThingSpeak() {
  unsigned long now = millis();
  if (now - lastThingSpeakTime < THINGSPEAK_INTERVAL_MS) return; 
  
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(F("[WIFI] Connection lost. Reconnecting..."));
    WiFi.disconnect();
    WiFi.begin(ssid, pass);
    lastThingSpeakTime = now;
    return;
  }

  ThingSpeak.setField(1, (int)presenceDetected);
  ThingSpeak.setField(2, currentLux);
  ThingSpeak.setField(3, (int)(targetBrightness * 100 / 255));
  ThingSpeak.setField(4, (int)currentBrightness);
  ThingSpeak.setField(5, (int)currentState);
  ThingSpeak.setField(6, (long)(totalActiveTimeMs / 1000));
  ThingSpeak.setField(7, (long)(totalIdleTimeMs / 1000));
  ThingSpeak.setField(8, (long)(totalSleepTimeMs / 1000));

  Serial.print(F("[THINGSPEAK] Transmitting data packet... "));
  int responseCode = ThingSpeak.writeFields(myChannelNumber, myWriteAPIKey);
  
  if (responseCode == 200) {
    Serial.println(F("Success (HTTP 200)."));
  } else {
    Serial.print(F("Failed. HTTP Error code: "));
    Serial.println(responseCode);
  }
  
  lastThingSpeakTime = millis();
}

void printSystemStatus() {
  unsigned long now = millis();
  if (now - lastStatusPrintTime < STATUS_PRINT_INTERVAL_MS) return;
  lastStatusPrintTime = now;

  unsigned long inactiveElapsed = presenceDetected ? 0 : (now - presenceLostTimestamp);

  Serial.print(F("Lux: "));         Serial.print(currentLux, 1);
  Serial.print(F(" | Presence: ")); Serial.print(presenceDetected ? "YES" : "NO ");
  Serial.print(F(" | State: "));    Serial.print(stateToString(currentState));
  Serial.print(F(" | Target: "));   Serial.print(targetBrightness);
  Serial.print(F(" | PWM: "));      Serial.print((int)currentBrightness);
  Serial.print(F(" | Inactive: ")); Serial.print(inactiveElapsed / 1000);
  Serial.print(F("s | IP: "));      Serial.println(WiFi.localIP());
}

const char* stateToString(SystemState state) {
  switch (state) {
    case STATE_ACTIVE:      return "ACTIVE";
    case STATE_DIM_LEVEL_1: return "DIM1";
    case STATE_DIM_LEVEL_2: return "DIM2";
    case STATE_DIM_LEVEL_3: return "DIM3";
    case STATE_SLEEP:       return "SLEEP";
  }
  return "?";
}

// ==========================================
// WEB SERVER HANDLERS
// ==========================================
void setupWebServer() {
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/statistics", HTTP_GET, handleStatistics);
  server.on("/logs", HTTP_GET, handleLogs);
  server.on("/mode", HTTP_POST, handleMode);
  server.on("/manual", HTTP_POST, handleManual);
  server.on("/settings", HTTP_POST, handleSettings);
  server.begin();
  Serial.println(F("[WEB] HTTP server started on port 80"));
}

void handleStatus() {
  String json = "{";
  json += "\"presence\":" + String(presenceDetected ? "true" : "false") + ",";
  json += "\"ambient_light\":" + String(currentLux) + ",";
  json += "\"brightness\":" + String((int)(targetBrightness * 100 / 255)) + ",";
  json += "\"pwm_value\":" + String((int)currentBrightness) + ",";
  json += "\"mode\":\"" + operatingMode + "\",";
  json += "\"state\":\"" + String(stateToString(currentState)) + "\"";
  json += "}";
  server.send(200, "application/json", json);
}

void handleStatistics() {
  float totalEnergyWh = totalEnergyWattSeconds / 3600.0;
  String json = "{";
  json += "\"active_time\":" + String(totalActiveTimeMs / 1000) + ",";
  json += "\"idle_time\":" + String(totalIdleTimeMs / 1000) + ",";
  json += "\"sleep_time\":" + String(totalSleepTimeMs / 1000) + ",";
  json += "\"energy_consumed_wh\":" + String(totalEnergyWh, 4);
  json += "}";
  server.send(200, "application/json", json);
}

void handleLogs() {
  // Provide empty logs to prevent app from throwing parsing errors on this endpoint.
  server.send(200, "application/json", "{\"events\":[]}");
}

void handleMode() {
  String body = server.arg("plain");
  if (body.indexOf("\"mode\":\"manual\"") != -1 || body.indexOf("\"mode\": \"manual\"") != -1) {
    operatingMode = "manual";
  } else if (body.indexOf("\"mode\":\"auto\"") != -1 || body.indexOf("\"mode\": \"auto\"") != -1) {
    operatingMode = "auto";
  }
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleManual() {
  String body = server.arg("plain");
  int bIndex = body.indexOf("\"brightness\"");
  if (bIndex != -1) {
    int colon = body.indexOf(':', bIndex);
    if (colon != -1) {
      int val = body.substring(colon + 1).toInt();
      manualBrightness = constrain(val, 0, 100);
      operatingMode = "manual";
    }
  }
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleSettings() {
  String body = server.arg("plain");
  
  // Parse blinkTimeMs for the micro-blink duration
  int bIndex = body.indexOf("\"blinkTimeMs\"");
  if (bIndex != -1) {
    int colon = body.indexOf(':', bIndex);
    if (colon != -1) {
      int endQuote = body.indexOf(',', colon);
      if (endQuote == -1) endQuote = body.indexOf('}', colon);
      if (endQuote != -1) {
        unsigned long val = body.substring(colon + 1, endQuote).toInt();
        if (val >= 1000 && val <= 60000) {
          microBlinkIntervalMs = val;
        }
      }
    }
  }
  
  // If a restoreDefaults flag is sent, reset to default
  if (body.indexOf("\"restoreDefaults\":true") != -1 || body.indexOf("\"restoreDefaults\": true") != -1) {
    microBlinkIntervalMs = MICRO_BLINK_INTERVAL_DEFAULT_MS;
  }
  
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}