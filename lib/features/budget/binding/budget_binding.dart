import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controller/budget_controller.dart';
import '../../expense/repository/expense_repository.dart';
import '../../../database/app_database.dart';

class BudgetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BudgetRepository(
      db: Get.find<AppDatabase>(),
      firestore: FirebaseFirestore.instance,
    ));

    Get.lazyPut(() => ExpenseRepository(
      db: Get.find<AppDatabase>(),
      firestore: FirebaseFirestore.instance,
    ));

    Get.lazyPut(() => BudgetController(
      repository: Get.find<BudgetRepository>(),
      expenseRepository: Get.find<ExpenseRepository>(),
    ));
  }
}