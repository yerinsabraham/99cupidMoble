import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/block_report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_dialog.dart';

/// BlockedUsersScreen - Manage blocked users
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final BlockReportService _blockReportService = BlockReportService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final users = await _blockReportService.getBlockedUsers(currentUser.uid);
      
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnblock(String userId, String userName) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Unblock User',
      content: 'Are you sure you want to unblock $userName?',
      confirmText: 'Unblock',
    );

    if (confirmed == true) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final result = await _blockReportService.unblockUser(currentUser.uid, userId);
        
        if (result['success'] == true) {
          _loadBlockedUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$userName has been unblocked')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepPlum),
      ),
      body: _blockedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No blocked users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Users you block will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                final name = user['displayName'] ?? 'Unknown';
                final photos = List<String>.from(user['photos'] ?? []);
                final photo = photos.isNotEmpty ? photos.first : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.warmBlush,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null 
                          ? Icon(Icons.person, color: AppColors.cupidPink) 
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    subtitle: Text(
                      'Blocked',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _handleUnblock(user['id'], name),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cupidPink,
                      ),
                      child: const Text('Unblock'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
