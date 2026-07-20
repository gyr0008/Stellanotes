import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/frosted_card.dart';
import 'particle_system.dart';
import 'package:stargazer/core/theme/app_theme.dart';

/// 星尘调色盘设置页面
class ParticleColorSettingsPage extends ConsumerStatefulWidget {
  const ParticleColorSettingsPage({super.key});

  @override
  ConsumerState<ParticleColorSettingsPage> createState() =>
      _ParticleColorSettingsPageState();
}

class _ParticleColorSettingsPageState
    extends ConsumerState<ParticleColorSettingsPage> {
  Map<RelationType, ParticleColorConfig> _currentColors =
      Map.from(ParticlePreset.defaultPreset.colors);
  double _globalBrightness = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('星尘调色盘'),
        actions: [
          TextButton(
            onPressed: _resetToDefault,
            child: const Text('重置'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 预览区域
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const Text(
                  '预览',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _ParticlePreview(
                    colors: _currentColors,
                    brightness: _globalBrightness,
                  ),
                ),
              ],
            ),
          ),

          // 全局亮度
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '全局亮度',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _globalBrightness,
                  min: 0.3,
                  max: 1.5,
                  divisions: 24,
                  label: '${(_globalBrightness * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() => _globalBrightness = value);
                  },
                ),
              ],
            ),
          ),

          // 预设方案
          const Text(
            '预设方案',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ParticlePreset.allPresets.map((preset) {
                return _buildPresetCard(preset, theme);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // 随机配色按钮
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 24),
            onTap: _randomizeColors,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.tagColor.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.casino, color: theme.tagColor.color),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '随机配色',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '生成一套和谐的随机配色',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),

          // 关联类型颜色配置
          const Text(
            '关联类型',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...RelationType.values.map((type) {
            return _buildRelationTypeCard(type, theme);
          }),
        ],
      ),
    );
  }

  Widget _buildPresetCard(ParticlePreset preset, StarfieldTheme theme) {
    final isSelected = _currentColors.values.toList().toString() ==
        preset.colors.values.toList().toString();

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColors = Map.from(preset.colors);
        });
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.diaryColor.color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.diaryColor.color
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 颜色预览
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: preset.colors[RelationType.entryToEntry]!.startColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: preset.colors[RelationType.todoToEntry]!.startColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: preset.colors[RelationType.todoToTodo]!.startColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.diaryColor.color : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationTypeCard(RelationType type, StarfieldTheme theme) {
    final config = _currentColors[type]!;
    final typeName = _getRelationTypeName(type);

    return FrostedCard(
      effect: theme.glassEffect,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.startColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getRelationTypeIcon(type),
                  color: config.startColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  typeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 起始颜色
          Row(
            children: [
              const Text(
                '起始颜色',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickColor(type, true),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: config.startColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 结束颜色
          Row(
            children: [
              const Text(
                '结束颜色',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickColor(type, false),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: config.endColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 亮度
          Row(
            children: [
              const Text(
                '亮度',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              Expanded(
                child: Slider(
                  value: config.brightness,
                  min: 0.3,
                  max: 1.5,
                  divisions: 24,
                  label: '${(config.brightness * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _currentColors[type] = config.copyWith(brightness: value);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(RelationType type, bool isStart) async {
    final config = _currentColors[type]!;
    final currentColor = isStart ? config.startColor : config.endColor;

    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: currentColor,
      ),
    );

    if (color != null) {
      setState(() {
        if (isStart) {
          _currentColors[type] = config.copyWith(startColor: color);
        } else {
          _currentColors[type] = config.copyWith(endColor: color);
        }
      });
    }
  }

  void _resetToDefault() {
    setState(() {
      _currentColors = Map.from(ParticlePreset.defaultPreset.colors);
      _globalBrightness = 1.0;
    });
  }

  void _randomizeColors() {
    setState(() {
      _currentColors = ParticleColorRandomizer.generateHarmoniousColors();
    });
  }

  String _getRelationTypeName(RelationType type) {
    switch (type) {
      case RelationType.entryToEntry:
        return '日记 → 日记';
      case RelationType.todoToEntry:
        return '待办 → 日记';
      case RelationType.todoToTodo:
        return '待办 → 待办';
      case RelationType.tagToEntry:
        return '标签 → 日记';
      case RelationType.constellationToConstellation:
        return '星座 → 星座';
    }
  }

  IconData _getRelationTypeIcon(RelationType type) {
    switch (type) {
      case RelationType.entryToEntry:
        return Icons.menu_book;
      case RelationType.todoToEntry:
        return Icons.swap_horiz;
      case RelationType.todoToTodo:
        return Icons.check_box;
      case RelationType.tagToEntry:
        return Icons.tag;
      case RelationType.constellationToConstellation:
        return Icons.auto_awesome;
    }
  }
}

/// 粒子预览组件
class _ParticlePreview extends StatefulWidget {
  final Map<RelationType, ParticleColorConfig> colors;
  final double brightness;

  const _ParticlePreview({
    required this.colors,
    required this.brightness,
  });

  @override
  State<_ParticlePreview> createState() => _ParticlePreviewState();
}

class _ParticlePreviewState extends State<_ParticlePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ParticleSystem _particleSystem;

  @override
  void initState() {
    super.initState();
    _particleSystem = ParticleSystem(
      colorConfig: widget.colors,
      globalBrightness: widget.brightness,
      maxParticles: 100,
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _controller.addListener(_emitParticles);
  }

  @override
  void didUpdateWidget(_ParticlePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _particleSystem.colorConfig = widget.colors;
    _particleSystem.globalBrightness = widget.brightness;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emitParticles() {
    if (!mounted) return;

    // 在预览区域生成一些示例粒子
    final types = RelationType.values;
    final type = types[_controller.value.toInt() % types.length];

    _particleSystem.emitBetween(
      const Offset(50, 100),
      const Offset(250, 100),
      type,
      strength: 1.0,
      count: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PreviewPainter(_particleSystem),
          size: Size.infinite,
        );
      },
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final ParticleSystem particleSystem;

  _PreviewPainter(this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // 更新并绘制粒子
    particleSystem.update(0.016);
    particleSystem.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) => true;
}

/// 颜色选择器对话框
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  @override
  Widget build(BuildContext context) {
    final currentColor =
        HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('选择颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 颜色预览
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 24),

          // 色相
          Row(
            children: [
              const Text('色相', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _hue,
                  min: 0,
                  max: 360,
                  onChanged: (value) => setState(() => _hue = value),
                ),
              ),
            ],
          ),

          // 饱和度
          Row(
            children: [
              const Text('饱和度', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _saturation,
                  min: 0,
                  max: 1,
                  onChanged: (value) => setState(() => _saturation = value),
                ),
              ),
            ],
          ),

          // 亮度
          Row(
            children: [
              const Text('亮度', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _lightness,
                  min: 0,
                  max: 1,
                  onChanged: (value) => setState(() => _lightness = value),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, currentColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
