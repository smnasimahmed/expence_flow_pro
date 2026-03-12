import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:expence_flow_pro/features/expense/controller/expense_controller.dart';
import 'package:expence_flow_pro/features/expense/model/expense_model.dart';
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  late ExpenseController controller;
  late MockExpenseRepository mockRepository;

  setUp(() {
    setupGetX();
    StorageService.userId = kTestUserId;
    mockRepository = MockExpenseRepository();

    // Default stub so onInit's loadExpenses() doesn't throw
    when(mockRepository.getExpenses(
      userId: anyNamed('userId'),
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
    )).thenAnswer((_) async => []);

    controller = ExpenseController(repository: mockRepository);
    Get.put(controller);
  });

  tearDown(teardownGetX);

  // ─── loadExpenses ─────────────────────────────────────────────────────────

  group('loadExpenses', () {
    test('populates expenses list on success', () async {
      final expenses = [makeExpense(), makeExpense()];
      when(mockRepository.getExpenses(
        userId: kTestUserId,
        limit: 20,
        offset: 0,
      )).thenAnswer((_) async => expenses);

      await controller.loadExpenses(refresh: true);

      expect(controller.expenses.length, equals(2));
    });

    test('sets hasMore=true when full page is returned', () async {
      final fullPage = List.generate(20, (_) => makeExpense());
      when(mockRepository.getExpenses(
        userId: anyNamed('userId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => fullPage);

      await controller.loadExpenses(refresh: true);

      expect(controller.hasMore, isTrue);
    });

    test('sets hasMore=false when partial page is returned', () async {
      final partial = List.generate(5, (_) => makeExpense());
      when(mockRepository.getExpenses(
        userId: anyNamed('userId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => partial);

      await controller.loadExpenses(refresh: true);

      expect(controller.hasMore, isFalse);
    });

    test('refresh=true resets page counter and clears list', () async {
      controller.expenses = [makeExpense(), makeExpense()];

      when(mockRepository.getExpenses(
        userId: anyNamed('userId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => [makeExpense()]);

      await controller.loadExpenses(refresh: true);

      expect(controller.expenses.length, equals(1));
    });

    test('sets isLoading=false after repository error', () async {
      when(mockRepository.getExpenses(
        userId: anyNamed('userId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenThrow(Exception('DB error'));

      await controller.loadExpenses(refresh: true);

      expect(controller.isLoading, isFalse);
    });

    test('does not load more when hasMore is false', () async {
      controller.hasMore = false;

      await controller.loadExpenses();

      // repository should only be called from onInit, not this call
      verifyNever(mockRepository.getExpenses(
        userId: anyNamed('userId'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      ));
    });
  });

  // ─── filteredExpenses ─────────────────────────────────────────────────────

  group('filteredExpenses', () {
    setUp(() {
      controller.expenses = [
        makeExpense(title: 'Coffee', categoryId: 'food'),
        makeExpense(title: 'Uber', categoryId: 'transport'),
        makeExpense(title: 'Pizza', categoryId: 'food'),
      ];
    });

    test('returns all expenses when no filter is applied', () {
      expect(controller.filteredExpenses.length, equals(3));
    });

    test('filters by search query (case-insensitive)', () {
      controller.setSearch('coffee');
      expect(controller.filteredExpenses.length, equals(1));
      expect(controller.filteredExpenses.first.title, equals('Coffee'));
    });

    test('filters by category', () {
      controller.setFilterCategory('food');
      expect(controller.filteredExpenses.length, equals(2));
      expect(controller.filteredExpenses.every((e) => e.categoryId == 'food'), isTrue);
    });

    test('search + category filters combine with AND logic', () {
      controller.setSearch('pizza');
      controller.setFilterCategory('food');
      expect(controller.filteredExpenses.length, equals(1));
      expect(controller.filteredExpenses.first.title, equals('Pizza'));
    });

    test('returns empty list when search matches nothing', () {
      controller.setSearch('xyzzy');
      expect(controller.filteredExpenses, isEmpty);
    });

    test('returns empty list when category matches nothing', () {
      controller.setFilterCategory('entertainment');
      expect(controller.filteredExpenses, isEmpty);
    });
  });

  // ─── fillFormForEdit ──────────────────────────────────────────────────────

  group('fillFormForEdit', () {
    test('populates all form fields from the given expense', () {
      final expense = makeExpense(
        title: 'Gym',
        amount: 45.0,
        categoryId: 'health',
        walletId: 'w1',
        notes: 'monthly fee',
      );

      controller.fillFormForEdit(expense);

      expect(controller.titleController.text, equals('Gym'));
      expect(controller.amountController.text, equals('45.0'));
      expect(controller.notesController.text, equals('monthly fee'));
      expect(controller.selectedCategoryId, equals('health'));
      expect(controller.selectedWalletId, equals('w1'));
    });

    test('sets notesController to empty string when notes is null', () {
      final expense = makeExpense(notes: null);
      controller.fillFormForEdit(expense);
      expect(controller.notesController.text, equals(''));
    });
  });

  // ─── deleteExpense ────────────────────────────────────────────────────────

  group('deleteExpense', () {
    test('removes expense from list immediately (optimistic)', () async {
      final expense = makeExpense(id: 'e1');
      controller.expenses = [expense];

      when(mockRepository.hardDelete(any)).thenAnswer((_) async {});

      await controller.deleteExpense('e1');

      expect(controller.expenses, isEmpty);
    });

    test('does nothing when expense id is not found', () async {
      controller.expenses = [makeExpense(id: 'e1')];

      await controller.deleteExpense('nonexistent');

      expect(controller.expenses.length, equals(1));
      verifyNever(mockRepository.hardDelete(any));
    });

    test('calls repository.hardDelete with the correct expense', () async {
      final expense = makeExpense(id: 'e_target');
      controller.expenses = [expense];
      when(mockRepository.hardDelete(any)).thenAnswer((_) async {});

      await controller.deleteExpense('e_target');

      final captured = verify(mockRepository.hardDelete(captureAny)).captured;
      expect((captured.first as ExpenseModel).id, equals('e_target'));
    });
  });

  // ─── setters ──────────────────────────────────────────────────────────────

  group('setCategory / setWallet / setDate', () {
    test('setCategory updates selectedCategoryId', () {
      controller.setCategory('transport');
      expect(controller.selectedCategoryId, equals('transport'));
    });

    test('setWallet updates selectedWalletId', () {
      controller.setWallet('wallet_xyz');
      expect(controller.selectedWalletId, equals('wallet_xyz'));
    });

    test('setDate updates selectedDate', () {
      final date = DateTime(2024, 12, 25);
      controller.setDate(date);
      expect(controller.selectedDate, equals(date));
    });
  });
}
