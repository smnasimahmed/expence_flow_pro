import 'package:get/get.dart';
import '../../expense/repository/expense_repository.dart';
import '../../expense/model/expense_model.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/constants/app_strings.dart';

class AnalyticsController extends GetxController {
  final ExpenseRepository _repository;

  AnalyticsController({required ExpenseRepository repository})
    : _repository = repository;

  // ─── State ────────────────────────────────────────────────────────────────
  bool isLoading = false;
  List<ExpenseModel> monthlyExpenses = [];
  Map<String, double> categoryTotals = {};
  double totalThisMonth = 0;
  double totalLastMonth = 0;
  double averageDailySpend = 0;

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadAnalytics() async {
    isLoading = true;
    update();

    try {
      final now = DateTime.now();

      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // This month
      monthlyExpenses = await _repository.getExpensesInRange(
        userId: StorageService.userId,
        from: thisMonthStart,
        to: thisMonthEnd,
      );

      // Last month total (for comparison)
      final lastMonthExpenses = await _repository.getExpensesInRange(
        userId: StorageService.userId,
        from: lastMonthStart,
        to: lastMonthEnd,
      );

      totalThisMonth = monthlyExpenses.fold(0, (sum, e) => sum + e.amount);
      totalLastMonth = lastMonthExpenses.fold(0, (sum, e) => sum + e.amount);

      // Average daily spend (based on days elapsed this month)
      final daysElapsed = now.day;
      averageDailySpend = daysElapsed > 0 ? totalThisMonth / daysElapsed : 0;

      // Category breakdown
      categoryTotals = {};
      for (final expense in monthlyExpenses) {
        categoryTotals[expense.categoryId] =
            (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      }
    } catch (e) {
      Get.snackbar('Error', AppStrings.somethingWentWrong);
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  // Month-over-month change as percentage
  double get monthlyChange {
    if (totalLastMonth == 0) return 0;
    return ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100;
  }

  bool get spentMoreThisMonth => totalThisMonth > totalLastMonth;

  // Most expensive category this month
  String get topCategory {
    if (categoryTotals.isEmpty) return 'none';
    return categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  @override
  void onInit() {
    loadAnalytics();
    super.onInit();
  }
}
