class AppStrings {
  AppStrings._();

  static const appName = 'ExpenseFlow';

  // Auth
  static const signIn = 'Sign In';
  static const signUp = 'Create Account';
  static const email = 'Email Address';
  static const password = 'Password';
  static const forgotPassword = 'Forgot Password?';
  static const rememberMe = 'Remember me';
  static const dontHaveAccount = "Don't have an account? ";
  static const alreadyHaveAccount = 'Already have an account? ';
  static const logout = 'Log Out';
  static const logoutConfirm = 'Are you sure you want to log out?';

  // Expense
  static const addExpense = 'Add Expense';
  static const editExpense = 'Edit Expense';
  static const deleteExpense = 'Delete Expense';
  static const expenseDeleted = 'Expense deleted';
  static const undo = 'UNDO';
  static const title = 'Title';
  static const amount = 'Amount';
  static const category = 'Category';
  static const wallet = 'Wallet';
  static const date = 'Date';
  static const notes = 'Notes (optional)';

  // Wallet
  static const addWallet = 'Add Wallet';
  static const totalBalance = 'Total Balance';
  static const walletDeleted = 'Wallet deleted';

  // Transfer
  static const transfer = 'Transfer';
  static const transferHistory = 'Transfer History';
  static const newTransfer = 'New Transfer';
  static const fromWallet = 'From Wallet';
  static const toWallet = 'To Wallet';
  static const transferDone = 'Transfer complete ✓';

  // Budget
  static const budget = 'Budget';
  static const budgetWarning = 'You have used 80% of your budget!';
  static const budgetExceeded = 'Budget exceeded!';

  // Errors
  static const pleaseEnterEmail = 'Please enter your email';
  static const pleaseEnterValidEmail = 'Please enter a valid email';
  static const pleaseEnterPassword = 'Please enter your password';
  static const pleaseEnterTitle = 'Please enter a title';
  static const pleaseEnterAmount = 'Please enter an amount';
  static const somethingWentWrong = 'Something went wrong. Try again.';

  // Sync
  static const syncing = 'Syncing...';
  static const syncDone = 'All data synced!';
  static const offline = 'You are offline. Data saved locally.';
}

class AppKeys {
  AppKeys._();
  static const rememberMe = 'remember_me';
  static const userId = 'user_id';
  static const userEmail = 'user_email';
  static const userName = 'user_name';
  static const lastSyncTime = 'last_sync_time';
  static const biometricEnabled = 'biometric_enabled';
  static const currency = 'currency';
}
