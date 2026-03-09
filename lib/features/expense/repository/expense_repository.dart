import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../core/services/log/app_log.dart';
import '../../../core/services/connectivity/connectivity_service.dart';
import '../model/expense_model.dart';

// Repository: one place for all expense data operations.
// Controller calls repository -> repository talks to Drift or Firestore.
class ExpenseRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  ExpenseRepository({required AppDatabase db, required FirebaseFirestore firestore})
      : _db = db, _firestore = firestore;

  // ─── Local (Drift) ────────────────────────────────────────────────────────

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

  // Save + immediately push to Firestore if device is online
  Future<void> saveAndSync(ExpenseModel expense) async {
    await saveLocally(expense);

    final isOnline = await ConnectivityService.isOnline;
    if (isOnline) {
      await pushToFirestore(expense);
      await markSynced(expense.id);
      appLog('Expense instantly synced: ${expense.id}', source: 'ExpenseRepo');
    }
  }

  Future<List<ExpenseModel>> getExpenses({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await (_db.select(_db.expenses)
          ..where((e) => e.userId.equals(userId) & e.isDeleted.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.date)])
          ..limit(limit, offset: offset))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<List<ExpenseModel>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await (_db.select(_db.expenses)
          ..where((e) =>
              e.userId.equals(userId) &
              e.isDeleted.equals(false) &
              e.date.isBetweenValues(from, to)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Hard delete: remove from expenses table + save to deleted_expenses tombstone
  Future<void> hardDelete(ExpenseModel expense) async {
    // 1. Save to tombstone table so sync knows to delete it from Firestore too
    await _db.into(_db.deletedExpenses).insertOnConflictUpdate(
      DeletedExpensesCompanion(
        id: Value(expense.id),
        userId: Value(expense.userId),
        title: Value(expense.title),
        amount: Value(expense.amount),
        categoryId: Value(expense.categoryId),
        walletId: Value(expense.walletId),
        date: Value(expense.date),
        notes: Value(expense.notes),
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );

    // 2. Remove from active expenses
    await (_db.delete(_db.expenses)..where((e) => e.id.equals(expense.id))).go();

    // 3. If online, push delete to Firestore immediately
    final isOnline = await ConnectivityService.isOnline;
    if (isOnline) {
      await _pushDeleteToFirestore(expense);
      await _markDeleteSynced(expense.id);
    }

    appLog('Expense hard deleted: ${expense.id}', source: 'ExpenseRepo');
  }

  // Restore from tombstone back to active (undo delete — only works before next sync)
  Future<void> restoreDeleted(ExpenseModel expense) async {
    await saveLocally(expense.copyWith(isDeleted: false, isSynced: false));
    await (_db.delete(_db.deletedExpenses)..where((e) => e.id.equals(expense.id))).go();
    appLog('Expense restored: ${expense.id}', source: 'ExpenseRepo');
  }

  Future<List<ExpenseModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.expenses)
          ..where((e) => e.userId.equals(userId) & e.isSynced.equals(false)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<List<DeletedExpense>> getUnsyncedDeleted(String userId) async {
    return (_db.select(_db.deletedExpenses)
          ..where((e) => e.userId.equals(userId) & e.isSynced.equals(false)))
        .get();
  }

  Future<void> markSynced(String expenseId) async {
    await (_db.update(_db.expenses)..where((e) => e.id.equals(expenseId)))
        .write(const ExpensesCompanion(isSynced: Value(true)));
  }

  // ─── Remote (Firestore) ───────────────────────────────────────────────────

  Future<void> pushToFirestore(ExpenseModel expense) async {
    await _firestore
        .collection('users')
        .doc(expense.userId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toFirestore());

    appLog('Expense pushed to Firestore: ${expense.id}', source: 'ExpenseRepo');
  }

  Future<void> _pushDeleteToFirestore(ExpenseModel expense) async {
    // Move to deleted_expenses collection in Firestore, remove from expenses
    await _firestore
        .collection('users')
        .doc(expense.userId)
        .collection('deleted_expenses')
        .doc(expense.id)
        .set({
          ...expense.toFirestore(),
          'deletedAt': DateTime.now().millisecondsSinceEpoch,
        });

    await _firestore
        .collection('users')
        .doc(expense.userId)
        .collection('expenses')
        .doc(expense.id)
        .delete();
  }

  Future<void> pushDeletedToFirestore(DeletedExpense row) async {
    await _firestore
        .collection('users')
        .doc(row.userId)
        .collection('deleted_expenses')
        .doc(row.id)
        .set({
          'id': row.id,
          'userId': row.userId,
          'title': row.title,
          'amount': row.amount,
          'categoryId': row.categoryId,
          'walletId': row.walletId,
          'date': row.date.millisecondsSinceEpoch,
          'notes': row.notes,
          'deletedAt': row.deletedAt.millisecondsSinceEpoch,
        });

    // Also remove from Firestore active expenses collection
    await _firestore
        .collection('users')
        .doc(row.userId)
        .collection('expenses')
        .doc(row.id)
        .delete();
  }

  Future<void> _markDeleteSynced(String expenseId) async {
    await (_db.update(_db.deletedExpenses)..where((e) => e.id.equals(expenseId)))
        .write(const DeletedExpensesCompanion(isSynced: Value(true)));
  }

  Future<void> markDeleteSynced(String expenseId) => _markDeleteSynced(expenseId);

  Future<List<ExpenseModel>> pullFromFirestore({
    required String userId,
    required DateTime lastSyncTime,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('lastModified', isGreaterThan: lastSyncTime.millisecondsSinceEpoch)
        .get();

    return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc.data())).toList();
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
