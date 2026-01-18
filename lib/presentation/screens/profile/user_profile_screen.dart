import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/block_report_service.dart';
import '../../widgets/common/loading_indicator.dart';

/// UserProfileScreen - View another user's profile
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BlockReportService _blockReportService = BlockReportService();
  
  bool _isLoading = true;
  UserModel? _profile;
  int _currentPhotoIndex = 0;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final currentUser = FirebaseAuth.instance.currentUser;
        bool isBlocked = false;
        
        if (currentUser != null) {
          isBlocked = await _blockReportService.hasBlocked(
            currentUser.uid, 
            widget.userId,
          );
        }

        setState(() {
          _profile = UserModel.fromFirestore(userDoc);
          _isBlocked = isBlocked;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBlock() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          _isBlocked 
              ? 'Are you sure you want to unblock ${_profile?.displayName}?' 
              : 'Are you sure you want to block ${_profile?.displayName}? They won\'t be able to see you or message you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(
              _isBlocked ? 'Unblock' : 'Block',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Map<String, dynamic> result;
      if (_isBlocked) {
        result = await _blockReportService.unblockUser(currentUser.uid, widget.userId);
      } else {
        result = await _blockReportService.blockUser(currentUser.uid, widget.userId);
      }

      if (result['success'] == true) {
        setState(() => _isBlocked = !_isBlocked);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBlocked ? 'User blocked' : 'User unblocked'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReport() async {
    final reasonController = TextEditingController();
    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this user?'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BlockReportService.reportReasons.map((reason) {
                  return ChoiceChip(
                    label: Text(reason.replaceAll('_', ' ').toUpperCase()),
                    selected: selectedReason == reason,
                    onSelected: (_) => setDialogState(() => selectedReason = reason),
                    selectedColor: AppColors.cupidPink,
                    labelStyle: TextStyle(
                      color: selectedReason == reason ? Colors.white : null,
                      fontSize: 11,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)',
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
              onPressed: selectedReason != null 
                  ? () => Navigator.pop(context, true) 
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedReason != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final result = await _blockReportService.reportUser(
          widget.userId,
          currentUser.uid,
          selectedReason!,
          reasonController.text,
        );

        if (result['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted. We will review it shortly.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.softIvory,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.deepPlum),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.cupidPink,
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.softIvory,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.deepPlum),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'User not found',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final photos = _profile!.photos;

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: CustomScrollView(
        slivers: [
          // Photo Header
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: Colors.black,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'block') {
                      _handleBlock();
                    } else if (value == 'report') {
                      _handleReport();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            _isBlocked ? Icons.check_circle : Icons.block,
                            color: _isBlocked ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(_isBlocked ? 'Unblock' : 'Block'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo carousel
                  PageView.builder(
                    itemCount: photos.isEmpty ? 1 : photos.length,
                    onPageChanged: (index) {
                      setState(() => _currentPhotoIndex = index);
                    },
                    itemBuilder: (context, index) {
                      if (photos.isEmpty) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.cupidPink, AppColors.deepPlum],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, size: 100, color: Colors.white54),
                          ),
                        );
                      }
                      return Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.deepPlum,
                          child: const Icon(Icons.broken_image, size: 60, color: Colors.white54),
                        ),
                      );
                    },
                  ),
                  
                  // Photo indicators
                  if (photos.length > 1)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: (MediaQuery.of(context).size.width - 40) / photos.length,
                            height: 4,
                            decoration: BoxDecoration(
                              color: index == _currentPhotoIndex 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Name and basic info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_profile!.displayName ?? 'User'}${_profile!.age != null ? ', ${_profile!.age}' : ''}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_profile!.isVerified)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 20),
                              ),
                          ],
                        ),
                        if (_profile!.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _profile!.location!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Profile Content
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.softIvory,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio Section
                  if (_profile!.bio != null && _profile!.bio!.isNotEmpty)
                    _buildSection(
                      'About',
                      child: Text(
                        _profile!.bio!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                  
                  // Details Section
                  _buildSection(
                    'Details',
                    child: Column(
                      children: [
                        if (_profile!.job != null)
                          _buildDetailRow(Icons.work_outline, _profile!.job!),
                        if (_profile!.education != null)
                          _buildDetailRow(Icons.school_outlined, _profile!.education!),
                        if (_profile!.gender != null)
                          _buildDetailRow(Icons.person_outline, _profile!.gender!.toUpperCase()),
                      ],
                    ),
                  ),
                  
                  // Interests Section
                  if (_profile!.interests.isNotEmpty)
                    _buildSection(
                      'Interests',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _profile!.interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warmBlush,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                color: AppColors.cupidPink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  // Verification Badges
                  if (_profile!.isPhoneVerified || _profile!.isPhotoVerified || _profile!.isIDVerified)
                    _buildSection(
                      'Verified',
                      child: Row(
                        children: [
                          if (_profile!.isPhoneVerified)
                            _buildVerificationBadge(Icons.phone, 'Phone'),
                          if (_profile!.isPhotoVerified)
                            _buildVerificationBadge(Icons.camera_alt, 'Photo'),
                          if (_profile!.isIDVerified)
                            _buildVerificationBadge(Icons.badge, 'ID'),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20, 
          16, 
          20, 
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pass Button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.close, size: 30),
                color: Colors.grey[600],
                onPressed: () => context.pop(),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const Spacer(),
            // Super Like Button
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.star, size: 26),
                color: Colors.blue,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Super Liked!')),
                  );
                  context.pop();
                },
                padding: const EdgeInsets.all(14),
              ),
            ),
            const Spacer(),
            // Like Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cupidPink, AppColors.deepPlum],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cupidPink.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite, size: 30),
                color: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liked!')),
                  );
                  context.pop();
                },
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.cupidPink),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
