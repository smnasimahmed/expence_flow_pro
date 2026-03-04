import 'package:uuid/uuid.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String walletId;
  final String categoryId;
  final RecurringFrequency frequency;
  final DateTime nextExecutionDate;
  final bool isActive;
  final bool isSynced;
  final DateTime lastModified;

  RecurringModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.walletId,
    required this.categoryId,
    required this.frequency,
    required this.nextExecutionDate,
    this.isActive = true,
    this.isSynced = false,
    required this.lastModified,
  });

  factory RecurringModel.create({
    required String userId,
    required String title,
    required double amount,
    required String walletId,
    required String categoryId,
    required RecurringFrequency frequency,
    required DateTime startDate,
  }) {
    return RecurringModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      amount: amount,
      walletId: walletId,
      categoryId: categoryId,
      frequency: frequency,
      nextExecutionDate: startDate,
      isActive: true,
      isSynced: false,
      lastModified: DateTime.now(),
    );
  }

  // Advance the next execution date based on frequency
  DateTime get nextAfterExecution {
    switch (frequency) {
      case RecurringFrequency.daily:
        return nextExecutionDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return nextExecutionDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(
          nextExecutionDate.year,
          nextExecutionDate.month + 1,
          nextExecutionDate.day,
        );
      case RecurringFrequency.yearly:
        return DateTime(
          nextExecutionDate.year + 1,
          nextExecutionDate.month,
          nextExecutionDate.day,
        );
    }
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'title': title,
    'amount': amount,
    'walletId': walletId,
    'categoryId': categoryId,
    'frequency': frequency.name,
    'nextExecutionDate': nextExecutionDate.millisecondsSinceEpoch,
    'isActive': isActive,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory RecurringModel.fromFirestore(Map<String, dynamic> map) {
    return RecurringModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      walletId: map['walletId'],
      categoryId: map['categoryId'],
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      nextExecutionDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextExecutionDate'],
      ),
      isActive: map['isActive'] ?? true,
      isSynced: true,
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
    );
  }

  RecurringModel copyWith({
    DateTime? nextExecutionDate,
    bool? isActive,
    bool? isSynced,
  }) {
    return RecurringModel(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      walletId: walletId,
      categoryId: categoryId,
      frequency: frequency,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      lastModified: DateTime.now(),
    );
  }
}
