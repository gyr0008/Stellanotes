import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/entry_repository.dart';
import '../../../shared/widgets/frosted_card.dart';
import '../../../core/theme/theme_provider.dart';

/// "去年今日"回顾页面
///
/// 展示历史上今天写过的日记，帮助用户回顾过去的记录。
class OnThisDayPage extends ConsumerWidget {
  const OnThisDayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final today = DateTime.now();
    final month = today.month;
    final day = today.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('去年今日'),
      ),
      body: FutureBuilder<List<Entry>>(
        future: _getEntriesOnThisDay(ref, month, day),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('加载失败: ${snapshot.error}'),
            );
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_edu,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '历史上今天的 ${month}月${day}日',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '还没有留下记录',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final yearsAgo = today.year - entry.createdAt.year;

              return FrostedCard(
                effect: theme.glassEffect,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.diaryColor.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$yearsAgo 年前',
                            style: TextStyle(
                              color: theme.diaryColor.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${entry.createdAt.year}年${entry.createdAt.month}月${entry.createdAt.day}日',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (entry.mood != null)
                          Text(entry.mood!, style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (entry.title.isNotEmpty)
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (entry.title.isNotEmpty) const SizedBox(height: 8),
                    Text(
                      entry.content,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Entry>> _getEntriesOnThisDay(
    WidgetRef ref,
    int month,
    int day,
  ) async {
    final repo = ref.read(entryRepositoryProvider);
    final allEntries = await repo.getAllEntries();

    // 筛选出月日匹配的条目
    return allEntries.where((entry) {
      return entry.createdAt.month == month && entry.createdAt.day == day;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按年份倒序
  }
}
