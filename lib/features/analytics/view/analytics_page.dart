import 'package:expence_flow_pro/features/expense/repository/expense_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/analytics_controller.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Analytics', size: 18, weight: FontWeight.w600),
      ),
      body: GetBuilder<AnalyticsController>(
        init: AnalyticsController(repository: Get.find<ExpenseRepository>()),
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _monthComparison(controller),
              const SizedBox(height: 24),
              _categoryBreakdown(controller),
              const SizedBox(height: 24),
              _dailyAverage(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _monthComparison(AnalyticsController controller) {
    final isMore = controller.spentMoreThisMonth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('This Month', size: 13, color: AppColors.grey),
          const SizedBox(height: 8),
          AppText(
            '\$${controller.totalThisMonth.toStringAsFixed(2)}',
            size: 28,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isMore ? Icons.arrow_upward : Icons.arrow_downward,
                color: isMore ? AppColors.red : AppColors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              AppText(
                '${controller.monthlyChange.abs().toStringAsFixed(1)}% vs last month',
                size: 12,
                color: isMore ? AppColors.red : AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: controller.totalLastMonth == 0
                ? 0
                : (controller.totalThisMonth / controller.totalLastMonth).clamp(0, 1),
            backgroundColor: AppColors.surfaceLight,
            color: isMore ? AppColors.red : AppColors.green,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdown(AnalyticsController controller) {
    if (controller.categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = controller.totalThisMonth;
    final categoryColors = {
      'food': AppColors.food,
      'transport': AppColors.transport,
      'shopping': AppColors.shopping,
      'health': AppColors.health,
      'entertainment': AppColors.entertainment,
      'bills': AppColors.bills,
      'other': AppColors.other,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Spending by Category'),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: controller.categoryTotals.entries.map((entry) {
                  final color = categoryColors[entry.key] ?? AppColors.other;
                  return PieChartSectionData(
                    value: entry.value,
                    color: color,
                    radius: 50,
                    showTitle: false,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...controller.categoryTotals.entries.map((entry) {
            final color = categoryColors[entry.key] ?? AppColors.other;
            final percent = total == 0 ? 0 : (entry.value / total * 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      entry.key[0].toUpperCase() + entry.key.substring(1),
                      size: 13,
                    ),
                  ),
                  AppText(
                    '\$${entry.value.toStringAsFixed(2)}',
                    size: 13,
                    weight: FontWeight.w500,
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    '${percent.toStringAsFixed(0)}%',
                    size: 12,
                    color: AppColors.grey,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _dailyAverage(AnalyticsController controller) {
    return Row(
      children: [
        Expanded(
          child: AmountCard(
            label: 'Daily Average',
            amount: controller.averageDailySpend,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AmountCard(
            label: 'Last Month',
            amount: controller.totalLastMonth,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}
