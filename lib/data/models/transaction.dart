import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String categoryId;

  @HiveField(5)
  final bool isIncome;

  @HiveField(6)
  final String walletId;

  @HiveField(7)
  final String? note;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.isIncome,
    required this.walletId,
    this.note,
  }) : id = id ?? const Uuid().v4();

  /// Convert to a map for Firestore saving.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'isIncome': isIncome,
      'walletId': walletId,
      'note': note,
    };
  }

  /// Create a Transaction from a Firestore map.
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['categoryId'] as String,
      isIncome: map['isIncome'] as bool,
      walletId: map['walletId'] as String,
      note: map['note'] as String?,
    );
  }
}
