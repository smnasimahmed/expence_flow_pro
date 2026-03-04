import 'package:uuid/uuid.dart';

enum WalletType { cash, bank, savings, custom }

class WalletModel {
  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final double initialBalance;
  final String color;
  final bool isSynced;
  final bool isDeleted;
  final DateTime lastModified;

  // This is calculated on the fly – not stored
  double balance;

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.color = '#6C63FF',
    this.isSynced = false,
    this.isDeleted = false,
    required this.lastModified,
    this.balance = 0,
  });

  factory WalletModel.create({
    required String userId,
    required String name,
    required WalletType type,
    double initialBalance = 0,
    String color = '#6C63FF',
  }) {
    return WalletModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      type: type,
      initialBalance: initialBalance,
      color: color,
      isSynced: false,
      isDeleted: false,
      lastModified: DateTime.now(),
      balance: initialBalance,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type.name,
    'initialBalance': initialBalance,
    'color': color,
    'isDeleted': isDeleted,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory WalletModel.fromFirestore(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      type: WalletType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WalletType.cash,
      ),
      initialBalance: (map['initialBalance'] as num).toDouble(),
      color: map['color'] ?? '#6C63FF',
      isSynced: true,
      isDeleted: map['isDeleted'] ?? false,
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
    );
  }

  WalletModel copyWith({
    String? name,
    WalletType? type,
    double? initialBalance,
    String? color,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return WalletModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: DateTime.now(),
      balance: balance,
    );
  }

  String get typeLabel {
    switch (type) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bank:
        return 'Bank';
      case WalletType.savings:
        return 'Savings';
      case WalletType.custom:
        return 'Custom';
    }
  }
}
