import 'package:drift/drift.dart';

part 'database.g.dart';

// ─── 日记条目 ───────────────────────────────────────────
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get mood => text().nullable()();
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(false))();
  TextColumn get encryptedContent => text().nullable()();
}

// ─── 待办事项 ───────────────────────────────────────────
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// ─── 关联关系 ───────────────────────────────────────────
class Relations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  TextColumn get type => text()(); // 'mention' | 'tag' | 'manual'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── 标签 ───────────────────────────────────────────────
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().withDefault(const Constant('#9C27B0'))();
  TextColumn get icon => text().withDefault(const Constant('tag'))();
}

// ─── 条目-标签关联 ───────────────────────────────────────
class EntryTags extends Table {
  IntColumn get entryId => integer()();
  IntColumn get tagId => integer()();
}

// ─── 条目-待办关联 ───────────────────────────────────────
class EntryTodos extends Table {
  IntColumn get entryId => integer()();
  IntColumn get todoId => integer()();
}

// ─── 习惯打卡 ───────────────────────────────────────────
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('star'))();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  IntColumn get frequency => integer().withDefault(const Constant(1))(); // 每天几次
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// ─── 习惯打卡记录 ───────────────────────────────────────
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()();
  DateTimeColumn get date => dateTime()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  Entries,
  Todos,
  Relations,
  Tags,
  EntryTags,
  EntryTodos,
  Habits,
  HabitLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(habits);
          await m.createTable(habitLogs);
        }
      },
    );
  }
}
