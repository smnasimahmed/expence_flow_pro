import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_widgets.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _header(),
                  const SizedBox(height: 40),
                  _emailField(controller),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Send Reset Email',
                    isLoading: controller.isLoading,
                    onPressed: controller.forgotPassword,
                  ),
                  const SizedBox(height: 24),
                  _backToSignIn(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🔐', style: TextStyle(fontSize: 40)),
        SizedBox(height: 16),
        AppText('Forgot Password?', size: 26, weight: FontWeight.w700),
        SizedBox(height: 8),
        AppText(
          'Enter your email and we\'ll send you a link to reset your password.',
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

  Widget _backToSignIn() {
    return Center(
      child: GestureDetector(
        onTap: () => Get.back(),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios, size: 13, color: AppColors.primary),
            SizedBox(width: 4),
            AppText('Back to Sign In', size: 13, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
