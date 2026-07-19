// 工具函数：Markdown 链接解析
// 解析 [[双链]] 和 @todo 语法

/// 从 Markdown 内容中提取 [[双链]] 引用
List<String> extractWikiLinks(String content) {
  final regex = RegExp(r'\[\[([^\]]+)\]\]');
  return regex.allMatches(content).map((m) => m.group(1)!).toList();
}

/// 从 Markdown 内容中提取 @todo 待办
List<String> extractTodos(String content) {
  final regex = RegExp(r'@todo\s+([^\n]+)');
  return regex.allMatches(content).map((m) => m.group(1)!.trim()).toList();
}

/// 从 Markdown 内容中提取标签 #tag
List<String> extractTags(String content) {
  final regex = RegExp(r'#(\w+)');
  return regex.allMatches(content).map((m) => m.group(1)!).toList();
}

/// 将 Entry 数据转换为 Obsidian 兼容的 Markdown 文件内容
String entryToMarkdown({
  required String title,
  required String content,
  required DateTime createdAt,
  List<String>? tags,
  String? mood,
  List<String>? linkedEntries,
}) {
  final buffer = StringBuffer();

  // YAML frontmatter
  buffer.writeln('---');
  buffer.writeln('title: "$title"');
  buffer.writeln('date: ${createdAt.toIso8601String()}');
  if (mood != null) buffer.writeln('mood: "$mood"');
  if (tags != null && tags.isNotEmpty) {
    buffer.writeln('tags:');
    for (final tag in tags) {
      buffer.writeln('  - $tag');
    }
  }
  buffer.writeln('---');
  buffer.writeln();

  // 标题
  buffer.writeln('# $title');
  buffer.writeln();

  // 正文
  buffer.writeln(content);
  buffer.writeln();

  // 关联条目
  if (linkedEntries != null && linkedEntries.isNotEmpty) {
    buffer.writeln('---');
    buffer.writeln('关联:');
    for (final entry in linkedEntries) {
      buffer.writeln('- [[$entry]]');
    }
  }

  return buffer.toString();
}

/// 从 Obsidian 兼容的 Markdown 文件内容解析出 Entry 数据
Map<String, dynamic> parseMarkdownEntry(String markdown) {
  final result = <String, dynamic>{};
  final lines = markdown.split('\n');

  // 解析 frontmatter
  if (lines.first.trim() == '---') {
    int endIndex = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        endIndex = i;
        break;
      }
    }

    if (endIndex > 0) {
      for (int i = 1; i < endIndex; i++) {
        final line = lines[i];
        if (line.startsWith('title:')) {
          result['title'] = line.substring(6).trim().replaceAll('"', '');
        } else if (line.startsWith('date:')) {
          result['createdAt'] = DateTime.parse(line.substring(5).trim());
        } else if (line.startsWith('mood:')) {
          result['mood'] = line.substring(5).trim().replaceAll('"', '');
        } else if (line.startsWith('tags:')) {
          // tags 是多行的，在下一轮处理
        }
      }
    }
  }

  // 解析正文（跳过 frontmatter 和第一个标题）
  final contentLines = <String>[];
  bool pastFrontmatter = false;
  bool pastTitle = false;

  for (final line in lines) {
    if (!pastFrontmatter) {
      if (line.trim() == '---' && contentLines.isEmpty) {
        // 找到 frontmatter 结束
        int count = 0;
        for (final l in lines) {
          if (l.trim() == '---') count++;
          if (count == 2) break;
        }
        pastFrontmatter = true;
        continue;
      }
      continue;
    }

    if (!pastTitle && line.startsWith('# ')) {
      pastTitle = true;
      continue;
    }

    contentLines.add(line);
  }

  result['content'] = contentLines.join('\n').trim();
  return result;
}
