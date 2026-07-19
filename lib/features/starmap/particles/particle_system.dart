import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 关联类型
enum RelationType {
  entryToEntry,    // 日记→日记
  todoToEntry,     // 待办→日记
  todoToTodo,      // 待办→待办
  tagToEntry,      // 标签→日记
  constellationToConstellation, // 星座→星座
}

/// 粒子颜色配置
class ParticleColorConfig {
  final Color startColor;
  final Color endColor;
  final double brightness;

  const ParticleColorConfig({
    required this.startColor,
    required this.endColor,
    this.brightness = 1.0,
  });

  ParticleColorConfig copyWith({
    Color? startColor,
    Color? endColor,
    double? brightness,
  }) {
    return ParticleColorConfig(
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      brightness: brightness ?? this.brightness,
    );
  }
}

/// 粒子预设方案
class ParticlePreset {
  final String name;
  final Map<RelationType, ParticleColorConfig> colors;

  const ParticlePreset({
    required this.name,
    required this.colors,
  });

  /// 默认预设
  static const defaultPreset = ParticlePreset(
    name: '默认',
    colors: {
      RelationType.entryToEntry: ParticleColorConfig(
        startColor: Color(0xFFFFD700),
        endColor: Color(0xFFFFA500),
      ),
      RelationType.todoToEntry: ParticleColorConfig(
        startColor: Color(0xFF4FC3F7),
        endColor: Color(0xFF2196F3),
      ),
      RelationType.todoToTodo: ParticleColorConfig(
        startColor: Color(0xFF81C784),
        endColor: Color(0xFF4CAF50),
      ),
      RelationType.tagToEntry: ParticleColorConfig(
        startColor: Color(0xFFBA68C8),
        endColor: Color(0xFF9C27B0),
      ),
      RelationType.constellationToConstellation: ParticleColorConfig(
        startColor: Color(0xFFFF8A65),
        endColor: Color(0xFFFF5722),
      ),
    },
  );

  /// 极光预设
  static const auroraPreset = ParticlePreset(
    name: '极光',
    colors: {
      RelationType.entryToEntry: ParticleColorConfig(
        startColor: Color(0xFF9C27B0),
        endColor: Color(0xFF00BCD4),
      ),
      RelationType.todoToEntry: ParticleColorConfig(
        startColor: Color(0xFF00BCD4),
        endColor: Color(0xFF4CAF50),
      ),
      RelationType.todoToTodo: ParticleColorConfig(
        startColor: Color(0xFF4CAF50),
        endColor: Color(0xFF8BC34A),
      ),
      RelationType.tagToEntry: ParticleColorConfig(
        startColor: Color(0xFFE91E63),
        endColor: Color(0xFF9C27B0),
      ),
      RelationType.constellationToConstellation: ParticleColorConfig(
        startColor: Color(0xFF00E5FF),
        endColor: Color(0xFF1DE9B6),
      ),
    },
  );

  /// 火焰预设
  static const flamePreset = ParticlePreset(
    name: '火焰',
    colors: {
      RelationType.entryToEntry: ParticleColorConfig(
        startColor: Color(0xFFFF5722),
        endColor: Color(0xFFFFC107),
      ),
      RelationType.todoToEntry: ParticleColorConfig(
        startColor: Color(0xFFFF9800),
        endColor: Color(0xFFFFEB3B),
      ),
      RelationType.todoToTodo: ParticleColorConfig(
        startColor: Color(0xFFF44336),
        endColor: Color(0xFFFF5722),
      ),
      RelationType.tagToEntry: ParticleColorConfig(
        startColor: Color(0xFFFFEB3B),
        endColor: Color(0xFFFFC107),
      ),
      RelationType.constellationToConstellation: ParticleColorConfig(
        startColor: Color(0xFFD32F2F),
        endColor: Color(0xFFFF6F00),
      ),
    },
  );

  /// 海洋预设
  static const oceanPreset = ParticlePreset(
    name: '海洋',
    colors: {
      RelationType.entryToEntry: ParticleColorConfig(
        startColor: Color(0xFF0D47A1),
        endColor: Color(0xFF42A5F5),
      ),
      RelationType.todoToEntry: ParticleColorConfig(
        startColor: Color(0xFF1976D2),
        endColor: Color(0xFF64B5F6),
      ),
      RelationType.todoToTodo: ParticleColorConfig(
        startColor: Color(0xFF0277BD),
        endColor: Color(0xFF03A9F4),
      ),
      RelationType.tagToEntry: ParticleColorConfig(
        startColor: Color(0xFF00838F),
        endColor: Color(0xFF26C6DA),
      ),
      RelationType.constellationToConstellation: ParticleColorConfig(
        startColor: Color(0xFF01579B),
        endColor: Color(0xFF00B0FF),
      ),
    },
  );

