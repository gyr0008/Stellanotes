import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/theme_provider.dart';

/// 图谱截图分享功能
///
/// 将当前星空图谱保存为图片并分享。
class StarmapScreenshot {
  /// 捕获组件并保存为图片
  static Future<File?> captureAndShare(
    GlobalKey widgetKey,
    String fileName,
  ) async {
    try {
      // 获取组件的 RenderObject
      final renderObject = widgetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }

      // 转换为图片
      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // 分享图片
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '我的星空图谱 - Stargazer',
      );

      return file;
    } catch (e) {
      debugPrint('截图失败: $e');
      return null;
    }
  }

  /// 仅保存不分享
  static Future<File?> captureAndSave(
    GlobalKey widgetKey,
    String fileName,
  ) async {
    try {
      final renderObject = widgetKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint('保存截图失败: $e');
      return null;
    }
  }
}

/// 截图按钮组件
class ScreenshotButton extends StatelessWidget {
  final GlobalKey widgetKey;
  final String fileName;
  final IconData icon;
  final String label;
  final VoidCallback? onCaptured;

  const ScreenshotButton({
    super.key,
    required this.widgetKey,
    required this.fileName,
    required this.icon,
    required this.label,
    this.onCaptured,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      onPressed: () async {
        final file = await StarmapScreenshot.captureAndShare(
          widgetKey,
          fileName,
        );
        if (file != null && onCaptured != null) {
          onCaptured!();
        }
      },
    );
  }
}
