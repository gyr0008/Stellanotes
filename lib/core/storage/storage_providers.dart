import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_provider.dart';
import 'entry_repository.dart';
import 'todo_repository.dart';
import 'markdown_vault.dart';
import 'git_repo_manager.dart';

// ─── Repository Providers ───────────────────────────────

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository(database);
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(database);
});

// ─── Markdown Vault Provider ───────────────────────────

final markdownVaultProvider = Provider<MarkdownVault>((ref) {
  final vault = MarkdownVault();
  // 异步初始化需要在首次使用时完成
  return vault;
});

// ─── Git Repo Manager Provider ──────────────────────────

final gitRepoManagerProvider = Provider<GitRepoManager>((ref) {
  // 路径会在 init 时设置
  return GitRepoManager('');
});

// ── 日记列表 Stream Provider ───────────────────────────

final entriesStreamProvider = StreamProvider<List<Entry>>((ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.watchAllEntries();
});

// ─── 活跃待办 Stream Provider ───────────────────────────

final activeTodosStreamProvider = StreamProvider<List<Todo>>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.watchActiveTodos();
});

// ─── 待办数量 Provider ──────────────────────────────────

final activeTodoCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.getActiveTodoCount();
});

// ─── 今日完成数量 Provider ──────────────────────────────

final completedTodayCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.getCompletedTodayCount();
});

// ─── 日记总数 Provider ──────────────────────────────────

final entryCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getEntryCount();
});
