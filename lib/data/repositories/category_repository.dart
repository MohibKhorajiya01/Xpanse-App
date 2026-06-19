import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository(ref));

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) async* {
  final box = Hive.box<Category>('categories');
  yield box.values.toList();
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});

class CategoryRepository {
  final Ref _ref;
  final Box<Category> _box = Hive.box<Category>('categories');

  CategoryRepository(this._ref);

  List<Category> getCategories({bool? isExpense}) {
    final all = _box.values.toList();
    if (isExpense == null) return all;
    return all.where((c) => c.isExpense == isExpense).toList();
  }

  Future<void> addCategory(Category category) async {
    await _box.put(category.id, category);
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).saveCategory(user.uid, category);
      } catch (_) {}
    }
  }

  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).deleteCategory(user.uid, id);
      } catch (_) {}
    }
  }

  Future<void> seedDefaultCategories({bool force = false}) async {
    final defaults = [
      // --- Expense Categories ---
      Category(id: 'cat_food', name: 'Food & Dining', iconCodepoint: 0xe25a, colorValue: 0xFFF44336, isExpense: true),
      Category(id: 'cat_transport', name: 'Transport', iconCodepoint: 0xe52f, colorValue: 0xFF2196F3, isExpense: true),
      Category(id: 'cat_shopping', name: 'Shopping', iconCodepoint: 0xe8cc, colorValue: 0xFFFF9800, isExpense: true),
      Category(id: 'cat_groceries', name: 'Groceries', iconCodepoint: 0xe3c6, colorValue: 0xFF4CAF50, isExpense: true),
      Category(id: 'cat_bills', name: 'Bills & Utilities', iconCodepoint: 0xef4f, colorValue: 0xFF009688, isExpense: true),
      Category(id: 'cat_entertainment', name: 'Entertainment', iconCodepoint: 0xe405, colorValue: 0xFFE91E63, isExpense: true),
      Category(id: 'cat_health', name: 'Health', iconCodepoint: 0xe3f3, colorValue: 0xFF00BCD4, isExpense: true),
      Category(id: 'cat_travel', name: 'Travel', iconCodepoint: 0xe53d, colorValue: 0xFF673AB7, isExpense: true),
      Category(id: 'cat_others_exp', name: 'Others', iconCodepoint: 0xe142, colorValue: 0xFF607D8B, isExpense: true),

      // --- Income Categories ---
      Category(id: 'cat_salary', name: 'Salary', iconCodepoint: 0xe263, colorValue: 0xFF4CAF50, isExpense: false),
      Category(id: 'cat_business', name: 'Business', iconCodepoint: 0xe84f, colorValue: 0xFF00BCD4, isExpense: false),
      Category(id: 'cat_freelance', name: 'Freelance', iconCodepoint: 0xe7ef, colorValue: 0xFF3F51B5, isExpense: false),
      Category(id: 'cat_investment', name: 'Investment', iconCodepoint: 0xe850, colorValue: 0xFFFFC107, isExpense: false),
      Category(id: 'cat_bonus', name: 'Bonus', iconCodepoint: 0xe80e, colorValue: 0xFFFF5722, isExpense: false),
      Category(id: 'cat_others_inc', name: 'Others', iconCodepoint: 0xe142, colorValue: 0xFF607D8B, isExpense: false),
    ];

    if (force) {
      await _box.clear();
      for (var c in defaults) {
        await _box.put(c.id, c);
      }
      return;
    }

    // Check by ID instead of names to avoid duplicates if user renames them
    for (var c in defaults) {
      if (!_box.containsKey(c.id)) {
        await _box.put(c.id, c);
      }
    }
  }
}
