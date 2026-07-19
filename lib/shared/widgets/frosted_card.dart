import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// 毛玻璃卡片组件
///
/// 根据 [StarfieldTheme] 中的 [GlassEffect] 配置渲染毛玻璃效果。
/// 用于图谱浮层、详情面板、设置页等场景。
class FrostedCard extends StatelessWidget {
  final Widget child;
  final GlassEffect? effect;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const FrostedCard({
    super.key,
    required this.child,
    this.effect,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = effect ?? GlassEffect.frosted;

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: _buildBorder(glass),
        boxShadow: _buildShadow(glass),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 模糊背景层
          if (glass.blurRadius > 0)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: borderRadius ?? BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: glass.blurRadius,
                    sigmaY: glass.blurRadius,
                  ),
                  child: Container(
                    color: glass.tint?.withOpacity(glass.opacity * 0.3) ??
                        Colors.black.withOpacity(glass.opacity * 0.1),
                  ),
                ),
              ),
            ),

          // 内容层
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }

  Border? _buildBorder(GlassEffect glass) {
    switch (glass.border) {
      case GlassBorder.none:
        return null;
      case GlassBorder.thin:
        return Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 0.5,
        );
      case GlassBorder.bright:
        return Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1.0,
        );
    }
  }

  List<BoxShadow>? _buildShadow(GlassEffect glass) {
    switch (glass.shadow) {
      case GlassShadow.none:
        return null;
      case GlassShadow.light:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      case GlassShadow.heavy:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
    }
  }
}

/// 毛玻璃预览组件（用于设置页实时预览）
class GlassPreview extends StatelessWidget {
  final GlassEffect effect;

  const GlassPreview({super.key, required this.effect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            'https://picsum.photos/400/200',
          ),
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 模拟星空背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0E27),
                    const Color(0xFF1A1A3E),
                  ],
                ),
              ),
            ),
          ),
          // 毛玻璃卡片
          Center(
            child: FrostedCard(
              effect: effect,
              width: 200,
              height: 60,
              child: const Center(
                child: Text(
                  '毛玻璃预览',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
