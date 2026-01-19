import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/user_account_service.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';

/// SettingsScreen - User settings and account management
/// Ported from web app SettingsPage.jsx
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final UserAccountService _accountService = UserAccountService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  UserModel? _profile;

  // Settings state
  bool _notifyMatches = true;
  bool _notifyMessages = true;
  bool _notifyLikes = true;
  bool _showOnlineStatus = true;
  bool _showDistance = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _profile = UserModel.fromFirestore(userDoc);
          _notifyMatches = data['notifications']?['matches'] ?? true;
          _notifyMessages = data['notifications']?['messages'] ?? true;
          _notifyLikes = data['notifications']?['likes'] ?? true;
          _showOnlineStatus = data['privacy']?['showOnlineStatus'] ?? true;
          _showDistance = data['privacy']?['showDistance'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'notifications.$key': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        switch (key) {
          case 'matches':
            _notifyMatches = value;
            break;
          case 'messages':
            _notifyMessages = value;
            break;
          case 'likes':
            _notifyLikes = value;
            break;
        }
      });
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    }
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'privacy.$key': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        switch (key) {
          case 'showOnlineStatus':
            _showOnlineStatus = value;
            break;
          case 'showDistance':
            _showDistance = value;
            break;
        }
      });
    } catch (e) {
      debugPrint('Error updating privacy setting: $e');
    }
  }

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      final result = await _accountService.deleteAccount(
        passwordController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          context.go('/login');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete account'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cupidPink,
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepPlum),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your photos, bio, and preferences',
              onTap: () => context.push('/edit-profile'),
            ),
            _buildSettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'Verification',
              subtitle: _getVerificationStatus(),
              onTap: () => context.push('/verification'),
            ),
            if (_profile?.isAdmin == true)
              _buildSettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin Dashboard',
                subtitle: 'Manage users, reports, and verifications',
                onTap: () => context.push('/admin'),
              ),

            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              icon: Icons.favorite_outline,
              title: 'New Matches',
              subtitle: 'Get notified when you have a new match',
              value: _notifyMatches,
              onChanged: (value) =>
                  _updateNotificationSetting('matches', value),
            ),
            _buildSwitchTile(
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              subtitle: 'Get notified when you receive a message',
              value: _notifyMessages,
              onChanged: (value) =>
                  _updateNotificationSetting('messages', value),
            ),
            _buildSwitchTile(
              icon: Icons.thumb_up_outlined,
              title: 'Likes',
              subtitle: 'Get notified when someone likes you',
              value: _notifyLikes,
              onChanged: (value) => _updateNotificationSetting('likes', value),
            ),

            const SizedBox(height: 16),

            // Privacy Section
            _buildSectionHeader('Privacy'),
            _buildSwitchTile(
              icon: Icons.visibility_outlined,
              title: 'Online Status',
              subtitle: 'Show when you are online',
              value: _showOnlineStatus,
              onChanged: (value) =>
                  _updatePrivacySetting('showOnlineStatus', value),
            ),
            _buildSwitchTile(
              icon: Icons.location_on_outlined,
              title: 'Show Distance',
              subtitle: 'Show your distance to other users',
              value: _showDistance,
              onChanged: (value) =>
                  _updatePrivacySetting('showDistance', value),
            ),
            _buildSettingsTile(
              icon: Icons.block_outlined,
              title: 'Blocked Users',
              subtitle: 'Manage blocked users',
              onTap: () => context.push('/blocked-users'),
            ),

            const SizedBox(height: 16),

            // Data & Legal Section
            _buildSectionHeader('Data & Legal'),
            _buildSettingsTile(
              icon: Icons.download_outlined,
              title: 'Export Data',
              subtitle: 'Download all your data',
              onTap: _handleExportData,
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.gavel_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // Danger Zone
            _buildSectionHeader('Danger Zone', color: Colors.red),
            _buildSettingsTile(
              icon: IconlyLight.logout,
              title: 'Log Out',
              subtitle: 'Sign out of your account',
              onTap: _handleLogout,
              iconColor: Colors.orange,
            ),
            _buildSettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              onTap: _handleDeleteAccount,
              iconColor: Colors.red,
              textColor: Colors.red,
            ),

            const SizedBox(height: 32),

            // App Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getVerificationStatus() {
    if (_profile == null) return 'Not verified';

    final verified = <String>[];
    if (_profile!.isPhoneVerified) verified.add('Phone');
    if (_profile!.isPhotoVerified) verified.add('Photo');
    if (_profile!.isIDVerified) verified.add('ID');

    if (verified.isEmpty) return 'Not verified';
    return verified.join(', ') + ' verified';
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey[600],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
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
            color: textColor ?? AppColors.deepPlum,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cupidPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.cupidPink, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.deepPlum,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.cupidPink,
      ),
    );
  }
}
