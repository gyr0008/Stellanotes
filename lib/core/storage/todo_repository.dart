import 'package:drift/drift.dart';
import 'database.dart';

part 'todo_repository.g.dart';

@DriftAccessor(tables: [Todos, EntryTodos, Entries])
class TodoRepository extends DatabaseAccessor<AppDatabase>
    with _$TodoRepositoryMixin {
  TodoRepository(AppDatabase db) : super(db);

  // ─── 查询 ───────────────────────────────────────────
  Future<List<Todo>> getAllTodos() => select(todos).get();

  Future<List<Todo>> getActiveTodos() {
    return (select(todos)..where((t) => t.done.equals(false))).get();
  }

  Future<List<Todo>> getCompletedTodos() {
    return (select(todos)..where((t) => t.done.equals(true))).get();
  }

  Future<List<Todo>> getOverdueTodos() {
    // 简化：没有 dueDate 字段时返回空，后续可扩展
    return [];
  }

  Future<List<Todo>> getTodosByPriority(int priority) {
    return (select(todos)..where((t) => t.priority.equals(priority))).get();
  }

  Future<Todo?> getTodoById(int id) {
    return (select(todos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<Todo>> watchActiveTodos() {
    return (select(todos)..where((t) => t.done.equals(false))).watch();
  }

  // ─── 创建 ───────────────────────────────────────────
  Future<int> createTodo(TodosCompanion todo) {
    return into(todos).insert(todo);
  }

  Future<int> createTodoFromText(String title, {int priority = 2}) {
    return into(todos).insert(TodosCompanion(
      title: Value(title),
      priority: Value(priority),
    ));
  }

  // ── 更新 ───────────────────────────────────────────
  Future<bool> updateTodo(Todo todo) {
    return update(todos).replace(todo);
  }

  Future<int> toggleTodo(int id) async {
    final todo = await getTodoById(id);
    if (todo == null) return 0;

    return (update(todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        done: Value(!todo.done),
        completedAt: Value(todo.done ? null : DateTime.now()),
      ),
    );
  }

  Future<int> updateTodoTitle(int id, String title) {
    return (update(todos)..where((t) => t.id.equals(id)))
        .write(TodosCompanion(title: Value(title)));
  }

  // ─── 删除 ──────────────────────────────────────────
  Future<int> deleteTodo(int id) {
    return (delete(todos)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteCompletedTodos() {
    return (delete(todos)..where((t) => t.done.equals(true))).go();
  }

  // ─── 待办-日记关联 ─────────────────────────────────
  Future<void> linkTodoToEntry(int todoId, int entryId) {
    return into(entryTodos).insert(EntryTodosCompanion(
      todoId: Value(todoId),
      entryId: Value(entryId),
    ));
  }

  Future<void> unlinkTodoFromEntry(int todoId, int entryId) {
    return (delete(entryTodos)
          ..where((t) => t.todoId.equals(todoId) & t.entryId.equals(entryId)))
        .go();
  }

  Future<List<Entry>> getEntriesForTodo(int todoId) {
    return (select(entries).join([
          innerJoin(entryTodos, entryTodos.entryId.equalsExp(entries.id)),
        ])
          ..where(entryTodos.todoId.equals(todoId)))
        .map((row) => row.readTable(entries))
        .get();
  }

  Future<List<Todo>> getTodosForEntry(int entryId) {
    return (select(todos).join([
          innerJoin(entryTodos, entryTodos.todoId.equalsExp(todos.id)),
        ])
          ..where(entryTodos.entryId.equals(entryId)))
        .map((row) => row.readTable(todos))
        .get();
  }

  // ─── 统计 ───────────────────────────────────────────
  Future<int> getActiveTodoCount() {
    return (selectOnly(todos)
          ..addColumns([todos.id.count()])
          ..where(todos.done.equals(false)))
        .map((row) => row.read(todos.id.count()))
        .getSingle();
  }

  Future<int> getCompletedTodayCount() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    return (selectOnly(todos)
          ..addColumns([todos.id.count()])
          ..where(todos.done.equals(true) &
              todos.completedAt.isBiggerOrEqualValue(start) &
              todos.completedAt.isSmallerThanValue(end)))
        .map((row) => row.read(todos.id.count()))
        .getSingle();
  }
}
