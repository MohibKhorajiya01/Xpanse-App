import 'package:flutter/material.dart';
import 'package:xpanse/core/utils/icon_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../data/models/transaction.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/wallet.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/repositories/wallet_repository.dart';
import 'package:xpanse/data/services/settings_service.dart';

import '../../../../data/services/auth_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final bool initialIsIncome;
  const AddTransactionScreen({super.key, this.initialIsIncome = false});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  late bool _isIncome;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialIsIncome;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: _isIncome ? AppColors.primary.withValues(alpha: 0.1) : AppColors.expense.withValues(alpha: 0.1),
        title: Text(
          _isIncome ? 'Add Income' : 'Add Expense',
          style: AppTypography.heading2.copyWith(
            color: _isIncome ? AppColors.primary : AppColors.expense,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.close_circle_copy, color: _isIncome ? AppColors.primary : AppColors.expense),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 32),
            _buildAmountInput(),
            const SizedBox(height: 32),
            _buildTextField(label: 'Title', controller: _titleController, icon: Iconsax.edit_2_copy),
            const SizedBox(height: 24),
            _buildSelector(
              label: 'Category',
              value: _selectedCategory?.name ?? 'Select Category',
              icon: Iconsax.category_copy,
              onTap: _showCategoryPicker,
            ),
            const SizedBox(height: 24),
            _buildSelector(
              label: 'Wallet',
              value: _selectedWallet?.name ?? 'Select Wallet',
              icon: Iconsax.wallet_copy,
              onTap: _showWalletPicker,
            ),
            const SizedBox(height: 24),
            _buildSelector(
              label: 'Date',
              value: DateFormat('MMM dd, yyyy').format(_selectedDate),
              icon: Iconsax.calendar_copy,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 48),
            AppButton(
              label: _isIncome ? 'Save Income' : 'Save Expense',
              color: AppColors.primary,
              onPressed: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem('Expense', !_isIncome)),
          Expanded(child: _buildToggleItem('Income', _isIncome)),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_isIncome != (label == 'Income')) {
          setState(() {
            _isIncome = label == 'Income';
            _selectedCategory = null; // Reset category when switching type
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.buttonLabel.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How much?', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (_isIncome ? AppColors.primary : AppColors.expense).withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isIncome ? AppColors.primary : AppColors.expense).withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                ref.watch(settingsServiceProvider).currencySymbol,
                style: AppTypography.heading1.copyWith(
                  fontSize: 40,
                  color: _isIncome ? AppColors.primary : AppColors.expense,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTypography.heading1.copyWith(
                      fontSize: 40,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: AppTypography.heading1.copyWith(
                    fontSize: 40,
                    color: _isIncome ? AppColors.primary : AppColors.expense,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: 'Enter $label',
          ),
        ),
      ],
    );
  }

  Widget _buildSelector({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            borderRadius: 16,
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(value, style: AppTypography.bodyMedium),
                const Spacer(),
                const Icon(Iconsax.arrow_right_3_copy, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Select Category', style: AppTypography.heading2),
                const SizedBox(height: 16),
                Flexible(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final categoriesAsync = ref.watch(categoriesStreamProvider);
                      
                      return categoriesAsync.when(
                        data: (categoryList) {
                          final categories = categoryList.where((c) => c.isExpense == !_isIncome).toList();
                          
                          if (categories.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text('No categories found', style: AppTypography.bodySmall),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: categories.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategory?.id == cat.id;
                              return ListTile(
                                onTap: () {
                                  setState(() => _selectedCategory = cat);
                                  Navigator.pop(context);
                                },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceDark,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(cat.colorValue).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(iconDataFromCodepoint(cat.iconCodepoint), color: Color(cat.colorValue), size: 20),
                                ),
                                title: Text(cat.name, style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.textPremium,
                                )),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null,
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )),
                        error: (err, stack) => Center(child: Text('Error: $err')),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWalletPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Select Wallet', style: AppTypography.heading2),
                const SizedBox(height: 16),
                Flexible(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final walletsAsync = ref.watch(walletsStreamProvider);
                      
                      return walletsAsync.when(
                        data: (wallets) {
                          if (wallets.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text('No wallets found', style: AppTypography.bodySmall),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: wallets.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final wallet = wallets[index];
                              final isSelected = _selectedWallet?.id == wallet.id;
                              return ListTile(
                                onTap: () {
                                  setState(() => _selectedWallet = wallet);
                                  Navigator.pop(context);
                                },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceDark,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(wallet.colorValue).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(iconDataFromCodepoint(wallet.iconCodepoint), color: Color(wallet.colorValue), size: 20),
                                ),
                                title: Text(wallet.name, style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.textPremium,
                                )),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null,
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )),
                        error: (err, stack) => Center(child: Text('Error: $err')),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveTransaction() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add transactions!'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || _titleController.text.isEmpty || _selectedCategory == null || _selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid details, category and wallet')));
      return;
    }

    final repo = ref.read(transactionRepositoryProvider);
    
    // Balance validation for expenses
    if (!_isIncome) {
      final currentBalance = repo.getTotalBalance(walletId: _selectedWallet!.id);
      if (amount > currentBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient balance in selected wallet!'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
        return;
      }
    }

    final transaction = Transaction(
      title: _titleController.text,
      amount: amount,
      date: _selectedDate,
      categoryId: _selectedCategory!.id,
      isIncome: _isIncome,
      walletId: _selectedWallet!.id,
    );

    await repo.addTransaction(transaction);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_isIncome ? 'Income' : 'Expense'} added successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }
}
