#!/bin/bash
# Script to remove ALL mock data from Flutter app
# Safe execution with rollback capability

echo "🔧 Starting Mock Data Removal Process..."
echo "=================================================="

# Navigate to project root
cd "$(dirname "$0")"

# Create backups directory
mkdir -p .backups/mock_removal_$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=".backups/mock_removal_$(date +%Y%m%d_%H%M%S)"

# Backup files before modifying
echo "📦 Creating backups..."
cp lib/presentation/screens/chat/chat_screen.dart "$BACKUP_DIR/"
cp lib/presentation/screens/matches/matches_screen.dart "$BACKUP_DIR/"
cp lib/presentation/screens/admin/admin_dashboard_screen.dart "$BACKUP_DIR/"
echo "✅ Backups created in $BACKUP_DIR/"

echo ""
echo "🧹 Removing mock data from chat_screen.dart..."

# chat_screen.dart: Remove _useMockData flag and method
sed -i.tmp1 '31d' lib/presentation/screens/chat/chat_screen.dart # Remove _useMockData = true line
sed -i.tmp2 '34,49d' lib/presentation/screens/chat/chat_screen.dart # Remove _mockMessages array (lines 34-49)
sed -i.tmp3 '58,87d' lib/presentation/screens/chat/chat_screen.dart # Remove _loadMockDataSetting method
sed -i.tmp4 's/if (widget.chatId.startsWith.*mock.*)/if (false) {/g' lib/presentation/screens/chat/chat_screen.dart
sed -i.tmp5 's/_useMockData/false/g' lib/presentation/screens/chat/chat_screen.dart

echo "✅ chat_screen.dart cleaned"

echo ""
echo "🧹 Removing mock data from matches_screen.dart..."

# matches_screen.dart: Similar process
sed -i.bak '/bool _useMockData/d' lib/presentation/screens/matches/matches_screen.dart
sed -i.bak2 '/_mockMatches = \[/,/\];/d' lib/presentation/screens/matches/matches_screen.dart
sed -i.bak3 '/_loadMockDataSetting/,/^  }/d' lib/presentation/screens/matches/matches_screen.dart

echo "✅ matches_screen.dart cleaned"

echo ""
echo "🧹 Removing mock data toggle from admin_dashboard_screen.dart..."

# admin_dashboard_screen.dart: Remove mock toggle section
# Lines 326-442 contain the entire mock data control section
sed -i.admin_bak '326,442d' lib/presentation/screens/admin/admin_dashboard_screen.dart

echo "✅ admin_dashboard_screen.dart cleaned"

echo ""
echo "🗑️ Cleaning up temp files..."
rm -f lib/presentation/screens/**/*.tmp*
rm -f lib/presentation/screens/**/*.bak*

echo ""
echo "=================================================="
echo "✅ Mock Data Removal Complete!"
echo "📁 Backups saved in: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Run: flutter analyze"
echo "2. Fix any remaining compilation errors"
echo "3. Test the app thoroughly"
echo ""
