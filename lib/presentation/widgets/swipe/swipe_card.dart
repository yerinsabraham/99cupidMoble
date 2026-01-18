import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import 'dart:math' as math;

class SwipeCard extends StatefulWidget {
  final UserModel profile;
  final Function(String userId, bool isLike) onSwipe;

  const SwipeCard({
    super.key,
    required this.profile,
    required this.onSwipe,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _angle = 0;
  Size _screenSize = Size.zero;
  int _currentPhotoIndex = 0;
  late AnimationController _resetController;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size;
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final photos = widget.profile.photos;
    final name = widget.profile.displayName;
    final age = widget.profile.age?.toString();
    final bio = widget.profile.bio;
    final interests = widget.profile.interests;
    final location = widget.profile.location;
    final isVerified = widget.profile.isVerified;

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
          width: MediaQuery.of(context).size.width * 0.94,
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Photo with Hero animation support
                Positioned.fill(
                  child: photos.isNotEmpty
                      ? GestureDetector(
                          onTapDown: (details) {
                            final width = MediaQuery.of(context).size.width;
                            if (details.localPosition.dx < width / 3) {
                              // Tap left - previous photo
                              if (_currentPhotoIndex > 0) {
                                setState(() => _currentPhotoIndex--);
                              }
                            } else if (details.localPosition.dx > width * 2 / 3) {
                              // Tap right - next photo
                              if (_currentPhotoIndex < photos.length - 1) {
                                setState(() => _currentPhotoIndex++);
                              }
                            }
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: CachedNetworkImage(
                              key: ValueKey(photos[_currentPhotoIndex]),
                              imageUrl: photos[_currentPhotoIndex],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey[300]!,
                                      Colors.grey[200]!,
                                    ],
                                  ),
                                ),
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
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.warmBlush,
                                AppColors.warmBlush.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 100,
                            color: AppColors.cupidPink,
                          ),
                        ),
                ),

                // Premium Photo Indicators
                if (photos.length > 1)
                  Positioned(
                    top: 16,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: List.generate(
                        photos.length,
                        (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: index == _currentPhotoIndex
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
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
                            padding: const EdgeInsets.all(24),
                            child: Transform.rotate(
                              angle: _position.dx > 0 ? -0.4 : 0.4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _getStatusColor()!,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _position.dx > 0 ? 'LIKE' : 'NOPE',
                                  style: TextStyle(
                                    color: _getStatusColor()!,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Premium Gradient Overlay with profile info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 28),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name, Age & Verified Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (age != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      age,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                  if (isVerified) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/user/${widget.profile.uid}'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Location
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Bio
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            bio,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        
                        // Interest Tags
                        if (interests.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interests.take(4).map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.cupidPink.withValues(alpha: 0.9),
                                      AppColors.cupidPink.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cupidPink.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  interest.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
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
}
