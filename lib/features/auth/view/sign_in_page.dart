import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../routes/app_routes.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: controller.signInFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    _header(),
                    const SizedBox(height: 40),
                    _emailField(controller),
                    const SizedBox(height: 16),
                    _passwordField(controller),
                    const SizedBox(height: 12),
                    _rememberMeRow(controller),
                    const SizedBox(height: 8),
                    _forgotPassword(),
                    const SizedBox(height: 32),
                    AppButton(
                      label: AppStrings.signIn,
                      isLoading: controller.isLoading,
                      onPressed: controller.signIn,
                    ),
                    const SizedBox(height: 24),
                    _signUpLink(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AppText('Welcome back 👋', size: 28, weight: FontWeight.w700),
        SizedBox(height: 8),
        AppText(
          'Sign in to continue tracking your expenses',
          size: 14,
          color: AppColors.grey,
        ),
      ],
    );
  }

  Widget _emailField(AuthController controller) {
    return AppTextField(
      hint: AppStrings.email,
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.grey),
      validator: (value) {
        if (value == null || value.isEmpty) return AppStrings.pleaseEnterEmail;
        if (!value.contains('@') || !value.contains('.')) {
          return AppStrings.pleaseEnterValidEmail;
        }
        return null;
      },
    );
  }

  Widget _passwordField(AuthController controller) {
    return AppTextField(
      hint: AppStrings.password,
      controller: controller.passwordController,
      isPassword: true,
      isPasswordVisible: controller.isPasswordVisible,
      onTogglePassword: controller.togglePasswordVisibility,
      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grey),
      validator: (value) {
        if (value == null || value.isEmpty) return AppStrings.pleaseEnterPassword;
        return null;
      },
    );
  }

  Widget _rememberMeRow(AuthController controller) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: controller.rememberMe,
            onChanged: (_) => controller.toggleRememberMe(),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        const AppText(AppStrings.rememberMe, size: 13, color: AppColors.grey),
      ],
    );
  }

  Widget _forgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.forgotPassword),
        child: const AppText(
          AppStrings.forgotPassword,
          size: 13,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _signUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppText(
          AppStrings.dontHaveAccount,
          size: 13,
          color: AppColors.grey,
        ),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.signUp),
          child: const AppText(
            AppStrings.signUp,
            size: 13,
            color: AppColors.primary,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
