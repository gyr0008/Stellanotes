import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/theme/app_theme.dart';

/// 每日星空壁纸服务
class DailyWallpaperService {
  /// 生成壁纸数据
  static WallpaperData generateWallpaper({
    required DateTime date,
    required int entryCount,
    required int todoCount,
    required int starCount,
    String? mood,
  }) {
    return WallpaperData(
      date: date,
      entryCount: entryCount,
      todoCount: todoCount,
      starCount: starCount,
      mood: mood,
    );
  }

  /// 分享壁纸
  static Future<void> shareWallpaper(Uint8List imageBytes, DateTime date) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/stargazer_wallpaper_${date.year}${date.month}${date.day}.png';
    final file = File(path);
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles(
      [XFile(path)],
      text: '我在 Stargazer 的星空 ${date.month}/${date.day}',
    );
  }
}

/// 壁纸数据
class WallpaperData {
  final DateTime date;
  final int entryCount;
  final int todoCount;
  final int starCount;
  final String? mood;

  WallpaperData({
    required this.date,
    required this.entryCount,
    required this.todoCount,
    required this.starCount,
    this.mood,
  });
}

/// 壁纸画廊页面
class WallpaperGalleryPage extends ConsumerStatefulWidget {
  const WallpaperGalleryPage({super.key});

  @override
  ConsumerState<WallpaperGalleryPage> createState() => _WallpaperGalleryPageState();
}

class _WallpaperGalleryPageState extends ConsumerState<WallpaperGalleryPage> {
  List<WallpaperData> _wallpapers = [];

  @override
  void initState() {
    super.initState();
    _generateSampleWallpapers();
  }

  void _generateSampleWallpapers() {
    final now = DateTime.now();
    final random = Random();
    _wallpapers = List.generate(30, (index) {
      final date = now.subtract(Duration(days: index));
      return WallpaperData(
        date: date,
        entryCount: random.nextInt(5),
        todoCount: random.nextInt(8),
        starCount: 10 + random.nextInt(50),
        mood: ['😊', '😎', '😐', '😢'][random.nextInt(4)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('星空画廊'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _wallpapers.length,
        itemBuilder: (context, index) {
          final wp = _wallpapers[index];
          return _WallpaperThumbnail(wallpaper: wp, theme: theme);
        },
      ),
    );
  }
}

class _WallpaperThumbnail extends StatelessWidget {
  final WallpaperData wallpaper;
  final StarfieldTheme theme;

  const _WallpaperThumbnail({
    required this.wallpaper,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.backgroundTop.withOpacity(0.8),
              theme.backgroundBottom.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 模拟星空
            CustomPaint(
              size: Size.infinite,
              painter: _MiniStarPainter(wallpaper.starCount, theme.diaryColor.color),
            ),
            // 底部信息
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${wallpaper.date.month}/${wallpaper.date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (wallpaper.mood != null)
                      Text(
                        wallpaper.mood!,
                        style: const TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FrostedCard(
        effect: theme.glassEffect,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${wallpaper.date.year}/${wallpaper.date.month}/${wallpaper.date.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('星星', wallpaper.starCount.toString(), theme.diaryColor.color),
                _stat('日记', wallpaper.entryCount.toString(), theme.diaryColor.color),
                _stat('待办', wallpaper.todoCount.toString(), theme.todoColor.color),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.download),
                    label: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }
}

class _MiniStarPainter extends CustomPainter {
  final int starCount;
  final Color color;

  _MiniStarPainter(this.starCount, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(starCount);
    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.5 + random.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = color.withOpacity(0.5 + random.nextDouble() * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_MiniStarPainter oldDelegate) => false;
}
