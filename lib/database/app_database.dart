import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get categoryId => text()();
  TextColumn get walletId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash, bank, savings, custom
  RealColumn get initialBalance => real().withDefault(const Constant(0))();
  TextColumn get color => text().withDefault(const Constant('#6C63FF'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get categoryId => text().nullable()(); // null = total budget
  RealColumn get amount => real()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Recurrings extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get walletId => text()();
  TextColumn get categoryId => text()();
  TextColumn get frequency => text()(); // daily, weekly, monthly, yearly
  DateTimeColumn get nextExecutionDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Expenses, Wallets, Budgets, Recurrings, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
    },
  );

  // ─── Seed default categories on first run ──────────────────────────────────
  Future<void> _seedCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        id: 'food',
        name: 'Food & Drink',
        icon: '🍔',
        color: '#FF6B6B',
      ),
      CategoriesCompanion.insert(
        id: 'transport',
        name: 'Transport',
        icon: '🚗',
        color: '#4ECDC4',
      ),
      CategoriesCompanion.insert(
        id: 'shopping',
        name: 'Shopping',
        icon: '🛍',
        color: '#FFBE0B',
      ),
      CategoriesCompanion.insert(
        id: 'health',
        name: 'Health',
        icon: '💊',
        color: '#06D6A0',
      ),
      CategoriesCompanion.insert(
        id: 'entertainment',
        name: 'Entertainment',
        icon: '🎮',
        color: '#FF006E',
      ),
      CategoriesCompanion.insert(
        id: 'bills',
        name: 'Bills',
        icon: '🧾',
        color: '#3A86FF',
      ),
      CategoriesCompanion.insert(
        id: 'salary',
        name: 'Salary',
        icon: '💰',
        color: '#4CAF82',
        isIncome: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'other',
        name: 'Other',
        icon: '📦',
        color: '#8E8E9E',
      ),
    ];

    for (final cat in defaultCategories) {
      await into(categories).insertOnConflictUpdate(cat);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_flow.db'));
    return NativeDatabase.createInBackground(file);
  });
}
