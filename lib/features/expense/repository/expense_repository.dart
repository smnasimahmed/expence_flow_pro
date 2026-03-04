import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../core/services/log/app_log.dart';
import '../model/expense_model.dart';

// Repository: one place for all expense data operations.
// Controller calls repository → repository talks to Drift or Firestore.
class ExpenseRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  ExpenseRepository({
    required AppDatabase db,
    required FirebaseFirestore firestore,
  }) : _db = db,
       _firestore = firestore;

  // ─── Local (Drift) ────────────────────────────────────────────────────────

  // Save expense locally first (offline-first)
  Future<void> saveLocally(ExpenseModel expense) async {
    await _db.into(_db.expenses).insertOnConflictUpdate(
      ExpensesCompanion(
        id: Value(expense.id),
        userId: Value(expense.userId),
        title: Value(expense.title),
        amount: Value(expense.amount),
        categoryId: Value(expense.categoryId),
        walletId: Value(expense.walletId),
        date: Value(expense.date),
        notes: Value(expense.notes),
        isSynced: Value(expense.isSynced),
        isDeleted: Value(expense.isDeleted),
        lastModified: Value(expense.lastModified),
      ),
    );
    appLog('Expense saved locally: ${expense.title}', source: 'ExpenseRepo');
  }

  // Get all non-deleted expenses for a user (paginated)
  Future<List<ExpenseModel>> getExpenses({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await (_db.select(_db.expenses)
          ..where(
            (e) => e.userId.equals(userId) & e.isDeleted.equals(false),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.date)])
          ..limit(limit, offset: offset))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Get expenses in a date range (for analytics and budget calculation)
  Future<List<ExpenseModel>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await (_db.select(_db.expenses)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                e.isDeleted.equals(false) &
                e.date.isBetweenValues(from, to),
          ))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Soft delete: just mark as deleted, sync engine will clean up
  Future<void> softDelete(String expenseId) async {
    await (_db.update(_db.expenses)
          ..where((e) => e.id.equals(expenseId)))
        .write(
          ExpensesCompanion(
            isDeleted: const Value(true),
            isSynced: const Value(false),
            lastModified: Value(DateTime.now()),
          ),
        );
    appLog('Expense soft deleted: $expenseId', source: 'ExpenseRepo');
  }

  // Undo delete
  Future<void> undoDelete(String expenseId) async {
    await (_db.update(_db.expenses)
          ..where((e) => e.id.equals(expenseId)))
        .write(
          ExpensesCompanion(
            isDeleted: const Value(false),
            isSynced: const Value(false),
            lastModified: Value(DateTime.now()),
          ),
        );
  }

  // All unsynced expenses (used by sync engine to push to Firestore)
  Future<List<ExpenseModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.expenses)
          ..where(
            (e) => e.userId.equals(userId) & e.isSynced.equals(false),
          ))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Mark as synced after successful push
  Future<void> markSynced(String expenseId) async {
    await (_db.update(_db.expenses)
          ..where((e) => e.id.equals(expenseId)))
        .write(const ExpensesCompanion(isSynced: Value(true)));
  }

  // ─── Remote (Firestore) ───────────────────────────────────────────────────

  // Push one expense to Firestore
  Future<void> pushToFirestore(ExpenseModel expense) async {
    await _firestore
        .collection('users')
        .doc(expense.userId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toFirestore());

    appLog('Expense pushed to Firestore: ${expense.id}', source: 'ExpenseRepo');
  }

  // Pull expenses updated after lastSyncTime from Firestore
  Future<List<ExpenseModel>> pullFromFirestore({
    required String userId,
    required DateTime lastSyncTime,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where(
          'lastModified',
          isGreaterThan: lastSyncTime.millisecondsSinceEpoch,
        )
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc.data()))
        .toList();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  ExpenseModel _rowToModel(Expense row) {
    return ExpenseModel(
      id: row.id,
      userId: row.userId,
      title: row.title,
      amount: row.amount,
      categoryId: row.categoryId,
      walletId: row.walletId,
      date: row.date,
      notes: row.notes,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
      lastModified: row.lastModified,
    );
  }
}
