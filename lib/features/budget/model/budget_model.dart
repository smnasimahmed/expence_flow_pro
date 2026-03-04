import 'package:uuid/uuid.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String? categoryId; // null means total monthly budget
  final double amount;
  final int month;
  final int year;
  final bool isSynced;
  final DateTime lastModified;

  // Calculated field – not stored
  double spent;

  BudgetModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    this.isSynced = false,
    required this.lastModified,
    this.spent = 0,
  });

  // What percentage of budget is used (0.0 to 1.0+)
  double get usagePercent => amount == 0 ? 0 : spent / amount;

  double get remaining => amount - spent;

  bool get isWarning => usagePercent >= 0.8 && usagePercent < 1.0;
  bool get isExceeded => usagePercent >= 1.0;

  factory BudgetModel.create({
    required String userId,
    String? categoryId,
    required double amount,
    required int month,
    required int year,
  }) {
    return BudgetModel(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      month: month,
      year: year,
      isSynced: false,
      lastModified: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'categoryId': categoryId,
    'amount': amount,
    'month': month,
    'year': year,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory BudgetModel.fromFirestore(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      userId: map['userId'],
      categoryId: map['categoryId'],
      amount: (map['amount'] as num).toDouble(),
      month: map['month'],
      year: map['year'],
      isSynced: true,
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
    );
  }
}
