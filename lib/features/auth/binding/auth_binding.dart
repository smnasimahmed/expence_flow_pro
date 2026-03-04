import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../repository/auth_repository.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      AuthRepository(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
      permanent: true,
    );

    Get.put(
      AuthController(
        repository: Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
  }
}