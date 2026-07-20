import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/entry_repository.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../features/journal/journal_page.dart';
import 'share_card_generator.dart';
import 'package:stargazer/core/theme/theme_provider.dart';

/// 分享卡片预览页面
class ShareCardPage extends ConsumerStatefulWidget {
  final int entryId;

  const ShareCardPage({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends ConsumerState<ShareCardPage> {
  CardTemplate _selectedTemplate = CardTemplate.starry;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final entryAsync = ref.watch(entryProvider(widget.entryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享卡片'),
        actions: [
          TextButton(
            onPressed: _isGenerating ? null : _generateAndShare,
            child: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('分享'),
          ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('日记不存在'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 卡片预览
              FrostedCard(
                effect: theme.glassEffect,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _getTemplateColors(_selectedTemplate),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.title.isEmpty ? '无标题' : entry.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (entry.mood != null)
                              Text(
                                entry.mood!,
                                style: const TextStyle(fontSize: 48),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Text(
                            entry.content,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              height: 1.6,
                            ),
                            maxLines: 12,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${entry.createdAt.year}年${entry.createdAt.month}月${entry.createdAt.day}日',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '— Stargazer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 模板选择
              const Text(
                '选择模板',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: CardTemplate.values.map((template) {
                  final isSelected = _selectedTemplate == template;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTemplate = template),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: _getTemplateColors(template),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getTemplateName(template),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  List<Color> _getTemplateColors(CardTemplate template) {
    switch (template) {
      case CardTemplate.minimal:
        return [const Color(0xFFE0E0E0), const Color(0xFFF5F5F5)];
      case CardTemplate.literary:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case CardTemplate.starry:
        return [const Color(0xFF0A0E27), const Color(0xFF1A1A3E)];
    }
  }

  String _getTemplateName(CardTemplate template) {
    switch (template) {
      case CardTemplate.minimal:
        return '简约';
      case CardTemplate.literary:
        return '文艺';
      case CardTemplate.starry:
        return '星空';
    }
  }

  Future<void> _generateAndShare() async {
    final entry = await ref.read(entryRepositoryProvider).getEntryById(widget.entryId);
    if (entry == null) return;

    setState(() => _isGenerating = true);

    try {
      await ShareCardGenerator.shareCard(
        title: entry.title.isEmpty ? '无标题' : entry.title,
        content: entry.content,
        mood: entry.mood,
        date: entry.createdAt,
        template: _selectedTemplate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
