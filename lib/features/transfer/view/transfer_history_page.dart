import 'package:expence_flow_pro/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/transfer_controller.dart';
import '../model/transfer_model.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import 'transfer_sheet.dart';

class TransferHistoryPage extends StatelessWidget {
  const TransferHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Transfers', size: 18, weight: FontWeight.w600),
      ),
      body: GetBuilder<TransferController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.transfers.isEmpty) {
            return const _EmptyTransfers();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: controller.transfers.length,
            itemBuilder: (_, i) => _TransferTile(transfer: controller.transfers[i]),
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
        label: const AppText(AppStrings.newTransfer, color: AppColors.white),
      ),
    );
  }
}

// ─── Transfer Tile ────────────────────────────────────────────────────────────

class _TransferTile extends StatelessWidget {
  final TransferModel transfer;
  const _TransferTile({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Transfer icon
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          // From → To wallet names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppText(transfer.fromWalletName, size: 13, weight: FontWeight.w600, maxLines: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 14, color: AppColors.grey),
                    ),
                    Flexible(
                      child: AppText(transfer.toWalletName, size: 13, weight: FontWeight.w600, maxLines: 1),
                    ),
                  ],
                ),
                AppText(
                  DateFormat('MMM dd, yyyy').format(transfer.date),
                  size: 12,
                  color: AppColors.grey,
                  top: 3,
                ),
                if (transfer.notes != null)
                  AppText(transfer.notes!, size: 11, color: AppColors.grey, top: 2, maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppText(
            '\$${transfer.amount.toStringAsFixed(2)}',
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyTransfers extends StatelessWidget {
  const _EmptyTransfers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💸', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          AppText('No transfers yet', size: 16, weight: FontWeight.w500, color: AppColors.grey),
          SizedBox(height: 8),
          AppText('Tap + to move money between wallets', size: 13, color: AppColors.grey),
        ],
      ),
    );
  }
}
