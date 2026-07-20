import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';

class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  ConsumerState<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends ConsumerState<AppearanceSettingsPage> {
  int _selectedPresetIndex = 0;
  bool _isCustomizing = false;

  @override
  void initState() {
    super.initState();
    // 找到当前主题对应的预设索引
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final theme = ref.read(appThemeProvider);
      for (int i = 0; i < PresetThemes.all.length; i++) {
        if (PresetThemes.all[i].name == theme.name) {
          setState(() => _selectedPresetIndex = i);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final notifier = ref.read(appThemeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('星空主题'),
        actions: [
          TextButton(
            onPressed: () => notifier.resetToPreset(PresetThemes.all[_selectedPresetIndex]),
            child: const Text('重置'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 实时预览 ────────────────────────────────
          const Text(
            '实时预览',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundTop, theme.backgroundBottom],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 模拟星星
                ...List.generate(20, (i) {
                  final random = (i * 7 + 3) % 100 / 100;
                  return Positioned(
                    left: random * 300,
                    top: (i * 13 + 7) % 160,
                    child: Container(
                      width: 2 + (i % 3) * 1.5,
                      height: 2 + (i % 3) * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: [
                          theme.diaryColor.color,
                          theme.todoColor.color,
                          theme.tagColor.color,
                        ][i % 3].withOpacity(0.6 + (i % 4) * 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: [
                              theme.diaryColor.color,
                              theme.todoColor.color,
                              theme.tagColor.color,
                            ][i % 3].withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // 毛玻璃卡片预览
                Center(
                  child: FrostedCard(
                    effect: theme.glassEffect,
                    width: 160,
                    height: 50,
                    child: const Center(
                      child: Text(
                        '毛玻璃效果预览',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 配色方案 ────────────────────────────────
          const Text(
            '配色方案',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: PresetThemes.all.length + 1,
              itemBuilder: (context, index) {
                if (index == PresetThemes.all.length) {
                  // 自定义按钮
                  return _buildCustomThemeButton(context);
                }
                final preset = PresetThemes.all[index];
                return _buildPresetCard(context, preset, index);
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── 自定义颜色 ──────────────────────────────
          if (_isCustomizing) ...[
            const Text(
              '自定义颜色',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildColorPicker('日记星星', theme.diaryColor.color, (color) {
                      notifier.updateDiaryColor(color);
                    }),
                    const Divider(height: 24, color: Colors.white12),
                    _buildColorPicker('待办星星', theme.todoColor.color, (color) {
                      notifier.updateTodoColor(color);
                    }),
                    const Divider(height: 24, color: Colors.white12),
                    _buildColorPicker('标签星星', theme.tagColor.color, (color) {
                      notifier.updateTagColor(color);
                    }),
                    const Divider(height: 24, color: Colors.white12),
                    _buildColorPicker(
                      '背景上部',
                      theme.backgroundTop,
                      (color) => notifier.updateBackground(color, theme.backgroundBottom),
                    ),
                    const Divider(height: 24, color: Colors.white12),
                    _buildColorPicker(
                      '背景下部',
                      theme.backgroundBottom,
                      (color) => notifier.updateBackground(theme.backgroundTop, color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ─── 毛玻璃效果 ─────────────────────────────
          const Text(
            '毛玻璃效果',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 预设选择
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGlassPresetButton('透明', GlassEffect.none, theme, notifier),
                      _buildGlassPresetButton('轻雾', GlassEffect.light, theme, notifier),
                      _buildGlassPresetButton('磨砂', GlassEffect.frosted, theme, notifier),
                      _buildGlassPresetButton('凝霜', GlassEffect.condensed, theme, notifier),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),

                  // 自定义滑块
                  Text(
                    '自定义参数',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    '模糊半径',
                    theme.glassEffect.blurRadius,
                    0,
                    40,
                    (value) {
                      notifier.updateGlassEffect(
                        theme.glassEffect.copyWith(
                          blurRadius: value,
                          preset: GlassPreset.custom,
                        ),
                      );
                    },
                    (v) => '${v.toInt()}px',
                  ),
                  _buildSlider(
                    '透明度',
                    theme.glassEffect.opacity,
                    0.1,
                    0.9,
                    (value) {
                      notifier.updateGlassEffect(
                        theme.glassEffect.copyWith(
                          opacity: value,
                          preset: GlassPreset.custom,
                        ),
                      );
                    },
                    (v) => '${(v * 100).toInt()}%',
                  ),
                  const SizedBox(height: 8),

                  // 边框和阴影选择
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '边框高光',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: GlassBorder.values.map((border) {
                                final labels = ['无', '细', '亮'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(labels[border.index]),
                                    selected: theme.glassEffect.border == border,
                                    onSelected: (selected) {
                                      if (selected) {
                                        notifier.updateGlassEffect(
                                          theme.glassEffect.copyWith(
                                            border: border,
                                            preset: GlassPreset.custom,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '阴影深度',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: GlassShadow.values.map((shadow) {
                                final labels = ['无', '轻', '重'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(labels[shadow.index]),
                                    selected: theme.glassEffect.shadow == shadow,
                                    onSelected: (selected) {
                                      if (selected) {
                                        notifier.updateGlassEffect(
                                          theme.glassEffect.copyWith(
                                            shadow: shadow,
                                            preset: GlassPreset.custom,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPresetCard(BuildContext context, StarfieldTheme preset, int index) {
    final isSelected = _selectedPresetIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPresetIndex = index);
          ref.read(appThemeProvider.notifier).resetToPreset(preset);
        },
        child: Container(
          width: 80,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [preset.backgroundTop, preset.backgroundBottom],
            ),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: preset.diaryColor.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.diaryColor.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.todoColor.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: preset.tagColor.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preset.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomThemeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _isCustomizing = !_isCustomizing),
        child: Container(
          width: 80,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isCustomizing ? Colors.white : Colors.white38,
              width: 1.5,
            ),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isCustomizing ? Icons.check : Icons.add,
                color: Colors.white70,
              ),
              const SizedBox(height: 4),
              const Text(
                '自定义',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, ValueChanged<Color> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: () => _showColorPicker(context, label, currentColor, onChanged),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38),
          ),
        ),
      ),
      title: Text(label),
      trailing: Text(
        '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      onTap: () => _showColorPicker(context, label, currentColor, onChanged),
    );
  }

  void _showColorPicker(BuildContext context, String label, Color currentColor, ValueChanged<Color> onChanged) {
    Color pickerColor = currentColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择 $label 颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onChanged(pickerColor);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPresetButton(
    String label,
    GlassEffect effect,
    StarfieldTheme theme,
    AppThemeNotifier notifier,
  ) {
    final isSelected = theme.glassEffect.preset == effect.preset;
    return GestureDetector(
      onTap: () => notifier.updateGlassEffect(effect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String Function(double) displayValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              Text(
                displayValue(value),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: Colors.white70,
            inactiveColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}
