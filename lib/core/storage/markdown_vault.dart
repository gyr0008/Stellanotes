import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/markdown_utils.dart';

/// Markdown 文件仓库管理器
///
/// 将数据库中的日记条目同步为本地 .md 文件，兼容 Obsidian 格式。
/// 文件结构：
///   vault/
///   ├── 2026/
///   │   ├── 07/
///   │   │   ├── 2026-07-19-日记标题.md
///   │   │   └── ...
///   └── _todos/
///       └── todos.md
class MarkdownVault {
  late Directory _vaultDir;
  late Directory _todosDir;

  /// 初始化仓库目录
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _vaultDir = Directory(p.join(appDir.path, 'stargazer_vault'));
    _todosDir = Directory(p.join(_vaultDir.path, '_todos'));

    if (!await _vaultDir.exists()) {
      await _vaultDir.create(recursive: true);
    }
    if (!await _todosDir.exists()) {
      await _todosDir.create(recursive: true);
    }
  }

  String get vaultPath => _vaultDir.path;

  /// 根据日期获取文件路径
  /// 格式：vault/YYYY/MM/YYYY-MM-DD-title.md
  Future<File> _getEntryFile(DateTime date, String title) async {
    final yearDir = Directory(p.join(_vaultDir.path, '${date.year}'));
    final monthDir = Directory(p.join(yearDir.path, '${date.month.toString().padLeft(2, '0')}'));

    if (!await yearDir.exists()) await yearDir.create(recursive: true);
    if (!await monthDir.exists()) await monthDir.create(recursive: true);

    final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-$safeTitle.md';
    return File(p.join(monthDir.path, fileName));
  }

  /// 写入日记条目为 Markdown 文件
  Future<File> writeEntry({
    required String title,
    required String content,
    required DateTime createdAt,
    List<String>? tags,
    String? mood,
    List<String>? linkedEntries,
  }) async {
    final file = await _getEntryFile(createdAt, title);

    final markdown = entryToMarkdown(
      title: title,
      content: content,
      createdAt: createdAt,
      tags: tags,
      mood: mood,
      linkedEntries: linkedEntries,
    );

    await file.writeAsString(markdown, flush: true);
    return file;
  }

  /// 读取 Markdown 文件
  Future<Map<String, dynamic>?> readEntry(File file) async {
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    final parsed = parseMarkdownEntry(content);
    parsed['filePath'] = file.path;
    return parsed;
  }

  /// 获取所有 Markdown 文件
  Future<List<File>> getAllEntryFiles() async {
    final files = <File>[];
    await for (final entity in _vaultDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        // 跳过 _todos 目录
        if (!entity.path.contains('_todos')) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  /// 删除条目文件
  Future<void> deleteEntryFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 写入待办列表
  Future<void> writeTodos(List<Map<String, dynamic>> todos) async {
    final file = File(p.join(_todosDir.path, 'todos.md'));
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('type: todo-list');
    buffer.writeln('updated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('---');
    buffer.writeln();

    for (final todo in todos) {
      final checkbox = todo['done'] == true ? '[x]' : '[ ]';
      final priority = todo['priority'] ?? 2;
      final priorityMark = 'P$priority';
      buffer.writeln('- $checkbox $priorityMark ${todo['title']}');
      if (todo['createdAt'] != null) {
        buffer.writeln('  created: ${todo['createdAt']}');
      }
      if (todo['completedAt'] != null) {
        buffer.writeln('  completed: ${todo['completedAt']}');
      }
      buffer.writeln();
    }

    await file.writeAsString(buffer.toString(), flush: true);
  }

  /// 读取待办列表
  Future<List<Map<String, dynamic>>> readTodos() async {
    final file = File(p.join(_todosDir.path, 'todos.md'));
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final todos = <Map<String, dynamic>>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final match = RegExp(r'- \[([ x])\] (P\d) (.+)').firstMatch(line);
      if (match != null) {
        todos.add({
          'done': match.group(1) == 'x',
          'priority': int.parse(match.group(2)!.substring(1)),
          'title': match.group(3)!,
        });
      }
    }

    return todos;
  }

  /// 检查文件是否有变更（用于同步）
  Future<Map<String, DateTime>> getFileModificationTimes() async {
    final result = <String, DateTime>{};
    await for (final entity in _vaultDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final stat = await entity.stat();
        result[entity.path] = stat.modified;
      }
    }
    return result;
  }
}
