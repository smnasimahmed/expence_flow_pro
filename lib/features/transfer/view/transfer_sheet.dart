import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/transfer_controller.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class TransferSheet extends StatefulWidget {
  const TransferSheet({super.key});

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  // Fresh key every open — avoids GlobalKey conflict on reopen
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Controller stays alive (permanent), so reset its form state on every open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<TransferController>().resetForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: GetBuilder<TransferController>(
        builder: (controller) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const AppText('Transfer Money', size: 18, weight: FontWeight.w700),
                const SizedBox(height: 20),

                _walletDropdown(
                  label: 'From Wallet',
                  selectedId: controller.fromWalletId,
                  onChanged: controller.setFromWallet,
                  excludeId: controller.toWalletId,
                ),
                const SizedBox(height: 12),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      final temp = controller.fromWalletId;
                      controller.setFromWallet(controller.toWalletId);
                      controller.setToWallet(temp);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_vert, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _walletDropdown(
                  label: 'To Wallet',
                  selectedId: controller.toWalletId,
                  onChanged: controller.setToWallet,
                  excludeId: controller.fromWalletId,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: controller.amountController,
                  hint: 'Amount',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AppTextField(
                  controller: controller.notesController,
                  hint: 'Notes (optional)',
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Transfer',
                    isLoading: controller.isLoading,
                    onPressed: () => controller.doTransfer(_formKey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _walletDropdown({
    required String label,
    required String selectedId,
    required Function(String) onChanged,
    required String excludeId,
  }) {
    final wallets = Get.find<WalletController>().wallets
        .where((w) => w.id != excludeId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, size: 12, color: AppColors.grey, bottom: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId.isEmpty ? null : selectedId,
              hint: const AppText('Select wallet', size: 14, color: AppColors.grey),
              isExpanded: true,
              dropdownColor: AppColors.surface,
              items: wallets.map((w) => DropdownMenuItem(
                value: w.id,
                child: Row(
                  children: [
                    AppText(w.name, size: 14),
                    const Spacer(),
                    AppText('\$${w.balance.toStringAsFixed(2)}', size: 12, color: AppColors.grey),
                  ],
                ),
              )).toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }
}
