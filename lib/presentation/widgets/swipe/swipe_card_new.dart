import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import 'dart:math' as math;

class SwipeCard extends StatefulWidget {
  final UserModel profile;
  final Function(String userId, bool isLike) onSwipe;

  const SwipeCard({super.key, required this.profile, required this.onSwipe});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _angle = 0;
  Size _screenSize = Size.zero;
  int _currentPhotoIndex = 0;
  int _currentContentIndex = 0; // 0 = photos, 1 = bio/interests, 2 = more info
  late AnimationController _resetController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size;
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    // Started dragging
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      _angle = 35 * _position.dx / _screenSize.width;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const swipeThreshold = 120;
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (_position.dx.abs() > swipeThreshold || velocity.abs() > 800) {
      final isLike = _position.dx > 0 || velocity > 800;
      HapticFeedback.mediumImpact(); // Haptic feedback on swipe
      widget.onSwipe(widget.profile.uid, isLike);
      _animateCardOff(isLike);
    } else {
      _resetPosition();
    }
  }

  void _animateCardOff(bool isLike) {
    final direction = isLike ? 1 : -1;
    setState(() {
      _position = Offset(direction * _screenSize.width * 2, _position.dy);
    });
  }

  void _handleButtonSwipe(bool isLike) {
    _animateCardOff(isLike);
    // Delay calling onSwipe to allow animation to start
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onSwipe(widget.profile.uid, isLike);
    });
  }

  void _resetPosition() {
    setState(() {
      _position = Offset.zero;
      _angle = 0;
    });
  }

  double _getSwipeOpacity() {
    const threshold = 50.0;
    final opacity = (_position.dx.abs() - threshold) / 50.0;
    return opacity.clamp(0.0, 1.0);
  }

  Color? _getStatusColor() {
    const threshold = 50;
    if (_position.dx > threshold) {
      return const Color(0xFF4CAF50);
    } else if (_position.dx < -threshold) {
      return const Color(0xFFFF6B6B);
    }
    return null;
  }

  Widget _buildPhotoView() {
    final photos = widget.profile.photos;

    return photos.isNotEmpty
        ? GestureDetector(
            onTapDown: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.localPosition.dx < width / 2) {
                // Tap left half - previous photo
                if (_currentPhotoIndex > 0) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPhotoIndex--);
                }
              } else {
                // Tap right half - next photo
                if (_currentPhotoIndex < photos.length - 1) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPhotoIndex++);
                }
              }
            },
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: CachedNetworkImage(
                    key: ValueKey(photos[_currentPhotoIndex]),
                    imageUrl: photos[_currentPhotoIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: AppColors.warmBlush,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.cupidPink,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.warmBlush,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 100,
                        color: AppColors.cupidPink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            color: AppColors.warmBlush,
            child: const Icon(
              Icons.person_rounded,
              size: 100,
              color: AppColors.cupidPink,
            ),
          );
  }

  void _showInfoBottomSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    widget.profile.displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  if (widget.profile.age != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.profile.age.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: AppColors.deepPlum,
                      ),
                    ),
                  ],
                  if (widget.profile.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ],
              ),
             if (widget.profile.showDistance && widget.profile.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppColors.cupidPink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.profile.location,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (widget.profile.bio.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.profile.bio,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
              ],
              if (widget.profile.interests.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Interests',
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
                  children: widget.profile.interests.map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmBlush,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cupidPink.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        interest.toString(),
                        style: const TextStyle(
                          color: AppColors.deepPlum,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement report/block
                },
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Report or Block'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.displayName;
    final age = widget.profile.age?.toString();
    final bio = widget.profile.bio;
    final location = widget.profile.location;
    final isVerified = widget.profile.isVerified;
    final photos = widget.profile.photos;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(_position.dx, _position.dy)
          ..rotateZ(_angle * math.pi / 180),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Full-screen photo background
                Positioned.fill(child: _buildPhotoView()),

                // Info button in top-right
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => context.push('/user/${widget.profile.uid}'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Location badge in top-left
                if (widget.profile.showDistance && location.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.cupidPink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepPlum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Like/Nope Stamp Overlay
                if (_getStatusColor() != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _getSwipeOpacity(),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _getStatusColor()!,
                            width: 4,
                          ),
                        ),
                        child: Align(
                          alignment: _position.dx > 0
                              ? Alignment.topLeft
                              : Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Transform.rotate(
                              angle: _position.dx > 0 ? -0.4 : 0.4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _getStatusColor()!,
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _position.dx > 0 ? 'LIKE' : 'NOPE',
                                  style: TextStyle(
                                    color: _getStatusColor()!,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom gradient with user info (tappable to view profile)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => context.push('/user/${widget.profile.uid}'),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name and age row
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (age != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  age,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF00D4FF),
                                  size: 22,
                                ),
                              ],
                            ],
                          ),

                          // Job/Education info
                          if (widget.profile.job != null &&
                              widget.profile.job!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.work_outline,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.profile.job!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Bio preview
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              bio,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    double size = 56,
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
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
