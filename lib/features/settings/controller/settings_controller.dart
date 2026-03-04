// ─── Small controller just for settings state ─────────────────────────────────

import 'package:expence_flow_pro/core/services/storage/storage_service.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  String currency = StorageService.currency;

  void setCurrency(String value) {
    currency = value;
    StorageService.currency = value;
    update();
  }
}
