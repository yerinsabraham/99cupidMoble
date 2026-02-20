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
        result = await _blockReportService.unblockUser(
          currentUser.uid,
          widget.userId,
        );
      } else {
        result = await _blockReportService.blockUser(
          currentUser.uid,
          widget.userId,
        );
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
                    onSelected: (_) =>
                        setDialogState(() => selectedReason = reason),
                    selectedColor: AppColors.cupidPink,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selectedReason == reason
                          ? AppColors.cupidPink
                          : Colors.grey.withOpacity(0.3),
                    ),
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
              child: const Text(
                'Report',
                style: TextStyle(color: Colors.white),
              ),
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

  void _handlePass() {
    // Navigate back - user passed on this profile
    context.pop();
  }

  void _handleLike() {
    // Handle like action - could trigger match dialog if mutual
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Liked!')));
    context.pop();
  }

  void _handleSuperLike() {
    // Handle super like action
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Super Liked!')));
    context.pop();
  }

  void _openImageViewer(int initialIndex) {
    final photos = _profile!.photos;
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
      return Scaffold(
        backgroundColor: AppColors.softIvory,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.cupidPink),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.softIvory,
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
                      onTap: () => _openImageViewer(0),
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
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Back Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
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
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.deepPlum,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),

                    // Distance Badge
                    if (_profile!.location != null &&
                        _profile!.location!.isNotEmpty)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _profile!.location!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Circular Profile Photo (overlapping)
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
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
                                ? Image.network(profilePhoto, fit: BoxFit.cover)
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
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                // Name and Age
                Text(
                  '${_profile!.displayName ?? 'User'}${_profile!.age != null ? ', ${_profile!.age}' : ''}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // About Section
                if (_profile!.bio != null && _profile!.bio!.isNotEmpty)
                  Container(
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
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profile!.bio!,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Interest Section
                if (_profile!.interests.isNotEmpty)
                  Container(
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
                        const Text(
                          'Interest',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
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
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Gallery Section
                if (photos.length > 1)
                  Container(
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
                        const Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Large photo on left
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: () =>
                                    _openImageViewer(1 % photos.length),
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
                      ],
                    ),
                  ),

                const SizedBox(height: 100), // Space for floating buttons
              ],
            ),
          ),

          // Floating Action Buttons
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    isWhite: true,
                    onPressed: _handlePass,
                  ),
                  _buildActionButton(
                    icon: Icons.favorite,
                    isPrimary: true,
                    onPressed: _handleLike,
                  ),
                  _buildActionButton(
                    icon: Icons.waving_hand,
                    isWhite: true,
                    onPressed: _handleSuperLike,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isWhite = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isPrimary ? 64 : 56,
        height: isPrimary ? 64 : 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFA3C7)],
                )
              : null,
          color: isWhite ? Colors.white : null,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppColors.cupidPink.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isPrimary ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
          size: isPrimary ? 28 : 24,
        ),
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
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
