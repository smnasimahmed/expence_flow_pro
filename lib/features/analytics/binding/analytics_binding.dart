import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controller/analytics_controller.dart';
import '../../expense/repository/expense_repository.dart';
import '../../../database/app_database.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ExpenseRepository(
      db: Get.find<AppDatabase>(),
      firestore: FirebaseFirestore.instance,
    ));

    Get.lazyPut(() => AnalyticsController(
      repository: Get.find<ExpenseRepository>(),
    ));
  }
}
