import 'package:get/get.dart';
import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/log/app_log.dart';
import '../../../../core/constants/app_strings.dart';
import '../../budget/controller/budget_controller.dart';
import '../../expense/repository/expense_repository.dart';
import '../../recurring/controller/recurring_controller.dart';
import '../../wallet/repository/wallet_repository.dart';

// SyncController is the "brain" that coordinates all push/pull operations.
// It runs automatically when connectivity returns.
class SyncController extends GetxController {
  final ExpenseRepository _expenseRepo;
  final WalletRepository _walletRepo;
  final BudgetRepository _budgetRepo;
  final RecurringRepository _recurringRepo;

  SyncController({
    required ExpenseRepository expenseRepo,
    required WalletRepository walletRepo,
    required BudgetRepository budgetRepo,
    required RecurringRepository recurringRepo,
  }) : _expenseRepo = expenseRepo,
       _walletRepo = walletRepo,
       _budgetRepo = budgetRepo,
       _recurringRepo = recurringRepo;

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

      await Future.wait([
        _pushExpenses(userId),
        _pushWallets(userId),
        _pushBudgets(userId),
        _pushRecurrings(userId),
      ]);

      await Future.wait([
        _pullExpenses(userId),
        _pullWallets(userId),
      ]);

      // Record sync time
      StorageService.lastSyncTime = DateTime.now();

      appLog('Sync complete', source: 'SyncController');
      Get.snackbar(AppStrings.syncDone, '');
    } catch (e) {
      errorLog(e, source: 'SyncController');
    } finally {
      isSyncing = false;
      update();
    }
  }

  // ─── Push (local -> Firestore) ─────────────────────────────────────────────

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

  // ─── Pull (Firestore -> local) ─────────────────────────────────────────────
  // Conflict resolution: latest lastModified wins

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
}
