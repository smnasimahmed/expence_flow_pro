import 'package:mockito/annotations.dart';
import 'package:expence_flow_pro/features/auth/repository/auth_repository.dart';
import 'package:expence_flow_pro/features/expense/repository/expense_repository.dart';
import 'package:expence_flow_pro/features/wallet/repository/wallet_repository.dart';
import 'package:expence_flow_pro/features/wallet/controller/wallet_controller.dart';
import 'package:expence_flow_pro/features/budget/controller/budget_controller.dart';
import 'package:expence_flow_pro/features/recurring/controller/recurring_controller.dart';
import 'package:expence_flow_pro/features/sync/controller/sync_controller.dart';
import 'package:expence_flow_pro/features/transfer/repository/transfer_repository.dart';
import 'package:expence_flow_pro/core/services/connectivity/connectivity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Run `dart run build_runner build --delete-conflicting-outputs` to generate mocks.
@GenerateMocks([
  AuthRepository,
  ExpenseRepository,
  WalletRepository,
  WalletController,
  BudgetRepository,
  BudgetController,
  RecurringRepository,
  TransferRepository,
  User,
])
void main() {}
