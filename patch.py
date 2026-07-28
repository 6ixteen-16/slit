import re

# 1. system_provider.dart
path = 'lib/providers/system_provider.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix 1: Set lastUpdated to DateTime.now() so it shows when the app updated, not the history time
content = content.replace(
    '_systemStatus = SystemStatus.fromJson(statusMap).copyWith(\n          mode: _lastConfirmedMode,\n        );',
    '_systemStatus = SystemStatus.fromJson(statusMap).copyWith(\n          mode: _lastConfirmedMode,\n          lastUpdated: DateTime.now(),\n        );'
)

# Fix 2: Also for ESP32 fallback, ensure lastUpdated is now
content = content.replace(
    '_systemStatus = await _apiService.getSystemStatus();',
    '_systemStatus = (await _apiService.getSystemStatus()).copyWith(lastUpdated: DateTime.now());'
)

# Fix 3: In refreshAll(), do NOT overwrite _statistics with last 100 feeds! This ruins the time range selection.
content = content.replace(
    '_statistics = _calculateStatisticsFromThingSpeak(feeds);',
    '// _statistics = _calculateStatisticsFromThingSpeak(feeds); // Removed to preserve time-range filter'
)

with open(path, 'w') as f:
    f.write(content)

# 2. thingspeak_status.dart
path = 'lib/widgets/thingspeak_status.dart'
with open(path, 'r') as f:
    content = f.read()

content = content.replace('Receiving live data from cloud', 'Receiving data from cloud')

with open(path, 'w') as f:
    f.write(content)

# 3. statistics_screen.dart
path = 'lib/screens/statistics_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix 4: Do not show full screen CircularProgressIndicator if we already have stats data, to prevent flickering
content = content.replace(
    'if (provider.isLoadingStatistics) {\n            return const Center(\n              child: CircularProgressIndicator(),\n            );\n          }',
    'if (provider.isLoadingStatistics && provider.statistics.isEmpty) {\n            return const Center(\n              child: CircularProgressIndicator(),\n            );\n          }'
)

with open(path, 'w') as f:
    f.write(content)

print("Patch applied successfully.")
