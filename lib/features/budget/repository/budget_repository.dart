import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../model/budget_model.dart';
import '../../../core/services/log/app_log.dart';

class BudgetRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  BudgetRepository({
    required AppDatabase db,
    required FirebaseFirestore firestore,
  }) : _db = db,
       _firestore = firestore;

  Future<void> saveLocally(BudgetModel budget) async {
    await _db.into(_db.budgets).insertOnConflictUpdate(
      BudgetsCompanion(
        id: Value(budget.id),
        userId: Value(budget.userId),
        categoryId: Value(budget.categoryId),
        amount: Value(budget.amount),
        month: Value(budget.month),
        year: Value(budget.year),
        isSynced: Value(budget.isSynced),
        lastModified: Value(budget.lastModified),
      ),
    );
    appLog('Budget saved locally', source: 'BudgetRepo');
  }

  Future<List<BudgetModel>> getBudgetsForMonth(
    String userId,
    int month,
    int year,
  ) async {
    final rows = await (_db.select(_db.budgets)
          ..where(
            (b) =>
                b.userId.equals(userId) &
                b.month.equals(month) &
                b.year.equals(year),
          ))
        .get();

    return rows
        .map(
          (row) => BudgetModel(
            id: row.id,
            userId: row.userId,
            categoryId: row.categoryId,
            amount: row.amount,
            month: row.month,
            year: row.year,
            isSynced: row.isSynced,
            lastModified: row.lastModified,
          ),
        )
        .toList();
  }

  Future<List<BudgetModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.budgets)
          ..where(
            (b) => b.userId.equals(userId) & b.isSynced.equals(false),
          ))
        .get();
    return rows
        .map(
          (row) => BudgetModel(
            id: row.id,
            userId: row.userId,
            categoryId: row.categoryId,
            amount: row.amount,
            month: row.month,
            year: row.year,
            isSynced: row.isSynced,
            lastModified: row.lastModified,
          ),
        )
        .toList();
  }

  Future<void> pushToFirestore(BudgetModel budget) async {
    await _firestore
        .collection('users')
        .doc(budget.userId)
        .collection('budgets')
        .doc(budget.id)
        .set(budget.toFirestore());
  }
}
