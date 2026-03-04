import 'package:expence_flow_pro/features/auth/view/forgot_password_page.dart';
import 'package:expence_flow_pro/features/budget/binding/budget_binding.dart';
import 'package:expence_flow_pro/features/budget/view/budget_page.dart';
import 'package:expence_flow_pro/features/expense/view/all_expenses_page.dart';
import 'package:expence_flow_pro/features/recurring/binding/recurring_binding.dart';
import 'package:expence_flow_pro/features/recurring/view/recurring_page.dart';
import 'package:expence_flow_pro/features/settings/view/settings_page.dart';
import 'package:get/get.dart';
import '../features/auth/view/sign_in_page.dart';
import '../features/auth/view/sign_up_page.dart';
import '../features/wallet/view/wallets_page.dart';
import '../features/analytics/view/analytics_page.dart';
import '../features/expense/binding/expense_binding.dart';
import '../features/wallet/binding/wallet_binding.dart';
import '../features/analytics/binding/analytics_binding.dart';
import '../core/utils/app_navbar.dart';
import 'app_routes.dart';

List<GetPage> appPages = [
  GetPage(
    name: AppRoutes.signIn,
    page: () => const SignInPage(),
  ),
  GetPage(
    name: AppRoutes.signUp,
    page: () => const SignUpPage(),
  ),
  GetPage(
    name: AppRoutes.dashboard,
    page: () => const AppNavbar(),
    bindings: [
      ExpenseBinding(),
      WalletBinding(),
    ],
  ),
  GetPage(
    name: AppRoutes.wallets,
    page: () => const WalletsPage(),
    binding: WalletBinding(),
  ),
  GetPage(
    name: AppRoutes.analytics,
    page: () => const AnalyticsPage(),
    binding: AnalyticsBinding(),
  ),
  GetPage(
    name: AppRoutes.budget,
    page: () => const BudgetPage(),
    binding: BudgetBinding(),
  ),
  GetPage(
    name: AppRoutes.recurring,
    page: () => const RecurringPage(),
    binding: RecurringBinding(),
  ),
  GetPage(
    name: AppRoutes.settings,
    page: () => const SettingsPage(),
  ),
  GetPage(
    name: AppRoutes.allExpenses,
    page: () => const AllExpensesPage(),
  ),
  GetPage(
    name: AppRoutes.forgotPassword,
    page: () => const ForgotPasswordPage(),
  ),
];
