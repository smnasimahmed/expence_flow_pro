import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import '../../../database/app_database.dart';
import '../model/budget_model.dart';
import '../../../core/services/log/app_log.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';
import '../../expense/repository/expense_repository.dart';

class BudgetRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  BudgetRepository({
    required AppDatabase db,
    required FirebaseFirestore firestore,
  }) : _db = db,
       _firestore = firestore;

  Future<void> saveLocally(BudgetModel budget) async {
    await _db.into(_db.budgets).insertOnConflictUpdate(
      BudgetsCompanion(
        id: Value(budget.id),
        userId: Value(budget.userId),
        categoryId: Value(budget.categoryId),
        amount: Value(budget.amount),
        month: Value(budget.month),
        year: Value(budget.year),
        isSynced: Value(budget.isSynced),
        lastModified: Value(budget.lastModified),
      ),
    );
    appLog('Budget saved locally', source: 'BudgetRepo');
  }

  Future<List<BudgetModel>> getBudgetsForMonth(
    String userId,
    int month,
    int year,
  ) async {
    final rows = await (_db.select(_db.budgets)
          ..where(
            (b) =>
                b.userId.equals(userId) &
                b.month.equals(month) &
                b.year.equals(year),
          ))
        .get();

    return rows
        .map(
          (row) => BudgetModel(
            id: row.id,
            userId: row.userId,
            categoryId: row.categoryId,
            amount: row.amount,
            month: row.month,
            year: row.year,
            isSynced: row.isSynced,
            lastModified: row.lastModified,
          ),
        )
        .toList();
  }

  Future<List<BudgetModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.budgets)
          ..where(
            (b) => b.userId.equals(userId) & b.isSynced.equals(false),
          ))
        .get();
    return rows
        .map(
          (row) => BudgetModel(
            id: row.id,
            userId: row.userId,
            categoryId: row.categoryId,
            amount: row.amount,
            month: row.month,
            year: row.year,
            isSynced: row.isSynced,
            lastModified: row.lastModified,
          ),
        )
        .toList();
  }

  Future<void> pushToFirestore(BudgetModel budget) async {
    await _firestore
        .collection('users')
        .doc(budget.userId)
        .collection('budgets')
        .doc(budget.id)
        .set(budget.toFirestore());
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class BudgetController extends GetxController {
  final BudgetRepository _repository;
  final ExpenseRepository _expenseRepository;

  BudgetController({
    required BudgetRepository repository,
    required ExpenseRepository expenseRepository,
  }) : _repository = repository,
       _expenseRepository = expenseRepository;

  // ─── State ────────────────────────────────────────────────────────────────
  List<BudgetModel> budgets = [];
  bool isLoading = false;

  // ─── Form ─────────────────────────────────────────────────────────────────
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? selectedCategoryId; // null = total budget

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadBudgets() async {
    isLoading = true;
    update();

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      budgets = await _repository.getBudgetsForMonth(
        StorageService.userId,
        now.month,
        now.year,
      );

      // Calculate how much was spent for each budget
      final expenses = await _expenseRepository.getExpensesInRange(
        userId: StorageService.userId,
        from: monthStart,
        to: monthEnd,
      );

      for (var i = 0; i < budgets.length; i++) {
        final budget = budgets[i];

        if (budget.categoryId == null) {
          // Total budget
          budgets[i].spent = expenses.fold(0, (sum, e) => sum + e.amount);
        } else {
          // Category budget
          budgets[i].spent = expenses
              .where((e) => e.categoryId == budget.categoryId)
              .fold(0, (sum, e) => sum + e.amount);
        }

        // Show warning/exceeded alerts
        if (budgets[i].isExceeded) {
          Get.snackbar('⚠️ Budget Exceeded', AppStrings.budgetExceeded);
        } else if (budgets[i].isWarning) {
          Get.snackbar('⚠️ Budget Warning', AppStrings.budgetWarning);
        }
      }
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  Future<void> addBudget() async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    update();

    try {
      final now = DateTime.now();
      final budget = BudgetModel.create(
        userId: StorageService.userId,
        categoryId: selectedCategoryId,
        amount: double.parse(amountController.text),
        month: now.month,
        year: now.year,
      );

      await _repository.saveLocally(budget);
      budgets.add(budget);

      amountController.clear();
      selectedCategoryId = null;
      Get.back();
      Get.snackbar('Done', 'Budget set ✓');
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  @override
  void onInit() {
    loadBudgets();
    super.onInit();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}
