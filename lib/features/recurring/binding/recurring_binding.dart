import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_flow_pro/features/recurring/repository/recurring_repository.dart';
import 'package:get/get.dart';
import '../controller/recurring_controller.dart';
import '../../expense/repository/expense_repository.dart';
import '../../../database/app_database.dart';

class RecurringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecurringRepository(
          db: Get.find<AppDatabase>(),
          firestore: FirebaseFirestore.instance,
        ));

    Get.lazyPut(() => ExpenseRepository(
          db: Get.find<AppDatabase>(),
          firestore: FirebaseFirestore.instance,
        ));

    Get.lazyPut(() => RecurringController(
          repository: Get.find<RecurringRepository>(),
          expenseRepository: Get.find<ExpenseRepository>(),
        ));
  }
}
