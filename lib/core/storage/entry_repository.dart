import 'package:drift/drift.dart';
import 'database.dart';

part 'entry_repository.g.dart';

@DriftAccessor(tables: [Entries, EntryTags, Tags, EntryTodos, Todos, Relations])
class EntryRepository extends DatabaseAccessor<AppDatabase>
    with _$EntryRepositoryMixin {
  EntryRepository(super.db);

  // ─── 查询 ───────────────────────────────────────────
  Future<List<Entry>> getAllEntries() => select(entries).get();

  Future<List<Entry>> getEntriesByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(entries)
          ..where((e) => e.createdAt.isBetween(Constant(start), Constant(end))))
        .get();
  }

  Future<Entry?> getEntryById(int id) {
    return (select(entries)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<List<Entry>> searchEntries(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(entries)
          ..where((e) =>
              e.content.lower().like(pattern) |
              e.title.lower().like(pattern)))
        .get();
  }

  Future<List<Entry>> getEntriesByTag(String tagName) {
    return (select(entries).join([
          innerJoin(entryTags, entryTags.entryId.equalsExp(entries.id)),
          innerJoin(tags, entryTags.tagId.equalsExp(tags.id)),
        ])
          ..where(tags.name.equals(tagName)))
        .map((row) => row.readTable(entries))
        .get();
  }

  Stream<List<Entry>> watchAllEntries() => select(entries).watch();

  // ─── 创建 ───────────────────────────────────────────
  Future<int> createEntry(EntriesCompanion entry) {
    return into(entries).insert(entry);
  }

  // ─── 更新 ───────────────────────────────────────────
  Future<bool> updateEntry(Entry entry) {
    return update(entries).replace(entry);
  }

  Future<int> updateEntryContent(int id, String content) {
    return (update(entries)..where((e) => e.id.equals(id)))
        .write(EntriesCompanion(
      content: Value(content),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ─── 删除 ───────────────────────────────────────────
  Future<int> deleteEntry(int id) {
    return (delete(entries)..where((e) => e.id.equals(id))).go();
  }

  // ── 标签操作 ───────────────────────────────────────
  Future<int> createTag(String name, {String color = '#9C27B0', String icon = 'tag'}) {
    return into(tags).insert(TagsCompanion(
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
    ));
  }

  Future<List<Tag>> getAllTags() => select(tags).get();

  Future<void> addTagToEntry(int entryId, int tagId) {
    return into(entryTags).insert(EntryTagsCompanion(
      entryId: Value(entryId),
      tagId: Value(tagId),
    ));
  }

  Future<void> removeTagFromEntry(int entryId, int tagId) {
    return (delete(entryTags)
          ..where((t) => t.entryId.equals(entryId) & t.tagId.equals(tagId)))
        .go();
  }

  // ─── 关联操作 ───────────────────────────────────────
  Future<void> addRelation(int fromId, int toId, String type) {
    return into(relations).insert(RelationsCompanion(
      fromId: Value(fromId),
      toId: Value(toId),
      type: Value(type),
    ));
  }

  Future<List<Relation>> getRelationsForEntry(int entryId) {
    return (select(relations)
          ..where((r) => r.fromId.equals(entryId) | r.toId.equals(entryId)))
        .get();
  }

  // ─── 统计 ───────────────────────────────────────────
  Future<int> getEntryCount() async {
    final count = await (selectOnly(entries)..addColumns([entries.id.count()]))
        .map((row) => row.read(entries.id.count()))
        .getSingle();
    return count ?? 0;
  }

  Future<Map<DateTime, int>> getEntryCountByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final entriesList = await (select(entries)
          ..where((e) => e.createdAt.isBetween(Constant(start), Constant(end))))
        .get();

    final map = <DateTime, int>{};
    for (final entry in entriesList) {
      final day = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }
}
