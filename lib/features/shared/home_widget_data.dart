import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';

/// Android 桌面小组件数据提供器
///
/// 为桌面 Widget 提供今日待办和日记数据。
class HomeWidgetDataProvider {
  /// 获取今日待办列表（供 Widget 使用）
  static Future<List<Map<String, dynamic>>> getTodayTodos(
    WidgetRef ref,
  ) async {
    final repo = ref.read(todoRepositoryProvider);
    final todos = await repo.getActiveTodos();
    final today = DateTime.now();

    return todos
        .where((t) =>
            t.createdAt.year == today.year &&
            t.createdAt.month == today.month &&
            t.createdAt.day == today.day)
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'done': t.done,
              'priority': t.priority,
            })
        .toList();
  }

  /// 获取今日日记数量
  static Future<int> getTodayEntryCount(WidgetRef ref) async {
    final repo = ref.read(entryRepositoryProvider);
    final today = DateTime.now();
    final entries = await repo.getEntriesByDate(today);
    return entries.length;
  }

  /// 获取待完成的待办数量
  static Future<int> getPendingTodoCount(WidgetRef ref) async {
    final repo = ref.read(todoRepositoryProvider);
    return repo.getActiveTodoCount();
  }
}

/// 小组件预览（应用内展示用）
class WidgetPreview extends ConsumerWidget {
  const WidgetPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return FrostedCard(
      effect: theme.glassEffect,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: theme.diaryColor.color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Stargazer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${DateTime.now().month}/${DateTime.now().day}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '待办',
                  '0',
                  theme.todoColor.color,
                  Icons.check_box_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  '日记',
                  '0',
                  theme.diaryColor.color,
                  Icons.menu_book_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
