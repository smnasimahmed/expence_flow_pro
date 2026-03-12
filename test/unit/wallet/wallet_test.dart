import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import 'package:expence_flow_pro/features/wallet/controller/wallet_controller.dart';
import 'package:expence_flow_pro/features/wallet/model/wallet_model.dart';
import 'package:expence_flow_pro/core/services/storage/storage_service.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  // ─── WalletModel ───────────────────────────────────────────────────────────

  group('WalletModel', () {
    group('create', () {
      test('generates unique ids', () {
        final w1 = WalletModel.create(
          userId: kTestUserId,
          name: 'Cash',
          type: WalletType.cash,
        );
        final w2 = WalletModel.create(
          userId: kTestUserId,
          name: 'Bank',
          type: WalletType.bank,
        );
        expect(w1.id, isNot(equals(w2.id)));
      });

      test('sets initial balance as both initialBalance and balance', () {
        final w = WalletModel.create(
          userId: kTestUserId,
          name: 'Savings',
          type: WalletType.savings,
          initialBalance: 5000.0,
        );
        expect(w.initialBalance, equals(5000.0));
        expect(w.balance, equals(5000.0));
      });

      test('defaults color to #6C63FF', () {
        final w = WalletModel.create(
          userId: kTestUserId,
          name: 'Default',
          type: WalletType.cash,
        );
        expect(w.color, equals('#6C63FF'));
      });
    });

    group('typeLabel', () {
      test('returns correct label for each type', () {
        final cases = {
          WalletType.cash: 'Cash',
          WalletType.bank: 'Bank',
          WalletType.savings: 'Savings',
          WalletType.custom: 'Custom',
        };
        cases.forEach((type, expected) {
          final w = makeWallet(type: type);
          expect(w.typeLabel, equals(expected));
        });
      });
    });

    group('toFirestore / fromFirestore', () {
      test('round-trips without data loss', () {
        final original = makeWallet(
          id: 'w1',
          userId: 'u1',
          name: 'My Bank',
          type: WalletType.bank,
          initialBalance: 2500.0,
        );

        final map = original.toFirestore();
        final restored = WalletModel.fromFirestore(map);

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.type, equals(original.type));
        expect(restored.initialBalance, equals(original.initialBalance));
        expect(restored.isSynced, isTrue); // fromFirestore always sets true
      });

      test('does NOT include isSynced in Firestore map', () {
        final map = makeWallet().toFirestore();
        expect(map.containsKey('isSynced'), isFalse);
      });

      test('falls back to WalletType.cash for unknown type string', () {
        final map = makeWallet().toFirestore();
        map['type'] = 'unknown_type';
        final w = WalletModel.fromFirestore(map);
        expect(w.type, equals(WalletType.cash));
      });
    });

    group('copyWith', () {
      test('preserves id and userId', () {
        final original = makeWallet(id: 'fixed', userId: 'user_fixed');
        final copy = original.copyWith(name: 'Updated');
        expect(copy.id, equals('fixed'));
        expect(copy.userId, equals('user_fixed'));
      });

      test('updates lastModified to now', () {
        final original = makeWallet();
        final before = DateTime.now();
        final copy = original.copyWith(name: 'New Name');
        expect(copy.lastModified.isAfter(before) || copy.lastModified == before, isTrue);
      });
    });
  });

  // ─── WalletController ─────────────────────────────────────────────────────

  group('WalletController', () {
    late WalletController controller;
    late MockWalletRepository mockRepository;

    setUp(() {
      setupGetX();
      StorageService.userId = kTestUserId;
      mockRepository = MockWalletRepository();

      when(mockRepository.getWallets(any)).thenAnswer((_) async => []);
      when(mockRepository.calculateBalance(any)).thenAnswer((_) async => 0.0);

      controller = WalletController(repository: mockRepository);
      Get.put(controller);
    });

    tearDown(teardownGetX);

    group('totalBalance', () {
      test('sums all wallet balances', () {
        controller.wallets = [
          makeWallet(balance: 1000),
          makeWallet(balance: 500),
          makeWallet(balance: 250),
        ];
        expect(controller.totalBalance, equals(1750.0));
      });

      test('returns 0.0 when wallet list is empty', () {
        controller.wallets = [];
        expect(controller.totalBalance, equals(0.0));
      });
    });

    group('loadWallets', () {
      test('populates wallets list and calculates balances', () async {
        final wallets = [makeWallet(id: 'w1'), makeWallet(id: 'w2')];

        when(mockRepository.getWallets(kTestUserId))
            .thenAnswer((_) async => wallets);
        when(mockRepository.calculateBalance('w1'))
            .thenAnswer((_) async => 800.0);
        when(mockRepository.calculateBalance('w2'))
            .thenAnswer((_) async => 1200.0);

        await controller.loadWallets();

        expect(controller.wallets.length, equals(2));
        expect(controller.wallets[0].balance, equals(800.0));
        expect(controller.wallets[1].balance, equals(1200.0));
      });

      test('sets isLoading=false even on repository error', () async {
        when(mockRepository.getWallets(any)).thenThrow(Exception('DB error'));

        await controller.loadWallets();

        expect(controller.isLoading, isFalse);
      });
    });

    group('deleteWallet', () {
      test('refuses to delete wallet with transactions (balance != initialBalance)', () async {
        final wallet = makeWallet(id: 'w1', initialBalance: 1000, balance: 750);
        controller.wallets = [wallet];

        await controller.deleteWallet('w1');

        verifyNever(mockRepository.hardDelete(any));
        expect(controller.wallets.length, equals(1));
      });

      test('deletes wallet when balance equals initialBalance', () async {
        final wallet = makeWallet(id: 'w1', initialBalance: 1000, balance: 1000);
        controller.wallets = [wallet];
        when(mockRepository.hardDelete(any)).thenAnswer((_) async {});

        await controller.deleteWallet('w1');

        verify(mockRepository.hardDelete(any)).called(1);
        expect(controller.wallets, isEmpty);
      });

      test('does nothing when walletId is not in the list', () async {
        controller.wallets = [makeWallet(id: 'w1')];

        await controller.deleteWallet('nonexistent');

        verifyNever(mockRepository.hardDelete(any));
      });
    });

    group('setType / setColor', () {
      test('setType updates selectedType', () {
        controller.setType(WalletType.bank);
        expect(controller.selectedType, equals(WalletType.bank));
      });

      test('setColor updates selectedColor', () {
        controller.setColor('#FF0000');
        expect(controller.selectedColor, equals('#FF0000'));
      });
    });
  });
}
