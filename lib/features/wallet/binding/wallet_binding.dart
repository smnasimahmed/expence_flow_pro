import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controller/wallet_controller.dart';
import '../repository/wallet_repository.dart';
import '../../../database/app_database.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WalletRepository(
      db: Get.find<AppDatabase>(),
      firestore: FirebaseFirestore.instance,
    ));

    Get.lazyPut(() => WalletController(
      repository: Get.find<WalletRepository>(),
    ));
  }
}
