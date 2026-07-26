# API Documentation

## ESP32 REST API for Smart Light System

This document describes the REST API endpoints exposed by the ESP32 embedded system for communication with the Flutter mobile application.

---

## Base URL

```
http://<ESP32_IP_ADDRESS>:80
```

Configure the base URL in `lib/config/api_constants.dart`:

```dart
const String baseUrl = 'http://192.168.1.100';
```

---

## Authentication

Currently, the API does not require authentication. Future implementations may include API key or token-based authentication for security.

---

## Response Format

All API responses use JSON format.

### Success Response

```json
{
  "data": { ... },
  "status": "success"
}
```

### Error Response

```json
{
  "error": "Error message",
  "status": "error"
}
```

---

## Endpoints

### 1. Get System Status

Retrieve the current system status including presence detection, ambient light, brightness, and operating mode.

**Endpoint**: `GET /status`

**Request Headers**:
```
Content-Type: application/json
```

**Response**:
```json
{
  "presence": true,
  "ambient_light": 250.5,
  "brightness": 75,
  "pwm_value": 192,
  "mode": "auto",
  "state": "active",
  "last_updated": "2024-01-15T10:30:00Z",
  "connection_status": "connected"
}
```

**Field Descriptions**:

| Field | Type | Description |
|-------|------|-------------|
| presence | boolean | True if presence is detected, false otherwise |
| ambient_light | float | Ambient light level in lux (0-65535) |
| brightness | integer | Current brightness percentage (0-100) |
| pwm_value | integer | Current PWM duty cycle value (0-255 or 0-1023) |
| mode | string | Operating mode: "auto" or "manual" |
| state | string | System state: "active", "dim1", "dim2", "sleep", "off" |
| last_updated | string | ISO 8601 timestamp of last update |
| connection_status | string | Connection status: "connected", "disconnected" |

**Example Request**:
```bash
curl http://192.168.1.100/status
```

**Example Response**:
```json
{
  "presence": true,
  "ambient_light": 250.5,
  "brightness": 75,
  "pwm_value": 192,
  "mode": "auto",
  "state": "active",
  "last_updated": "2024-01-15T10:30:00Z",
  "connection_status": "connected"
}
```

---

### 2. Get Event Logs

Retrieve the event log history containing chronological events.

**Endpoint**: `GET /logs`

**Request Headers**:
```
Content-Type: application/json
```

**Query Parameters** (optional):

| Parameter | Type | Description |
|-----------|------|-------------|
| limit | integer | Maximum number of logs to return (default: 100) |
| offset | integer | Number of logs to skip (default: 0) |
| type | string | Filter by event type (optional) |

**Response**:
```json
[
  {
    "id": "evt_12345",
    "timestamp": "2024-01-15T10:30:00Z",
    "event_type": "presence",
    "message": "Presence Detected",
    "details": "Target detected at 2.5m"
  },
  {
    "id": "evt_12346",
    "timestamp": "2024-01-15T10:31:00Z",
    "event_type": "brightness",
    "message": "Brightness 100%",
    "details": null
  }
]
```

**Field Descriptions**:

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique event identifier |
| timestamp | string | ISO 8601 timestamp when event occurred |
| event_type | string | Event type: "presence", "brightness", "state", "mode", "system" |
| message | string | Human-readable event description |
| details | string | Additional event details (nullable) |

**Example Request**:
```bash
curl http://192.168.1.100/logs?limit=50&type=presence
```

---

### 3. Get Statistics

Retrieve daily statistics including active time, idle time, and energy metrics.

**Endpoint**: `GET /statistics`

**Request Headers**:
```
Content-Type: application/json
```

**Query Parameters** (optional):

| Parameter | Type | Description |
|-----------|------|-------------|
| date | string | Date in YYYY-MM-DD format (default: today) |

**Response**:
```json
{
  "active_time": 14400,
  "idle_time": 7200,
  "sleep_time": 14400,
  "avg_brightness": 65.5,
  "presence_events": 45,
  "energy_saving_time": 21600
}
```

**Field Descriptions**:

| Field | Type | Description |
|-------|------|-------------|
| active_time | integer | Total active time in seconds |
| idle_time | integer | Total idle time in seconds |
| sleep_time | integer | Total sleep time in seconds |
| avg_brightness | float | Average brightness percentage |
| presence_events | integer | Number of presence detection events |
| energy_saving_time | integer | Total energy saving time in seconds |

**Example Request**:
```bash
curl http://192.168.1.100/statistics?date=2024-01-15
```

---

### 4. Set Manual Brightness

Send a manual brightness control command to the ESP32. Only valid when in manual mode.

**Endpoint**: `POST /manual`

**Request Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "brightness": 75
}
```

**Field Descriptions**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| brightness | integer | Brightness percentage (0-100) | Required, 0-100 |

**Success Response**:
```json
{
  "status": "success",
  "message": "Brightness set to 75%"
}
```

**Error Response**:
```json
{
  "status": "error",
  "message": "Invalid brightness value or not in manual mode"
}
```

**Example Request**:
```bash
curl -X POST http://192.168.1.100/manual \
  -H "Content-Type: application/json" \
  -d '{"brightness": 75}'
```

---

### 5. Update Settings

Update system configuration settings on the ESP32.

**Endpoint**: `POST /settings`

**Request Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "luxThresholdOn": 25,
  "luxThresholdOff": 35,
  "timeBeforeDim1Ms": 10000,
  "timeBeforeDim2Ms": 30000,
  "timeBeforeDim3Ms": 60000,
  "timeBeforeOffMs": 120000,
  "fadeSpeed": 5
}
```

