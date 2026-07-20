import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:stargazer/core/theme/app_theme.dart';

/// Markdown 渲染器
/// 支持标题、粗体、斜体、代码块、表格、任务列表、链接、图片
class MarkdownRenderer extends ConsumerWidget {
  final String content;
  final bool editable;
  final VoidCallback? onTaskToggled;

  const MarkdownRenderer({
    super.key,
    required this.content,
    this.editable = false,
    this.onTaskToggled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final lines = content.split('\n');
    final widgets = <Widget>[];
    bool inCodeBlock = false;
    final codeBuffer = <String>[];
    String codeLang = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 代码块
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          widgets.add(_buildCodeBlock(codeBuffer.join('\n'), codeLang, theme));
          codeBuffer.clear();
          codeLang = '';
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLang = line.trim().substring(3).trim();
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.add(line);
        continue;
      }

      // 空行
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // 标题
      if (line.startsWith('# ')) {
        widgets.add(_buildHeading(line.substring(2), 1, theme));
      } else if (line.startsWith('## ')) {
        widgets.add(_buildHeading(line.substring(3), 2, theme));
      } else if (line.startsWith('### ')) {
        widgets.add(_buildHeading(line.substring(4), 3, theme));
      } else if (line.startsWith('#### ')) {
        widgets.add(_buildHeading(line.substring(5), 4, theme));
      }
      // 任务列表
      else if (line.trim().startsWith('- [ ] ') || line.trim().startsWith('- [x] ')) {
        widgets.add(_buildTaskItem(line.trim(), theme));
      }
      // 无序列表
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(_buildListItem(line.trim().substring(2), theme));
      }
      // 有序列表
      else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        final text = line.trim().replaceFirst(RegExp(r'^\d+\.\s'), '');
        widgets.add(_buildListItem(text, theme, numbered: true));
      }
      // 表格
      else if (line.contains('|') && line.trim().startsWith('|')) {
        // 收集表格行
        final tableLines = <String>[line];
        while (i + 1 < lines.length && lines[i + 1].contains('|') && lines[i + 1].trim().startsWith('|')) {
          i++;
          tableLines.add(lines[i]);
        }
        widgets.add(_buildTable(tableLines, theme));
      }
      // 引用
      else if (line.startsWith('> ')) {
        widgets.add(_buildBlockquote(line.substring(2), theme));
      }
      // 分割线
      else if (line.trim() == '---' || line.trim() == '***') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Colors.white.withOpacity(0.2)),
        ));
      }
      // 普通段落
      else {
        widgets.add(_buildParagraph(line, theme));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildHeading(String text, int level, StarfieldTheme theme) {
    double fontSize;
    FontWeight fontWeight;
    switch (level) {
      case 1: fontSize = 28; fontWeight = FontWeight.bold; break;
      case 2: fontSize = 24; fontWeight = FontWeight.bold; break;
      case 3: fontSize = 20; fontWeight = FontWeight.w600; break;
      default: fontSize = 17; fontWeight = FontWeight.w600; break;
    }

    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 16 : 12, bottom: 8),
      child: _buildRichText(text, TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.white,
      )),
    );
  }

  Widget _buildParagraph(String text, StarfieldTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildRichText(text, const TextStyle(
        fontSize: 15,
        color: Colors.white70,
        height: 1.6,
      )),
    );
  }

  Widget _buildRichText(String text, TextStyle style) {
    // 解析行内格式
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)|(\[(.+?)\]\((.+?)\))|(!(.+?)\((.+?)\))',
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      // 匹配前的普通文本
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      if (match.group(2) != null) {
        // 粗体
        spans.add(TextSpan(
          text: match.group(2),
          style: style.merge(const TextStyle(fontWeight: FontWeight.bold)),
        ));
      } else if (match.group(4) != null) {
        // 斜体
        spans.add(TextSpan(
          text: match.group(4),
          style: style.merge(const TextStyle(fontStyle: FontStyle.italic)),
        ));
      } else if (match.group(6) != null) {
        // 行内代码
        spans.add(TextSpan(
          text: match.group(6),
          style: style.merge(TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.white.withOpacity(0.1),
            color: Colors.amberAccent,
          )),
        ));
      } else if (match.group(8) != null) {
        // 链接
        spans.add(TextSpan(
          text: match.group(8),
          style: style.merge(const TextStyle(
            color: Colors.blueAccent,
            decoration: TextDecoration.underline,
          )),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    if (spans.isEmpty) {
      return Text(text, style: style);
    }

    return RichText(text: TextSpan(style: style, children: spans));
  }

  Widget _buildTaskItem(String line, StarfieldTheme theme) {
    final isDone = line.startsWith('- [x]');
    final text = line.replaceFirst(RegExp(r'^- \[[ x]\]\s*'), '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isDone,
            onChanged: (_) => onTaskToggled?.call(),
            activeColor: theme.todoColor.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildRichText(text, TextStyle(
                fontSize: 15,
                color: isDone ? Colors.white38 : Colors.white70,
                decoration: isDone ? TextDecoration.lineThrough : null,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text, StarfieldTheme theme, {bool numbered = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              numbered ? '•' : '•',
              style: TextStyle(color: theme.diaryColor.color, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildRichText(text, const TextStyle(
              fontSize: 15,
              color: Colors.white70,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockquote(String text, StarfieldTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.diaryColor.color, width: 3),
        ),
        color: Colors.white.withOpacity(0.03),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: _buildRichText(text, const TextStyle(
        fontSize: 15,
        color: Colors.white60,
        fontStyle: FontStyle.italic,
        height: 1.6,
      )),
    );
  }

  Widget _buildCodeBlock(String code, String lang, StarfieldTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lang.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                lang,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SelectableText(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.greenAccent.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<String> tableLines, StarfieldTheme theme) {
    if (tableLines.length < 2) return const SizedBox.shrink();

    final rows = <List<String>>[];
    for (int i = 0; i < tableLines.length; i++) {
      final line = tableLines[i].trim();
      // 跳过分隔行
      if (line.contains('---')) continue;

      final cells = line
          .split('|')
          .where((c) => c.trim().isNotEmpty)
          .map((c) => c.trim())
          .toList();
      if (cells.isNotEmpty) rows.add(cells);
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
          children: [
            // 表头
            if (rows.isNotEmpty)
              TableRow(
                decoration: BoxDecoration(
                  color: theme.diaryColor.color.withOpacity(0.15),
                ),
                children: rows.first.map((cell) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        cell,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            // 数据行
            ...rows.skip(1).map((row) {
              return TableRow(
                children: row.map((cell) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: _buildRichText(cell, const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      )),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Markdown 编辑器页面（带实时预览）
class MarkdownEditorPage extends ConsumerStatefulWidget {
  final int? entryId;
  final String? initialContent;

  const MarkdownEditorPage({
    super.key,
    this.entryId,
    this.initialContent,
  });

  @override
  ConsumerState<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends ConsumerState<MarkdownEditorPage> {
  late TextEditingController _controller;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId != null ? '编辑日记' : '新建日记'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() => _showPreview = !_showPreview);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(),
          ),
        ],
      ),
      body: _showPreview
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownRenderer(content: _controller.text),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: '开始写点什么...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
      bottomNavigationBar: !_showPreview
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _toolbarButton(Icons.format_bold, '**粗体**'),
                  _toolbarButton(Icons.format_italic, '*斜体*'),
                  _toolbarButton(Icons.code, '`代码`'),
                  _toolbarButton(Icons.link, '[链接](url)'),
                  _toolbarButton(Icons.check_box, '- [ ] 任务'),
                  _toolbarButton(Icons.image, '![图片](url)'),
                ],
              ),
            )
          : null,
    );
  }

  Widget _toolbarButton(IconData icon, String snippet) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70, size: 20),
      onPressed: () {
        final pos = _controller.selection.baseOffset;
        final text = _controller.text;
        _controller.text = text.substring(0, pos) + snippet + text.substring(pos);
        _controller.selection = TextSelection.collapsed(
          offset: pos + snippet.length,
        );
      },
    );
  }

  void _save() {
    // TODO: 保存到数据库
    Navigator.pop(context);
  }
}
