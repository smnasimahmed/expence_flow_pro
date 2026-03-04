import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/expense_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class AllExpensesPage extends StatelessWidget {
  const AllExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('All Expenses', size: 18, weight: FontWeight.w600),
      ),
      body: GetBuilder<ExpenseController>(
        builder: (controller) {
          return Column(
            children: [
              _searchBar(controller),
              _categoryFilter(controller),
              Expanded(child: _expenseList(controller)),
            ],
          );
        },
      ),
    );
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  Widget _searchBar(ExpenseController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        onChanged: (value) => controller.setSearch(value),
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: 'Search expenses...',
          hintStyle: const TextStyle(color: AppColors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey),
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ─── Category Filter ───────────────────────────────────────────────────────

  Widget _categoryFilter(ExpenseController controller) {
    final categories = [
      ('all', '🔍', 'All'),
      ('food', '🍔', 'Food'),
      ('transport', '🚗', 'Transport'),
      ('shopping', '🛍', 'Shopping'),
      ('health', '💊', 'Health'),
      ('entertainment', '🎮', 'Fun'),
      ('bills', '🧾', 'Bills'),
      ('other', '📦', 'Other'),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (id, emoji, name) = categories[i];
          final isSelected = controller.selectedFilterCategory == id;

          return GestureDetector(
            onTap: () => controller.setFilterCategory(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  AppText(
                    name,
                    size: 12,
                    color: isSelected ? AppColors.white : AppColors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Expense List ──────────────────────────────────────────────────────────

  Widget _expenseList(ExpenseController controller) {
    final filtered = controller.filteredExpenses;

    if (controller.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 6,
        itemBuilder: (_, __) => const _LoadingTile(),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            AppText('No expenses found', color: AppColors.grey, size: 15),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      // Load more when user scrolls to the bottom
      onNotification: (scroll) {
        if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 100) {
          if (controller.hasMore && !controller.isPaginating) {
            controller.loadExpenses();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: filtered.length + (controller.isPaginating ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == filtered.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final expense = filtered[i];

          return Dismissible(
            key: Key(expense.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: AppColors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.red),
            ),
            onDismissed: (_) => controller.deleteExpense(expense.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _categoryIcon(expense.categoryId),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          expense.title,
                          size: 14,
                          weight: FontWeight.w500,
                          maxLines: 1,
                        ),
                        AppText(
                          DateFormat('MMM dd, yyyy').format(expense.date),
                          size: 12,
                          color: AppColors.grey,
                          top: 2,
                        ),
                      ],
                    ),
                  ),
                  AppText(
                    '-\$${expense.amount.toStringAsFixed(2)}',
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryIcon(String categoryId) {
    final categoryIcons = {
      'food': ('🍔', AppColors.food),
      'transport': ('🚗', AppColors.transport),
      'shopping': ('🛍', AppColors.shopping),
      'health': ('💊', AppColors.health),
      'entertainment': ('🎮', AppColors.entertainment),
      'bills': ('🧾', AppColors.bills),
      'salary': ('💰', AppColors.salary),
      'other': ('📦', AppColors.other),
    };

    final info = categoryIcons[categoryId] ?? ('📦', AppColors.other);

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: info.$2.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(info.$1, style: const TextStyle(fontSize: 20))),
    );
  }
}

// ─── Loading Tile ─────────────────────────────────────────────────────────────

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ShimmerBox(height: 44, width: 44, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, width: 120),
                SizedBox(height: 8),
                ShimmerBox(height: 12, width: 80),
              ],
            ),
          ),
          ShimmerBox(height: 16, width: 60),
        ],
      ),
    );
  }
}
