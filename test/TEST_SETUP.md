# Test Setup Guide

## 1. Add test dependencies to pubspec.yaml

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.9
```

## 2. Generate mocks

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `test/helpers/mocks.mocks.dart` and
`test/unit/auth/auth_repository_test.mocks.dart` from the
`@GenerateMocks` annotations.

## 3. Run unit + widget tests

```bash
# All tests
flutter test

# Single file
flutter test test/unit/expense/expense_controller_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 4. Run integration tests

Requires a connected device or emulator with Firebase configured.

```bash
flutter test integration_test/expense_flow_integration_test.dart
```

Integration tests use a dedicated test Firebase account:
- Email: `integration@expenseflow.test`  
- Password: `IntTest@123`

Create this account in your Firebase Console before running.

---

## Test file map

```
test/
├── helpers/
│   ├── test_helpers.dart          # Fixtures, shared setup, testableWidget()
│   └── mocks.dart                 # @GenerateMocks — run build_runner after changes
│
├── unit/
│   ├── auth/
│   │   ├── auth_controller_test.dart     # signIn, signUp, forgotPassword, signOut, toggles
│   │   └── auth_repository_test.dart     # Firebase Auth + Firestore document creation
│   │
│   ├── expense/
│   │   ├── expense_model_test.dart       # create, copyWith, toFirestore, fromFirestore
│   │   └── expense_controller_test.dart  # loadExpenses, pagination, filtering, delete, undo
│   │
│   ├── wallet/
│   │   └── wallet_test.dart             # WalletModel + WalletController (load, delete guard, balance)
│   │
│   ├── budget/
│   │   └── budget_test.dart             # BudgetModel thresholds + BudgetController spend calc
│   │
│   ├── recurring/
│   │   └── recurring_test.dart          # nextAfterExecution (all 4 frequencies) + RecurringEngine
│   │
│   ├── transfer/
│   │   └── transfer_test.dart           # TransferModel + TransferController (walletName resolution)
│   │
│   ├── analytics/
│   │   └── analytics_controller_test.dart # totals, categoryTotals, monthlyChange, topCategory
│   │
│   └── sync/
│       └── sync_controller_test.dart    # push/pull guards, isSyncing flag, tombstone logic
│
├── widget/
│   ├── sign_in_page_test.dart           # rendering, form validation, checkbox/visibility toggles
│   └── dashboard_page_test.dart         # rendering, loading state, FAB, expense list display
│
└── integration/
    └── expense_flow_integration_test.dart  # full user journeys: auth, CRUD, wallet, budget, sync
```
