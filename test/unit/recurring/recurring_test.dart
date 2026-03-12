import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import 'package:expence_flow_pro/features/recurring/controller/recurring_controller.dart';
import 'package:expence_flow_pro/features/recurring/model/recurring_model.dart';
import 'package:expence_flow_pro/features/expense/model/expense_model.dart';
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  // ─── RecurringModel ────────────────────────────────────────────────────────

  group('RecurringModel', () {
    group('nextAfterExecution', () {
      test('daily: advances by 1 day', () {
        final base = DateTime(2024, 6, 15);
        final r = makeRecurring(
          frequency: RecurringFrequency.daily,
          nextExecutionDate: base,
        );
        expect(r.nextAfterExecution, equals(DateTime(2024, 6, 16)));
      });

      test('weekly: advances by 7 days', () {
        final base = DateTime(2024, 6, 15);
        final r = makeRecurring(
          frequency: RecurringFrequency.weekly,
          nextExecutionDate: base,
        );
        expect(r.nextAfterExecution, equals(DateTime(2024, 6, 22)));
      });

      test('monthly: advances to same day next month', () {
        final base = DateTime(2024, 6, 15);
        final r = makeRecurring(
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: base,
        );
        expect(r.nextAfterExecution, equals(DateTime(2024, 7, 15)));
      });

      test('monthly: advances across year boundary (December -> January)', () {
        final base = DateTime(2024, 12, 10);
        final r = makeRecurring(
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: base,
        );
        expect(r.nextAfterExecution, equals(DateTime(2025, 1, 10)));
      });

      test('yearly: advances by exactly 1 year', () {
        final base = DateTime(2024, 3, 1);
        final r = makeRecurring(
          frequency: RecurringFrequency.yearly,
          nextExecutionDate: base,
        );
        expect(r.nextAfterExecution, equals(DateTime(2025, 3, 1)));
      });
    });

    group('toFirestore / fromFirestore', () {
      test('round-trips correctly', () {
        final original = makeRecurring(
          id: 'r1',
          userId: 'u1',
          title: 'Netflix',
          amount: 15.0,
          frequency: RecurringFrequency.monthly,
        );

        final map = original.toFirestore();
        final restored = RecurringModel.fromFirestore(map);

        expect(restored.id, equals(original.id));
        expect(restored.title, equals(original.title));
        expect(restored.amount, equals(original.amount));
        expect(restored.frequency, equals(original.frequency));
        expect(restored.isActive, equals(original.isActive));
        expect(restored.isSynced, isTrue);
      });

      test('frequency stored and restored as string name', () {
        for (final freq in RecurringFrequency.values) {
          final r = makeRecurring(frequency: freq);
          final map = r.toFirestore();
          expect(map['frequency'], equals(freq.name));
          final restored = RecurringModel.fromFirestore(map);
          expect(restored.frequency, equals(freq));
        }
      });

      test('falls back to monthly for unknown frequency string', () {
        final map = makeRecurring().toFirestore();
        map['frequency'] = 'biweekly';
        final restored = RecurringModel.fromFirestore(map);
        expect(restored.frequency, equals(RecurringFrequency.monthly));
      });
    });
  });

  // ─── RecurringController ──────────────────────────────────────────────────

  group('RecurringController', () {
    late RecurringController controller;
    late MockRecurringRepository mockRecurringRepo;
    late MockExpenseRepository mockExpenseRepo;

    setUp(() {
      setupGetX();
      StorageService.userId = kTestUserId;
      mockRecurringRepo = MockRecurringRepository();
      mockExpenseRepo = MockExpenseRepository();

      // Stub getDue + getAll for onInit's runRecurringEngine()
      when(mockRecurringRepo.getDue(any)).thenAnswer((_) async => []);
      when(mockRecurringRepo.getAll(any)).thenAnswer((_) async => []);

      controller = RecurringController(
        repository: mockRecurringRepo,
        expenseRepository: mockExpenseRepo,
      );
      Get.put(controller);
    });

    tearDown(teardownGetX);

    group('runRecurringEngine', () {
      test('creates an expense for each due recurring', () async {
        final dueItems = [
          makeRecurring(title: 'Netflix', amount: 15),
          makeRecurring(title: 'Spotify', amount: 10),
        ];

        when(mockRecurringRepo.getDue(kTestUserId))
            .thenAnswer((_) async => dueItems);
        when(mockExpenseRepo.saveLocally(any)).thenAnswer((_) async {});
        when(mockRecurringRepo.updateNextExecutionDate(any, any))
            .thenAnswer((_) async {});
        when(mockRecurringRepo.getAll(any)).thenAnswer((_) async => []);

        await controller.runRecurringEngine();

        verify(mockExpenseRepo.saveLocally(any)).called(2);
        verify(mockRecurringRepo.updateNextExecutionDate(any, any)).called(2);
      });

      test('auto-created expense has correct title and amount', () async {
        final due = makeRecurring(title: 'Gym', amount: 45.0, categoryId: 'health');
        when(mockRecurringRepo.getDue(kTestUserId))
            .thenAnswer((_) async => [due]);
        when(mockExpenseRepo.saveLocally(any)).thenAnswer((_) async {});
        when(mockRecurringRepo.updateNextExecutionDate(any, any))
            .thenAnswer((_) async {});
        when(mockRecurringRepo.getAll(any)).thenAnswer((_) async => []);

        await controller.runRecurringEngine();

        final captured = verify(mockExpenseRepo.saveLocally(captureAny)).captured;
        final expense = captured.first as ExpenseModel;
        expect(expense.title, equals('Gym'));
        expect(expense.amount, equals(45.0));
        expect(expense.categoryId, equals('health'));
      });

      test('advances nextExecutionDate to correct value for monthly recurring', () async {
        final base = DateTime(2024, 6, 1);
        final due = makeRecurring(
          id: 'r1',
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: base,
        );

        when(mockRecurringRepo.getDue(kTestUserId))
            .thenAnswer((_) async => [due]);
        when(mockExpenseRepo.saveLocally(any)).thenAnswer((_) async {});
        when(mockRecurringRepo.getAll(any)).thenAnswer((_) async => []);

        DateTime? capturedDate;
        when(mockRecurringRepo.updateNextExecutionDate(any, any))
            .thenAnswer((inv) async {
          capturedDate = inv.positionalArguments[1] as DateTime;
        });

        await controller.runRecurringEngine();

        expect(capturedDate, equals(DateTime(2024, 7, 1)));
      });

      test('does nothing when no recurrings are due', () async {
        when(mockRecurringRepo.getDue(kTestUserId))
            .thenAnswer((_) async => []);
        when(mockRecurringRepo.getAll(any)).thenAnswer((_) async => []);

        await controller.runRecurringEngine();

        verifyNever(mockExpenseRepo.saveLocally(any));
        verifyNever(mockRecurringRepo.updateNextExecutionDate(any, any));
      });
    });

    group('setFrequency', () {
      test('updates selectedFrequency', () {
        controller.setFrequency(RecurringFrequency.weekly);
        expect(controller.selectedFrequency, equals(RecurringFrequency.weekly));
      });
    });
  });
}
