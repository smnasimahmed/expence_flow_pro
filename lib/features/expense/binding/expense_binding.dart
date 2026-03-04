import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controller/expense_controller.dart';
import '../repository/expense_repository.dart';
import '../../../database/app_database.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExpenseRepository(
      db: Get.find<AppDatabase>(),
      firestore: FirebaseFirestore.instance,
    ));

    Get.lazyPut(() => ExpenseController(
      repository: Get.find<ExpenseRepository>(),
    ));
  }
}
