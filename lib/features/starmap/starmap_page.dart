import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/starmap_canvas.dart';
import 'widgets/shader_starfield_background.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/storage/storage_providers.dart';

class StarmapPage extends ConsumerWidget {
  const StarmapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final entryCountAsync = ref.watch(entryCountProvider);
    final activeTodoCountAsync = ref.watch(activeTodoCountProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Shader 星空背景
          ShaderStarfieldBackground(
            particleDensity: theme.particleDensity,
            topColor: theme.backgroundTop,
            bottomColor: theme.backgroundBottom,
          ),

          // 星空图谱画布
          const StarmapCanvas(),

          // 顶部工具栏
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: FrostedCard(
              effect: theme.glassEffect,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.stars, color: theme.diaryColor.color),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '星空图谱',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: () {
                      // TODO: 搜索功能
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, size: 20),
                    onPressed: () {
                      _showFilterSheet(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 右下角快捷操作
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                FrostedCard(
                  effect: theme.glassEffect,
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    // TODO: 新建日记
                  },
                  child: Icon(Icons.add, color: theme.diaryColor.color),
                ),
                const SizedBox(height: 8),
                FrostedCard(
                  effect: theme.glassEffect,
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    // TODO: 视图切换
                  },
                  child: Icon(Icons.view_agenda, color: theme.todoColor.color),
                ),
              ],
            ),
          ),

          // 底部统计信息
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FrostedCard(
              effect: theme.glassEffect,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '日记',
                    entryCountAsync.valueOrNull?.toString() ?? '0',
                    theme.diaryColor.color,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _buildStatItem(
                    '待办',
                    activeTodoCountAsync.valueOrNull?.toString() ?? '0',
                    theme.todoColor.color,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  _buildStatItem('标签', '0', theme.tagColor.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FrostedCard(
        effect: ref.watch(appThemeProvider).glassEffect,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '筛选图谱',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('显示日记'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('显示待办'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('显示标签'),
              value: true,
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            const Text(
              '时间范围',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('全部'), selected: true, onSelected: (_) {}),
                ChoiceChip(label: const Text('最近 7 天'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('最近 30 天'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('今年'), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
