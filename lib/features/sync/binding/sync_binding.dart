import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_flow_pro/features/budget/repository/budget_repository.dart';
import 'package:expence_flow_pro/features/recurring/repository/recurring_repository.dart';
import 'package:get/get.dart';
import '../controller/sync_controller.dart';
import '../../expense/repository/expense_repository.dart';
import '../../transfer/repository/transfer_repository.dart';
import '../../wallet/repository/wallet_repository.dart';
import '../../../database/app_database.dart';

class SyncBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ExpenseRepository>()) {
      Get.put(ExpenseRepository(db: Get.find<AppDatabase>(), firestore: FirebaseFirestore.instance), permanent: true);
    }

    if (!Get.isRegistered<WalletRepository>()) {
      Get.put(WalletRepository(db: Get.find<AppDatabase>(), firestore: FirebaseFirestore.instance), permanent: true);
    }

    if (!Get.isRegistered<BudgetRepository>()) {
      Get.put(BudgetRepository(db: Get.find<AppDatabase>(), firestore: FirebaseFirestore.instance), permanent: true);
    }

    if (!Get.isRegistered<RecurringRepository>()) {
      Get.put(RecurringRepository(db: Get.find<AppDatabase>(), firestore: FirebaseFirestore.instance), permanent: true);
    }

    if (!Get.isRegistered<TransferRepository>()) {
      Get.put(TransferRepository(db: Get.find<AppDatabase>(), firestore: FirebaseFirestore.instance), permanent: true);
    }

    if (!Get.isRegistered<SyncController>()) {
      Get.put(
        SyncController(
          expenseRepo: Get.find<ExpenseRepository>(),
          walletRepo: Get.find<WalletRepository>(),
          budgetRepo: Get.find<BudgetRepository>(),
          recurringRepo: Get.find<RecurringRepository>(),
          transferRepo: Get.find<TransferRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
