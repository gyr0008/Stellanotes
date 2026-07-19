import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stargazer/core/storage/storage_providers.dart';
import 'package:stargazer/core/storage/entry_repository.dart';
import 'package:stargazer/core/storage/todo_repository.dart';

/// 待办管理 Provider
final todoManagerProvider =
    StateNotifierProvider<TodoManagerNotifier, TodoManagerState>(
  (ref) => TodoManagerNotifier(ref),
);

class TodoManagerState {
  final List<Todo> activeTodos;
  final List<Todo> completedTodos;
  final String filter; // 'all' | 'active' | 'completed' | 'today'
  final int? priorityFilter;
  final bool isLoading;

  const TodoManagerState({
    this.activeTodos = const [],
    this.completedTodos = const [],
    this.filter = 'all',
    this.priorityFilter,
    this.isLoading = false,
  });

  List<Todo> get filteredTodos {
    switch (filter) {
      case 'active':
        return activeTodos;
      case 'completed':
        return completedTodos;
      case 'today':
        final today = DateTime.now();
        return activeTodos.where((t) {
          return t.createdAt.year == today.year &&
              t.createdAt.month == today.month &&
              t.createdAt.day == today.day;
        }).toList();
      default:
        return [...activeTodos, ...completedTodos];
    }
  }

  TodoManagerState copyWith({
    List<Todo>? activeTodos,
    List<Todo>? completedTodos,
    String? filter,
    int? priorityFilter,
    bool? isLoading,
  }) {
    return TodoManagerState(
      activeTodos: activeTodos ?? this.activeTodos,
      completedTodos: completedTodos ?? this.completedTodos,
      filter: filter ?? this.filter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TodoManagerNotifier extends StateNotifier<TodoManagerState> {
  final Ref ref;

  TodoManagerNotifier(this.ref) : super(const TodoManagerState()) {
    loadTodos();
  }

  Future<void> loadTodos() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(todoRepositoryProvider);
    final active = await repo.getActiveTodos();
    final completed = await repo.getCompletedTodos();
    state = state.copyWith(
      activeTodos: active,
      completedTodos: completed,
      isLoading: false,
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setPriorityFilter(int? priority) {
    state = state.copyWith(priorityFilter: priority);
  }

  Future<void> addTodo(String title, {int priority = 2}) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.createTodoFromText(title, priority: priority);
    await loadTodos();
  }

  Future<void> toggleTodo(int id) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.toggleTodo(id);

    // 如果完成，自动回链到今天的日记
    final todo = await repo.getTodoById(id);
    if (todo?.done == true) {
      await _linkToTodayDiary(id);
    }

    await loadTodos();
  }

  Future<void> deleteTodo(int id) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.deleteTodo(id);
    await loadTodos();
  }

  Future<void> updateTodoTitle(int id, String title) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.updateTodoTitle(id, title);
    await loadTodos();
  }

  Future<void> clearCompleted() async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.deleteCompletedTodos();
    await loadTodos();
  }

  /// 将完成的待办关联到今天的日记
  Future<void> _linkToTodayDiary(int todoId) async {
    final entryRepo = ref.read(entryRepositoryProvider);
    final todoRepo = ref.read(todoRepositoryProvider);
    final today = DateTime.now();
    final todayEntries = await entryRepo.getEntriesByDate(today);

    if (todayEntries.isNotEmpty) {
      await todoRepo.linkTodoToEntry(todoId, todayEntries.first.id);
    }
  }
}
