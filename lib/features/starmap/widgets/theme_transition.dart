import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

/// 主题切换过渡动画组件
///
/// 在主题切换时提供平滑的颜色过渡效果。
class ThemeTransitionOverlay extends ConsumerWidget {
  final Widget child;

  const ThemeTransitionOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.backgroundTop,
            theme.backgroundBottom,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// 星星颜色过渡动画组件
class StarColorTransition extends StatelessWidget {
  final Color fromColor;
  final Color toColor;
  final double radius;
  final double twinkle;

  const StarColorTransition({
    super.key,
    required this.fromColor,
    required this.toColor,
    required this.radius,
    required this.twinkle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color>(
      tween: Tween<Color>(begin: fromColor, end: toColor),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, color, child) {
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.9 * twinkle),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3 * twinkle) ?? Colors.transparent,
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}
