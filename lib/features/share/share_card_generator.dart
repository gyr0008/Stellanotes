import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 分享卡片生成器
///
/// 将日记内容生成精美图片卡片，支持多种模板风格。
class ShareCardGenerator {
  /// 生成分享卡片图片
  static Future<File?> generateCard({
    required String title,
    required String content,
    required String? mood,
    required DateTime date,
    required CardTemplate template,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1080, 1920);

    // 绘制背景
    _drawBackground(canvas, size, template);

    // 绘制内容
    _drawContent(canvas, size, title, content, mood, date, template);

    // 转换为图片
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    // 保存到临时文件
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }

  /// 分享卡片
  static Future<void> shareCard({
    required String title,
    required String content,
    required String? mood,
    required DateTime date,
    required CardTemplate template,
  }) async {
    final file = await generateCard(
      title: title,
      content: content,
      mood: mood,
      date: date,
      template: template,
    );

    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: title,
      );
    }
  }

  /// 绘制背景
  static void _drawBackground(Canvas canvas, Size size, CardTemplate template) {
    final paint = Paint();

    switch (template) {
      case CardTemplate.minimal:
        // 简约白色背景
        paint.color = const Color(0xFFF5F5F5);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case CardTemplate.literary:
        // 文艺渐变背景
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        );
        paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case CardTemplate.starry:
        // 星空渐变背景
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0E27),
            const Color(0xFF1A1A3E),
          ],
        );
        paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

        // 绘制星星
        final starPaint = Paint()..color = Colors.white.withOpacity(0.6);
        for (int i = 0; i < 50; i++) {
          final x = (i * 137.5) % size.width;
          final y = (i * 97.3) % size.height;
          final radius = (i % 3) + 1.0;
          canvas.drawCircle(Offset(x, y), radius, starPaint);
        }
        break;
    }
  }

  /// 绘制内容
  static void _drawContent(
    Canvas canvas,
    Size size,
    String title,
    String content,
    String? mood,
    DateTime date,
    CardTemplate template,
  ) {
    final isDark = template == CardTemplate.starry;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF666666);

    // 标题
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: textColor,
          fontSize: 72,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    titlePainter.layout(maxWidth: size.width - 160);
    titlePainter.paint(canvas, const Offset(80, 200));

    // 情绪标签
    if (mood != null) {
      final moodPainter = TextPainter(
        text: TextSpan(
          text: mood,
          style: const TextStyle(fontSize: 120),
        ),
        textDirection: TextDirection.ltr,
      );
      moodPainter.layout();
      moodPainter.paint(canvas, Offset(size.width - 200, 200));
    }

    // 内容
    final contentPainter = TextPainter(
      text: TextSpan(
        text: content,
        style: TextStyle(
          color: textColor.withOpacity(0.9),
          fontSize: 48,
          height: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 15,
    );
    contentPainter.layout(maxWidth: size.width - 160);
    contentPainter.paint(canvas, const Offset(80, 400));

    // 日期
    final dateText = '${date.year}年${date.month}月${date.day}日';
    final datePainter = TextPainter(
      text: TextSpan(
        text: dateText,
        style: TextStyle(
          color: subtextColor,
          fontSize: 36,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    datePainter.layout();
    datePainter.paint(canvas, Offset(80, size.height - 200));

    // 品牌水印
    final brandPainter = TextPainter(
      text: TextSpan(
        text: '— Stargazer',
        style: TextStyle(
          color: subtextColor.withOpacity(0.6),
          fontSize: 32,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    brandPainter.layout();
    brandPainter.paint(canvas, Offset(size.width - brandPainter.width - 80, size.height - 200));
  }
}

/// 卡片模板
enum CardTemplate {
  minimal,   // 简约
  literary,  // 文艺
  starry,    // 星空
}
