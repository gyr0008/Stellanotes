import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stargazer/core/storage/storage_providers.dart';
import 'package:stargazer/core/storage/markdown_vault.dart';
import 'package:stargazer/core/storage/git_repo_manager.dart';
import 'package:stargazer/core/storage/entry_repository.dart';
import 'package:stargazer/core/storage/todo_repository.dart';
import 'package:stargazer/shared/utils/markdown_utils.dart';

/// 日记创建/编辑 Provider
final journalEditorProvider =
    StateNotifierProvider<JournalEditorNotifier, JournalEditorState>(
  (ref) => JournalEditorNotifier(ref),
);

class JournalEditorState {
  final String title;
  final String content;
  final String? mood;
  final List<String> tags;
  final List<int> linkedTodoIds;
  final bool isSaving;
  final String? error;

  const JournalEditorState({
    this.title = '',
    this.content = '',
    this.mood,
    this.tags = const [],
    this.linkedTodoIds = const [],
    this.isSaving = false,
    this.error,
  });

  JournalEditorState copyWith({
    String? title,
    String? content,
    String? mood,
    List<String>? tags,
    List<int>? linkedTodoIds,
    bool? isSaving,
    String? error,
  }) {
    return JournalEditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      linkedTodoIds: linkedTodoIds ?? this.linkedTodoIds,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class JournalEditorNotifier extends StateNotifier<JournalEditorState> {
  final Ref ref;

  JournalEditorNotifier(this.ref) : super(const JournalEditorState());

  void setTitle(String title) => state = state.copyWith(title: title);
  void setContent(String content) => state = state.copyWith(content: content);
  void setMood(String? mood) => state = state.copyWith(mood: mood);

  void addTag(String tag) {
    if (!state.tags.contains(tag)) {
      state = state.copyWith(tags: [...state.tags, tag]);
    }
  }

  void removeTag(String tag) {
    state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());
  }

  void toggleLinkedTodo(int todoId) {
    final ids = List<int>.from(state.linkedTodoIds);
    if (ids.contains(todoId)) {
      ids.remove(todoId);
    } else {
      ids.add(todoId);
    }
    state = state.copyWith(linkedTodoIds: ids);
  }

  /// 保存日记（数据库 + Markdown 文件 + Git commit）
  Future<bool> save() async {
    if (state.title.trim().isEmpty && state.content.trim().isEmpty) {
      state = state.copyWith(error: '标题和内容不能同时为空');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final entryRepo = ref.read(entryRepositoryProvider);
      final vault = ref.read(markdownVaultProvider);
      final git = ref.read(gitRepoManagerProvider);

      // 1. 写入数据库
      final entryId = await entryRepo.createEntry(EntriesCompanion(
        title: Value(state.title),
        content: Value(state.content),
        mood: Value(state.mood),
      ));

      // 2. 写入 Markdown 文件
      await vault.init();
      await vault.writeEntry(
        title: state.title,
        content: state.content,
        createdAt: DateTime.now(),
        tags: state.tags,
        mood: state.mood,
      );

      // 3. 提取并创建待办
      final todos = extractTodos(state.content);
      final todoRepo = ref.read(todoRepositoryProvider);
      for (final todoText in todos) {
        final todoId = await todoRepo.createTodoFromText(todoText);
        await todoRepo.linkTodoToEntry(todoId, entryId);
      }

      // 4. 提取双链并创建关联
      final links = extractWikiLinks(state.content);
      for (final linkTitle in links) {
        // 查找目标条目
        final targets = await entryRepo.searchEntries(linkTitle);
        for (final target in targets) {
          await entryRepo.addRelation(entryId, target.id, 'mention');
        }
      }

      // 5. Git 自动提交
      if (git.isInitialized) {
        await git.autoCommit();
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// 加载已有日记进行编辑
  Future<void> loadEntry(int entryId) async {
    final entryRepo = ref.read(entryRepositoryProvider);
    final entry = await entryRepo.getEntryById(entryId);

    if (entry != null) {
      state = JournalEditorState(
        title: entry.title,
        content: entry.content,
        mood: entry.mood,
      );
    }
  }

  void reset() {
    state = const JournalEditorState();
  }
}
