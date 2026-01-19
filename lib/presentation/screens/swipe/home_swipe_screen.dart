import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/matching_service.dart';
import '../../../data/services/swipe_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/swipe/swipe_card_new.dart';

class HomeSwipeScreen extends ConsumerStatefulWidget {
  const HomeSwipeScreen({super.key});

  @override
  ConsumerState<HomeSwipeScreen> createState() => _HomeSwipeScreenState();
}

class _HomeSwipeScreenState extends ConsumerState<HomeSwipeScreen>
    with TickerProviderStateMixin {
  final SwipeService _swipeService = SwipeService();
  final MatchingService _matchingService = MatchingService();
  List<UserModel> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadProfiles();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final profiles = await _matchingService.getMatches(currentUser.uid);
        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSwipe(String targetUserId, bool isLike) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (isLike) {
        // Get current user data
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final currentUserData = currentUserDoc.data() ?? {};

        // Get target user data
        final targetUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();
        final targetUserData = targetUserDoc.data() ?? {};

        final result = await _swipeService.likeUser(
          currentUser.uid,
          targetUserId,
          currentUserData,
          targetUserData,
        );

        if (result['match'] != null) {
          _showMatchDialog(result['match']);
        }
      } else {
        await _swipeService.passOnUser(currentUser.uid, targetUserId);
      }

      setState(() {
        if (_currentIndex < _profiles.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
          _loadProfiles();
        }
      });
    } catch (e) {
      debugPrint('Error handling swipe: $e');
    }
  }

  void _showMatchDialog(Map<String, dynamic> match) {
    HapticFeedback.heavyImpact(); // Celebrate the match!
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Match Dialog',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B9D),
                    Color(0xFFFF5FA8),
                    Color(0xFFE91E8C),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cupidPink.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hearts animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 120,
                      ),
                      const Icon(Icons.favorite, color: Colors.white, size: 80),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "It's a Match! 💕",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You and ${match['matchedUserName'] ?? 'someone special'}\nliked each other!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Keep Swiping',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (match['chatId'] != null) {
                              context.push('/chat/${match['chatId']}');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.cupidPink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Say Hello 👋',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.softIvory,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cupidPink,
                        AppColors.cupidPink.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Finding your matches...',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.deepPlum.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.softIvory,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated heart illustration
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.warmBlush,
                              AppColors.warmBlush.withValues(alpha: 0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 100,
                              color: AppColors.cupidPink.withValues(alpha: 0.3),
                            ),
                            const Icon(
                              Icons.check_circle,
                              size: 50,
                              color: AppColors.cupidPink,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'You\'re all caught up!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No new profiles nearby right now.\nCheck back soon or expand your search!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Stats card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatItem(
                        Icons.favorite,
                        'Liked',
                        '${_currentIndex}',
                      ),
                      const SizedBox(width: 32),
                      _buildStatItem(
                        Icons.visibility,
                        'Viewed',
                        '${_currentIndex}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cupidPink.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _loadProfiles,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Refresh Profiles',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '99cupid',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepPlum,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(
                            IconlyLight.filter,
                            color: AppColors.deepPlum,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Stack - Fill more screen space
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Show next card behind
                    if (_currentIndex < _profiles.length - 1)
                      Transform.scale(
                        scale: 0.92,
                        child: Opacity(
                          opacity: 0.5,
                          child: SwipeCard(
                            key: ValueKey(_profiles[_currentIndex + 1].uid),
                            profile: _profiles[_currentIndex + 1],
                            onSwipe: (_, __) {},
                          ),
                        ),
                      ),

                    // Current card
                    if (_currentIndex < _profiles.length)
                      SwipeCard(
                        key: ValueKey(_profiles[_currentIndex].uid),
                        profile: _profiles[_currentIndex],
                        onSwipe: _handleSwipe,
                      ),
                  ],
                ),
              ),
            ),

            // Action Buttons Row (below the card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pass Button (X)
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.white,
                    iconColor: const Color(0xFFFF6B6B),
                    size: 56,
                    onPressed: () {
                      if (_currentIndex < _profiles.length) {
                        _handleSwipe(_profiles[_currentIndex].uid, false);
                      }
                    },
                  ),
                  const SizedBox(width: 20),

                  // Super Like Button (Star)
                  _buildActionButton(
                    icon: Icons.star,
                    color: Colors.white,
                    iconColor: const Color(0xFF00D4FF),
                    size: 56,
                    onPressed: () {
                      if (_currentIndex < _profiles.length) {
                        HapticFeedback.mediumImpact();
                        _handleSwipe(_profiles[_currentIndex].uid, true);
                      }
                    },
                  ),
                  const SizedBox(width: 20),

                  // Like Button (Heart)
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: AppColors.cupidPink,
                    iconColor: Colors.white,
                    size: 64,
                    onPressed: () {
                      if (_currentIndex < _profiles.length) {
                        HapticFeedback.heavyImpact();
                        _handleSwipe(_profiles[_currentIndex].uid, true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required double size,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cupidPink, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
