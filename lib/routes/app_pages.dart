import 'package:get/get.dart';
import '../features/auth/view/sign_in_page.dart';
import '../features/auth/view/sign_up_page.dart';
import '../features/expense/view/dashboard_page.dart';
import '../features/wallet/view/wallets_page.dart';
import '../features/analytics/view/analytics_page.dart';
import '../features/auth/binding/auth_binding.dart';
import '../features/expense/binding/expense_binding.dart';
import '../features/wallet/binding/wallet_binding.dart';
import '../features/analytics/binding/analytics_binding.dart';
import '../core/utils/app_navbar.dart';
import 'app_routes.dart';

List<GetPage> appPages = [
  GetPage(
    name: AppRoutes.signIn,
    page: () => const SignInPage(),
    binding: AuthBinding(),
  ),
  GetPage(
    name: AppRoutes.signUp,
    page: () => const SignUpPage(),
    binding: AuthBinding(),
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
];
