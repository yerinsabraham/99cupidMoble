import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/heart_loader.dart';
import '../../widgets/common/app_dialog.dart';

/// ProfileScreen - User's own profile matching web app ProfilePageV2.jsx
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  UserModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _profile = UserModel.fromFirestore(userDoc);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Log Out',
      content: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
    );

    if (confirmed) {
      try {
        await _authService.signOut();
        if (mounted) {
          // Navigate to login screen
          context.go('/login');
        }
      } catch (e) {
        debugPrint('Error logging out: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to log out. Please try again.'),
            ),
          );
        }
      }
    }
  }

  void _openImageViewer(int initialIndex) {
    final photos = _profile?.photos ?? [];
    if (photos.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _FullScreenImageViewer(images: photos, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.softIvory,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cupidPink),
        ),
      );
    }

    final photos = _profile?.photos ?? [];
    final bannerPhoto = photos.isNotEmpty ? photos[0] : null;
    final profilePhoto = photos.isNotEmpty ? photos[0] : null;

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Banner + Profile Photo Section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner Photo
                    GestureDetector(
                      onTap: () =>
                          photos.isNotEmpty ? _openImageViewer(0) : null,
                      child: Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          color: AppColors.cupidPink.withOpacity(0.2),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          child: bannerPhoto != null
                              ? Image.network(
                                  bannerPhoto,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.cupidPink,
                                        AppColors.warmBlush,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 60,
                                          color: Colors.white54,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Add Photos',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Settings/Logout Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            IconlyLight.setting,
                            color: AppColors.deepPlum,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push('/edit-profile');
                            } else if (value == 'settings') {
                              context.push('/settings');
                            } else if (value == 'admin') {
                              context.push('/admin');
                            } else if (value == 'logout') {
                              _handleLogout();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(IconlyLight.edit, size: 18),
                                  SizedBox(width: 12),
                                  Text('Edit Profile'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(IconlyLight.setting, size: 18),
                                  SizedBox(width: 12),
                                  Text('Settings'),
                                ],
                              ),
                            ),
                            if (_profile?.isAdmin == true)
                              const PopupMenuItem(
                                value: 'admin',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_outlined,
                                      size: 18,
                                      color: Colors.purple,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Admin Panel',
                                      style: TextStyle(color: Colors.purple),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    IconlyLight.logout,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Circular Profile Photo (overlapping) with Edit Button
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => photos.isNotEmpty
                                  ? _openImageViewer(0)
                                  : null,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: profilePhoto != null
                                      ? Image.network(
                                          profilePhoto,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: AppColors.cupidPink,
                                          child: const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            // Edit button on profile photo
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => context.push('/edit-profile'),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.cupidPink,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    IconlyLight.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                // Name and Age
                Text(
                  '${_profile?.displayName ?? 'User'}${_profile?.age != null ? ', ${_profile!.age}' : ''}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Verification Badges or Get Verified prompt
                if (_getVerifiedCount() > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_profile?.isPhoneVerified == true)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_android,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                            ],
                          ),
                        ),
                      if (_profile?.isPhotoVerified == true)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                      if (_profile?.isIDVerified == true)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.purple.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.badge,
                                size: 14,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.purple.shade700,
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () => context.push('/verification'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cupidPink.withOpacity(0.1),
                            AppColors.deepPlum.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppColors.cupidPink.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 18,
                            color: AppColors.cupidPink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Get Verified to Build Trust',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.deepPlum,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.cupidPink,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Trust Score / Stats Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.verified_user,
                        label: 'Trust Score',
                        value: _calculateTrustScore().toString() + '%',
                        color: AppColors.cupidPink,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatItem(
                        icon: Icons.shield_outlined,
                        label: 'Verified',
                        value: _getVerifiedCount().toString() + '/3',
                        color: Colors.green,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatItem(
                        icon: Icons.account_circle_outlined,
                        label: 'Account',
                        value: _profile?.profileSetupComplete == true
                            ? 'Complete'
                            : 'Incomplete',
                        color: AppColors.deepPlum,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About Section
                if (_profile?.bio != null && _profile!.bio!.isNotEmpty)
                  _buildEditableSection(
                    title: 'About',
                    onEdit: () => context.push('/edit-profile'),
                    child: Text(
                      _profile!.bio!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Interest Section
                if (_profile?.interests.isNotEmpty == true)
                  _buildEditableSection(
                    title: 'Interest',
                    onEdit: () => context.push('/edit-profile'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _profile!.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              color: AppColors.cupidPink,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Gallery Section
                if (photos.length > 1)
                  _buildEditableSection(
                    title: 'Gallery',
                    onEdit: () => context.push('/edit-profile'),
                    child: Row(
                      children: [
                        // Large photo on left
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _openImageViewer(1 % photos.length),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 0.75,
                                child: Image.network(
                                  photos[1 % photos.length],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Two smaller photos on right
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _openImageViewer(2 % photos.length),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Image.network(
                                      photos[2 % photos.length],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              if (photos.length > 3) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _openImageViewer(3),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.network(
                                        photos[3 % photos.length],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getVerifiedCount() {
    int count = 0;
    if (_profile?.isPhoneVerified == true) count++;
    if (_profile?.isPhotoVerified == true) count++;
    if (_profile?.isIDVerified == true) count++;
    return count;
  }

  int _calculateTrustScore() {
    int score = 0;

    // Base score for account creation
    score += 20;

    // Verification bonuses
    if (_profile?.isPhoneVerified == true) score += 25;
    if (_profile?.isPhotoVerified == true) score += 30;
    if (_profile?.isIDVerified == true) score += 25;

    return score.clamp(0, 100);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEditableSection({
    required String title,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPlum,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cupidPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    IconlyLight.edit,
                    size: 16,
                    color: AppColors.cupidPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Full-screen image viewer with swipe functionality
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.cupidPink,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Image counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Photo indicators at bottom
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? AppColors.cupidPink
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