**Field Descriptions**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| luxThresholdOn | number | Turn-on threshold (lux) | Must be below `luxThresholdOff` |
| luxThresholdOff | number | Turn-off threshold (lux) | Creates the firmware hysteresis band |
| timeBeforeDim1Ms | integer | First dim delay (milliseconds) | 0 or greater |
| timeBeforeDim2Ms | integer | Second dim delay (milliseconds) | Greater than dim 1 |
| timeBeforeDim3Ms | integer | Third dim delay (milliseconds) | Greater than dim 2 |
| timeBeforeOffMs | integer | Sleep/off delay (milliseconds) | Greater than dim 3 |
| fadeSpeed | number | Fade smoothing factor | Greater than zero |

**Success Response**:
```json
{
  "status": "success",
  "message": "Settings updated successfully"
}
```

**Error Response**:
```json
{
  "status": "error",
  "message": "Invalid settings values"
}
```

**Example Request**:
```bash
curl -X POST http://192.168.1.100/settings \
  -H "Content-Type: application/json" \
  -d '{
    "luxThresholdOn": 25,
    "luxThresholdOff": 35,
    "timeBeforeDim1Ms": 10000,
    "timeBeforeDim2Ms": 30000,
    "timeBeforeDim3Ms": 60000,
    "timeBeforeOffMs": 120000,
    "fadeSpeed": 5
  }'
```

---

### 6. Set Operating Mode

Change the operating mode of the system between auto and manual.

**Endpoint**: `POST /mode`

**Request Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "mode": "auto"
}
```

**Field Descriptions**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| mode | string | Operating mode | Required, "auto" or "manual" |

**Success Response**:
```json
{
  "status": "success",
  "message": "Mode changed to auto"
}
```

**Error Response**:
```json
{
  "status": "error",
  "message": "Invalid mode value"
}
```

**Example Request**:
```bash
curl -X POST http://192.168.1.100/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "auto"}'
```

---

## Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 200 | OK | Request successful |
| 400 | BAD_REQUEST | Invalid request parameters |
| 404 | NOT_FOUND | Endpoint not found |
| 500 | INTERNAL_ERROR | Server error |
| 503 | SERVICE_UNAVAILABLE | Service temporarily unavailable |

---

## Rate Limiting

Currently, there is no rate limiting implemented. However, it is recommended to:

- Poll `/status` at most once per second
- Cache responses where appropriate
- Implement exponential backoff on errors

---

## WebSocket Support (Future)

Future implementations may include WebSocket support for real-time push notifications:

**Endpoint**: `WS /ws`

**Events**:
- `status_update`: System status update
- `presence_detected`: Presence detection event
- `state_changed`: System state change
- `error`: Error notification

---

## Testing the API

### Using cURL

```bash
# Test connection
curl http://192.168.1.100/status

# Test manual brightness
curl -X POST http://192.168.1.100/manual \
  -H "Content-Type: application/json" \
  -d '{"brightness": 50}'

# Test mode change
curl -X POST http://192.168.1.100/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "manual"}'
```

### Using Postman

1. Import the API collection
2. Set base URL variable to your ESP32 IP
3. Test each endpoint
4. Verify response formats

### Using Python

```python
import requests

BASE_URL = "http://192.168.1.100"

# Get status
response = requests.get(f"{BASE_URL}/status")
print(response.json())

# Set manual brightness
data = {"brightness": 75}
response = requests.post(f"{BASE_URL}/manual", json=data)
print(response.json())
```

---

## Security Considerations

### Current Implementation

- No authentication required
- No encryption (HTTP only)
- No rate limiting
- No input validation on ESP32 side

### Recommended Improvements

1. **Authentication**: Implement API key or token-based authentication
2. **Encryption**: Use HTTPS/TLS for secure communication
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **Input Validation**: Validate all input parameters on ESP32
5. **CORS**: Configure CORS if web access is needed
6. **Logging**: Implement request/response logging for debugging

---

## ESP32 Implementation Guide

### Required Endpoints

Your ESP32 firmware must implement the following endpoints:

1. **GET /status** - Return current system status
2. **GET /logs** - Return event log history
3. **GET /statistics** - Return daily statistics
4. **POST /manual** - Accept manual brightness command
5. **POST /settings** - Accept settings update
6. **POST /mode** - Accept mode change command

### JSON Library

Use ArduinoJson library for JSON serialization:

```cpp
#include <ArduinoJson.h>

// Create JSON document
StaticJsonDocument<200> doc;
doc["presence"] = true;
doc["ambient_light"] = 250.5;
doc["brightness"] = 75;

// Serialize to string
String jsonString;
serializeJson(doc, jsonString);
```

### Web Server

Use ESP32 WebServer library:

```cpp
#include <WebServer.h>

WebServer server(80);

void setup() {
  server.on("/status", handleStatus);
  server.on("/manual", HTTP_POST, handleManual);
  server.begin();
}

void loop() {
  server.handleClient();
}
```

---

## Troubleshooting

### Connection Refused

- Verify ESP32 is running
- Check IP address is correct
- Ensure device and ESP32 on same network
- Check firewall settings

### Timeout Errors

- Increase timeout in Flutter app
- Check ESP32 response time
- Verify Wi-Fi signal strength
- Reduce polling frequency

### Invalid JSON

- Verify JSON format matches specification
- Check data types (int vs float)
- Ensure all required fields are present
- Validate field constraints

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01-15 | Initial API specification |

---

## Support

For issues or questions regarding the API implementation, refer to the main project documentation or contact the development team.
