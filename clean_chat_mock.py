#!/usr/bin/env python3
import re

# Read the file
with open('lib/presentation/screens/chat/chat_screen.dart', 'r') as f:
    content = f.read()

# Remove _useMockData flag
content = re.sub(r'  bool _useMockData = true;\n', '', content)

# Remove _mockMessages array
content = re.sub(
    r'  // Mock conversation data\n  final List<Map<String, dynamic>> _mockMessages = \[.*?\];',
    '',
    content,
    flags=re.DOTALL
)

# Remove _loadMockDataSetting method
content = re.sub(
    r'  Future<void> _loadMockDataSetting\(\) async \{.*?\n  \}',
    '',
    content,
    flags=re.DOTALL
)

# Remove mockUsers map definition
content = re.sub(
    r"      final mockUsers = \{.*?\n      \};",
    "",
    content,
    flags=re.DOTALL
)

# Remove mock_ prefix checks
content = re.sub(r"widget\.chatId\.startsWith\('mock_'\)", "false", content)

# Write back
with open('lib/presentation/screens/chat/chat_screen.dart', 'w') as f:
    f.write(content)

print("✅ Cleaned chat_screen.dart of all mock data")
