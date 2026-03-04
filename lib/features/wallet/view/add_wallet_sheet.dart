import 'package:expence_flow_pro/core/constants/app_strings.dart';
import 'package:expence_flow_pro/core/constants/app_theme.dart';
import 'package:expence_flow_pro/core/widgets/app_widgets.dart';
import 'package:expence_flow_pro/features/wallet/controller/wallet_controller.dart';
import 'package:expence_flow_pro/features/wallet/model/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddWalletSheet extends StatelessWidget {
  const AddWalletSheet({super.key});

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
