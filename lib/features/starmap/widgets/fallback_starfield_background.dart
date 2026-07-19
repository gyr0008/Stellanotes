import 'dart:math';
import 'package:flutter/material.dart';

/// 星空粒子背景（降级方案）
///
/// 当 Shader 不可用时，使用此组件作为降级方案。
/// 使用 Canvas 绘制静态星点和简单动画。
class FallbackStarfieldBackground extends StatefulWidget {
  final double particleDensity;
  final Color topColor;
  final Color bottomColor;

  const FallbackStarfieldBackground({
    super.key,
    this.particleDensity = 1.0,
    required this.topColor,
    required this.bottomColor,
  });

  @override
  State<FallbackStarfieldBackground> createState() =>
      _FallbackStarfieldBackgroundState();
}

class _FallbackStarfieldBackgroundState
    extends State<FallbackStarfieldBackground>
    with TickerProviderStateMixin {
  late AnimationController _twinkleController;
  final List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _generateStars();
  }

  void _generateStars() {
    _stars.clear();
    final random = DateTime.now().millisecondsSinceEpoch;
    final count = (100 * widget.particleDensity).toInt();

    for (int i = 0; i < count; i++) {
      _stars.add(Star(
        x: ((random * (i + 1)) % 1000) / 1000,
        y: ((random * (i + 7)) % 1000) / 1000,
        size: 1 + ((random * (i + 3)) % 3),
        twinkleSpeed: 0.5 + ((random * (i + 11)) % 100) / 100,
      ));
    }
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _twinkleController,
      builder: (context, child) {
        return CustomPaint(
          painter: StarfieldPainter(
            stars: _stars,
            topColor: widget.topColor,
            bottomColor: widget.bottomColor,
            twinklePhase: _twinkleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
  });
}

class StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final Color topColor;
  final Color bottomColor;
  final double twinklePhase;

  StarfieldPainter({
    required this.stars,
    required this.topColor,
    required this.bottomColor,
    required this.twinklePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制渐变背景
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // 绘制星星
    for (final star in stars) {
      final twinkle = sin(twinklePhase * star.twinkleSpeed * 2 * pi) * 0.3 + 0.7;
      final x = star.x * size.width;
      final y = star.y * size.height;

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(twinkle * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), star.size, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
