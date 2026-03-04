import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repository/auth_repository.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository})
    : _repository = repository;

  // ─── Form fields ──────────────────────────────────────────────────────────
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final signInFormKey = GlobalKey<FormState>();
  final signUpFormKey = GlobalKey<FormState>();

  // ─── State ────────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool rememberMe = false;
  bool isPasswordVisible = false;

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<void> signIn() async {
    if (!signInFormKey.currentState!.validate()) return;

    isLoading = true;
    update();

    try {
      final user = await _repository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user == null) {
        Get.snackbar('Error', AppStrings.somethingWentWrong);
        return;
      }

      // Save user info locally
      StorageService.userId = user.uid;
      StorageService.userEmail = user.email ?? '';
      StorageService.userName = user.displayName ?? '';
      StorageService.rememberMe = rememberMe;

      Get.offAllNamed(AppRoutes.dashboard);
    } on Exception catch (e) {
      Get.snackbar('Sign In Failed', _readableError(e.toString()));
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  Future<void> signUp() async {
    if (!signUpFormKey.currentState!.validate()) return;

    isLoading = true;
    update();

    try {
      final user = await _repository.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user == null) {
        Get.snackbar('Error', AppStrings.somethingWentWrong);
        return;
      }

      StorageService.userId = user.uid;
      StorageService.userEmail = user.email ?? '';
      StorageService.userName = user.displayName ?? '';

      Get.offAllNamed(AppRoutes.dashboard);
    } on Exception catch (e) {
      Get.snackbar('Sign Up Failed', _readableError(e.toString()));
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Email required', 'Enter your email to reset password');
      return;
    }

    isLoading = true;
    update();

    try {
      await _repository.sendPasswordResetEmail(email);
      Get.snackbar('Email Sent', 'Check your inbox for reset instructions');
    } on Exception catch (e) {
      Get.snackbar('Error', _readableError(e.toString()));
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _repository.signOut();
    await StorageService.clearAll();
    Get.offAllNamed(AppRoutes.signIn);
  }

  // ─── Toggle helpers ───────────────────────────────────────────────────────

  void toggleRememberMe() {
    rememberMe = !rememberMe;
    update();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    update();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    // Pre-fill in debug mode
    if (kDebugMode) {
      emailController.text = 'test@expenseflow.com';
      passwordController.text = 'Test@1234';
    }
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  // Turn Firebase error codes into human-readable messages
  String _readableError(String error) {
    if (error.contains('user-not-found')) return 'No account found with this email.';
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('email-already-in-use')) return 'This email is already registered.';
    if (error.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (error.contains('invalid-email')) return 'Please enter a valid email.';
    if (error.contains('network-request-failed')) return 'No internet connection.';
    return AppStrings.somethingWentWrong;
  }
}
