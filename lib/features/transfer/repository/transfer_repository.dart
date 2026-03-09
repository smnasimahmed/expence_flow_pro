import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../core/services/log/app_log.dart';
import '../model/transfer_model.dart';

class TransferRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  TransferRepository({required AppDatabase db, required FirebaseFirestore firestore})
      : _db = db, _firestore = firestore;

  // ─── Local ────────────────────────────────────────────────────────────────

  Future<void> saveLocally(TransferModel transfer) async {
    await _db.into(_db.walletTransfers).insertOnConflictUpdate(
      WalletTransfersCompanion(
        id: Value(transfer.id),
        userId: Value(transfer.userId),
        fromWalletId: Value(transfer.fromWalletId),
        toWalletId: Value(transfer.toWalletId),
        amount: Value(transfer.amount),
        notes: Value(transfer.notes),
        date: Value(transfer.date),
        isSynced: Value(transfer.isSynced),
        lastModified: Value(transfer.lastModified),
      ),
    );
    appLog('Transfer saved locally: ${transfer.id}', source: 'TransferRepo');
  }

  Future<List<TransferModel>> getTransfers(String userId) async {
    final rows = await (_db.select(_db.walletTransfers)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Transfers involving a specific wallet (for wallet detail view)
  Future<List<TransferModel>> getTransfersForWallet(String walletId) async {
    final rows = await (_db.select(_db.walletTransfers)
          ..where((t) => t.fromWalletId.equals(walletId) | t.toWalletId.equals(walletId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<List<TransferModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.walletTransfers)
          ..where((t) => t.userId.equals(userId) & t.isSynced.equals(false)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<void> markSynced(String transferId) async {
    await (_db.update(_db.walletTransfers)..where((t) => t.id.equals(transferId)))
        .write(const WalletTransfersCompanion(isSynced: Value(true)));
  }

  // ─── Remote ───────────────────────────────────────────────────────────────

  Future<void> pushToFirestore(TransferModel transfer) async {
    await _firestore
        .collection('users')
        .doc(transfer.userId)
        .collection('transfers')
        .doc(transfer.id)
        .set(transfer.toFirestore());

    appLog('Transfer pushed to Firestore: ${transfer.id}', source: 'TransferRepo');
  }

  Future<List<TransferModel>> pullFromFirestore({
    required String userId,
    required DateTime lastSyncTime,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transfers')
        .where('lastModified', isGreaterThan: lastSyncTime.millisecondsSinceEpoch)
        .get();

    return snapshot.docs.map((doc) => TransferModel.fromFirestore(doc.data())).toList();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  TransferModel _rowToModel(WalletTransfer row) {
    return TransferModel(
      id: row.id,
      userId: row.userId,
      fromWalletId: row.fromWalletId,
      toWalletId: row.toWalletId,
      amount: row.amount,
      notes: row.notes,
      date: row.date,
      isSynced: row.isSynced,
      lastModified: row.lastModified,
    );
  }
}
