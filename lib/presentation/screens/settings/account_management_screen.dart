import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/user_account_service.dart';
import '../../providers/auth_provider.dart';

/// AccountManagementScreen - Advanced account settings and danger zone
/// Contains sensitive account operations like deletion
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  final UserAccountService _accountService = UserAccountService();

  Future<void> _handleExportData() async {
    final json = await _accountService.exportUserDataAsJson();
    if (json != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Data'),
          content: SingleChildScrollView(
            child: Text(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export data')));
    }
  }

  Future<void> _handleDeleteAccount() async {
    final passwordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // First confirmation - explain what will happen
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 28),
            const SizedBox(width: 8),
            Text(
              'Delete Account?',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.deepPlum,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.87)
                    : AppColors.grey900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeletionItem('Your profile and photos'),
            _buildDeletionItem('All your matches and conversations'),
            _buildDeletionItem('Your likes and preferences'),
            _buildDeletionItem('All account data'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.red[300]! : Colors.red[200]!,
                ),
              ),
              child: Text(
                '⚠️ This action cannot be undone',
                style: TextStyle(
                  color: isDark ? Colors.red[300] : Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : AppColors.grey600,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.red[300] : Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Second confirmation - require password
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Deletion',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.deepPlum,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your password to permanently delete your account:',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.87)
                    : AppColors.grey700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.grey900,
              ),
              decoration: InputDecoration(
                hintText: 'Enter password',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.grey500,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.grey500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.grey300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.grey300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.red[300]! : Colors.red[700]!,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : AppColors.grey600,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.red[400] : Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );

    if (secondConfirm == true && passwordController.text.isNotEmpty) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _accountService.deleteAccount(
        passwordController.text,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (result['success'] == true) {
        if (mounted) {
          context.go('/login');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDeletionItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.close,
            size: 18,
            color: isDark ? Colors.red[300] : Colors.red[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.87)
                    : AppColors.grey700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.softIvory,
      appBar: AppBar(
        title: const Text(
          'Account Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Account Data Section
            _buildSectionHeader('Account Data'),
            _buildSettingsTile(
              icon: Icons.download_outlined,
              title: 'Export My Data',
              subtitle: 'Download a copy of all your data',
              onTap: _handleExportData,
              iconColor: AppColors.cupidPink,
            ),

            const SizedBox(height: 24),

            // Warning Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.red[300]! : Colors.red[200]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isDark ? Colors.red[300] : Colors.red[700],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.red[300] : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Irreversible actions that affect your account',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.red[200] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delete Account Section
            _buildSettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Delete My Account',
              subtitle: 'Permanently delete your account and all data',
              onTap: _handleDeleteAccount,
              iconColor: Colors.red,
              textColor: Colors.red,
            ),

            const SizedBox(height: 16),

            // Information Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.grey200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.white70 : AppColors.grey600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Before you delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Consider exporting your data first\n'
                    '• Deletion is permanent and cannot be undone\n'
                    '• All matches will lose access to your conversation\n'
                    '• Your profile will be immediately removed\n'
                    '• You can create a new account later with the same email',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.grey700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white60 : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.cupidPink).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.cupidPink, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? (isDark ? Colors.white : AppColors.deepPlum),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.white30 : Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
