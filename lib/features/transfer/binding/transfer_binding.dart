import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controller/transfer_controller.dart';
import '../repository/transfer_repository.dart';
import '../../../database/app_database.dart';

class TransferBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true keeps these alive so the sheet can always find them on re-open
    Get.put(
      TransferRepository(db: Get.find<AppDatabase>(), firestore: FirebaseFirestore.instance),
      permanent: true,
    );

    Get.put(
      TransferController(repository: Get.find<TransferRepository>()),
      permanent: true,
    );
  }
}
