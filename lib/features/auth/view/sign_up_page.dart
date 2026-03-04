import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_widgets.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const AppText(AppStrings.signUp, size: 18, weight: FontWeight.w600),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: controller.signUpFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const AppText(
                      'Create your account',
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      'Start tracking your money today',
                      size: 14,
                      color: AppColors.grey,
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      hint: 'Full Name',
                      controller: controller.nameController,
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.grey),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      hint: AppStrings.email,
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.grey),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.pleaseEnterEmail;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return AppStrings.pleaseEnterValidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      hint: AppStrings.password,
                      controller: controller.passwordController,
                      isPassword: true,
                      isPasswordVisible: controller.isPasswordVisible,
                      onTogglePassword: controller.togglePasswordVisibility,
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grey),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.pleaseEnterPassword;
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Create Account',
                      isLoading: controller.isLoading,
                      onPressed: controller.signUp,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppText(
                          AppStrings.alreadyHaveAccount,
                          size: 13,
                          color: AppColors.grey,
                        ),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: const AppText(
                            AppStrings.signIn,
                            size: 13,
                            color: AppColors.primary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
