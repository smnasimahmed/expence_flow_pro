import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repository/transfer_repository.dart';
import '../model/transfer_model.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/services/connectivity/connectivity_service.dart';

class TransferController extends GetxController {
  final TransferRepository _repository;

  TransferController({required TransferRepository repository})
      : _repository = repository;

  // ─── State ────────────────────────────────────────────────────────────────
  List<TransferModel> transfers = [];
  bool isLoading = false;

  // ─── Form fields (no formKey here — sheet owns its own key) ───────────────
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  String fromWalletId = '';
  String toWalletId = '';

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadTransfers() async {
    isLoading = true;
    update();

    try {
      final walletController = Get.find<WalletController>();
      transfers = await _repository.getTransfers(StorageService.userId);

      for (final t in transfers) {
        final from = walletController.wallets.firstWhereOrNull((w) => w.id == t.fromWalletId);
        final to = walletController.wallets.firstWhereOrNull((w) => w.id == t.toWalletId);
        t.fromWalletName = from?.name ?? 'Deleted Wallet';
        t.toWalletName = to?.name ?? 'Deleted Wallet';
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load transfer history');
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Transfer — formKey passed in from the sheet ──────────────────────────

  Future<void> doTransfer(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    if (fromWalletId.isEmpty || toWalletId.isEmpty) {
      Get.snackbar('Select Wallets', 'Please choose both wallets');
      return;
    }

    if (fromWalletId == toWalletId) {
      Get.snackbar('Same Wallet', 'From and To wallets must be different');
      return;
    }

    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar('Invalid Amount', 'Amount must be greater than 0');
      return;
    }

    isLoading = true;
    update();

    try {
      final transfer = TransferModel.create(
        userId: StorageService.userId,
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      await _repository.saveLocally(transfer);

      final isOnline = await ConnectivityService.isOnline;
      if (isOnline) {
        await _repository.pushToFirestore(transfer);
        await _repository.markSynced(transfer.id);
      }

      await Get.find<WalletController>().loadWallets();

      // Reload history so the list updates immediately after sheet closes
      await loadTransfers();

      _clearForm();
      Get.back();
      Get.snackbar('Done', 'Transfer complete ✓');
    } catch (e) {
      Get.snackbar('Error', 'Transfer failed. Try again.');
    } finally {
      isLoading = false;
      update();
    }
  }

  void setFromWallet(String id) { fromWalletId = id; update(); }
  void setToWallet(String id) { toWalletId = id; update(); }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    loadTransfers();
    super.onInit();
  }

  @override
  void onClose() {
    amountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Called every time the sheet opens so the form always starts fresh
  void resetForm() {
    amountController.clear();
    notesController.clear();
    fromWalletId = '';
    toWalletId = '';
    update();
  }

  void _clearForm() {
    amountController.clear();
    notesController.clear();
    fromWalletId = '';
    toWalletId = '';
  }
}
