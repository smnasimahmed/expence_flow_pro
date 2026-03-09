import 'package:get/get.dart';
import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/log/app_log.dart';
import '../../../../core/constants/app_strings.dart';
import '../../budget/controller/budget_controller.dart';
import '../../expense/controller/expense_controller.dart';
import '../../expense/repository/expense_repository.dart';
import '../../recurring/controller/recurring_controller.dart';
import '../../transfer/repository/transfer_repository.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../wallet/repository/wallet_repository.dart';

// SyncController coordinates all offline -> online data push/pull.
// Runs automatically when connectivity is restored.
class SyncController extends GetxController {
  final ExpenseRepository _expenseRepo;
  final WalletRepository _walletRepo;
  final BudgetRepository _budgetRepo;
  final RecurringRepository _recurringRepo;
  final TransferRepository _transferRepo;

  SyncController({
    required ExpenseRepository expenseRepo,
    required WalletRepository walletRepo,
    required BudgetRepository budgetRepo,
    required RecurringRepository recurringRepo,
    required TransferRepository transferRepo,
  }) : _expenseRepo = expenseRepo,
       _walletRepo = walletRepo,
       _budgetRepo = budgetRepo,
       _recurringRepo = recurringRepo,
       _transferRepo = transferRepo;

  bool isSyncing = false;

  // ─── Start watching connectivity ──────────────────────────────────────────

  @override
  void onInit() {
    _listenToConnectivity();
    super.onInit();
  }

  void _listenToConnectivity() {
    ConnectivityService.onConnectivityChange.listen((isOnline) {
      if (isOnline) {
        appLog('Back online -> starting sync', source: 'SyncController');
        syncAll();
      }
    });
  }

  // ─── Main sync method ─────────────────────────────────────────────────────

  Future<void> syncAll() async {
    final isOnline = await ConnectivityService.isOnline;
    if (!isOnline || isSyncing) return;

    isSyncing = true;
    update();

    try {
      final userId = StorageService.userId;
      if (userId.isEmpty) return;

      Get.snackbar(AppStrings.syncing, '', duration: const Duration(seconds: 1));

      // Push all offline changes (adds, edits, deletes, transfers) in parallel
      await Future.wait([
        _pushExpenses(userId),
        _pushDeletedExpenses(userId),
        _pushWallets(userId),
        _pushDeletedWallets(userId),
        _pushBudgets(userId),
        _pushRecurrings(userId),
        _pushTransfers(userId),
      ]);

      // Pull latest data from Firestore
      await Future.wait([
        _pullExpenses(userId),
        _pullWallets(userId),
        _pullTransfers(userId),
      ]);

      StorageService.lastSyncTime = DateTime.now();

      appLog('Sync complete', source: 'SyncController');
      Get.snackbar(AppStrings.syncDone, '');

      // Refresh UI after sync
      _refreshControllers();
    } catch (e) {
      errorLog(e, source: 'SyncController');
    } finally {
      isSyncing = false;
      update();
    }
  }

  // ─── Push active records ──────────────────────────────────────────────────

  Future<void> _pushExpenses(String userId) async {
    final unsynced = await _expenseRepo.getUnsynced(userId);
    for (final expense in unsynced) {
      await _expenseRepo.pushToFirestore(expense);
      await _expenseRepo.markSynced(expense.id);
    }
    appLog('Pushed ${unsynced.length} expenses', source: 'SyncController');
  }

  Future<void> _pushWallets(String userId) async {
    final unsynced = await _walletRepo.getUnsynced(userId);
    for (final wallet in unsynced) {
      await _walletRepo.pushToFirestore(wallet);
      await _walletRepo.markSynced(wallet.id);
    }
    appLog('Pushed ${unsynced.length} wallets', source: 'SyncController');
  }

  Future<void> _pushBudgets(String userId) async {
    final unsynced = await _budgetRepo.getUnsynced(userId);
    for (final budget in unsynced) {
      await _budgetRepo.pushToFirestore(budget);
    }
  }

  Future<void> _pushRecurrings(String userId) async {
    final unsynced = await _recurringRepo.getUnsynced(userId);
    for (final r in unsynced) {
      await _recurringRepo.pushToFirestore(r);
    }
  }

  Future<void> _pushTransfers(String userId) async {
    final unsynced = await _transferRepo.getUnsynced(userId);
    for (final transfer in unsynced) {
      await _transferRepo.pushToFirestore(transfer);
      await _transferRepo.markSynced(transfer.id);
    }
    appLog('Pushed ${unsynced.length} transfers', source: 'SyncController');
  }

  // ─── Push tombstone (deleted) records ────────────────────────────────────

  Future<void> _pushDeletedExpenses(String userId) async {
    final deletedRows = await _expenseRepo.getUnsyncedDeleted(userId);
    for (final row in deletedRows) {
      await _expenseRepo.pushDeletedToFirestore(row);
      await _expenseRepo.markDeleteSynced(row.id);
    }
    appLog('Pushed ${deletedRows.length} deleted expenses', source: 'SyncController');
  }

  Future<void> _pushDeletedWallets(String userId) async {
    final deletedRows = await _walletRepo.getUnsyncedDeleted(userId);
    for (final row in deletedRows) {
      await _walletRepo.pushDeletedToFirestore(row);
      await _walletRepo.markDeleteSynced(row.id);
    }
    appLog('Pushed ${deletedRows.length} deleted wallets', source: 'SyncController');
  }

  // ─── Pull from Firestore ──────────────────────────────────────────────────

  Future<void> _pullExpenses(String userId) async {
    final lastSync = StorageService.lastSyncTime ?? DateTime(2000);

    final remoteExpenses = await _expenseRepo.pullFromFirestore(
      userId: userId,
      lastSyncTime: lastSync,
    );

    for (final remote in remoteExpenses) {
      await _expenseRepo.saveLocally(remote);
    }

    appLog('Pulled ${remoteExpenses.length} expenses', source: 'SyncController');
  }

  Future<void> _pullWallets(String userId) async {
    final lastSync = StorageService.lastSyncTime ?? DateTime(2000);

    final remoteWallets = await _walletRepo.pullFromFirestore(
      userId: userId,
      lastSyncTime: lastSync,
    );

    for (final wallet in remoteWallets) {
      await _walletRepo.saveLocally(wallet);
    }

    appLog('Pulled ${remoteWallets.length} wallets', source: 'SyncController');
  }

  Future<void> _pullTransfers(String userId) async {
    final lastSync = StorageService.lastSyncTime ?? DateTime(2000);

    final remoteTransfers = await _transferRepo.pullFromFirestore(
      userId: userId,
      lastSyncTime: lastSync,
    );

    for (final transfer in remoteTransfers) {
      await _transferRepo.saveLocally(transfer);
    }

    appLog('Pulled ${remoteTransfers.length} transfers', source: 'SyncController');
  }

  // ─── Refresh UI controllers after sync ───────────────────────────────────

  void _refreshControllers() {
    if (Get.isRegistered<ExpenseController>()) {
      Get.find<ExpenseController>().loadExpenses(refresh: true);
    }
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().loadWallets();
    }
  }
}