  /// 所有预设
  static const List<ParticlePreset> allPresets = [
    defaultPreset,
    auroraPreset,
    flamePreset,
    oceanPreset,
  ];
}

/// 单个粒子
class Particle {
  Offset position;
  Offset velocity;
  double life;
  double maxLife;
  double size;
  Color color;
  RelationType type;
  double progress; // 0.0 ~ 1.0，表示在路径上的位置

  Particle({
    required this.position,
    required this.velocity,
    required this.maxLife,
    required this.size,
    required this.color,
    required this.type,
  })  : life = maxLife,
        progress = 0.0;

  void update(double dt) {
    position += velocity * dt;
    life -= dt;
    progress += dt / maxLife;
  }

  bool get isDead => life <= 0;
  double get lifeRatio => life / maxLife;
}

/// 粒子系统
class ParticleSystem {
  final List<Particle> _particles = [];
  final Random _random = Random();

  /// 粒子颜色配置
  Map<RelationType, ParticleColorConfig> colorConfig;

  /// 粒子亮度
  double globalBrightness;

  /// 最大粒子数
  int maxParticles;

  ParticleSystem({
    Map<RelationType, ParticleColorConfig>? colorConfig,
    this.globalBrightness = 1.0,
    this.maxParticles = 500,
  }) : colorConfig = colorConfig ?? ParticlePreset.defaultPreset.colors;

  /// 在两个点之间生成粒子流
  void emitBetween(
    Offset start,
    Offset end,
    RelationType type, {
    double strength = 1.0,
    int count = 5,
  }) {
    if (_particles.length >= maxParticles) return;

    final config = colorConfig[type]!;
    final direction = (end - start).direction;

    for (int i = 0; i < count; i++) {
      final progress = _random.nextDouble();
      final position = Offset.lerp(start, end, progress)!;

      // 添加一些随机偏移
      final offset = Offset(
        (_random.nextDouble() - 0.5) * 10,
        (_random.nextDouble() - 0.5) * 10,
      );

      final speed = 20 + _random.nextDouble() * 30 * strength;
      final velocity = Offset(cos(direction) * speed, sin(direction) * speed);

      final maxLife = 1.0 + _random.nextDouble() * 2.0;
      final size = 1.0 + _random.nextDouble() * 2.0;

      // 根据进度插值颜色
      final color = Color.lerp(
        config.startColor,
        config.endColor,
        progress,
      )!.withOpacity(config.brightness * globalBrightness);

      _particles.add(Particle(
        position: position + offset,
        velocity: velocity,
        maxLife: maxLife,
        size: size,
        color: color,
        type: type,
      ));
    }
  }

  /// 从某个点向外发射脉冲波
  void emitPulse(
    Offset center,
    List<Offset> targets,
    RelationType type,
  ) {
    for (final target in targets) {
      emitBetween(center, target, type, strength: 2.0, count: 10);
    }
  }

  /// 更新所有粒子
  void update(double dt) {
    _particles.removeWhere((p) => p.isDead);

    for (final particle in _particles) {
      particle.update(dt);
    }
  }

  /// 绘制所有粒子
  void draw(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final opacity = particle.lifeRatio;
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);

      canvas.drawCircle(particle.position, particle.size, paint);

      // 绘制光晕
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(opacity * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 4);
      canvas.drawCircle(particle.position, particle.size * 2, glowPaint);
    }
  }

  /// 清空所有粒子
  void clear() {
    _particles.clear();
  }

  /// 当前粒子数量
  int get particleCount => _particles.length;
}

/// 随机配色生成器
class ParticleColorRandomizer {
  static final Random _random = Random();

  /// 生成一套和谐的随机配色
  static Map<RelationType, ParticleColorConfig> generateHarmoniousColors() {
    // 随机选择一个基础色相
    final baseHue = _random.nextDouble() * 360;

    // 使用类似色彩理论的方法生成和谐配色
    final colors = <RelationType, ParticleColorConfig>{};

    for (final type in RelationType.values) {
      // 每个类型使用不同的色相偏移
      final hueOffset = RelationType.values.indexOf(type) * 60.0;
      final hue = (baseHue + hueOffset) % 360;

      final startColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
      final endColor = HSLColor.fromAHSL(1.0, (hue + 30) % 360, 0.8, 0.5).toColor();

      colors[type] = ParticleColorConfig(
        startColor: startColor,
        endColor: endColor,
        brightness: 0.8 + _random.nextDouble() * 0.4,
      );
    }

    return colors;
  }
}
