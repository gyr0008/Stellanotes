import 'dart:ui';
import 'package:flutter/material.dart';

/// Shader 毛玻璃组件
///
/// 使用 Fragment Shader 实现高质量毛玻璃效果：
/// - 高斯模糊
/// - 色调叠加
/// - 边缘高光
class ShaderFrostedGlass extends StatefulWidget {
  final Widget child;
  final double blurRadius;
  final double opacity;
  final Color? tint;
  final double borderBrightness;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const ShaderFrostedGlass({
    super.key,
    required this.child,
    this.blurRadius = 20,
    this.opacity = 0.35,
    this.tint,
    this.borderBrightness = 0.5,
    this.borderRadius,
    this.padding,
  });

  @override
  State<ShaderFrostedGlass> createState() => _ShaderFrostedGlassState();
}

class _ShaderFrostedGlassState extends State<ShaderFrostedGlass> {
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
        'lib/features/starmap/shaders/frosted_glass.frag',
      );
      setState(() {
        _shader = program.fragmentShader();
        _shaderLoaded = true;
      });
    } catch (e) {
      setState(() => _shaderLoaded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shaderLoaded || _shader == null) {
      // 降级：使用 BackdropFilter
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurRadius,
            sigmaY: widget.blurRadius,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.tint?.withOpacity(widget.opacity * 0.3) ??
                  Colors.black.withOpacity(widget.opacity * 0.1),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(widget.borderBrightness * 0.3),
                width: 0.5,
              ),
            ),
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: FrostedGlassPainter(
            shader: _shader!,
            blurRadius: widget.blurRadius,
            opacity: widget.opacity,
            tint: widget.tint ?? Colors.transparent,
            borderBrightness: widget.borderBrightness,
          ),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class FrostedGlassPainter extends CustomPainter {
  final FragmentShader shader;
  final double blurRadius;
  final double opacity;
  final Color tint;
  final double borderBrightness;

  FrostedGlassPainter({
    required this.shader,
    required this.blurRadius,
    required this.opacity,
    required this.tint,
    required this.borderBrightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, DateTime.now().millisecondsSinceEpoch / 1000.0);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    shader.setFloat(3, 0); // rectPos.x
    shader.setFloat(4, 0); // rectPos.y
    shader.setFloat(5, size.width); // rectSize.x
    shader.setFloat(6, size.height); // rectSize.y
    shader.setFloat(7, blurRadius);
    shader.setFloat(8, opacity);
    shader.setFloat(9, tint.red / 255.0);
    shader.setFloat(10, tint.green / 255.0);
    shader.setFloat(11, tint.blue / 255.0);
    shader.setFloat(12, tint.alpha);
    shader.setFloat(13, borderBrightness);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
