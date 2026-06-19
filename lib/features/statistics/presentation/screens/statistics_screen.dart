import 'package:fl_chart/fl_chart.dart';
import 'package:xpanse/core/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpanse/core/theme/app_colors.dart';
import 'package:xpanse/core/theme/app_typography.dart';
import 'package:xpanse/data/models/category.dart';
import 'package:xpanse/data/repositories/category_repository.dart';
import 'package:xpanse/data/repositories/transaction_repository.dart';
import 'package:intl/intl.dart';
import 'package:xpanse/data/services/settings_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _touchedIndex = -1;
  bool _showIncome = false;

  get currencySymbol => null;

  @override
  Widget build(BuildContext context) {
    // Watch stream to rebuild on any changes
    ref.watch(transactionsStreamProvider);
    
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final currencySymbol = ref.watch(settingsServiceProvider).currencySymbol;
    
    final allTransactions = transactionRepo.getAllTransactions();
    final items = allTransactions.where((t) => t.isIncome == _showIncome).toList();
    final total = items.fold(0.0, (sum, t) => sum + t.amount);
    
    final allCategories = categoryRepo.getCategories(isExpense: !_showIncome);
    final Map<String, double> categoryData = {};
    
    for (var tx in items) {
      categoryData[tx.categoryId] = (categoryData[tx.categoryId] ?? 0) + tx.amount;
    }

    final List<Map<String, dynamic>> breakdownData = [];
    for (var cat in allCategories) {
      final amount = categoryData[cat.id] ?? 0;
      if (amount > 0) {
        breakdownData.add({
          'category': cat,
          'amount': amount,
          'percentage': total > 0 ? (amount / total) * 100 : 0.0,
        });
      }
    }
    
    // Sort by amount descending
    breakdownData.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 32),
            breakdownData.isEmpty 
              ? SizedBox(
                  height: 300,
                  child: Center(child: Text('No ${_showIncome ? 'income' : 'expenses'} recorded yet', style: AppTypography.bodySmall))
                )
              : Column(
                  children: [
                    _buildChartSection(breakdownData, total, currencySymbol),
                    const SizedBox(height: 32),
                    _buildCategoryList(breakdownData, currencySymbol),
                  ],
                ),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionScreen(initialIsIncome: _showIncome),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Iconsax.add_copy, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem('Expense', !_showIncome)),
          Expanded(child: _buildToggleItem('Income', _showIncome)),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showIncome = label == 'Income'),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> data, double total, String currencySymbol) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _buildPieSections(data),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: AppTypography.heading2),
        Text(
          'Total ${_showIncome ? 'Income' : 'Spending'}: $currencySymbol${total.toStringAsFixed(2)}', 
          style: AppTypography.bodySmall.copyWith(color: _showIncome ? AppColors.income : AppColors.expense),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (i) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final category = data[i]['category'] as Category;

      return PieChartSectionData(
        color: Color(category.colorValue),
        value: data[i]['amount'],
        title: '',
        radius: radius,
        badgeWidget: _buildBadge(category.name, isTouched ? 60 : 45, Color(category.colorValue)),
        badgePositionPercentageOffset: .98,
      );
    });
  }

  Widget _buildBadge(String title, double size, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Text(
          title[0],
          style: TextStyle(
            fontSize: size * .4,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> data, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending Breakdown', style: AppTypography.heading2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        ...data.map((item) {
          final cat = item['category'] as Category;
          return _buildCategoryItem(
            cat.name, 
            '$currencySymbol${(item['amount'] as double).toStringAsFixed(0)}', 
            item['percentage'], 
            Color(cat.colorValue), 
            iconDataFromCodepoint(cat.iconCodepoint),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryItem(String title, String amount, double percentage, Color color, IconData icon) {
    return Container(
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              Text('${percentage.toInt()}%', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
