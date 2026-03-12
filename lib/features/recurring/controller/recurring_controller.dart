import 'package:expence_flow_pro/features/recurring/repository/recurring_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import '../model/recurring_model.dart';
import '../../expense/model/expense_model.dart';
import '../../expense/repository/expense_repository.dart';
import '../../analytics/controller/analytics_controller.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../core/services/log/app_log.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';


// ─── Controller ───────────────────────────────────────────────────────────────

class RecurringController extends GetxController {
  final RecurringRepository _repository;
  final ExpenseRepository _expenseRepository;

  RecurringController({
    required RecurringRepository repository,
    required ExpenseRepository expenseRepository,
  }) : _repository = repository,
       _expenseRepository = expenseRepository;

  List<RecurringModel> recurrings = [];
  bool isLoading = false;

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String selectedWalletId = '';
  String selectedCategoryId = 'bills';
  RecurringFrequency selectedFrequency = RecurringFrequency.monthly;
  DateTime selectedStartDate = DateTime.now();

  // ─── Engine ───────────────────────────────────────────────────────────────

  // Called on every app start – auto-creates expenses for due recurrings
  Future<void> runRecurringEngine() async {
    final dueItems = await _repository.getDue(StorageService.userId);

    for (final recurring in dueItems) {
      // Auto-create the expense
      final expense = ExpenseModel.create(
        userId: recurring.userId,
        title: recurring.title,
        amount: recurring.amount,
        categoryId: recurring.categoryId,
        walletId: recurring.walletId,
        date: recurring.nextExecutionDate,
        notes: 'Auto-created by recurring: ${recurring.frequency.name}',
      );

      await _expenseRepository.saveLocally(expense);

      // Move next execution date forward
      await _repository.updateNextExecutionDate(
        recurring.id,
        recurring.nextAfterExecution,
      );

      appLog(
        'Recurring expense created: ${recurring.title}',
        source: 'RecurringEngine',
      );
    }

    if (dueItems.isNotEmpty) {
      Get.snackbar(
        'Auto-pay',
        '${dueItems.length} recurring expense(s) added',
      );
    }

    await loadRecurrings();
    if (dueItems.isNotEmpty) _refreshDependentControllers();
  }

  Future<void> loadRecurrings() async {
    isLoading = true;
    update();

    try {
      recurrings = await _repository.getAll(StorageService.userId);
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> addRecurring() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedWalletId.isEmpty) {
      Get.snackbar('Select Wallet', 'Please choose a wallet');
      return;
    }

    isLoading = true;
    update();

    try {
      final recurring = RecurringModel.create(
        userId: StorageService.userId,
        title: titleController.text.trim(),
        amount: double.parse(amountController.text),
        walletId: selectedWalletId,
        categoryId: selectedCategoryId,
        frequency: selectedFrequency,
        startDate: selectedStartDate,
      );

      await _repository.saveLocally(recurring);
      recurrings.add(recurring);

      titleController.clear();
      amountController.clear();
      Get.back();
      Get.snackbar('Done', 'Recurring expense set ✓');
      runRecurringEngine();
      _refreshDependentControllers();
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  void _refreshDependentControllers() {
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().loadWallets();
    }
    if (Get.isRegistered<AnalyticsController>()) {
      Get.find<AnalyticsController>().loadAnalytics();
    }
  }

  void setFrequency(RecurringFrequency freq) {
    selectedFrequency = freq;
    update();
  }

  @override
  void onInit() {
    runRecurringEngine();
    super.onInit();
  }

  @override
  void onClose() {
    titleController.dispose();
    amountController.dispose();
    super.onClose();
  }
}
