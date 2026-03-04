import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/expense/view/dashboard_page.dart';
import '../../features/wallet/view/wallets_page.dart';
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
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withOpacity(0.2),
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
}
