import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/theme/app_theme.dart';
import 'package:stargazer/core/storage/database.dart';

/// 星座聚类服务
class ConstellationClusteringService {
  /// 基于时间和标签的简单聚类
  List<ConstellationCluster> clusterEntries(List<Entry> entries) {
    if (entries.isEmpty) return [];

    final clusters = <ConstellationCluster>[];
    final used = <int>{};

    for (int i = 0; i < entries.length; i++) {
      if (used.contains(i)) continue;

      final cluster = <int>[i];
      used.add(i);

      for (int j = i + 1; j < entries.length; j++) {
        if (used.contains(j)) continue;

        // 7天内 + 内容相似度
        final dayDiff = entries[i].createdAt
            .difference(entries[j].createdAt)
            .inDays
            .abs();

        if (dayDiff <= 7) {
          final similarity = _textSimilarity(
            entries[i].content,
            entries[j].content,
          );
          if (similarity > 0.3) {
            cluster.add(j);
            used.add(j);
          }
        }
      }

      if (cluster.length >= 2) {
        clusters.add(ConstellationCluster(
          entryIds: cluster.map((idx) => entries[idx].id).toList(),
          entries: cluster.map((idx) => entries[idx]).toList(),
          suggestedName: _generateName(cluster.map((idx) => entries[idx]).toList()),
        ));
      }
    }

    return clusters;
  }

  /// 简单的文本相似度（基于词频）
  double _textSimilarity(String a, String b) {
    final wordsA = _tokenize(a);
    final wordsB = _tokenize(b);

    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final intersection = wordsA.intersection(wordsB);
    final union = wordsA.union(wordsB);

    return intersection.length / union.length;
  }

  Set<String> _tokenize(String text) {
    // 简单中文分词：按2-gram
    final clean = text.replaceAll(RegExp(r'[^\u4e00-\u9fff\w]'), ' ');
    final words = <String>{};

    // 英文单词
    words.addAll(clean.split(RegExp(r'\s+')).where((w) => w.length > 1));

    // 中文 2-gram
    final chinese = RegExp(r'[\u4e00-\u9fff]+').allMatches(clean);
    for (final match in chinese) {
      final str = match.group(0)!;
      for (int i = 0; i < str.length - 1; i++) {
        words.add(str.substring(i, i + 2));
      }
    }

    return words;
  }

  /// 基于关键词生成星座名称
  String _generateName(List<Entry> entries) {
    final wordFreq = <String, int>{};
    final stopWords = {'的', '了', '是', '在', '我', '有', '和', '就', '不', '人', '都', '一', '一个'};

    for (final entry in entries) {
      final words = _tokenize(entry.content);
      for (final word in words) {
        if (stopWords.contains(word) || word.length < 2) continue;
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    if (wordFreq.isEmpty) return '未命名星座';

    // 取最高频的词
    final sorted = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topWord = sorted.first.key;
    return '$topWord之星';
  }
}

/// 星座聚类
class ConstellationCluster {
  final List<int> entryIds;
  final List<Entry> entries;
  final String suggestedName;
  String? customName;
  String? description;

  ConstellationCluster({
    required this.entryIds,
    required this.entries,
    required this.suggestedName,
    this.customName,
    this.description,
  });

  String get displayName => customName ?? suggestedName;
}

/// AI 星座命名页面
class ConstellationNamingPage extends ConsumerStatefulWidget {
  const ConstellationNamingPage({super.key});

  @override
  ConsumerState<ConstellationNamingPage> createState() =>
      _ConstellationNamingPageState();
}

class _ConstellationNamingPageState
    extends ConsumerState<ConstellationNamingPage> {
  final _clusteringService = ConstellationClusteringService();
  List<ConstellationCluster> _clusters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analyzeClusters();
  }

  Future<void> _analyzeClusters() async {
    final entryRepo = ref.read(entryRepositoryProvider);
    final entries = await entryRepo.getAllEntries();

    setState(() {
      _clusters = _clusteringService.clusterEntries(entries);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('星座发现'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clusters.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('还没有发现星座', style: TextStyle(color: Colors.white54)),
                      SizedBox(height: 8),
                      Text('写更多日记后，系统会自动发现记忆中的星座',
                          style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clusters.length,
                  itemBuilder: (context, index) {
                    return _buildClusterCard(_clusters[index], theme);
                  },
                ),
    );
  }

  Widget _buildClusterCard(ConstellationCluster cluster, StarfieldTheme theme) {
    return FrostedCard(
      effect: theme.glassEffect,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.tagColor.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.tagColor.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${cluster.entries.length} 条记忆',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showRenameDialog(cluster),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // 记忆预览
          ...cluster.entries.take(3).map((entry) {
            final title = entry.title.isEmpty
                ? entry.content.substring(0, entry.content.length.clamp(0, 40))
                : entry.title;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.star, size: 14, color: theme.diaryColor.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.createdAt.month}/${entry.createdAt.day}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            );
          }),

          if (cluster.entries.length > 3)
            Text(
              '还有 ${cluster.entries.length - 3} 条...',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),

          const SizedBox(height: 12),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRenameDialog(cluster),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('命名'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDescriptionDialog(cluster),
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('写故事'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(ConstellationCluster cluster) {
    final controller = TextEditingController(text: cluster.displayName);
    final suggestions = [cluster.suggestedName];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('命名星座'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '星座名称',
                hintText: '输入名称...',
              ),
            ),
            const SizedBox(height: 12),
            const Text('建议名称：', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () {
                    controller.text = s;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                cluster.customName = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDescriptionDialog(ConstellationCluster cluster) {
    final controller = TextEditingController(text: cluster.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cluster.displayName} 的故事'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '写下这个星座的故事...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                cluster.description = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
