import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_model.dart';
import '../../transfer/view/transfer_sheet.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Wallets', size: 18, weight: FontWeight.w600),
        actions: [
          // Quick link to transfer history
          TextButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.transferHistory),
            icon: const Icon(Icons.history, size: 18, color: AppColors.primary),
            label: const AppText('History', size: 13, color: AppColors.primary),
          ),
        ],
      ),
      body: GetBuilder<WalletController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.wallets.isEmpty) {
            return const Center(
              child: AppText('No wallets yet. Create one!', color: AppColors.grey),
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
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const TransferSheet(),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.swap_horiz, color: AppColors.white),
        label: const AppText('Transfer', color: AppColors.white),
      ),
    );
  }
}

// ─── Wallet Card ──────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final WalletModel wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(wallet.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        // Ask for confirmation before deleting a wallet
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const AppText('Delete Wallet', size: 16, weight: FontWeight.w600),
            content: AppText('Delete "${wallet.name}"? This cannot be undone.', size: 14, color: AppColors.grey),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Delete', style: TextStyle(color: AppColors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => Get.find<WalletController>().deleteWallet(wallet.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      child: Container(
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
        color: AppColors.primary.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icons[wallet.type] ?? Icons.wallet, color: AppColors.primary),
    );
  }
}
