import 'package:expence_flow_pro/features/budget/model/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/budget_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Budget', size: 18, weight: FontWeight.w600),
      ),
      body: GetBuilder<BudgetController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.budgets.isEmpty) {
            return const Center(
              child: AppText('No budgets set yet.', color: AppColors.grey),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: controller.budgets.length,
            itemBuilder: (_, i) => _BudgetCard(budget: controller.budgets[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_budget',
        onPressed: () => _openAddBudget(context),
        backgroundColor: AppColors.primary,
        label: const AppText('Set Budget', color: AppColors.white),
        icon: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _openAddBudget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddBudgetSheet(),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                budget.categoryId ?? 'Total Budget',
                size: 15,
                weight: FontWeight.w600,
              ),
              AppText(
                '\$${budget.remaining.toStringAsFixed(2)} left',
                size: 13,
                color: budget.isExceeded ? AppColors.red : AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.usagePercent.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceLight,
              color: budget.isExceeded
                  ? AppColors.red
                  : budget.isWarning
                      ? AppColors.orange
                      : AppColors.green,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                '\$${budget.spent.toStringAsFixed(2)} spent',
                size: 12,
                color: AppColors.grey,
              ),
              AppText(
                'of \$${budget.amount.toStringAsFixed(2)}',
                size: 12,
                color: AppColors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBudgetSheet extends StatelessWidget {
  const _AddBudgetSheet();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BudgetController>(
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
                const AppText('Set Budget', size: 18, weight: FontWeight.w700),
                const SizedBox(height: 24),
                AppTextField(
                  hint: 'Amount',
                  controller: controller.amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.grey),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter budget amount' : null,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Set Budget',
                  isLoading: controller.isLoading,
                  onPressed: controller.addBudget,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}