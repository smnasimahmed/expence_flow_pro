import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import '../../../database/app_database.dart';
import '../model/recurring_model.dart';
import '../../expense/model/expense_model.dart';
import '../../expense/repository/expense_repository.dart';
import '../../../core/services/log/app_log.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';

class RecurringRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  RecurringRepository({
    required AppDatabase db,
    required FirebaseFirestore firestore,
  }) : _db = db,
       _firestore = firestore;

  Future<void> saveLocally(RecurringModel recurring) async {
    await _db.into(_db.recurrings).insertOnConflictUpdate(
      RecurringsCompanion(
        id: Value(recurring.id),
        userId: Value(recurring.userId),
        title: Value(recurring.title),
        amount: Value(recurring.amount),
        walletId: Value(recurring.walletId),
        categoryId: Value(recurring.categoryId),
        frequency: Value(recurring.frequency.name),
        nextExecutionDate: Value(recurring.nextExecutionDate),
        isActive: Value(recurring.isActive),
        isSynced: Value(recurring.isSynced),
        lastModified: Value(recurring.lastModified),
      ),
    );
  }

  Future<List<RecurringModel>> getAll(String userId) async {
    final rows = await (_db.select(_db.recurrings)
          ..where((r) => r.userId.equals(userId) & r.isActive.equals(true)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  // Recurrings due today or earlier
  Future<List<RecurringModel>> getDue(String userId) async {
    final rows = await (_db.select(_db.recurrings)
          ..where(
            (r) =>
                r.userId.equals(userId) &
                r.isActive.equals(true) &
                r.nextExecutionDate.isSmallerOrEqualValue(DateTime.now()),
          ))
        .get();

    return rows.map(_rowToModel).toList();
  }

  Future<void> updateNextExecutionDate(
    String id,
    DateTime nextDate,
  ) async {
    await (_db.update(_db.recurrings)..where((r) => r.id.equals(id))).write(
      RecurringsCompanion(
        nextExecutionDate: Value(nextDate),
        isSynced: const Value(false),
        lastModified: Value(DateTime.now()),
      ),
    );
  }

  Future<List<RecurringModel>> getUnsynced(String userId) async {
    final rows = await (_db.select(_db.recurrings)
          ..where(
            (r) => r.userId.equals(userId) & r.isSynced.equals(false),
          ))
        .get();
    return rows.map(_rowToModel).toList();
  }

  Future<void> pushToFirestore(RecurringModel r) async {
    await _firestore
        .collection('users')
        .doc(r.userId)
        .collection('recurring')
        .doc(r.id)
        .set(r.toFirestore());
  }

  RecurringModel _rowToModel(Recurring row) => RecurringModel(
    id: row.id,
    userId: row.userId,
    title: row.title,
    amount: row.amount,
    walletId: row.walletId,
    categoryId: row.categoryId,
    frequency: RecurringFrequency.values.firstWhere(
      (e) => e.name == row.frequency,
      orElse: () => RecurringFrequency.monthly,
    ),
    nextExecutionDate: row.nextExecutionDate,
    isActive: row.isActive,
    isSynced: row.isSynced,
    lastModified: row.lastModified,
  );
}

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
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
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
