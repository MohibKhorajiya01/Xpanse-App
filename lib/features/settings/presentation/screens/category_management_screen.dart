import 'package:flutter/material.dart';
import 'package:xpanse/core/utils/icon_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/category.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/services/auth_service.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final expenseCats = categories.where((c) => c.isExpense).toList();
    final incomeCats = categories.where((c) => !c.isExpense).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_square_copy),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildCategoryHeader('Expenses'),
          const SizedBox(height: 16),
          ...expenseCats.map((c) => _buildCategoryItem(c)),
          const SizedBox(height: 32),
          _buildCategoryHeader('Incomes'),
          const SizedBox(height: 16),
          ...incomeCats.map((c) => _buildCategoryItem(c)),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Text(
      title,
      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildCategoryItem(Category category) {
    return Dismissible(
      key: Key(category.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Iconsax.trash_copy, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconDataFromCodepoint(category.iconCodepoint),
                  color: Color(category.colorValue), size: 24),
            ),
            const SizedBox(width: 16),
            Text(category.name,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    bool isExpense = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('New Category', style: AppTypography.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Category name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Type:'),
                const SizedBox(width: 8),
                DropdownButton<bool>(
                  value: isExpense,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Expense')),
                    DropdownMenuItem(value: false, child: Text('Income')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => isExpense = v);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final user = ref.read(authServiceProvider).currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add categories')));
                return;
              }
              if (name.isNotEmpty) {
                final cat = Category(
                  name: name,
                  iconCodepoint: 0xe142,
                  colorValue: 0xFF607D8B,
                  isExpense: isExpense,
                );
                ref.read(categoryRepositoryProvider).addCategory(cat);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
