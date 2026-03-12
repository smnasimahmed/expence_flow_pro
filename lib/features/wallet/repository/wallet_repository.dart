import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../core/services/log/app_log.dart';
import '../../../core/services/connectivity/connectivity_service.dart';
import '../model/wallet_model.dart';

class WalletRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  WalletRepository({required AppDatabase db, required FirebaseFirestore firestore})
      : _db = db, _firestore = firestore;

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

  // Save + immediately push to Firestore if device is online
  Future<void> saveAndSync(WalletModel wallet) async {
    await saveLocally(wallet);

    final isOnline = await ConnectivityService.isOnline;
    if (isOnline) {
      await pushToFirestore(wallet);
      await markSynced(wallet.id);
      appLog('Wallet instantly synced: ${wallet.id}', source: 'WalletRepo');
    }
  }

  Future<List<WalletModel>> getWallets(String userId) async {
    final rows = await (_db.select(_db.wallets)
          ..where((w) => w.userId.equals(userId) & w.isDeleted.equals(false)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Balance = initialBalance + income expenses - regular expenses - transfers out + transfers in
  Future<double> calculateBalance(String walletId) async {
    final wallet = await (_db.select(_db.wallets)..where((w) => w.id.equals(walletId)))
        .getSingleOrNull();

    if (wallet == null) return 0;

    final expenseRows = await (_db.select(_db.expenses)
          ..where((e) => e.walletId.equals(walletId) & e.isDeleted.equals(false)))
        .get();

    final totalExpenses = expenseRows.fold<double>(0, (num sum, e) => sum + e.amount);

    // Money sent out from this wallet
    final transfersOut = await (_db.select(_db.walletTransfers)
          ..where((t) => t.fromWalletId.equals(walletId)))
        .get();

    final totalOut = transfersOut.fold<double>(0, (num sum, t) => sum + t.amount);

    // Money received into this wallet
    final transfersIn = await (_db.select(_db.walletTransfers)
          ..where((t) => t.toWalletId.equals(walletId)))
        .get();

    final totalIn = transfersIn.fold<double>(0, (num sum, t) => sum + t.amount);

    return wallet.initialBalance - totalExpenses - totalOut + totalIn;
  }

  // Hard delete: remove from wallets + save to deleted_wallets tombstone
  Future<void> hardDelete(WalletModel wallet) async {
    // 1. Save to tombstone
    await _db.into(_db.deletedWallets).insertOnConflictUpdate(
      DeletedWalletsCompanion(
        id: Value(wallet.id),
        userId: Value(wallet.userId),
        name: Value(wallet.name),
        type: Value(wallet.type.name),
        initialBalance: Value(wallet.initialBalance),
        color: Value(wallet.color),
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );

    // 2. Remove from active wallets
    await (_db.delete(_db.wallets)..where((w) => w.id.equals(wallet.id))).go();

    // 3. If online, push delete to Firestore immediately
    final isOnline = await ConnectivityService.isOnline;
    if (isOnline) {
      await _pushDeleteToFirestore(wallet);
      await _markDeleteSynced(wallet.id);
    }

    appLog('Wallet hard deleted: ${wallet.id}', source: 'WalletRepo');
  }

  Future<List<WalletModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.wallets)
          ..where((w) => w.userId.equals(userId) & w.isSynced.equals(false)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<List<DeletedWallet>> getUnsyncedDeleted(String userId) async {
    return (_db.select(_db.deletedWallets)
          ..where((w) => w.userId.equals(userId) & w.isSynced.equals(false)))
        .get();
  }

  Future<void> markSynced(String walletId) async {
    await (_db.update(_db.wallets)..where((w) => w.id.equals(walletId)))
        .write(const WalletsCompanion(isSynced: Value(true)));
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

  Future<void> _pushDeleteToFirestore(WalletModel wallet) async {
    await _firestore
        .collection('users')
        .doc(wallet.userId)
        .collection('deleted_wallets')
        .doc(wallet.id)
        .set({
          ...wallet.toFirestore(),
          'deletedAt': DateTime.now().millisecondsSinceEpoch,
        });

    await _firestore
        .collection('users')
        .doc(wallet.userId)
        .collection('wallets')
        .doc(wallet.id)
        .delete();
  }

  Future<void> pushDeletedToFirestore(DeletedWallet row) async {
    await _firestore
        .collection('users')
        .doc(row.userId)
        .collection('deleted_wallets')
        .doc(row.id)
        .set({
          'id': row.id,
          'userId': row.userId,
          'name': row.name,
          'type': row.type,
          'initialBalance': row.initialBalance,
          'color': row.color,
          'deletedAt': row.deletedAt.millisecondsSinceEpoch,
        });

    await _firestore
        .collection('users')
        .doc(row.userId)
        .collection('wallets')
        .doc(row.id)
        .delete();
  }

  Future<void> _markDeleteSynced(String walletId) async {
    await (_db.update(_db.deletedWallets)..where((w) => w.id.equals(walletId)))
        .write(const DeletedWalletsCompanion(isSynced: Value(true)));
  }

  Future<void> markDeleteSynced(String walletId) => _markDeleteSynced(walletId);

  Future<List<WalletModel>> pullFromFirestore({
    required String userId,
    required DateTime lastSyncTime,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .where('lastModified', isGreaterThan: lastSyncTime.millisecondsSinceEpoch)
        .get();

    return snapshot.docs.map((doc) => WalletModel.fromFirestore(doc.data())).toList();
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
