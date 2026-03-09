import '../core/services/storage/storage_service.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const wallets = '/wallets';
  static const budget = '/budget';
  static const analytics = '/analytics';
  static const recurring = '/recurring';
  static const settings = '/settings';
  static const allExpenses = '/all-expenses';
  static const transferHistory = '/transfer-history'; // new

  static String get initialRoute {
    final hasUser = StorageService.userId.isNotEmpty;
    final rememberMe = StorageService.rememberMe;
    if (hasUser && rememberMe) return dashboard;
    return signIn;
  }
}
