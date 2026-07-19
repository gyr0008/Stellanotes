import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/entry_repository.dart';
import '../providers/journal_editor_provider.dart';
import '../../../shared/widgets/frosted_card.dart';

class JournalEditorPage extends ConsumerStatefulWidget {
  final int? entryId; // null = 新建
  const JournalEditorPage({super.key, this.entryId});

  @override
  ConsumerState<JournalEditorPage> createState() => _JournalEditorPageState();
}

class _JournalEditorPageState extends ConsumerState<JournalEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedMood;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  static const List<String> _moods = ['😊', '😐', '😢', '😡', '🤔', '', '🥰', '😎'];

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _loadEntry();
    }
  }

  Future<void> _loadEntry() async {
    final entry = await ref.read(entryRepositoryProvider).getEntryById(widget.entryId!);
    if (entry != null && mounted) {
      setState(() {
        _titleController.text = entry.title;
        _contentController.text = entry.content;
        _selectedMood = entry.mood;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(journalEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId == null ? '新建日记' : '编辑日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: editorState.isSaving ? null : _save,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题输入
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '标题',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: 16),

                // 情绪选择
                Row(
                  children: [
                    Text(
                      '情绪:',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(width: 8),
                    ..._moods.map((mood) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMood = mood),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedMood == mood
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(mood, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // 标签输入
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._tags.map((tag) => Chip(
                      label: Text('#$tag'),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    )),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _tagController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '+ 标签',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              _tags.add(value.trim());
                              _tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 内容输入
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 16, height: 1.8),
                  decoration: InputDecoration(
                    hintText: '开始写作...\n\n支持 Markdown 格式\n使用 [[双链]] 关联其他日记\n使用 @todo 创建待办',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ],
            ),
          ),

          // 保存中遮罩
          if (editorState.isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final notifier = ref.read(journalEditorProvider.notifier);

    notifier.setTitle(_titleController.text);
    notifier.setContent(_contentController.text);
    notifier.setMood(_selectedMood);

    // 清除旧标签并添加新标签
    for (final tag in _tags) {
      notifier.addTag(tag);
    }

    final success = await notifier.save();

    if (mounted) {
      if (success) {
        context.pop();
      } else {
        final error = ref.read(journalEditorProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? '保存失败')),
        );
      }
    }
  }
}
