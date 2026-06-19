import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:xpanse/core/utils/icon_helper.dart';
import 'package:xpanse/core/theme/app_colors.dart';
import 'package:xpanse/core/theme/app_typography.dart';
import 'package:xpanse/core/widgets/glass_container.dart';
import 'package:xpanse/data/repositories/category_repository.dart';
import 'package:xpanse/data/repositories/transaction_repository.dart';
import '../../../../data/models/budget.dart';
import '../../../../data/models/category.dart';
import '../../../../data/repositories/budget_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xpanse/data/services/settings_service.dart';
import 'package:xpanse/data/services/auth_service.dart';


class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionRepo = ref.watch(transactionRepositoryProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);
    final budgetRepo = ref.watch(budgetRepositoryProvider);
    final currencySymbol = ref.watch(settingsServiceProvider).currencySymbol;

    final allTransactions = transactionRepo.getAllTransactions();
    final expenses = allTransactions.where((t) => !t.isIncome).toList();
    
    final budgets = budgetRepo.getAllBudgets();
    final categories = categoryRepo.getCategories(isExpense: true);

    double totalLimit = budgets.fold(0, (sum, b) => sum + b.limitAmount);
    double totalSpent = 0;

    final List<Map<String, dynamic>> budgetItems = [];
    for (var cat in categories) {
      final budget = budgetRepo.getBudgetForCategory(cat.id);
      if (budget != null) {
        final spent = expenses
            .where((t) => t.categoryId == cat.id)
            .fold(0.0, (sum, t) => sum + t.amount);
        totalSpent += spent;
        budgetItems.add({
          'category': cat,
          'budget': budget,
          'spent': spent,
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Budget Planning'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_square_copy), 
            onPressed: () => _showAddBudgetSheet(context, categories, currencySymbol),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildOverallProgress(totalLimit, totalSpent, currencySymbol),
            const SizedBox(height: 32),
            _buildBudgetList(budgetItems, currencySymbol),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext context, List<Category> categories, String currencySymbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => _AddBudgetSheet(
        categories: categories,
        currencySymbol: currencySymbol,
        onBudgetSaved: () => setState(() {}),
      ),
    );
  }

  Widget _buildOverallProgress(double limit, double spent, String currencySymbol) {
    final progress = limit > 0 ? (spent / limit) : 0.0;
    final percent = (progress * 100).clamp(0.0, 100.0).toInt();

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 25,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget', style: AppTypography.bodySmall),
              Text('$percent% Used', style: AppTypography.bodySmall.copyWith(
                color: progress > 0.9 ? AppColors.expense : AppColors.income
              )),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(progress > 0.9 ? AppColors.expense : AppColors.primary),
            borderRadius: BorderRadius.circular(5),
            minHeight: 12,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currencySymbol${spent.toStringAsFixed(0)} Spent', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              Text('$currencySymbol${limit.toStringAsFixed(0)} Limit', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(List<Map<String, dynamic>> items, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Budgets', style: AppTypography.heading2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('No budgets set yet', style: AppTypography.bodySmall),
          )),
        ...items.map((item) {
          final cat = item['category'] as Category;
          final budget = item['budget'] as Budget;
          final spent = item['spent'] as double;
          return _buildBudgetItem(cat.name, budget.limitAmount, spent, Color(cat.colorValue), iconDataFromCodepoint(cat.iconCodepoint), currencySymbol);
        }),
      ],
    );
  }

  Widget _buildBudgetItem(String title, double limit, double spent, Color color, IconData icon, String currencySymbol) {
    final progress = spent / limit;
    final isExceeded = spent > limit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExceeded ? AppColors.expense.withValues(alpha: 0.5) : AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(isExceeded 
                      ? 'Exceeded by $currencySymbol${(spent - limit).toStringAsFixed(0)}' 
                      : '$currencySymbol${(limit - spent).toStringAsFixed(0)} remaining', 
                      style: AppTypography.bodySmall.copyWith(color: isExceeded ? AppColors.expense : null)
                    ),
                  ],
                ),
              ),
              Text('$currencySymbol${spent.toStringAsFixed(0)}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(isExceeded ? AppColors.expense : color),
            borderRadius: BorderRadius.circular(2),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  final List<Category> categories;
  final String currencySymbol;
  final VoidCallback onBudgetSaved;

  const _AddBudgetSheet({
    required this.categories,
    required this.currencySymbol,
    required this.onBudgetSaved,
  });

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  Category? _selectedCategory;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to set budgets')));
      return;
    }
    
    if (_selectedCategory != null && _amountController.text.isNotEmpty) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final budget = Budget(
        categoryId: _selectedCategory!.id,
        limitAmount: amount,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      ref.read(budgetRepositoryProvider).saveBudget(budget);
      Navigator.pop(context);
      widget.onBudgetSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set Monthly Limit', style: AppTypography.heading2),
          const SizedBox(height: 20),
          DropdownButtonFormField<Category>(
            dropdownColor: AppColors.surfaceDark,
            decoration: InputDecoration(
              labelText: 'Select Category',
              labelStyle: AppTypography.bodySmall,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
            items: widget.categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat.name, style: AppTypography.bodyMedium),
            )).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTypography.heading2,
            decoration: InputDecoration(
              prefixText: '${widget.currencySymbol} ',
              labelText: 'Monthly Limit',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _saveBudget,
            child: const Text('Save Budget'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
