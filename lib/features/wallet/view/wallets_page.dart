import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_model.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_widgets.dart';

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('Wallets', size: 18, weight: FontWeight.w600)),
      body: GetBuilder<WalletController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.wallets.isEmpty) {
            return const Center(
              child: AppText(
                'No wallets yet. Create one!',
                color: AppColors.grey,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: controller.wallets.length,
            itemBuilder: (_, i) => _WalletCard(wallet: controller.wallets[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddWallet(context),
        backgroundColor: AppColors.primary,
        label: const AppText('Add Wallet', color: AppColors.white),
        icon: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _openAddWallet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddWalletSheet(),
    );
  }
}

// ─── Wallet Card ──────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final WalletModel wallet;

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          _walletIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(wallet.name, size: 15, weight: FontWeight.w600),
                AppText(wallet.typeLabel, size: 12, color: AppColors.grey, top: 2),
              ],
            ),
          ),
          AppText(
            '\$${wallet.balance.toStringAsFixed(2)}',
            size: 16,
            weight: FontWeight.w700,
            color: wallet.balance >= 0 ? AppColors.green : AppColors.red,
          ),
        ],
      ),
    );
  }

  Widget _walletIcon() {
    final icons = {
      WalletType.cash: Icons.money,
      WalletType.bank: Icons.account_balance,
      WalletType.savings: Icons.savings,
      WalletType.custom: Icons.wallet,
    };

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icons[wallet.type] ?? Icons.wallet, color: AppColors.primary),
    );
  }
}

// ─── Add Wallet Sheet ─────────────────────────────────────────────────────────

class _AddWalletSheet extends StatelessWidget {
  const _AddWalletSheet();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      builder: (controller) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const AppText(AppStrings.addWallet, size: 18, weight: FontWeight.w700),
                const SizedBox(height: 24),
                AppTextField(
                  hint: 'Wallet Name (e.g. Main Account)',
                  controller: controller.nameController,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter wallet name' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  hint: 'Initial Balance',
                  controller: controller.initialBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.grey),
                ),
                const SizedBox(height: 14),
                _typePicker(controller),
                const SizedBox(height: 24),
                AppButton(
                  label: AppStrings.addWallet,
                  isLoading: controller.isLoading,
                  onPressed: controller.addWallet,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _typePicker(WalletController controller) {
    return Row(
      children: WalletType.values.map((type) {
        final isSelected = controller.selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.setType(type),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppText(
                type.name[0].toUpperCase() + type.name.substring(1),
                size: 12,
                align: TextAlign.center,
                color: isSelected ? AppColors.white : AppColors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
