import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCodepoint;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final bool isExpense;

  Category({
    String? id,
    required this.name,
    required this.iconCodepoint,
    required this.colorValue,
    required this.isExpense,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodepoint': iconCodepoint,
      'colorValue': colorValue,
      'isExpense': isExpense,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String?,
      name: map['name'] as String,
      iconCodepoint: map['iconCodepoint'] as int,
      colorValue: map['colorValue'] as int,
      isExpense: map['isExpense'] as bool,
    );
  }
}
