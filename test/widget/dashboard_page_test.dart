import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import 'package:expence_flow_pro/features/expense/view/dashboard_page.dart';
import 'package:expence_flow_pro/features/expense/controller/expense_controller.dart';
import 'package:expence_flow_pro/features/wallet/controller/wallet_controller.dart';

import '../helpers/test_helpers.dart';
import '../helpers/mocks.mocks.dart';

void main() {
  late MockExpenseRepository mockExpenseRepo;
  late MockWalletRepository mockWalletRepo;
  late ExpenseController expenseController;
  late WalletController walletController;

  setUp(() {
    setupGetX();

    mockExpenseRepo = MockExpenseRepository();
    mockWalletRepo = MockWalletRepository();

    when(mockExpenseRepo.getExpenses(
      userId: anyNamed('userId'),
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
    )).thenAnswer((_) async => []);

    when(mockWalletRepo.getWallets(any)).thenAnswer((_) async => []);
    when(mockWalletRepo.calculateBalance(any)).thenAnswer((_) async => 0.0);

    expenseController = ExpenseController(repository: mockExpenseRepo);
    walletController = WalletController(repository: mockWalletRepo);

    Get.put(expenseController);
    Get.put(walletController);
  });

  tearDown(teardownGetX);

  Widget buildDashboard() {
    return const GetMaterialApp(home: DashboardPage());
  }

  // ─── Rendering ────────────────────────────────────────────────────────────

  group('DashboardPage rendering', () {
    testWidgets('renders without errors when lists are empty', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows loading indicator while expenses are loading', (tester) async {
      expenseController.isLoading = true;

      await tester.pumpWidget(buildDashboard());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows expenses list after data loads', (tester) async {
      expenseController.expenses = [
        makeExpense(title: 'Coffee', amount: 4.5),
        makeExpense(title: 'Uber', amount: 12.0),
      ];
      expenseController.isLoading = false;

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Uber'), findsOneWidget);
    });

    testWidgets('displays total wallet balance', (tester) async {
      walletController.wallets = [
        makeWallet(balance: 1000),
        makeWallet(balance: 500),
      ];

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // Total balance = 1500, formatted as currency
      expect(find.textContaining('1500'), findsOneWidget);
    });
  });

  // ─── FAB / Add Expense ────────────────────────────────────────────────────

  group('DashboardPage add expense', () {
    testWidgets('FAB is present', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('tapping FAB opens add expense sheet', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Bottom sheet should appear
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
