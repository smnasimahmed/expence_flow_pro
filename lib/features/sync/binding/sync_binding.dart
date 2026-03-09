import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_flow_pro/database/app_database.dart';
import 'package:expence_flow_pro/features/budget/controller/budget_controller.dart';
import 'package:expence_flow_pro/features/expense/repository/expense_repository.dart';
import 'package:expence_flow_pro/features/recurring/controller/recurring_controller.dart';
import 'package:expence_flow_pro/features/sync/controller/sync_controller.dart';
import 'package:expence_flow_pro/features/wallet/repository/wallet_repository.dart';
import 'package:get/get.dart';

class SyncBinding extends Bindings {
  @override
  void dependencies() {

    if (!Get.isRegistered<ExpenseRepository>()) {
      Get.put(
        ExpenseRepository(
          db: Get.find<AppDatabase>(),
          firestore: FirebaseFirestore.instance,
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<WalletRepository>()) {
      Get.put(
        WalletRepository(
          db: Get.find<AppDatabase>(),
          firestore: FirebaseFirestore.instance,
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<BudgetRepository>()) {
      Get.put(
        BudgetRepository(
          db: Get.find<AppDatabase>(),
          firestore: FirebaseFirestore.instance,
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<RecurringRepository>()) {
      Get.put(
        RecurringRepository(
          db: Get.find<AppDatabase>(),
          firestore: FirebaseFirestore.instance,
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<SyncController>()) {
      Get.put(
        SyncController(
          expenseRepo: Get.find<ExpenseRepository>(),
          walletRepo: Get.find<WalletRepository>(),
          budgetRepo: Get.find<BudgetRepository>(),
          recurringRepo: Get.find<RecurringRepository>(),
        ),
        permanent: true,
      );
    }
  }
}