import 'package:flutter_test/flutter_test.dart';
import 'package:expence_flow_pro/features/expense/model/expense_model.dart';

import '../../helpers/test_helpers.dart';

void main() {
  // ─── ExpenseModel.create ───────────────────────────────────────────────────

  group('ExpenseModel.create', () {
    test('generates a non-empty UUID id', () {
      final e = ExpenseModel.create(
        userId: kTestUserId,
        title: 'Coffee',
        amount: 4.5,
        categoryId: 'food',
        walletId: kTestWalletId,
        date: DateTime(2024, 6, 1),
      );
      expect(e.id, isNotEmpty);
    });

    test('sets isSynced=false and isDeleted=false by default', () {
      final e = ExpenseModel.create(
        userId: kTestUserId,
        title: 'Coffee',
        amount: 4.5,
        categoryId: 'food',
        walletId: kTestWalletId,
        date: DateTime(2024, 6, 1),
      );
      expect(e.isSynced, isFalse);
      expect(e.isDeleted, isFalse);
    });

    test('notes defaults to null when not provided', () {
      final e = ExpenseModel.create(
        userId: kTestUserId,
        title: 'Uber',
        amount: 12.0,
        categoryId: 'transport',
        walletId: kTestWalletId,
        date: DateTime(2024, 6, 1),
      );
      expect(e.notes, isNull);
    });

    test('stores provided notes', () {
      final e = ExpenseModel.create(
        userId: kTestUserId,
        title: 'Dinner',
        amount: 80.0,
        categoryId: 'food',
        walletId: kTestWalletId,
        date: DateTime(2024, 6, 1),
        notes: 'Anniversary',
      );
      expect(e.notes, equals('Anniversary'));
    });
  });

  // ─── copyWith ─────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('preserves original id and userId', () {
      final original = makeExpense(id: 'fixed_id', userId: 'fixed_user');
      final copy = original.copyWith(title: 'Updated');
      expect(copy.id, equals('fixed_id'));
      expect(copy.userId, equals('fixed_user'));
    });

    test('updates only the specified fields', () {
      final original = makeExpense(amount: 100.0, categoryId: 'food');
      final copy = original.copyWith(amount: 200.0);
      expect(copy.amount, equals(200.0));
      expect(copy.categoryId, equals('food')); // unchanged
    });

    test('can mark isSynced=true', () {
      final original = makeExpense(isSynced: false);
      final copy = original.copyWith(isSynced: true);
      expect(copy.isSynced, isTrue);
    });

    test('can mark isDeleted=true', () {
      final original = makeExpense(isDeleted: false);
      final copy = original.copyWith(isDeleted: true);
      expect(copy.isDeleted, isTrue);
    });

    test('null notes can be explicitly set', () {
      final original = makeExpense(notes: 'has notes');
      final copy = original.copyWith(notes: null);
      // notes = null means unchanged (not cleared) due to null-coalesce pattern
      expect(copy.notes, equals('has notes'));
    });
  });

  // ─── toFirestore ─────────────────────────────────────────────────────────

  group('toFirestore', () {
    test('serializes all required fields', () {
      final date = DateTime(2024, 6, 15);
      final e = makeExpense(
        id: 'e1',
        userId: 'u1',
        title: 'Lunch',
        amount: 15.0,
        categoryId: 'food',
        walletId: 'w1',
        date: date,
        notes: 'with colleagues',
      );

      final map = e.toFirestore();

      expect(map['id'], equals('e1'));
      expect(map['userId'], equals('u1'));
      expect(map['title'], equals('Lunch'));
      expect(map['amount'], equals(15.0));
      expect(map['categoryId'], equals('food'));
      expect(map['walletId'], equals('w1'));
      expect(map['date'], equals(date.millisecondsSinceEpoch));
      expect(map['notes'], equals('with colleagues'));
      expect(map['isDeleted'], isFalse);
      expect(map['lastModified'], isA<int>());
    });

    test('does NOT include isSynced — that is local-only', () {
      final map = makeExpense().toFirestore();
      expect(map.containsKey('isSynced'), isFalse);
    });
  });

  // ─── fromFirestore ────────────────────────────────────────────────────────

  group('fromFirestore', () {
    test('round-trips correctly', () {
      final original = makeExpense(
        id: 'e1',
        userId: 'u1',
        title: 'Gym',
        amount: 30.0,
        categoryId: 'health',
        walletId: 'w1',
        isSynced: true,
      );

      final reconstructed = ExpenseModel.fromFirestore(original.toFirestore());

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.amount, equals(original.amount));
      expect(reconstructed.categoryId, equals(original.categoryId));
      expect(reconstructed.isSynced, isTrue); // fromFirestore always sets true
    });

    test('handles int amount stored as num from Firestore', () {
      final map = makeExpense().toFirestore();
      map['amount'] = 42; // int instead of double, common in Firestore

      final e = ExpenseModel.fromFirestore(map);
      expect(e.amount, equals(42.0));
      expect(e.amount, isA<double>());
    });

    test('handles missing notes gracefully', () {
      final map = makeExpense().toFirestore();
      map.remove('notes');
      // fromFirestore reads map['notes'] which will be null
      final e = ExpenseModel.fromFirestore(map);
      expect(e.notes, isNull);
    });
  });
}
