import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// HeartLoader - Animated heart loading indicator matching web app
class HeartLoader extends StatefulWidget {
  final String text;
  final double size;
  
  const HeartLoader({
    super.key,
    this.text = 'Loading...',
    this.size = 64,
  });

  @override
  State<HeartLoader> createState() => _HeartLoaderState();
}

class _HeartLoaderState extends State<HeartLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cupidPink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _HeartPainter(),
                ),
              ),
            );
          },
        ),
        if (widget.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              );
            },
            onEnd: () {
              // Pulse effect - restart animation
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cupidPink
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Heart shape using the same SVG path from web app
    // Scaled to fit the size
    final scaleX = size.width / 32;
    final scaleY = size.height / 29.6;
    
    path.moveTo(23.6 * scaleX, 0);
    path.cubicTo(
      20.2 * scaleX, 0,
      17.3 * scaleX, 2.7 * scaleY,
      16 * scaleX, 5.6 * scaleY,
    );
    path.cubicTo(
      14.7 * scaleX, 2.7 * scaleY,
      11.8 * scaleX, 0,
      8.4 * scaleX, 0,
    );
    path.cubicTo(
      3.8 * scaleX, 0,
      0, 3.8 * scaleY,
      0, 8.4 * scaleY,
    );
    path.cubicTo(
      0, 17.8 * scaleY,
      9.5 * scaleX, 20.3 * scaleY,
      16 * scaleX, 29.6 * scaleY,
    );
    path.cubicTo(
      22.1 * scaleX, 20.3 * scaleY,
      32 * scaleX, 17.5 * scaleY,
      32 * scaleX, 8.4 * scaleY,
    );
    path.cubicTo(
      32 * scaleX, 3.8 * scaleY,
      28.2 * scaleX, 0,
      23.6 * scaleX, 0,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
