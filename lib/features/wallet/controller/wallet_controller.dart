import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repository/wallet_repository.dart';
import '../model/wallet_model.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';

class WalletController extends GetxController {
  final WalletRepository _repository;

  WalletController({required WalletRepository repository})
    : _repository = repository;

  // ─── State ────────────────────────────────────────────────────────────────
  List<WalletModel> wallets = [];
  bool isLoading = false;

  // ─── Form ─────────────────────────────────────────────────────────────────
  final nameController = TextEditingController();
  final initialBalanceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  WalletType selectedType = WalletType.cash;
  String selectedColor = '#6C63FF';

  // ─── Calculated ───────────────────────────────────────────────────────────

  // Total across all wallets – shown on dashboard
  double get totalBalance => wallets.fold(0, (sum, w) => sum + w.balance);

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadWallets() async {
    isLoading = true;
    update();

    try {
      wallets = await _repository.getWallets(StorageService.userId);

      // Calculate live balance for each wallet
      for (var i = 0; i < wallets.length; i++) {
        wallets[i].balance = await _repository.calculateBalance(wallets[i].id);
      }
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  Future<void> addWallet() async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    update();

    try {
      final wallet = WalletModel.create(
        userId: StorageService.userId,
        name: nameController.text.trim(),
        type: selectedType,
        initialBalance: double.tryParse(initialBalanceController.text) ?? 0,
        color: selectedColor,
      );

      await _repository.saveLocally(wallet);
      wallet.balance = wallet.initialBalance;
      wallets.add(wallet);

      _clearForm();
      Get.back();
      Get.snackbar('Done', 'Wallet created ✓');
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteWallet(String walletId) async {
    // Only delete if no transactions attached
    final wallet = wallets.firstWhereOrNull((w) => w.id == walletId);
    if (wallet == null) return;

    if (wallet.balance != wallet.initialBalance) {
      Get.snackbar(
        'Cannot Delete',
        'Remove all transactions in this wallet first',
      );
      return;
    }

    await _repository.softDelete(walletId);
    wallets.removeWhere((w) => w.id == walletId);
    update();
  }

  void setType(WalletType type) {
    selectedType = type;
    update();
  }

  void setColor(String color) {
    selectedColor = color;
    update();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    loadWallets();
    super.onInit();
  }

  @override
  void onClose() {
    nameController.dispose();
    initialBalanceController.dispose();
    super.onClose();
  }

  void _clearForm() {
    nameController.clear();
    initialBalanceController.clear();
    selectedType = WalletType.cash;
    selectedColor = '#6C63FF';
  }
}
