import 'package:expence_flow_pro/features/expense/view/add_expense_sheet.dart';
import 'package:expence_flow_pro/features/wallet/view/add_wallet_sheet.dart';
import 'package:expence_flow_pro/features/wallet/view/wallets_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/expense/view/dashboard_page.dart';
import '../../features/analytics/view/analytics_page.dart';
import '../constants/app_theme.dart';
import '../widgets/app_widgets.dart';

class NavbarController extends GetxController {
  int currentIndex = 0;

  void changeTab(int index) {
    currentIndex = index;
    update();
  }
}

class AppNavbar extends StatelessWidget {
  const AppNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NavbarController>(
      init: NavbarController(),
      builder: (controller) {
        return Scaffold(
          body: IndexedStack(
            index: controller.currentIndex,
            children: const [
              DashboardPage(),
              WalletsPage(),
              AnalyticsPage(),
            ],
          ),
          // _floatingActionButton() is called here – one FAB, unique heroTag per tab
          floatingActionButton: _floatingActionButton(context, controller.currentIndex),
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withAlpha(51),
            selectedIndex: controller.currentIndex,
            onDestinationSelected: controller.changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                ),
                label: 'Wallets',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
                label: 'Analytics',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _floatingActionButton(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return FloatingActionButton.extended(
          heroTag: 'fab_add_expense',
          onPressed: () => _openSheet(context, const AddExpenseSheet()),
          backgroundColor: AppColors.primary,
          label: const AppText('Add Expense', color: AppColors.white),
          icon: const Icon(Icons.add, color: AppColors.white),
        );
      case 1:
        return FloatingActionButton.extended(
          heroTag: 'fab_add_wallet',
          onPressed: () => _openSheet(context, const AddWalletSheet()),
          backgroundColor: AppColors.primary,
          label: const AppText('Add Wallet', color: AppColors.white),
          icon: const Icon(Icons.add, color: AppColors.white),
        );
      default:
        return null; // no FAB on analytics tab
    }
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }
}
