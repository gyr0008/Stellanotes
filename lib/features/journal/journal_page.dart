import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/entry_repository.dart';
import 'providers/journal_editor_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/storage/database.dart';

class JournalPage extends ConsumerWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showCalendar(context, ref),
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) => entries.isEmpty
            ? _buildEmptyState(context)
            : _buildEntryList(context, ref, entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/journal/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            '还没有日记',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始记录',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, WidgetRef ref, List<Entry> entries) {
    // 按日期分组
    final grouped = <String, List<Entry>>{};
    for (final entry in entries) {
      final dateKey = '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayEntries = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...dayEntries.map((entry) => _buildEntryCard(context, ref, entry)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, WidgetRef ref, Entry entry) {
    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/journal/${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.mood != null)
                Text(
                  entry.mood!,
                  style: const TextStyle(fontSize: 20),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title.isEmpty ? '无标题' : entry.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: JournalSearchDelegate(ref));
  }

  void _showCalendar(BuildContext context, WidgetRef ref) {
    // TODO: 实现日历视图
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日历视图开发中')),
    );
  }
}

class JournalSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  JournalSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键词搜索日记', style: TextStyle(color: Colors.white54)),
      );
    }

    return FutureBuilder<List<Entry>>(
      future: ref.read(entryRepositoryProvider).searchEntries(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(
            child: Text('没有找到相关日记', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              title: Text(entry.title.isEmpty ? '无标题' : entry.title),
              subtitle: Text(
                entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${entry.createdAt.month}/${entry.createdAt.day}',
                style: const TextStyle(color: Colors.white54),
              ),
              onTap: () {
                close(context, null);
                context.push('/journal/${entry.id}');
              },
            );
          },
        );
      },
    );
  }
}

class JournalDetailPage extends ConsumerWidget {
  final int entryId;
  const JournalDetailPage({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('日记详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/journal/$entryId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('日记不存在'));
          }
          return _buildDetail(context, ref, entry);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Entry entry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            entry.title.isEmpty ? '无标题' : entry.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 元信息
          Row(
            children: [
              if (entry.mood != null)
                Text(entry.mood!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 16),
              Text(
                '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),

          // Markdown 内容
          MarkdownBody(
            data: entry.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 16, height: 1.8, color: Colors.white),
              h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              blockquote: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              code: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('这条日记将被永久删除，无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(entryRepositoryProvider).deleteEntry(entryId);
              if (context.mounted) {
                context.pop();
                context.pop();
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Provider for single entry
final entryProvider = FutureProvider.family<Entry?, int>((ref, id) async {
  return ref.read(entryRepositoryProvider).getEntryById(id);
});
