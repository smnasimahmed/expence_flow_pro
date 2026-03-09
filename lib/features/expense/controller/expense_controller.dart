import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repository/expense_repository.dart';
import '../model/expense_model.dart';
import '../../analytics/controller/analytics_controller.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _repository;

  ExpenseController({required ExpenseRepository repository})
      : _repository = repository;

  // ─── State ────────────────────────────────────────────────────────────────
  List<ExpenseModel> expenses = [];
  bool isLoading = false;
  bool isPaginating = false;
  int _currentPage = 0;
  static const _pageSize = 20;
  bool hasMore = true;
  String searchQuery = '';
  String selectedFilterCategory = 'all';

  // ─── Form fields ──────────────────────────────────────────────────────────
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String selectedCategoryId = 'food';
  String selectedWalletId = '';
  DateTime selectedDate = DateTime.now();

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadExpenses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      hasMore = true;
      expenses = [];
    }

    if (!hasMore) return;

    if (_currentPage == 0) {
      isLoading = true;
    } else {
      isPaginating = true;
    }
    update();

    try {
      final newItems = await _repository.getExpenses(
        userId: StorageService.userId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      expenses.addAll(newItems);
      hasMore = newItems.length == _pageSize;
      _currentPage++;
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      isPaginating = false;
      update();
    }
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  Future<void> addExpense() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedWalletId.isEmpty) {
      Get.snackbar('Select Wallet', 'Please choose a wallet');
      return;
    }

    isLoading = true;
    update();

    try {
      final expense = ExpenseModel.create(
        userId: StorageService.userId,
        title: titleController.text.trim(),
        amount: double.parse(amountController.text),
        categoryId: selectedCategoryId,
        walletId: selectedWalletId,
        date: selectedDate,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      // Save locally and push to Firestore instantly if online
      await _repository.saveAndSync(expense);

      // Add to top of list immediately (optimistic update)
      expenses.insert(0, expense);

      _clearForm();
      Get.back();
      Get.snackbar('Done', 'Expense added ✓');

      // Refresh wallet balances and analytics so everything stays in sync
      _refreshDependentControllers();
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Edit ─────────────────────────────────────────────────────────────────

  Future<void> updateExpense(String expenseId) async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    update();

    try {
      final index = expenses.indexWhere((e) => e.id == expenseId);
      if (index == -1) return;

      final updated = expenses[index].copyWith(
        title: titleController.text.trim(),
        amount: double.parse(amountController.text),
        categoryId: selectedCategoryId,
        walletId: selectedWalletId,
        date: selectedDate,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        isSynced: false,
      );

      // Save and sync instantly
      await _repository.saveAndSync(updated);
      expenses[index] = updated;

      _clearForm();
      Get.back();
      Get.snackbar('Done', 'Expense updated ✓');

      _refreshDependentControllers();
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Delete with undo ─────────────────────────────────────────────────────

  Future<void> deleteExpense(String expenseId) async {
    final index = expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final deletedExpense = expenses[index];

    // Remove from UI immediately
    expenses.removeAt(index);
    update();

    // Hard delete: moves to deleted_expenses table + syncs to Firestore if online
    await _repository.hardDelete(deletedExpense);

    _refreshDependentControllers();

    // Show undo snackbar — undo only works within the snackbar duration (before next sync)
    Get.snackbar(
      AppStrings.expenseDeleted,
      deletedExpense.title,
      mainButton: TextButton(
        onPressed: () => _undoDelete(index, deletedExpense),
        child: const Text(AppStrings.undo),
      ),
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _undoDelete(int index, ExpenseModel expense) async {
    await _repository.restoreDeleted(expense);
    expenses.insert(index, expense);
    update();
    _refreshDependentControllers();
  }

  // ─── Refresh dashboard and analytics after any CRUD ───────────────────────

  void _refreshDependentControllers() {
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().loadWallets();
    }
    if (Get.isRegistered<AnalyticsController>()) {
      Get.find<AnalyticsController>().loadAnalytics();
    }
  }

  // ─── Pre-fill form for edit ───────────────────────────────────────────────

  void fillFormForEdit(ExpenseModel expense) {
    titleController.text = expense.title;
    amountController.text = expense.amount.toString();
    notesController.text = expense.notes ?? '';
    selectedCategoryId = expense.categoryId;
    selectedWalletId = expense.walletId;
    selectedDate = expense.date;
    update();
  }

  void setCategory(String id) { selectedCategoryId = id; update(); }
  void setWallet(String id) { selectedWalletId = id; update(); }
  void setDate(DateTime date) { selectedDate = date; update(); }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    loadExpenses();
    super.onInit();
  }

  @override
  void onClose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  List<ExpenseModel> get filteredExpenses {
    return expenses.where((e) {
      final matchesSearch = searchQuery.isEmpty ||
          e.title.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedFilterCategory == 'all' || e.categoryId == selectedFilterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearch(String query) { searchQuery = query; update(); }
  void setFilterCategory(String categoryId) { selectedFilterCategory = categoryId; update(); }

  void _clearForm() {
    titleController.clear();
    amountController.clear();
    notesController.clear();
    selectedCategoryId = 'food';
    selectedDate = DateTime.now();
  }
}
