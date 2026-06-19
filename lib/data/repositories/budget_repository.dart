import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/budget.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref));

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final box = Hive.box<Budget>('budgets');
  return box.watch().map((_) => box.values.toList());
});

class BudgetRepository {
  final Ref _ref;
  final _box = Hive.box<Budget>('budgets');

  BudgetRepository(this._ref);

  List<Budget> getAllBudgets() {
    return _box.values.toList();
  }

  Future<void> saveBudget(Budget budget) async {
    // If a budget already exists for this category, reuse its ID to avoid duplicates
    final existing = getBudgetForCategory(budget.categoryId);
    final budgetToSave = existing != null 
      ? Budget(
          id: existing.id,
          categoryId: budget.categoryId,
          limitAmount: budget.limitAmount,
          startDate: budget.startDate,
          endDate: budget.endDate,
        )
      : budget;

    await _box.put(budgetToSave.id, budgetToSave);

    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).saveBudget(user.uid, budgetToSave);
      } catch (_) {}
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    await _box.delete(budgetId);

    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).deleteBudget(user.uid, budgetId);
      } catch (_) {}
    }
  }

  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _box.values.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }
}
