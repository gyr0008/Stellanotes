import 'dart:ui';
import 'package:flutter/material.dart';

/// Shader 星空背景组件
///
/// 使用 Fragment Shader 渲染高性能星空背景：
/// - 深空渐变
/// - 闪烁星点粒子
/// - 星云效果
class ShaderStarfieldBackground extends StatefulWidget {
  final double particleDensity;
  final Color topColor;
  final Color bottomColor;

  const ShaderStarfieldBackground({
    super.key,
    this.particleDensity = 1.0,
    required this.topColor,
    required this.bottomColor,
  });

  @override
  State<ShaderStarfieldBackground> createState() =>
      _ShaderStarfieldBackgroundState();
}

class _ShaderStarfieldBackgroundState
    extends State<ShaderStarfieldBackground> {
  FragmentShader? _shader;
  bool _shaderLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset(
        'lib/features/starmap/shaders/starfield.frag',
      );
      setState(() {
        _shader = program.fragmentShader();
        _shaderLoaded = true;
      });
    } catch (e) {
      // Shader 加载失败，使用降级方案
      setState(() => _shaderLoaded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shaderLoaded || _shader == null) {
      // 降级：使用普通渐变背景
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.topColor, widget.bottomColor],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _AnimatedShaderPainter(_shader!, widget.particleDensity),
        size: Size.infinite,
      ),
    );
  }
}

class _AnimatedShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double particleDensity;

  _AnimatedShaderPainter(this.shader, this.particleDensity);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, DateTime.now().millisecondsSinceEpoch / 1000.0);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    shader.setFloat(3, particleDensity);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
