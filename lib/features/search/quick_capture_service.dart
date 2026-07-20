import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/database.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/storage/entry_repository.dart';
import 'package:stargazer/core/storage/todo_repository.dart';
import 'package:drift/drift.dart' hide Column;

/// 快速捕获服务
class QuickCaptureService {
  final EntryRepository _entryRepo;
  final TodoRepository _todoRepo;

  QuickCaptureService(this._entryRepo, this._todoRepo);

  /// 快速创建记录
  /// 自动判断类型：@todo 开头为待办，其余为日记
  Future<void> quickCapture(String text) async {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();

    // 判断是否为待办
    if (trimmed.toLowerCase().startsWith('@todo')) {
      final title = trimmed.substring(5).trim();
      if (title.isNotEmpty) {
        await _todoRepo.createTodoFromText(title);
      }
    } else {
      // 创建日记
      await _entryRepo.createEntry(EntriesCompanion(
        content: Value(trimmed),
        title: Value(_extractTitle(trimmed)),
      ));
    }
  }

  /// 从内容提取标题
  String _extractTitle(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        if (trimmed.startsWith('#')) {
          return trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        }
        return trimmed.length > 50 ? '${trimmed.substring(0, 50)}...' : trimmed;
      }
    }
    return '无标题';
  }
}

// ─── Provider ──────────────────────────────────────────

final quickCaptureServiceProvider = Provider<QuickCaptureService>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  final todoRepo = ref.watch(todoRepositoryProvider);
  return QuickCaptureService(entryRepo, todoRepo);
});

/// 快速捕获对话框
/// 用于 Windows 全局快捷键弹出的迷你窗口
class QuickCaptureDialog extends ConsumerStatefulWidget {
  const QuickCaptureDialog({super.key});

  @override
  ConsumerState<QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends ConsumerState<QuickCaptureDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isTodo = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedCard(
        effect: theme.glassEffect,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _isTodo ? Icons.check_box : Icons.menu_book,
                  color: _isTodo ? theme.todoColor.color : theme.diaryColor.color,
                ),
                const SizedBox(width: 8),
                Text(
                  _isTodo ? '快速待办' : '快速日记',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // 类型切换
                IconButton(
                  icon: Icon(
                    _isTodo ? Icons.menu_book : Icons.check_box,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _isTodo = !_isTodo);
                    if (_isTodo && !_controller.text.startsWith('@todo')) {
                      _controller.text = '@todo ${_controller.text}';
                    } else if (!_isTodo && _controller.text.startsWith('@todo')) {
                      _controller.text = _controller.text.substring(5).trim();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isTodo ? '输入待办事项...' : '输入日记内容...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTodo
                          ? theme.todoColor.color
                          : theme.diaryColor.color,
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;

    final service = ref.read(quickCaptureServiceProvider);
    service.quickCapture(_controller.text);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTodo ? '待办已添加' : '日记已保存'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 显示快速捕获对话框
void showQuickCaptureDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const QuickCaptureDialog(),
  );
}
