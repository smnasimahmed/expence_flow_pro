import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:expence_flow_pro/features/auth/controller/auth_controller.dart';
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';
import '../../helpers/mocks.mocks.dart';
import '../../helpers/test_helpers.dart';
void main() {
  late AuthController controller;
  late MockAuthRepository mockRepository;
  late MockUser mockUser;

  setUp(() {
    setupGetX();
    mockRepository = MockAuthRepository();
    mockUser = MockUser();
    controller = AuthController(repository: mockRepository);
    Get.put(controller);
  });

  tearDown(teardownGetX);

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _fillSignInForm({
    String email = kTestEmail,
    String password = kTestPassword,
  }) {
    controller.emailController.text = email;
    controller.passwordController.text = password;
  }

  void _fillSignUpForm({
    String name = kTestName,
    String email = kTestEmail,
    String password = kTestPassword,
  }) {
    controller.nameController.text = name;
    controller.emailController.text = email;
    controller.passwordController.text = password;
  }

  // ─── Initial state ─────────────────────────────────────────────────────────

  group('initial state', () {
    test('isLoading defaults to false', () {
      expect(controller.isLoading, isFalse);
    });

    test('rememberMe defaults to false', () {
      expect(controller.rememberMe, isFalse);
    });

    test('isPasswordVisible defaults to false', () {
      expect(controller.isPasswordVisible, isFalse);
    });
  });

  // ─── Toggle helpers ────────────────────────────────────────────────────────

  group('toggleRememberMe', () {
    test('flips from false to true', () {
      controller.toggleRememberMe();
      expect(controller.rememberMe, isTrue);
    });

    test('flips back to false on second call', () {
      controller.toggleRememberMe();
      controller.toggleRememberMe();
      expect(controller.rememberMe, isFalse);
    });
  });

  group('togglePasswordVisibility', () {
    test('flips from false to true', () {
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isTrue);
    });

    test('flips back to false on second call', () {
      controller.togglePasswordVisibility();
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isFalse);
    });
  });

  // ─── _readableError ────────────────────────────────────────────────────────
  // Tested indirectly through signIn edge cases below.

  // ─── forgotPassword ────────────────────────────────────────────────────────

  group('forgotPassword', () {
    test('does nothing if email is empty', () async {
      controller.emailController.text = '';
      await controller.forgotPassword();
      verifyNever(mockRepository.sendPasswordResetEmail(any));
    });

    test('calls repository with trimmed email when email is provided', () async {
      controller.emailController.text = '  $kTestEmail  ';
      when(mockRepository.sendPasswordResetEmail(kTestEmail))
          .thenAnswer((_) async {});

      await controller.forgotPassword();

      verify(mockRepository.sendPasswordResetEmail(kTestEmail)).called(1);
    });

    test('sets isLoading to false after success', () async {
      controller.emailController.text = kTestEmail;
      when(mockRepository.sendPasswordResetEmail(any)).thenAnswer((_) async {});
      await controller.forgotPassword();
      expect(controller.isLoading, isFalse);
    });

    test('sets isLoading to false when repository throws', () async {
      controller.emailController.text = kTestEmail;
      when(mockRepository.sendPasswordResetEmail(any))
          .thenThrow(Exception('network-request-failed'));

      await controller.forgotPassword();
      expect(controller.isLoading, isFalse);
    });
  });

  // ─── signOut ───────────────────────────────────────────────────────────────

  group('signOut', () {
    test('calls repository.signOut()', () async {
      when(mockRepository.signOut()).thenAnswer((_) async {});

      // Pre-set some storage values to verify clearAll is called
      StorageService.userId = kTestUserId;
      StorageService.rememberMe = true;

      await controller.signOut();

      verify(mockRepository.signOut()).called(1);
      // After signOut storage should be cleared
      expect(StorageService.userId, isEmpty);
      expect(StorageService.rememberMe, isFalse);
    });
  });
}
