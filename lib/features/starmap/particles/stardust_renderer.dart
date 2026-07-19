import 'dart:ui';
import 'package:flutter/material.dart';
import 'particle_system.dart';

/// 星尘渲染器
/// 负责将粒子系统集成到星空图谱的渲染流程中
class StardustRenderer {
  final ParticleSystem _particleSystem;

  StardustRenderer(this._particleSystem);

  /// 渲染粒子层
  void render(Canvas canvas, Size size) {
    _particleSystem.draw(canvas, size);
  }

  /// 更新粒子系统
  void update(double dt) {
    _particleSystem.update(dt);
  }

  /// 在两个节点之间生成粒子流
  void emitFlow(
    Offset from,
    Offset to,
    RelationType type, {
    double strength = 1.0,
  }) {
    _particleSystem.emitBetween(from, to, type, strength: strength);
  }

  /// 从某个节点发射脉冲
  void emitPulse(Offset center, List<Offset> targets, RelationType type) {
    _particleSystem.emitPulse(center, targets, type);
  }

  /// 清空粒子
  void clear() {
    _particleSystem.clear();
  }

  /// 获取当前粒子数
  int get particleCount => _particleSystem.particleCount;
}

/// 粒子效果层 Widget
/// 叠加在星空图谱之上，用于显示粒子效果
class ParticleEffectLayer extends StatefulWidget {
  final ParticleSystem particleSystem;
  final bool enabled;

  const ParticleEffectLayer({
    super.key,
    required this.particleSystem,
    this.enabled = true,
  });

  @override
  State<ParticleEffectLayer> createState() => _ParticleEffectLayerState();
}

class _ParticleEffectLayerState extends State<ParticleEffectLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..repeat();
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
          painter: _ParticlePainter(widget.particleSystem),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final ParticleSystem particleSystem;

  _ParticlePainter(this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    // 更新粒子系统
    particleSystem.update(0.016); // 假设 60fps

    // 绘制粒子
    particleSystem.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return true; // 每帧都重绘
  }
}
