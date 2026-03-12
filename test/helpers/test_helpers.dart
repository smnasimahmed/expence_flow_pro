import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:expence_flow_pro/features/expense/model/expense_model.dart';
import 'package:expence_flow_pro/features/wallet/model/wallet_model.dart';
import 'package:expence_flow_pro/features/budget/model/budget_model.dart';
import 'package:expence_flow_pro/features/recurring/model/recurring_model.dart';
import 'package:expence_flow_pro/features/transfer/model/transfer_model.dart';

// ─── Mock declarations ────────────────────────────────────────────────────────
// Run: dart run build_runner build --delete-conflicting-outputs
// to regenerate mocks after adding new @GenerateMocks annotations.

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const kTestUserId = 'user_test_123';
const kTestEmail = 'test@expenseflow.com';
const kTestPassword = 'Test@1234';
const kTestName = 'Test User';
const kTestWalletId = 'wallet_test_abc';

ExpenseModel makeExpense({
  String? id,
  String? userId,
  String? title,
  double amount = 50.0,
  String categoryId = 'food',
  String? walletId,
  DateTime? date,
  String? notes,
  bool isSynced = false,
  bool isDeleted = false,
}) {
  return ExpenseModel(
    id: id ?? 'expense_${DateTime.now().microsecondsSinceEpoch}',
    userId: userId ?? kTestUserId,
    title: title ?? 'Test Expense',
    amount: amount,
    categoryId: categoryId,
    walletId: walletId ?? kTestWalletId,
    date: date ?? DateTime(2024, 6, 15),
    notes: notes,
    isSynced: isSynced,
    isDeleted: isDeleted,
    lastModified: DateTime(2024, 6, 15),
  );
}

WalletModel makeWallet({
  String? id,
  String? userId,
  String? name,
  WalletType type = WalletType.cash,
  double initialBalance = 1000.0,
  bool isSynced = false,
  bool isDeleted = false,
  double balance = 1000.0,
}) {
  return WalletModel(
    id: id ?? 'wallet_${DateTime.now().microsecondsSinceEpoch}',
    userId: userId ?? kTestUserId,
    name: name ?? 'Test Wallet',
    type: type,
    initialBalance: initialBalance,
    color: '#6C63FF',
    isSynced: isSynced,
    isDeleted: isDeleted,
    lastModified: DateTime(2024, 6, 15),
    balance: balance,
  );
}

BudgetModel makeBudget({
  String? id,
  String? userId,
  String? categoryId,
  double amount = 500.0,
  int? month,
  int? year,
  double spent = 0,
  bool isSynced = false,
}) {
  return BudgetModel(
    id: id ?? 'budget_${DateTime.now().microsecondsSinceEpoch}',
    userId: userId ?? kTestUserId,
    categoryId: categoryId,
    amount: amount,
    month: month ?? DateTime.now().month,
    year: year ?? DateTime.now().year,
    isSynced: isSynced,
    lastModified: DateTime(2024, 6, 15),
    spent: spent,
  );
}

RecurringModel makeRecurring({
  String? id,
  String? userId,
  String? title,
  double amount = 100.0,
  String? walletId,
  String categoryId = 'bills',
  RecurringFrequency frequency = RecurringFrequency.monthly,
  DateTime? nextExecutionDate,
  bool isActive = true,
}) {
  return RecurringModel(
    id: id ?? 'recurring_${DateTime.now().microsecondsSinceEpoch}',
    userId: userId ?? kTestUserId,
    title: title ?? 'Netflix',
    amount: amount,
    walletId: walletId ?? kTestWalletId,
    categoryId: categoryId,
    frequency: frequency,
    nextExecutionDate: nextExecutionDate ?? DateTime.now().subtract(const Duration(days: 1)),
    isActive: isActive,
    isSynced: false,
    lastModified: DateTime(2024, 6, 15),
  );
}

TransferModel makeTransfer({
  String? id,
  String? userId,
  String? fromWalletId,
  String? toWalletId,
  double amount = 200.0,
  String? notes,
}) {
  return TransferModel(
    id: id ?? 'transfer_${DateTime.now().microsecondsSinceEpoch}',
    userId: userId ?? kTestUserId,
    fromWalletId: fromWalletId ?? 'wallet_from',
    toWalletId: toWalletId ?? 'wallet_to',
    amount: amount,
    notes: notes,
    date: DateTime(2024, 6, 15),
    isSynced: false,
    lastModified: DateTime(2024, 6, 15),
  );
}

/// Wraps a widget in a minimal GetMaterialApp for widget testing
Widget testableWidget(Widget child) {
  return GetMaterialApp(
    home: Scaffold(body: child),
  );
}

/// Silences GetX snackbar/navigation calls during unit tests
void setupGetX() {
  Get.testMode = true;
}

void teardownGetX() {
  Get.reset();
}
