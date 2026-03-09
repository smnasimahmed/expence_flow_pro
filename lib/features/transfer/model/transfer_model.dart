import 'package:uuid/uuid.dart';

// Represents a money move from one wallet to another
class TransferModel {
  final String id;
  final String userId;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String? notes;
  final DateTime date;
  final bool isSynced;
  final DateTime lastModified;

  // Filled in by controller for display — not stored in DB
  String fromWalletName;
  String toWalletName;

  TransferModel({
    required this.id,
    required this.userId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.notes,
    required this.date,
    this.isSynced = false,
    required this.lastModified,
    this.fromWalletName = '',
    this.toWalletName = '',
  });

  factory TransferModel.create({
    required String userId,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? notes,
  }) {
    return TransferModel(
      id: const Uuid().v4(),
      userId: userId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      notes: notes,
      date: DateTime.now(),
      isSynced: false,
      lastModified: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'fromWalletId': fromWalletId,
    'toWalletId': toWalletId,
    'amount': amount,
    'notes': notes,
    'date': date.millisecondsSinceEpoch,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory TransferModel.fromFirestore(Map<String, dynamic> map) {
    return TransferModel(
      id: map['id'],
      userId: map['userId'],
      fromWalletId: map['fromWalletId'],
      toWalletId: map['toWalletId'],
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isSynced: true,
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
    );
  }
}
