path = 'lib/providers/system_provider.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix the division by 1000, since the ESP32 already sends the cumulative time in seconds
content = content.replace(
    'int activeTime = (latest.getFieldAsInt(\'active_time\') - earliest.getFieldAsInt(\'active_time\')) ~/ 1000;',
    'int activeTime = latest.getFieldAsInt(\'active_time\') - earliest.getFieldAsInt(\'active_time\');'
)
content = content.replace(
    'int idleTime = (latest.getFieldAsInt(\'idle_time\') - earliest.getFieldAsInt(\'idle_time\')) ~/ 1000;',
    'int idleTime = latest.getFieldAsInt(\'idle_time\') - earliest.getFieldAsInt(\'idle_time\');'
)
content = content.replace(
    'int sleepTime = (latest.getFieldAsInt(\'sleep_time\') - earliest.getFieldAsInt(\'sleep_time\')) ~/ 1000;',
    'int sleepTime = latest.getFieldAsInt(\'sleep_time\') - earliest.getFieldAsInt(\'sleep_time\');'
)

# And fix the negative fallback
content = content.replace(
    'if (activeTime < 0) activeTime = latest.getFieldAsInt(\'active_time\') ~/ 1000;',
    'if (activeTime < 0) activeTime = latest.getFieldAsInt(\'active_time\');'
)
content = content.replace(
    'if (idleTime < 0) idleTime = latest.getFieldAsInt(\'idle_time\') ~/ 1000;',
    'if (idleTime < 0) idleTime = latest.getFieldAsInt(\'idle_time\');'
)
content = content.replace(
    'if (sleepTime < 0) sleepTime = latest.getFieldAsInt(\'sleep_time\') ~/ 1000;',
    'if (sleepTime < 0) sleepTime = latest.getFieldAsInt(\'sleep_time\');'
)

# Also fix the comment
content = content.replace(
    '// Fields 6-8 are cumulative milliseconds supplied by the ESP32.',
    '// Fields 6-8 are cumulative seconds supplied by the ESP32.'
)

with open(path, 'w') as f:
    f.write(content)

print("Patch applied.")
