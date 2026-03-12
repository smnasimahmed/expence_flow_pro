import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import 'package:expence_flow_pro/features/budget/controller/budget_controller.dart';
import 'package:expence_flow_pro/features/budget/model/budget_model.dart';
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  // ─── BudgetModel ──────────────────────────────────────────────────────────

  group('BudgetModel', () {
    group('usagePercent', () {
      test('returns 0.0 when amount is zero (avoids divide-by-zero)', () {
        final b = makeBudget(amount: 0, spent: 100);
        expect(b.usagePercent, equals(0.0));
      });

      test('returns 0.5 when half the budget is spent', () {
        final b = makeBudget(amount: 200, spent: 100);
        expect(b.usagePercent, equals(0.5));
      });

      test('returns 1.0 when exactly at budget', () {
        final b = makeBudget(amount: 300, spent: 300);
        expect(b.usagePercent, equals(1.0));
      });

      test('returns >1.0 when budget is exceeded', () {
        final b = makeBudget(amount: 100, spent: 150);
        expect(b.usagePercent, greaterThan(1.0));
      });
    });

    group('remaining', () {
      test('returns positive value when under budget', () {
        final b = makeBudget(amount: 500, spent: 200);
        expect(b.remaining, equals(300.0));
      });

      test('returns 0 when exactly at budget', () {
        final b = makeBudget(amount: 400, spent: 400);
        expect(b.remaining, equals(0.0));
      });

      test('returns negative value when over budget', () {
        final b = makeBudget(amount: 100, spent: 120);
        expect(b.remaining, equals(-20.0));
      });
    });

    group('isWarning', () {
      test('is false below 80%', () {
        final b = makeBudget(amount: 100, spent: 79);
        expect(b.isWarning, isFalse);
      });

      test('is true at exactly 80%', () {
        final b = makeBudget(amount: 100, spent: 80);
        expect(b.isWarning, isTrue);
      });

      test('is true at 99%', () {
        final b = makeBudget(amount: 100, spent: 99);
        expect(b.isWarning, isTrue);
      });

      test('is false when exactly at 100% (that is isExceeded territory)', () {
        final b = makeBudget(amount: 100, spent: 100);
        expect(b.isWarning, isFalse);
      });
    });

    group('isExceeded', () {
      test('is false below 100%', () {
        final b = makeBudget(amount: 100, spent: 99);
        expect(b.isExceeded, isFalse);
      });

      test('is true at exactly 100%', () {
        final b = makeBudget(amount: 100, spent: 100);
        expect(b.isExceeded, isTrue);
      });

      test('is true above 100%', () {
        final b = makeBudget(amount: 100, spent: 200);
        expect(b.isExceeded, isTrue);
      });
    });

    group('create', () {
      test('categoryId defaults to null (total budget)', () {
        final b = BudgetModel.create(
          userId: kTestUserId,
          amount: 500,
          month: 6,
          year: 2024,
        );
        expect(b.categoryId, isNull);
      });

      test('accepts a specific categoryId', () {
        final b = BudgetModel.create(
          userId: kTestUserId,
          categoryId: 'food',
          amount: 300,
          month: 6,
          year: 2024,
        );
        expect(b.categoryId, equals('food'));
      });
    });

    group('toFirestore / fromFirestore', () {
      test('round-trips without loss', () {
        final original = makeBudget(
          id: 'b1',
          userId: 'u1',
          categoryId: 'food',
          amount: 400.0,
          month: 7,
          year: 2024,
        );

        final map = original.toFirestore();
        final restored = BudgetModel.fromFirestore(map);

        expect(restored.id, equals(original.id));
        expect(restored.categoryId, equals(original.categoryId));
        expect(restored.amount, equals(original.amount));
        expect(restored.month, equals(original.month));
        expect(restored.year, equals(original.year));
      });

      test('handles null categoryId (total budget)', () {
        final original = makeBudget(categoryId: null);
        final map = original.toFirestore();
        final restored = BudgetModel.fromFirestore(map);
        expect(restored.categoryId, isNull);
      });
    });
  });

  // ─── BudgetController ─────────────────────────────────────────────────────

  group('BudgetController', () {
    late BudgetController controller;
    late MockBudgetRepository mockBudgetRepo;
    late MockExpenseRepository mockExpenseRepo;

    setUp(() {
      setupGetX();
      StorageService.userId = kTestUserId;
      mockBudgetRepo = MockBudgetRepository();
      mockExpenseRepo = MockExpenseRepository();

      when(mockBudgetRepo.getBudgetsForMonth(any, any, any))
          .thenAnswer((_) async => []);
      when(mockExpenseRepo.getExpensesInRange(
        userId: anyNamed('userId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => []);

      controller = BudgetController(
        repository: mockBudgetRepo,
        expenseRepository: mockExpenseRepo,
      );
      Get.put(controller);
    });

    tearDown(teardownGetX);

    group('loadBudgets', () {
      test('calculates spent for category budgets correctly', () async {
        final budget = makeBudget(categoryId: 'food', amount: 300);

        final expenses = [
          makeExpense(categoryId: 'food', amount: 50),
          makeExpense(categoryId: 'food', amount: 75),
          makeExpense(categoryId: 'transport', amount: 100), // should be ignored
        ];

        when(mockBudgetRepo.getBudgetsForMonth(any, any, any))
            .thenAnswer((_) async => [budget]);
        when(mockExpenseRepo.getExpensesInRange(
          userId: anyNamed('userId'),
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => expenses);

        await controller.loadBudgets();

        expect(controller.budgets.first.spent, equals(125.0));
      });

      test('calculates spent for total budget (categoryId=null) across all categories', () async {
        final totalBudget = makeBudget(categoryId: null, amount: 1000);

        final expenses = [
          makeExpense(categoryId: 'food', amount: 200),
          makeExpense(categoryId: 'transport', amount: 150),
          makeExpense(categoryId: 'bills', amount: 300),
        ];

        when(mockBudgetRepo.getBudgetsForMonth(any, any, any))
            .thenAnswer((_) async => [totalBudget]);
        when(mockExpenseRepo.getExpensesInRange(
          userId: anyNamed('userId'),
          from: anyNamed('from'),
          to: anyNamed('to'),
        )).thenAnswer((_) async => expenses);

        await controller.loadBudgets();

        expect(controller.budgets.first.spent, equals(650.0));
      });

      test('sets isLoading=false on repository error', () async {
        when(mockBudgetRepo.getBudgetsForMonth(any, any, any))
            .thenThrow(Exception('DB error'));

        await controller.loadBudgets();

        expect(controller.isLoading, isFalse);
      });
    });
  });
}
