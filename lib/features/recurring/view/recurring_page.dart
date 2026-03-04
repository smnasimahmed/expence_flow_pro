import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/recurring_controller.dart';
import '../model/recurring_model.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_widgets.dart';

class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Recurring', size: 18, weight: FontWeight.w600),
      ),
      body: GetBuilder<RecurringController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.recurrings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔁', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  AppText(
                    'No recurring expenses yet',
                    size: 16,
                    weight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 8),
                  AppText(
                    'Set up rent, subscriptions, and bills\nto auto-add them every cycle',
                    size: 13,
                    color: AppColors.grey,
                    align: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: controller.recurrings.length,
            itemBuilder: (_, i) =>
                _RecurringCard(recurring: controller.recurrings[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_recurring',
        onPressed: () => _openAddRecurring(context),
        backgroundColor: AppColors.primary,
        label: const AppText('Add Recurring', color: AppColors.white),
        icon: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _openAddRecurring(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddRecurringSheet(),
    );
  }
}

// ─── Recurring Card ───────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  final RecurringModel recurring;

  const _RecurringCard({required this.recurring});

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
          _frequencyIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(recurring.title, size: 15, weight: FontWeight.w600),
                AppText(
                  'Next: ${DateFormat('MMM dd, yyyy').format(recurring.nextExecutionDate)}',
                  size: 12,
                  color: AppColors.grey,
                  top: 4,
                ),
                _frequencyBadge(),
              ],
            ),
          ),
          AppText(
            '-\$${recurring.amount.toStringAsFixed(2)}',
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.red,
          ),
        ],
      ),
    );
  }

  Widget _frequencyIcon() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.repeat, color: AppColors.primary),
    );
  }

  Widget _frequencyBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText(
        recurring.frequency.name[0].toUpperCase() +
            recurring.frequency.name.substring(1),
        size: 11,
        color: AppColors.grey,
      ),
    );
  }
}

// ─── Add Recurring Sheet ──────────────────────────────────────────────────────

class _AddRecurringSheet extends StatelessWidget {
  const _AddRecurringSheet();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecurringController>(
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
                // Sheet handle
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
                const AppText(
                  'Add Recurring Expense',
                  size: 18,
                  weight: FontWeight.w700,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  hint: 'Title (e.g. Netflix, Rent)',
                  controller: controller.titleController,
                  validator: (v) =>
                      v == null || v.isEmpty ? AppStrings.pleaseEnterTitle : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  hint: AppStrings.amount,
                  controller: controller.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon:
                      const Icon(Icons.attach_money, color: AppColors.grey),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.pleaseEnterAmount;
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _walletPicker(controller),
                const SizedBox(height: 14),
                _frequencyPicker(controller),
                const SizedBox(height: 14),
                _startDatePicker(context, controller),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Add Recurring',
                  isLoading: controller.isLoading,
                  onPressed: controller.addRecurring,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _walletPicker(RecurringController controller) {
    return GetBuilder<WalletController>(
      builder: (walletController) {
        if (walletController.wallets.isEmpty) {
          return const AppText(
            'No wallets found. Create one first.',
            size: 13,
            color: AppColors.red,
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: controller.selectedWalletId.isEmpty
              ? null
              : controller.selectedWalletId,
          hint: const AppText('Select Wallet', color: AppColors.grey),
          dropdownColor: AppColors.surfaceLight,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: walletController.wallets
              .map((w) => DropdownMenuItem(
                    value: w.id,
                    child: AppText(w.name),
                  ))
              .toList(),
          onChanged: (id) {
            if (id != null) controller.selectedWalletId = id;
          },
        );
      },
    );
  }

  Widget _frequencyPicker(RecurringController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Frequency', size: 13, color: AppColors.grey),
        const SizedBox(height: 8),
        Row(
          children: RecurringFrequency.values.map((freq) {
            final isSelected = controller.selectedFrequency == freq;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.setFrequency(freq),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppText(
                    freq.name[0].toUpperCase() + freq.name.substring(1),
                    size: 11,
                    align: TextAlign.center,
                    color: isSelected ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _startDatePicker(
      BuildContext context, RecurringController controller) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: controller.selectedStartDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.selectedStartDate = picked;
          controller.update();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.grey, size: 18),
            const SizedBox(width: 12),
            AppText(
              'Starts: ${DateFormat('MMMM dd, yyyy').format(controller.selectedStartDate)}',
              size: 14,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
