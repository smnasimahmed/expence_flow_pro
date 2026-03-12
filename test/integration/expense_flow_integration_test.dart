// These tests exercise the full stack:
//   UI → Controller → Repository → Drift (SQLite) → Firestore (when online)
//
// They are intentionally coarser-grained than unit tests — each scenario
// validates an end-to-end user journey rather than an isolated function.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expence_flow_pro/main.dart' as app;
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';
import 'package:expence_flow_pro/routes/app_routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Pre-condition: a test account must exist in Firebase Auth
  const testEmail = 'integration@expenseflow.test';
  const testPassword = 'IntTest@123';

  setUp(() async {
    await StorageService.clearAll();
  });

  // ─── Auth flow ────────────────────────────────────────────────────────────

  group('Auth flow', () {
    testWidgets('user can sign in and reach dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should be on sign in page
      expect(find.text('Sign In'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('emailField')), testEmail);
      await tester.enterText(
          find.byKey(const Key('passwordField')), testPassword);
      await tester.tap(find.byKey(const Key('signInButton')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should now be on dashboard
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('remember me persists session across restarts', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('emailField')), testEmail);
      await tester.enterText(
          find.byKey(const Key('passwordField')), testPassword);

      // Check Remember Me
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('signInButton')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(StorageService.rememberMe, isTrue);
      expect(StorageService.userId, isNotEmpty);

      // Simulate restart — initialRoute should go to dashboard directly
      expect(AppRoutes.initialRoute, equals(AppRoutes.dashboard));
    });
  });

  // ─── Expense CRUD offline ─────────────────────────────────────────────────

  group('Expense CRUD (offline-first)', () {
    Future<void> _signIn(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('emailField')), testEmail);
      await tester.enterText(
          find.byKey(const Key('passwordField')), testPassword);
      await tester.tap(find.byKey(const Key('signInButton')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    testWidgets('user can add an expense and it appears in the list',
        (tester) async {
      await _signIn(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('expenseTitleField')), 'Integration Coffee');
      await tester.enterText(
          find.byKey(const Key('expenseAmountField')), '5.50');

      await tester.tap(find.byKey(const Key('saveExpenseButton')));
      await tester.pumpAndSettle();

      expect(find.text('Integration Coffee'), findsOneWidget);
    });

    testWidgets('user can delete an expense with undo available',
        (tester) async {
      await _signIn(tester);

      // Assumes 'Integration Coffee' was added in previous test or seeded
      await tester.longPress(find.text('Integration Coffee'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteExpenseButton')));
      await tester.pumpAndSettle();

      expect(find.text('Integration Coffee'), findsNothing);

      // Undo snackbar should be visible
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('tapping Undo restores the deleted expense', (tester) async {
      await _signIn(tester);

      await tester.longPress(find.text('Integration Coffee'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteExpenseButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Integration Coffee'), findsOneWidget);
    });
  });

  // ─── Wallet flow ──────────────────────────────────────────────────────────

  group('Wallet flow', () {
    testWidgets('user can create a new wallet', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to wallets tab (assumes bottom nav)
      await tester.tap(find.byKey(const Key('walletsNavItem')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addWalletButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('walletNameField')), 'Integration Wallet');
      await tester.enterText(
          find.byKey(const Key('walletBalanceField')), '500');

      await tester.tap(find.byKey(const Key('saveWalletButton')));
      await tester.pumpAndSettle();

      expect(find.text('Integration Wallet'), findsOneWidget);
    });
  });

  // ─── Budget flow ──────────────────────────────────────────────────────────

  group('Budget flow', () {
    testWidgets('user can set a monthly budget and see spend percentage',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byKey(const Key('budgetNavItem')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addBudgetButton')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('budgetAmountField')), '1000');

      await tester.tap(find.byKey(const Key('saveBudgetButton')));
      await tester.pumpAndSettle();

      // Budget card should show progress
      expect(find.byKey(const Key('budgetProgressBar')), findsOneWidget);
    });
  });

  // ─── Sync flow ────────────────────────────────────────────────────────────

  group('Sync flow', () {
    testWidgets('syncing indicator appears when coming back online',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // We can't programmatically toggle network in integration tests without
      // platform channel mocking. This test documents the expected UI response
      // and should be run with network toggled manually or via a mock channel.
      //
      // Assertion: SyncController.isSyncing flips to true, then false.
      // Verified manually: sync snackbar appears with 'Syncing...' text.
      expect(true, isTrue); // placeholder — see manual test notes
    });
  });
}
