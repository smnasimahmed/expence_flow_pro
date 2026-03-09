import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../expense/controller/expense_controller.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../expense/model/expense_model.dart';
import '../../transfer/view/transfer_sheet.dart';
import '../../settings/controller/settings_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            Get.find<ExpenseController>().loadExpenses(refresh: true);
            Get.find<WalletController>().loadWallets();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _topBar()),
              SliverToBoxAdapter(child: _balanceCard()),
              SliverToBoxAdapter(child: _quickActions(context)),
              SliverToBoxAdapter(child: _recentHeader()),
              _expenseList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Hi, ${StorageService.userName.split(' ').first}', size: 22, weight: FontWeight.w700),
              const AppText("Here's your summary", size: 13, color: AppColors.grey),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.settings),
            child: const CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              radius: 20,
              child: Icon(Icons.settings_outlined, color: AppColors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    // Listen to both WalletController (balance amount) and SettingsController (currency symbol)
    return GetBuilder<SettingsController>(
      builder: (settings) {
        return GetBuilder<WalletController>(
          builder: (wallets) {
            return Container(
              margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Total Balance', size: 13, color: Colors.white70),
                  const SizedBox(height: 8),
                  wallets.isLoading
                      ? const ShimmerBox(height: 36, width: 160)
                      : AppText(
                          '${settings.symbol}${wallets.totalBalance.toStringAsFixed(2)}',
                          size: 32,
                          weight: FontWeight.w700,
                        ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final wallet in wallets.wallets.take(3))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AppText(wallet.name, size: 11, color: AppColors.white),
                        ),
                      if (wallets.wallets.length > 3)
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.wallets),
                          child: const AppText('+ more', size: 11, color: Colors.white70),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          _actionChip(icon: Icons.account_balance_wallet_outlined, label: 'Wallets', onTap: () => Get.toNamed(AppRoutes.wallets)),
          const SizedBox(width: 10),
          _actionChip(icon: Icons.swap_horiz, label: 'Transfer', onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const TransferSheet(),
          )),
          const SizedBox(width: 10),
          // Budget replaces Analytics here — analytics is accessible via the bottom nav tab
          _actionChip(icon: Icons.pie_chart_outline, label: 'Budget', onTap: () => Get.toNamed(AppRoutes.budget)),
          const SizedBox(width: 10),
          _actionChip(icon: Icons.repeat, label: 'Recurring', onTap: () => Get.toNamed(AppRoutes.recurring)),
        ],
      ),
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 4),
              AppText(label, size: 10, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: SectionHeader(
        title: 'Recent Expenses',
        actionLabel: 'See All',
        onAction: () => Get.toNamed(AppRoutes.allExpenses),
      ),
    );
  }

  Widget _expenseList() {
    return GetBuilder<ExpenseController>(
      builder: (controller) {
        if (controller.isLoading) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _ExpenseLoadingTile(),
              childCount: 5,
            ),
          );
        }

        if (controller.expenses.isEmpty) {
          return const SliverToBoxAdapter(child: _EmptyExpenses());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i == controller.expenses.length - 1 && controller.hasMore) {
                controller.loadExpenses();
              }
              return ExpenseTile(expense: controller.expenses[i]);
            },
            childCount: controller.expenses.length,
          ),
        );
      },
    );
  }
}

// ─── Expense Tile ─────────────────────────────────────────────────────────────

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.red.withAlpha(51),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      onDismissed: (_) => Get.find<ExpenseController>().deleteExpense(expense.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _categoryIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(expense.title, size: 14, weight: FontWeight.w500, maxLines: 1),
                  AppText(DateFormat('MMM dd, yyyy').format(expense.date), size: 12, color: AppColors.grey, top: 2),
                ],
              ),
            ),
            // Currency symbol from SettingsController
            GetBuilder<SettingsController>(
              builder: (settings) => AppText(
                '-${settings.symbol}${expense.amount.toStringAsFixed(2)}',
                size: 15,
                weight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryIcon() {
    final categoryIcons = {
      'food': ('🍔', AppColors.food),
      'transport': ('🚗', AppColors.transport),
      'shopping': ('🛍', AppColors.shopping),
      'health': ('💊', AppColors.health),
      'entertainment': ('🎮', AppColors.entertainment),
      'bills': ('🧾', AppColors.bills),
      'salary': ('💰', AppColors.salary),
      'other': ('📦', AppColors.other),
    };

    final info = categoryIcons[expense.categoryId] ?? ('📦', AppColors.other);

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: info.$2.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(info.$1, style: const TextStyle(fontSize: 20))),
    );
  }
}

// ─── Loading Tile ─────────────────────────────────────────────────────────────

class _ExpenseLoadingTile extends StatelessWidget {
  const _ExpenseLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          ShimmerBox(height: 44, width: 44, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, width: 120),
                SizedBox(height: 8),
                ShimmerBox(height: 12, width: 80),
              ],
            ),
          ),
          ShimmerBox(height: 16, width: 60),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text('💸', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          AppText('No expenses yet', size: 16, weight: FontWeight.w500, color: AppColors.grey),
          SizedBox(height: 8),
          AppText('Tap + to add your first expense', size: 13, color: AppColors.grey, align: TextAlign.center),
        ],
      ),
    );
  }
}
