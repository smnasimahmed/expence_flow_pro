import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import 'package:expence_flow_pro/features/auth/view/sign_in_page.dart';
import 'package:expence_flow_pro/features/auth/controller/auth_controller.dart';
import 'package:expence_flow_pro/features/auth/binding/auth_binding.dart';

import '../helpers/test_helpers.dart';
import '../helpers/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    setupGetX();
    mockRepository = MockAuthRepository();
    when(mockRepository.signIn(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => null);
  });

  tearDown(teardownGetX);

  Widget buildSignInPage() {
    Get.put(AuthController(repository: mockRepository));
    return const GetMaterialApp(home: SignInPage());
  }

  // ─── Rendering ────────────────────────────────────────────────────────────

  group('SignInPage rendering', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('renders Forgot Password link', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('renders Remember Me checkbox', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  // ─── Validation ───────────────────────────────────────────────────────────

  group('SignInPage validation', () {
    testWidgets('shows error when email is empty and Sign In is tapped', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Validation error text should appear
      expect(find.textContaining('email'), findsWidgets);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.textContaining('password'), findsWidgets);
    });
  });

  // ─── Interactions ─────────────────────────────────────────────────────────

  group('SignInPage interactions', () {
    testWidgets('tapping Remember Me toggles the checkbox', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      final controller = Get.find<AuthController>();
      expect(controller.rememberMe, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(controller.rememberMe, isTrue);
    });

    testWidgets('tapping password visibility icon shows/hides password', (tester) async {
      await tester.pumpWidget(buildSignInPage());

      final controller = Get.find<AuthController>();
      expect(controller.isPasswordVisible, isFalse);

      // Find and tap the visibility icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(controller.isPasswordVisible, isTrue);
    });
  });
}
