import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/theme/app_theme.dart';
import 'package:stargazer/core/storage/entry_repository.dart';
import 'package:stargazer/core/storage/todo_repository.dart';

/// 导出格式
enum ExportFormat {
  json,
  markdown,
  html,
}

/// 数据导出引擎
class ExportEngine {
  final EntryRepository _entryRepo;
  final TodoRepository _todoRepo;

  ExportEngine(this._entryRepo, this._todoRepo);

  /// 导出为 JSON
  Future<String> exportToJson({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var entries = await _entryRepo.getAllEntries();
    var todos = await _todoRepo.getAllTodos();
    final tags = await _entryRepo.getAllTags();

    // 日期筛选
    if (startDate != null) {
      entries = entries.where((e) => e.createdAt.isAfter(startDate)).toList();
      todos = todos.where((t) => t.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      entries = entries.where((e) => e.createdAt.isBefore(endDate)).toList();
      todos = todos.where((t) => t.createdAt.isBefore(endDate)).toList();
    }

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => {
        'id': e.id,
        'title': e.title,
        'content': e.content,
        'mood': e.mood,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      }).toList(),
      'todos': todos.map((t) => {
        'id': t.id,
        'title': t.title,
        'done': t.done,
        'priority': t.priority,
        'createdAt': t.createdAt.toIso8601String(),
        'completedAt': t.completedAt?.toIso8601String(),
      }).toList(),
      'tags': tags.map((t) => {
        'id': t.id,
        'name': t.name,
        'color': t.color,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 导出为 Markdown 文件集
  Future<Map<String, String>> exportToMarkdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var entries = await _entryRepo.getAllEntries();

    if (startDate != null) {
      entries = entries.where((e) => e.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      entries = entries.where((e) => e.createdAt.isBefore(endDate)).toList();
    }

    final files = <String, String>{};

    for (final entry in entries) {
      final date = entry.createdAt;
      final title = entry.title.isEmpty ? '无标题' : entry.title;
      final filename = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_$title.md';

      final buffer = StringBuffer();
      buffer.writeln('---');
      buffer.writeln('title: "$title"');
      buffer.writeln('date: ${date.toIso8601String()}');
      if (entry.mood != null) buffer.writeln('mood: "${entry.mood}"');
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('# $title');
      buffer.writeln();
      buffer.writeln(entry.content);

      files[filename] = buffer.toString();
    }

    return files;
  }

  /// 导出为 HTML 个人网站
  Future<String> exportToHtml() async {
    final entries = await _entryRepo.getAllEntries();
    final todos = await _todoRepo.getAllTodos();

    final entriesHtml = entries.map((e) {
      final title = e.title.isEmpty ? '无标题' : e.title;
      return '''
      <article class="entry">
        <h2>$title</h2>
        <time>${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}</time>
        ${e.mood != null ? '<span class="mood">${e.mood}</span>' : ''}
        <div class="content">${_escapeHtml(e.content)}</div>
      </article>
      ''';
    }).join('\n');

    final todosHtml = todos.map((t) {
      return '''
      <li class="${t.done ? 'done' : ''}">
        <span>${_escapeHtml(t.title)}</span>
      </li>
      ''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>我的星空 - Stargazer</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #0a0a2e 0%, #1a1a4e 50%, #0d0d3d 100%);
      color: #e0e0e0;
      min-height: 100vh;
      padding: 40px 20px;
    }
    .container { max-width: 800px; margin: 0 auto; }
    h1 {
      text-align: center;
      font-size: 2.5em;
      margin-bottom: 40px;
      background: linear-gradient(135deg, #7c4dff, #448aff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .entry {
      background: rgba(255,255,255,0.05);
      border-radius: 16px;
      padding: 24px;
      margin-bottom: 20px;
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255,255,255,0.1);
    }
    .entry h2 { color: #b388ff; margin-bottom: 8px; }
    .entry time { color: #888; font-size: 0.9em; }
    .entry .mood { margin-left: 12px; }
    .entry .content { margin-top: 16px; line-height: 1.8; white-space: pre-wrap; }
    .todos { margin-top: 40px; }
    .todos h2 { color: #82b1ff; margin-bottom: 16px; }
    .todos li {
      padding: 8px 0;
      list-style: none;
      border-bottom: 1px solid rgba(255,255,255,0.05);
    }
    .todos li.done { text-decoration: line-through; opacity: 0.5; }
    .footer { text-align: center; margin-top: 60px; color: #666; font-size: 0.8em; }
  </style>
</head>
<body>
  <div class="container">
    <h1>My Starfield</h1>
    $entriesHtml
    <div class="todos">
      <h2>Todos</h2>
      <ul>$todosHtml</ul>
    </div>
    <div class="footer">Generated by Stargazer</div>
  </div>
</body>
</html>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br>');
  }
}

/// 导出 Provider
final exportEngineProvider = Provider<ExportEngine>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  final todoRepo = ref.watch(todoRepositoryProvider);
  return ExportEngine(entryRepo, todoRepo);
});

/// 数据导出页面
class DataExportPage extends ConsumerStatefulWidget {
  const DataExportPage({super.key});

  @override
  ConsumerState<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends ConsumerState<DataExportPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据导出'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 日期范围
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '导出范围',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton('开始日期', _startDate, () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _startDate = date);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton('结束日期', _endDate, () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _endDate = date);
                      }),
                    ),
                  ],
                ),
                if (_startDate != null || _endDate != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    child: const Text('清除日期'),
                  ),
              ],
            ),
          ),

          // 导出格式
          const Text(
            '导出格式',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          _buildExportCard(
            theme,
            icon: Icons.data_object,
            title: 'JSON 完整备份',
            subtitle: '包含所有数据，可用于恢复',
            onTap: () => _export(ExportFormat.json),
          ),
          const SizedBox(height: 12),

          _buildExportCard(
            theme,
            icon: Icons.description,
            title: 'Markdown 文件',
            subtitle: '与 Obsidian 兼容的 Markdown 文件',
            onTap: () => _export(ExportFormat.markdown),
          ),
          const SizedBox(height: 12),

          _buildExportCard(
            theme,
            icon: Icons.language,
            title: 'HTML 个人网站',
            subtitle: '生成静态网站，可部署到 GitHub Pages',
            onTap: () => _export(ExportFormat.html),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              date != null ? '${date.month}/${date.day}' : label,
              style: TextStyle(
                color: date != null ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(
    StarfieldTheme theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FrostedCard(
      effect: theme.glassEffect,
      onTap: _exporting ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.diaryColor.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.diaryColor.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          if (_exporting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Future<void> _export(ExportFormat format) async {
    setState(() => _exporting = true);

    try {
      final engine = ref.read(exportEngineProvider);
      final dir = await getTemporaryDirectory();

      switch (format) {
        case ExportFormat.json:
          final json = await engine.exportToJson(
            startDate: _startDate,
            endDate: _endDate,
          );
          final path = '${dir.path}/stargazer_backup.json';
          await File(path).writeAsString(json);
          await Share.shareXFiles([XFile(path)], text: 'Stargazer 数据备份');
          break;

        case ExportFormat.markdown:
          final files = await engine.exportToMarkdown(
            startDate: _startDate,
            endDate: _endDate,
          );
          final mdDir = Directory('${dir.path}/stargazer_md');
          if (!await mdDir.exists()) await mdDir.create();
          for (final entry in files.entries) {
            await File('${mdDir.path}/${entry.key}').writeAsString(entry.value);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导出 ${files.length} 篇日记到 Markdown')),
          );
          break;

        case ExportFormat.html:
          final html = await engine.exportToHtml();
          final path = '${dir.path}/stargazer_site.html';
          await File(path).writeAsString(html);
          await Share.shareXFiles([XFile(path)], text: '我的星空网站');
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      setState(() => _exporting = false);
    }
  }
}
