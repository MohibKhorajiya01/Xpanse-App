import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'wallet.g.dart';

@HiveType(typeId: 2)
class Wallet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double balance;

  @HiveField(3)
  final int iconCodepoint;

  @HiveField(4)
  final int colorValue;

  Wallet({
    String? id,
    required this.name,
    required this.balance,
    required this.iconCodepoint,
    required this.colorValue,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'iconCodepoint': iconCodepoint,
      'colorValue': colorValue,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String?,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      iconCodepoint: map['iconCodepoint'] as int,
      colorValue: map['colorValue'] as int,
    );
  }
}
