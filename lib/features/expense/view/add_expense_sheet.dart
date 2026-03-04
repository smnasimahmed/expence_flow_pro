import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/expense_controller.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_widgets.dart';

class AddExpenseSheet extends StatelessWidget {
  const AddExpenseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpenseController>(
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
                _sheetHandle(),
                const SizedBox(height: 16),
                const AppText(
                  AppStrings.addExpense,
                  size: 18,
                  weight: FontWeight.w700,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  hint: AppStrings.title,
                  controller: controller.titleController,
                  validator: (v) =>
                      v == null || v.isEmpty ? AppStrings.pleaseEnterTitle : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  hint: AppStrings.amount,
                  controller: controller.amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.grey),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.pleaseEnterAmount;
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _categoryPicker(controller),
                const SizedBox(height: 14),
                _walletPicker(controller),
                const SizedBox(height: 14),
                _datePicker(context, controller),
                const SizedBox(height: 14),
                AppTextField(
                  hint: AppStrings.notes,
                  controller: controller.notesController,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: AppStrings.addExpense,
                  isLoading: controller.isLoading,
                  onPressed: controller.addExpense,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        height: 4,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _categoryPicker(ExpenseController controller) {
    final categories = [
      ('food', '🍔', 'Food'),
      ('transport', '🚗', 'Transport'),
      ('shopping', '🛍', 'Shopping'),
      ('health', '💊', 'Health'),
      ('entertainment', '🎮', 'Fun'),
      ('bills', '🧾', 'Bills'),
      ('other', '📦', 'Other'),
    ];

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (id, emoji, name) = categories[i];
          final isSelected = controller.selectedCategoryId == id;

          return GestureDetector(
            onTap: () => controller.setCategory(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primary)
                    : null,
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  AppText(
                    name,
                    size: 12,
                    color: isSelected ? AppColors.white : AppColors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _walletPicker(ExpenseController controller) {
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
          value: controller.selectedWalletId.isEmpty
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
              .map(
                (w) => DropdownMenuItem(
                  value: w.id,
                  child: AppText(w.name),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) controller.setWallet(id);
          },
        );
      },
    );
  }

  Widget _datePicker(BuildContext context, ExpenseController controller) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: controller.selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) controller.setDate(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.grey, size: 18),
            const SizedBox(width: 12),
            AppText(
              DateFormat('MMMM dd, yyyy').format(controller.selectedDate),
              size: 14,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
