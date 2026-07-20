import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/frosted_card.dart';

/// 星座详情视图
///
/// 展示某个标签（星座）下的所有关联日记和待办。
class ConstellationDetailView extends ConsumerWidget {
  final String tagName;
  final Color tagColor;
  final List<int> memberEntryIds;

  const ConstellationDetailView({
    super.key,
    required this.tagName,
    required this.tagColor,
    required this.memberEntryIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tagColor,
                boxShadow: [
                  BoxShadow(
                    color: tagColor.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('#$tagName'),
          ],
        ),
      ),
      body: memberEntryIds.isEmpty
          ? Center(
              child: Text(
                '这个星座还没有星星',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: memberEntryIds.length,
              itemBuilder: (context, index) {
                final entryId = memberEntryIds[index];
                return FrostedCard(
                  effect: theme.glassEffect,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.diaryColor.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '日记 #$entryId',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white38),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
