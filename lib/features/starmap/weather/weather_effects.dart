import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'mood_weather_system.dart';

/// 天气效果渲染器
class WeatherEffectsRenderer {
  final MoodWeatherSystem _weatherSystem;

  WeatherEffectsRenderer(this._weatherSystem);

  /// 绘制天气覆盖层
  void drawOverlay(Canvas canvas, Size size) {
    final weather = _weatherSystem.getInterpolatedWeather();

    if (weather.overlayOpacity > 0) {
      final paint = Paint()
        ..color = weather.overlayColor.withOpacity(weather.overlayOpacity);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  /// 绘制雾气效果
  void drawFog(Canvas canvas, Size size) {
    final weather = _weatherSystem.getInterpolatedWeather();

    if (weather.fogDensity > 0) {
      final fogPaint = Paint()
        ..color = Colors.white.withOpacity(weather.fogDensity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

      // 绘制多个模糊的圆形模拟雾气
      canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.4),
        150,
        fogPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.6),
        180,
        fogPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.2),
        120,
        fogPaint,
      );
    }
  }

  /// 绘制星暴闪电效果
  void drawLightning(Canvas canvas, Size size, double time) {
    final weather = _weatherSystem.getInterpolatedWeather();

    if (weather.type == WeatherType.stormy) {
      // 随机闪电效果
      if ((time * 10).toInt() % 30 == 0) {
        final lightningPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final path = Path();
        final startX = size.width * (0.3 + (time % 0.4));
        path.moveTo(startX, 0);

        // 绘制锯齿形闪电
        for (int i = 0; i < 5; i++) {
          final y = size.height * (i / 5);
          final xOffset = (i % 2 == 0 ? 20 : -20);
          path.lineTo(startX + xOffset, y);
        }

        canvas.drawPath(path, lightningPaint);
      }
    }
  }

  /// 获取星星亮度调整
  double getStarBrightnessMultiplier() {
    return _weatherSystem.getInterpolatedWeather().starBrightness;
  }

  /// 获取星星抖动偏移
  Offset getStarShakeOffset() {
    return _weatherSystem.getStarShakeOffset();
  }
}

/// 天气效果层 Widget
class WeatherEffectLayer extends StatefulWidget {
  final MoodWeatherSystem weatherSystem;
  final bool enabled;

  const WeatherEffectLayer({
    super.key,
    required this.weatherSystem,
    this.enabled = true,
  });

  @override
  State<WeatherEffectLayer> createState() => _WeatherEffectLayerState();
}

class _WeatherEffectLayerState extends State<WeatherEffectLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final WeatherEffectsRenderer _renderer;

  @override
  void initState() {
    super.initState();
    _renderer = WeatherEffectsRenderer(widget.weatherSystem);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void didUpdateWidget(WeatherEffectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weatherSystem != oldWidget.weatherSystem) {
      _renderer; // 重新创建渲染器
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WeatherEffectPainter(
            _renderer,
            _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WeatherEffectPainter extends CustomPainter {
  final WeatherEffectsRenderer renderer;
  final double time;

  _WeatherEffectPainter(this.renderer, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    // 更新天气系统
    renderer._weatherSystem.update(0.016);

    // 绘制天气效果
    renderer.drawOverlay(canvas, size);
    renderer.drawFog(canvas, size);
    renderer.drawLightning(canvas, size, time);
  }

  @override
  bool shouldRepaint(_WeatherEffectPainter oldDelegate) {
    return true;
  }
}

/// 天气指示器 Widget（显示在角落的小图标）
class WeatherIndicator extends StatelessWidget {
  final MoodWeatherSystem weatherSystem;

  const WeatherIndicator({
    super.key,
    required this.weatherSystem,
  });

  @override
  Widget build(BuildContext context) {
    final weather = weatherSystem.getInterpolatedWeather();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weather.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            weather.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
