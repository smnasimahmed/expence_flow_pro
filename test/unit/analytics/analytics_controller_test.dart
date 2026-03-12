import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import 'package:expence_flow_pro/features/analytics/controller/analytics_controller.dart';
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  late AnalyticsController controller;
  late MockExpenseRepository mockRepository;

  setUp(() {
    setupGetX();
    StorageService.userId = kTestUserId;
    mockRepository = MockExpenseRepository();

    when(mockRepository.getExpensesInRange(
      userId: anyNamed('userId'),
      from: anyNamed('from'),
      to: anyNamed('to'),
    )).thenAnswer((_) async => []);

    controller = AnalyticsController(repository: mockRepository);
    Get.put(controller);
  });

  tearDown(teardownGetX);

  // ─── loadAnalytics ────────────────────────────────────────────────────────

  group('loadAnalytics', () {
    test('calculates totalThisMonth correctly', () async {
      final expenses = [
        makeExpense(amount: 100),
        makeExpense(amount: 50),
        makeExpense(amount: 75),
      ];

      // Return our expenses for this-month call; empty for last-month call
      var callCount = 0;
      when(mockRepository.getExpensesInRange(
        userId: anyNamed('userId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? expenses : [];
      });

      await controller.loadAnalytics();

      expect(controller.totalThisMonth, equals(225.0));
    });

    test('builds categoryTotals correctly', () async {
      final expenses = [
        makeExpense(categoryId: 'food', amount: 100),
        makeExpense(categoryId: 'food', amount: 50),
        makeExpense(categoryId: 'transport', amount: 30),
      ];

      var callCount = 0;
      when(mockRepository.getExpensesInRange(
        userId: anyNamed('userId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? expenses : [];
      });

      await controller.loadAnalytics();

      expect(controller.categoryTotals['food'], equals(150.0));
      expect(controller.categoryTotals['transport'], equals(30.0));
    });

    test('calculates averageDailySpend based on days elapsed', () async {
      final today = DateTime.now();
      final daysElapsed = today.day;

      final total = 300.0;
      final expenses = List.generate(3, (_) => makeExpense(amount: 100));

      var callCount = 0;
      when(mockRepository.getExpensesInRange(
        userId: anyNamed('userId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? expenses : [];
      });

      await controller.loadAnalytics();

      expect(
        controller.averageDailySpend,
        closeTo(total / daysElapsed, 0.01),
      );
    });

    test('sets isLoading=false on repository error', () async {
      when(mockRepository.getExpensesInRange(
        userId: anyNamed('userId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenThrow(Exception('DB error'));

      await controller.loadAnalytics();

      expect(controller.isLoading, isFalse);
    });
  });

  // ─── computed properties ──────────────────────────────────────────────────

  group('monthlyChange', () {
    test('returns 0 when totalLastMonth is 0 (avoids divide-by-zero)', () {
      controller.totalLastMonth = 0;
      controller.totalThisMonth = 500;
      expect(controller.monthlyChange, equals(0.0));
    });

    test('returns 50.0 for a 50% increase', () {
      controller.totalLastMonth = 200;
      controller.totalThisMonth = 300;
      expect(controller.monthlyChange, equals(50.0));
    });

    test('returns -25.0 for a 25% decrease', () {
      controller.totalLastMonth = 400;
      controller.totalThisMonth = 300;
      expect(controller.monthlyChange, equals(-25.0));
    });

    test('returns 0 when spending is identical month-over-month', () {
      controller.totalLastMonth = 300;
      controller.totalThisMonth = 300;
      expect(controller.monthlyChange, equals(0.0));
    });
  });

  group('spentMoreThisMonth', () {
    test('returns true when this month > last month', () {
      controller.totalThisMonth = 600;
      controller.totalLastMonth = 400;
      expect(controller.spentMoreThisMonth, isTrue);
    });

    test('returns false when this month < last month', () {
      controller.totalThisMonth = 300;
      controller.totalLastMonth = 400;
      expect(controller.spentMoreThisMonth, isFalse);
    });

    test('returns false when equal', () {
      controller.totalThisMonth = 400;
      controller.totalLastMonth = 400;
      expect(controller.spentMoreThisMonth, isFalse);
    });
  });

  group('topCategory', () {
    test('returns "none" when categoryTotals is empty', () {
      controller.categoryTotals = {};
      expect(controller.topCategory, equals('none'));
    });

    test('returns the category with the highest total', () {
      controller.categoryTotals = {
        'food': 300.0,
        'transport': 100.0,
        'bills': 250.0,
      };
      expect(controller.topCategory, equals('food'));
    });

    test('returns single category when only one exists', () {
      controller.categoryTotals = {'health': 150.0};
      expect(controller.topCategory, equals('health'));
    });
  });
}
