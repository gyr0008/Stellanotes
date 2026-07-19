import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/frosted_card.dart';
import '../../../core/storage/storage_providers.dart';

/// 时间旅行模式页面
class TimeTravelPage extends ConsumerStatefulWidget {
  const TimeTravelPage({super.key});

  @override
  ConsumerState<TimeTravelPage> createState() => _TimeTravelPageState();
}

class _TimeTravelPageState extends ConsumerState<TimeTravelPage>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 1.0; // 1.0 = 现在
  DateTime? _selectedDate;
  bool _isPlaying = false;
  late AnimationController _playController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _playController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _playController.addListener(_onPlayTick);
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  void _onPlayTick() {
    if (!_isPlaying) return;
    setState(() {
      _sliderValue = _playController.value;
      final now = DateTime.now();
      final earliest = now.subtract(const Duration(days: 365));
      _selectedDate = earliest.add(
        Duration(days: (now.difference(earliest).inDays * _sliderValue).toInt()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final entriesAsync = ref.watch(entriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间旅行'),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                if (_isPlaying) {
                  _playController.forward(from: 0);
                } else {
                  _playController.stop();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 时间轴滑块
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'
                          : '现在',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _sliderValue = 1.0;
                          _selectedDate = DateTime.now();
                        });
                      },
                      child: const Text('回到现在'),
                    ),
                  ],
                ),
                Slider(
                  value: _sliderValue,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                      final now = DateTime.now();
                      final earliest = now.subtract(const Duration(days: 365));
                      _selectedDate = earliest.add(
                        Duration(days: (now.difference(earliest).inDays * value).toInt()),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // 里程碑标记
          _buildMilestones(theme),

          // 该时间点的星空快照
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filtered = entries.where((e) {
                  if (_selectedDate == null) return true;
                  return e.createdAt.isBefore(
                    _selectedDate!.add(const Duration(days: 1)),
                  );
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      '这个时间点还没有星星',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return _buildSnapshotView(filtered, theme);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('加载失败')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(StarfieldTheme theme) {
    final milestones = [
      _Milestone('第一颗星星', Icons.star, theme.diaryColor.color),
      _Milestone('第 10 颗', Icons.star_border, theme.todoColor.color),
      _Milestone('第一个星座', Icons.constellation, theme.tagColor.color),
    ];

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: milestones.map((m) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: m.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: m.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m.icon, color: m.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  m.label,
                  style: TextStyle(color: m.color, fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSnapshotView(List<dynamic> entries, StarfieldTheme theme) {
    return CustomPaint(
      painter: _SnapshotPainter(entries, theme),
      size: Size.infinite,
    );
  }
}

class _Milestone {
  final String label;
  final IconData icon;
  final Color color;
  _Milestone(this.label, this.icon, this.color);
}

class _SnapshotPainter extends CustomPainter {
  final List<dynamic> entries;
  final StarfieldTheme theme;

  _SnapshotPainter(this.entries, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final random = (entries.length * 7 + 13) % 100;
    for (int i = 0; i < entries.length && i < 50; i++) {
      final x = (size.width * ((i * 97 + random) % 100) / 100).clamp(20.0, size.width - 20);
      final y = (size.height * ((i * 53 + random * 3) % 100) / 100).clamp(20.0, size.height - 20);
      final starSize = 2.0 + (i % 5).toDouble();

      final paint = Paint()
        ..color = theme.diaryColor.color.withOpacity(0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, starSize * 2);

      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(_SnapshotPainter oldDelegate) => true;
}
