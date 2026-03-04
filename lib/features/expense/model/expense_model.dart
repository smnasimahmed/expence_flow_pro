import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String categoryId;
  final String walletId;
  final DateTime date;
  final String? notes;
  final bool isSynced;
  final bool isDeleted;
  final DateTime lastModified;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.notes,
    this.isSynced = false,
    this.isDeleted = false,
    required this.lastModified,
  });

  // Create a brand new expense (before saving)
  factory ExpenseModel.create({
    required String userId,
    required String title,
    required double amount,
    required String categoryId,
    required String walletId,
    required DateTime date,
    String? notes,
  }) {
    return ExpenseModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      amount: amount,
      categoryId: categoryId,
      walletId: walletId,
      date: date,
      notes: notes,
      isSynced: false,
      isDeleted: false,
      lastModified: DateTime.now(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'title': title,
    'amount': amount,
    'categoryId': categoryId,
    'walletId': walletId,
    'date': date.millisecondsSinceEpoch,
    'notes': notes,
    'isDeleted': isDeleted,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  // Create from Firestore map
  factory ExpenseModel.fromFirestore(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'],
      walletId: map['walletId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
      isSynced: true,
      isDeleted: map['isDeleted'] ?? false,
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
    );
  }

  // Create a copy with changed fields
  ExpenseModel copyWith({
    String? title,
    double? amount,
    String? categoryId,
    String? walletId,
    DateTime? date,
    String? notes,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastModified,
  }) {
    return ExpenseModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}
