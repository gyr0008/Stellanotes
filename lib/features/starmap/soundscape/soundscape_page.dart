import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/frosted_card.dart';
import 'soundscape_engine.dart';

/// 声音景观页面
class SoundscapePage extends ConsumerStatefulWidget {
  const SoundscapePage({super.key});

  @override
  ConsumerState<SoundscapePage> createState() => _SoundscapePageState();
}

class _SoundscapePageState extends ConsumerState<SoundscapePage>
    with SingleTickerProviderStateMixin {
  final SoundscapeEngine _engine = SoundscapeEngine();
  late AnimationController _visualizerController;

  @override
  void initState() {
    super.initState();
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    _engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('声音景观'),
        actions: [
          if (_engine.isPlaying)
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              onPressed: () => _showTimerDialog(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前播放状态
          if (_engine.isPlaying && _engine.currentScene != null)
            _buildNowPlayingCard(theme),

          const SizedBox(height: 24),

          // 场景列表
          const Text(
            '选择场景',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ...SoundscapeScene.allScenes.map((scene) {
            return _buildSceneCard(scene, theme);
          }),

          const SizedBox(height: 24),

          // 主音量控制
          FrostedCard(
            effect: theme.glassEffect,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '主音量',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white70),
                    Expanded(
                      child: Slider(
                        value: _engine.masterVolume,
                        onChanged: (value) {
                          setState(() {
                            _engine.setMasterVolume(value);
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingCard(StarfieldTheme theme) {
    final scene = _engine.currentScene!;

    return FrostedCard(
      effect: theme.glassEffect,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: scene.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  scene.icon,
                  color: scene.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _engine.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    if (_engine.isPlaying) {
                      _engine.pause();
                    } else {
                      _engine.resume();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, size: 28),
                onPressed: () {
                  setState(() {
                    _engine.stop();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 轨道控制
          const Text(
            '混音器',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          ...scene.tracks.map((track) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      track.enabled ? track.icon : Icons.volume_off,
                      color: track.enabled ? scene.color : Colors.white38,
                    ),
                    onPressed: () {
                      setState(() {
                        _engine.toggleTrack(track);
                      });
                    },
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      track.name,
                      style: TextStyle(
                        color: track.enabled ? Colors.white : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Slider(
                      value: track.volume,
                      onChanged: track.enabled
                          ? (value) {
                              setState(() {
                                _engine.setTrackVolume(track, value);
                              });
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),

          // 可视化动画
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _visualizerController,
            builder: (context, child) {
              return CustomPaint(
                painter: _VisualizerPainter(
                  _visualizerController.value,
                  scene.color,
                ),
                size: const Size.fromHeight(40),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSceneCard(SoundscapeScene scene, StarfieldTheme theme) {
    final isSelected = _engine.currentScene?.type == scene.type;

    return FrostedCard(
      effect: theme.glassEffect,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        setState(() {
          _engine.playScene(scene);
        });
      },
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scene.color.withOpacity(isSelected ? 0.4 : 0.2),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: scene.color, width: 2)
                  : null,
            ),
            child: Icon(
              scene.icon,
              color: scene.color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scene.description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.play_circle,
              color: scene.color,
              size: 32,
            )
          else
            const Icon(
              Icons.play_circle_outline,
              color: Colors.white38,
              size: 32,
            ),
        ],
      ),
    );
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('定时关闭'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _engine.setTimer(null);
              });
              Navigator.pop(context);
            },
            child: const Text('关闭'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _engine.setTimer(15);
              });
              Navigator.pop(context);
            },
            child: const Text('15 分钟'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _engine.setTimer(30);
              });
              Navigator.pop(context);
            },
            child: const Text('30 分钟'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _engine.setTimer(60);
              });
              Navigator.pop(context);
            },
            child: const Text('1 小时'),
          ),
        ],
      ),
    );
  }
}

/// 音频可视化绘制器
class _VisualizerPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _VisualizerPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final barCount = 20;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final height = (size.height / 2) *
          (0.3 + 0.7 * ((i + animationValue * barCount) % barCount) / barCount);

      path.moveTo(x, size.height / 2 - height);
      path.lineTo(x, size.height / 2 + height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VisualizerPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
