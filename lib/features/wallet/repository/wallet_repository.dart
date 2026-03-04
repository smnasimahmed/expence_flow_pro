import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../core/services/log/app_log.dart';
import '../model/wallet_model.dart';

class WalletRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  WalletRepository({
    required AppDatabase db,
    required FirebaseFirestore firestore,
  }) : _db = db,
       _firestore = firestore;

  // ─── Local ────────────────────────────────────────────────────────────────

  Future<void> saveLocally(WalletModel wallet) async {
    await _db.into(_db.wallets).insertOnConflictUpdate(
      WalletsCompanion(
        id: Value(wallet.id),
        userId: Value(wallet.userId),
        name: Value(wallet.name),
        type: Value(wallet.type.name),
        initialBalance: Value(wallet.initialBalance),
        color: Value(wallet.color),
        isSynced: Value(wallet.isSynced),
        isDeleted: Value(wallet.isDeleted),
        lastModified: Value(wallet.lastModified),
      ),
    );
    appLog('Wallet saved locally: ${wallet.name}', source: 'WalletRepo');
  }

  Future<List<WalletModel>> getWallets(String userId) async {
    final rows = await (_db.select(_db.wallets)
          ..where((w) => w.userId.equals(userId) & w.isDeleted.equals(false)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Balance = initialBalance + income - expenses
  // This calculates the real balance by reading all expense rows
  Future<double> calculateBalance(String walletId) async {
    final rows = await (_db.select(_db.expenses)
          ..where(
            (e) => e.walletId.equals(walletId) & e.isDeleted.equals(false),
          ))
        .get();

    final wallet = await (_db.select(_db.wallets)
          ..where((w) => w.id.equals(walletId)))
        .getSingleOrNull();

    if (wallet == null) return 0;

    // Income categories add to balance, expense categories subtract
    // For simplicity: negative amounts = expense, positive = income
    final totalExpenses = rows.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    return wallet.initialBalance - totalExpenses;
  }

  Future<void> softDelete(String walletId) async {
    await (_db.update(_db.wallets)..where((w) => w.id.equals(walletId))).write(
      WalletsCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now()),
      ),
    );
  }

  Future<List<WalletModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.wallets)
          ..where(
            (w) => w.userId.equals(userId) & w.isSynced.equals(false),
          ))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<void> markSynced(String walletId) async {
    await (_db.update(_db.wallets)..where((w) => w.id.equals(walletId))).write(
      const WalletsCompanion(isSynced: Value(true)),
    );
  }

  // ─── Remote ───────────────────────────────────────────────────────────────

  Future<void> pushToFirestore(WalletModel wallet) async {
    await _firestore
        .collection('users')
        .doc(wallet.userId)
        .collection('wallets')
        .doc(wallet.id)
        .set(wallet.toFirestore());
  }

  Future<List<WalletModel>> pullFromFirestore({
    required String userId,
    required DateTime lastSyncTime,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .where(
          'lastModified',
          isGreaterThan: lastSyncTime.millisecondsSinceEpoch,
        )
        .get();

    return snapshot.docs
        .map((doc) => WalletModel.fromFirestore(doc.data()))
        .toList();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  WalletModel _rowToModel(Wallet row) {
    return WalletModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: WalletType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => WalletType.cash,
      ),
      initialBalance: row.initialBalance,
      color: row.color,
      isSynced: row.isSynced,
      isDeleted: row.isDeleted,
      lastModified: row.lastModified,
    );
  }
}
