import 'package:get/get.dart';
import '../../../core/services/storage/storage_service.dart';

// Currency symbols map — used app-wide to format amounts
const Map<String, String> currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'BDT': '৳',
  'INR': '₹',
  'JPY': '¥',
};

class SettingsController extends GetxController {
  String currency = StorageService.currency;

  // The symbol that matches the selected currency — e.g. '$', '৳'
  String get symbol => currencySymbols[currency] ?? currency;

  void setCurrency(String value) {
    currency = value;
    StorageService.currency = value;
    update(); // rebuilds every GetBuilder<SettingsController> in the app
  }
}
