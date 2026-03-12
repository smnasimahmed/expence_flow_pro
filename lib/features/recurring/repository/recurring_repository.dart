import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../model/recurring_model.dart';

class RecurringRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  RecurringRepository({
    required AppDatabase db,
    required FirebaseFirestore firestore,
  }) : _db = db,
       _firestore = firestore;

  Future<void> saveLocally(RecurringModel recurring) async {
    await _db.into(_db.recurrings).insertOnConflictUpdate(
      RecurringsCompanion(
        id: Value(recurring.id),
        userId: Value(recurring.userId),
        title: Value(recurring.title),
        amount: Value(recurring.amount),
        walletId: Value(recurring.walletId),
        categoryId: Value(recurring.categoryId),
        frequency: Value(recurring.frequency.name),
        nextExecutionDate: Value(recurring.nextExecutionDate),
        isActive: Value(recurring.isActive),
        isSynced: Value(recurring.isSynced),
        lastModified: Value(recurring.lastModified),
      ),
    );
  }

  Future<List<RecurringModel>> getAll(String userId) async {
    final rows = await (_db.select(_db.recurrings)
          ..where((r) => r.userId.equals(userId) & r.isActive.equals(true)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Recurrings due today or earlier
  Future<List<RecurringModel>> getDue(String userId) async {
    final rows = await (_db.select(_db.recurrings)
          ..where(
            (r) =>
                r.userId.equals(userId) &
                r.isActive.equals(true) &
                r.nextExecutionDate.isSmallerOrEqualValue(DateTime.now()),
          ))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<void> updateNextExecutionDate(
    String id,
    DateTime nextDate,
  ) async {
    await (_db.update(_db.recurrings)..where((r) => r.id.equals(id))).write(
      RecurringsCompanion(
        nextExecutionDate: Value(nextDate),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now()),
      ),
    );
  }

  Future<List<RecurringModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.recurrings)
          ..where(
            (r) => r.userId.equals(userId) & r.isSynced.equals(false),
          ))
        .get();
    return rows.map(_rowToModel).toList();
  }

  Future<void> pushToFirestore(RecurringModel r) async {
    await _firestore
        .collection('users')
        .doc(r.userId)
        .collection('recurring')
        .doc(r.id)
        .set(r.toFirestore());
  }

  RecurringModel _rowToModel(Recurring row) => RecurringModel(
    id: row.id,
    userId: row.userId,
    title: row.title,
    amount: row.amount,
    walletId: row.walletId,
    categoryId: row.categoryId,
    frequency: RecurringFrequency.values.firstWhere(
      (e) => e.name == row.frequency,
      orElse: () => RecurringFrequency.monthly,
    ),
    nextExecutionDate: row.nextExecutionDate,
    isActive: row.isActive,
    isSynced: row.isSynced,
    lastModified: row.lastModified,
  );
}
