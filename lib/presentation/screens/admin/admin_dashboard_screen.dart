import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common/loading_indicator.dart';

/// AdminDashboardScreen - Admin panel for managing users, reports, and verifications
/// Ported from web app AdminPanelPage.jsx
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic> _stats = {};
  List<UserModel> _users = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _verifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdminAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoadData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      final isAdmin = await _adminService.isAdmin(currentUser.uid);

      if (!isAdmin) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      // Load all data in parallel
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getAllUsers(),
        _adminService.getAllReports(),
        _adminService.getVerificationRequests(includeAll: true),
      ]);

      setState(() {
        _isAdmin = true;
        _stats = results[0] as Map<String, dynamic>;
        _users = results[1] as List<UserModel>;
        _reports = results[2] as List<Map<String, dynamic>>;
        _verifications = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.softIvory,
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to access this page.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cupidPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepPlum),
        actions: [
          IconButton(
            onPressed: _checkAdminAndLoadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.cupidPink,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.cupidPink,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
            Tab(icon: Icon(Icons.verified_user), text: 'Verify'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildReportsTab(),
          _buildVerificationsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Total Users',
                _stats['totalUsers']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Active Users',
                _stats['activeUsers']?.toString() ?? '0',
                Icons.person_add,
                Colors.green,
              ),
              _buildStatCard(
                'Verified Users',
                _stats['verifiedUsers']?.toString() ?? '0',
                Icons.verified,
                Colors.purple,
              ),
              _buildStatCard(
                'Total Matches',
                _stats['totalMatches']?.toString() ?? '0',
                Icons.favorite,
                AppColors.cupidPink,
              ),
              _buildStatCard(
                'Pending Reports',
                _stats['pendingReports']?.toString() ?? '0',
                Icons.report_problem,
                Colors.orange,
              ),
              _buildStatCard(
                'Pending Verifications',
                _stats['pendingVerifications']?.toString() ?? '0',
                Icons.pending_actions,
                Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionChip(
                'View All Reports',
                Icons.report,
                () => _tabController.animateTo(2),
              ),
              _buildActionChip(
                'Process Verifications',
                Icons.verified_user,
                () => _tabController.animateTo(3),
              ),
              _buildActionChip(
                'Manage Users',
                Icons.people,
                () => _tabController.animateTo(1),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Development Settings
          const Text(
            'Development Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.cupidPink),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.warmBlush,
      labelStyle: const TextStyle(color: AppColors.deepPlum),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        // Users List
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    final statusColor = user.accountStatus == 'suspended'
        ? Colors.red
        : user.accountStatus == 'deleted'
        ? Colors.grey
        : Colors.green;

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
          backgroundImage: user.photos.isNotEmpty
              ? NetworkImage(user.photos.first)
              : null,
          child: user.photos.isEmpty
              ? Icon(Icons.person, color: AppColors.cupidPink)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (user.isVerified)
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.accountStatus ?? 'active',
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email ?? 'No email'),
            if (user.age != null) Text('Age: ${user.age}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(user, value),
          itemBuilder: (context) => [
            if (user.accountStatus != 'suspended')
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Suspend'),
                  ],
                ),
              ),
            if (user.accountStatus == 'suspended')
              const PopupMenuItem(
                value: 'unsuspend',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Unsuspend'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserAction(UserModel user, String action) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool success = false;
    String message = '';

    switch (action) {
      case 'suspend':
        success = await _adminService.suspendUser(user.uid);
        message = success ? 'User suspended' : 'Failed to suspend user';
        break;
      case 'unsuspend':
        success = await _adminService.unsuspendUser(user.uid);
        message = success ? 'User unsuspended' : 'Failed to unsuspend user';
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to delete ${user.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          success = await _adminService.deleteUser(user.uid);
          message = success ? 'User deleted' : 'Failed to delete user';
        }
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (success) {
        _checkAdminAndLoadData();
      }
    }
  }

  Widget _buildReportsTab() {
    final pendingReports = _reports
        .where((r) => r['status'] == 'pending')
        .toList();

    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReportStat('Pending', pendingReports.length, Colors.orange),
              _buildReportStat(
                'Resolved',
                _reports.where((r) => r['status'] == 'resolved').length,
                Colors.green,
              ),
              _buildReportStat(
                'Dismissed',
                _reports.where((r) => r['status'] == 'dismissed').length,
                Colors.grey,
              ),
            ],
          ),
        ),

        // Reports List
        Expanded(
          child: _reports.isEmpty
              ? const Center(child: Text('No reports found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return _buildReportCard(report);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final statusColor = report['status'] == 'pending'
        ? Colors.orange
        : report['status'] == 'resolved'
        ? Colors.green
        : Colors.grey;

    final createdAt = (report['createdAt'] as Timestamp?)?.toDate();
    final dateString = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'Unknown date';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getReasonColor(report['reason']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatReason(report['reason'] ?? 'other'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getReasonColor(report['reason']),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['status'] ?? 'pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report['description'] ?? 'No description',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateString,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (report['status'] == 'pending')
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            _handleReportAction(report['id'], 'dismissed'),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _handleReportAction(report['id'], 'resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cupidPink,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Resolve'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getReasonColor(String? reason) {
    switch (reason) {
      case 'harassment':
        return Colors.red;
      case 'fake_profile':
        return Colors.orange;
      case 'inappropriate':
        return Colors.purple;
      case 'spam':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatReason(String reason) {
    return reason.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _handleReportAction(String reportId, String status) async {
    final success = await _adminService.resolveReport(reportId, status);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Report $status' : 'Failed to update report'),
      ),
    );

    if (success) {
      _checkAdminAndLoadData();
    }
  }

  Widget _buildVerificationsTab() {
    final pendingVerifications = _verifications
        .where((v) => v['status'] == 'pending')
        .toList();

    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVerificationStat(
                'Pending',
                pendingVerifications.length,
                Colors.orange,
              ),
              _buildVerificationStat(
                'Approved',
                _verifications.where((v) => v['status'] == 'approved').length,
                Colors.green,
              ),
              _buildVerificationStat(
                'Rejected',
                _verifications.where((v) => v['status'] == 'rejected').length,
                Colors.red,
              ),
            ],
          ),
        ),

        // Verifications List
        Expanded(
          child: _verifications.isEmpty
              ? const Center(child: Text('No verification requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _verifications.length,
                  itemBuilder: (context, index) {
                    final verification = _verifications[index];
                    return _buildVerificationCard(verification);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVerificationStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> verification) {
    final statusColor = verification['status'] == 'pending'
        ? Colors.orange
        : verification['status'] == 'approved'
        ? Colors.green
        : Colors.red;

    final type = verification['verificationType'] ?? 'unknown';
    final typeIcon = type == 'phone'
        ? Icons.phone
        : type == 'photo'
        ? Icons.camera_alt
        : Icons.credit_card;

    final submittedAt = (verification['submittedAt'] as Timestamp?)?.toDate();
    final dateString = submittedAt != null
        ? '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}'
        : 'Unknown date';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warmBlush,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: AppColors.cupidPink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${type.toString().toUpperCase()} Verification',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    verification['status'] ?? 'pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Show verification details
            if (verification['selfieUrl'] != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  verification['selfieUrl'],
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateString,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (verification['status'] == 'pending')
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _handleVerificationAction(
                          verification['id'],
                          false,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _handleVerificationAction(verification['id'], true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerificationAction(
    String verificationId,
    bool approve,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool success;
    if (approve) {
      success = await _adminService.approveVerification(
        verificationId,
        currentUser.uid,
      );
    } else {
      success = await _adminService.rejectVerification(
        verificationId,
        currentUser.uid,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Verification ${approve ? 'approved' : 'rejected'}'
              : 'Failed to update verification',
        ),
      ),
    );

    if (success) {
      _checkAdminAndLoadData();
    }
  }
}
