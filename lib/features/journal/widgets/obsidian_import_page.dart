import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/entry_repository.dart';
import '../../../core/storage/todo_repository.dart';
import '../../../shared/utils/markdown_utils.dart';
import '../../../shared/widgets/frosted_card.dart';
import '../../../core/theme/theme_provider.dart';

/// Obsidian Vault 导入页面
///
/// 从 Obsidian 的 Markdown 文件导入日记和待办。
class ObsidianImportPage extends ConsumerStatefulWidget {
  const ObsidianImportPage({super.key});

  @override
  ConsumerState<ObsidianImportPage> createState() =>
      _ObsidianImportPageState();
}

class _ObsidianImportPageState extends ConsumerState<ObsidianImportPage> {
  String? _selectedVaultPath;
  List<FileSystemEntity> _mdFiles = [];
  bool _isScanning = false;
  bool _isImporting = false;
  int _importedCount = 0;
  int _skippedCount = 0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入 Obsidian 数据'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 说明 ────────────────────────────────
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.todoColor.color),
                    const SizedBox(width: 12),
                    const Text(
                      '导入说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Stargazer 支持从 Obsidian Vault 导入 Markdown 文件。\n\n'
                  '• 支持 YAML frontmatter 格式\n'
                  '• 自动识别 [[双链]] 关联\n'
                  '• 自动提取 @todo 待办事项\n'
                  '• 保留标签和情绪标记\n\n'
                  '请选择你的 Obsidian Vault 文件夹开始导入。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // ─── 选择文件夹 ───────────────────────────
          const Text(
            '选择 Vault 文件夹',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FrostedCard(
            effect: theme.glassEffect,
            onTap: _selectVaultFolder,
            child: Row(
              children: [
                Icon(
                  _selectedVaultPath != null
                      ? Icons.folder_open
                      : Icons.folder,
                  color: theme.diaryColor.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVaultPath != null ? '已选择文件夹' : '点击选择文件夹',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedVaultPath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _selectedVaultPath!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 扫描结果 ────────────────────────────
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_mdFiles.isNotEmpty)
            FrostedCard(
              effect: theme.glassEffect,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text(
                        '发现 ${_mdFiles.length} 个 Markdown 文件',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _mdFiles.length,
                      itemBuilder: (context, index) {
                        final file = _mdFiles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            p.basename(file.path),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ─── 错误信息 ─────────────────────────────
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ─── 导入按钮 ─────────────────────────────
          if (_mdFiles.isNotEmpty && !_isImporting)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _importFiles,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.diaryColor.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('开始导入'),
              ),
            ),

          if (_isImporting)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.diaryColor.color.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('导入中...'),
                  ],
                ),
              ),
            ),

          // ─── 导入结果 ─────────────────────────────
          if (_importedCount > 0 || _skippedCount > 0)
            FrostedCard(
              effect: theme.glassEffect,
              margin: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        '成功导入 $_importedCount 个文件',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_skippedCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.skip_next, color: Colors.orange),
                        const SizedBox(width: 12),
                        Text(
                          '跳过 $_skippedCount 个重复文件',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectVaultFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _selectedVaultPath = result;
          _mdFiles = [];
          _importedCount = 0;
          _skippedCount = 0;
          _errorMessage = null;
        });

        await _scanFiles(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择文件夹失败: $e';
      });
    }
  }

  Future<void> _scanFiles(String path) async {
    setState(() => _isScanning = true);

    try {
      final directory = Directory(path);
      final files = <FileSystemEntity>[];

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.md')) {
          // 跳过隐藏文件和系统文件
          if (!p.basename(entity.path).startsWith('.')) {
            files.add(entity);
          }
        }
      }

      setState(() {
        _mdFiles = files;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = '扫描文件失败: $e';
      });
    }
  }

  Future<void> _importFiles() async {
    setState(() {
      _isImporting = true;
      _importedCount = 0;
      _skippedCount = 0;
      _errorMessage = null;
    });

    try {
      final entryRepo = ref.read(entryRepositoryProvider);
      final todoRepo = ref.read(todoRepositoryProvider);

      for (final entity in _mdFiles) {
        if (entity is File) {
          try {
            final content = await entity.readAsString();
            final parsed = parseMarkdownEntry(content);

            final title = parsed['title'] as String? ?? p.basenameWithoutExtension(entity.path);
            final entryContent = parsed['content'] as String? ?? content;
            final createdAt = parsed['createdAt'] as DateTime? ?? DateTime.now();
            final mood = parsed['mood'] as String?;

            // 检查是否已存在（简单去重）
            final existing = await entryRepo.searchEntries(title);
            if (existing.any((e) => e.title == title)) {
              setState(() => _skippedCount++);
              continue;
            }

            // 创建日记条目
            await entryRepo.createEntry(EntriesCompanion(
              title: Value(title),
              content: Value(entryContent),
              createdAt: Value(createdAt),
              mood: Value(mood),
            ));

            // 提取并创建待办
            final todos = extractTodos(entryContent);
            for (final todoText in todos) {
              await todoRepo.createTodoFromText(todoText);
            }

            setState(() => _importedCount++);
          } catch (e) {
            debugPrint('导入文件失败: ${entity.path}, 错误: $e');
          }
        }
      }

      setState(() => _isImporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入完成: $_importedCount 个文件'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorMessage = '导入失败: $e';
      });
    }
  }
}
