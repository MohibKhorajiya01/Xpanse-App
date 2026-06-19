import 'package:flutter/material.dart';
import 'package:xpanse/core/utils/icon_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:xpanse/core/theme/app_colors.dart';
import 'package:xpanse/core/theme/app_typography.dart';
import 'package:xpanse/core/widgets/glass_container.dart';
import 'package:xpanse/data/models/transaction.dart';
import 'package:xpanse/data/models/wallet.dart';
import 'package:xpanse/data/repositories/transaction_repository.dart';
import 'package:xpanse/data/repositories/wallet_repository.dart';
import 'package:xpanse/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:xpanse/features/dashboard/presentation/widgets/stock_line_chart.dart';
import 'package:xpanse/data/services/auth_service.dart';
import 'package:xpanse/data/services/settings_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    // Watch the stream provider to trigger rebuilds on ANY transaction change
    ref.watch(transactionsStreamProvider);
    ref.watch(authStateProvider);
    
    final repo = ref.read(transactionRepositoryProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final wallets = walletsAsync.value ?? [];
    
    final balance = repo.getTotalBalance(walletId: _selectedWalletId);
    final income = repo.getIncomeSummary(walletId: _selectedWalletId);
    final expense = repo.getExpenseSummary(walletId: _selectedWalletId);
    final currencySymbol = ref.watch(settingsServiceProvider).currencySymbol;

    var candleData = repo.getDailyCandleData(walletId: _selectedWalletId);
    if (candleData.every((day) => day['open'] == 0 && day['close'] == 0)) {
      // Mock data for better first look if no data for selected wallet
      candleData = [
        {'open': 5000, 'high': 6500, 'low': 4800, 'close': 6000},
        {'open': 6000, 'high': 7200, 'low': 5500, 'close': 5200},
        {'open': 5200, 'high': 8000, 'low': 5000, 'close': 7500},
        {'open': 7500, 'high': 9000, 'low': 7000, 'close': 8200},
        {'open': 8200, 'high': 10000, 'low': 8000, 'close': 9500},
      ];
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildWalletSwitcher(wallets),
              const SizedBox(height: 24),
              _buildBalanceCard(balance, income, expense, wallets, currencySymbol),
              const SizedBox(height: 32),
              _buildChartSection(candleData),
              const SizedBox(height: 32),
              _buildRecentTransactionsHeader(context),
              const SizedBox(height: 16),
              _buildRecentTransactionsList(ref, wallets, currencySymbol),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {

    final nameAsync = ref.watch(userDisplayNameProvider);
    // Sirf signup wala name - Firestore/Firebase se, email kabhi nahi
    final userName = nameAsync.valueOrNull?.trim().isNotEmpty == true ? nameAsync.value! : 'Guest';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning,', style: AppTypography.bodySmall),
            Text(userName, style: AppTypography.heading2),
          ],
        ),
        GlassContainer(
          width: 48,
          height: 48,
          borderRadius: 14,
          child: const Icon(Iconsax.notification_copy, size: 22),
        ),
      ],
    );
  }

  Widget _buildWalletSwitcher(List<Wallet> wallets) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildWalletChip(null, 'All'),
          ...wallets.map((w) => _buildWalletChip(w.id, w.name)),
        ],
      ),
    );
  }

  Widget _buildWalletChip(String? id, String name) {
    final isSelected = _selectedWalletId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedWalletId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.glassBorder,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          name,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense, List<Wallet> wallets, String currencySymbol) {
    String walletName = 'Total Balance';
    if (_selectedWalletId != null) {
      final wallet = wallets.cast<Wallet?>().firstWhere(
        (w) => w?.id == _selectedWalletId,
        orElse: () => null,
      );
      if (wallet != null) {
        walletName = wallet.name;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(walletName, style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$currencySymbol${balance.toStringAsFixed(2)}', style: AppTypography.heading1.copyWith(fontSize: 36, color: Colors.white)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Income', income, Iconsax.arrow_up_copy, AppColors.income, currencySymbol),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem('Expense', expense, Iconsax.arrow_down_copy, AppColors.expense, currencySymbol),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, IconData icon, Color color, String currencySymbol) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 12)),
            Text('$currencySymbol${amount.toStringAsFixed(0)}', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(List<Map<String, double>> candleData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portfolio Performance', style: AppTypography.heading2.copyWith(fontSize: 20)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildIndicator('Profit', AppColors.income),
            const SizedBox(width: 16),
            _buildIndicator('Loss', AppColors.expense),
            const Spacer(),
            Text('Last 7 Days', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: StockLineChart(candleData: candleData),
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent Transactions', style: AppTypography.heading2.copyWith(fontSize: 20)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
            );
          },
          child: Text('See All', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList(WidgetRef ref, List<Wallet> wallets, String currencySymbol) {
    final transactions = ref.watch(transactionRepositoryProvider).getAllTransactions()
        .where((t) => _selectedWalletId == null || t.walletId == _selectedWalletId)
        .take(5).toList();
    
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('No transactions yet', style: AppTypography.bodySmall),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(transactions[index], wallets, currencySymbol);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction, List<Wallet> wallets, String currencySymbol) {
    final wallet = wallets.cast<Wallet?>().firstWhere(
      (w) => w?.id == transaction.walletId,
      orElse: () => null,
    );

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction.isIncome ? Iconsax.arrow_up_copy : Iconsax.shopping_bag_copy,
              color: transaction.isIncome ? AppColors.income : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (wallet != null) ...[
                      Icon(
                        iconDataFromCodepoint(wallet.iconCodepoint),
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          wallet.name,
                          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isIncome ? '+' : '-'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: transaction.isIncome ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('hh:mm a').format(transaction.date), style: AppTypography.bodySmall),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showTransactionActions(transaction),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransactionActions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('Transaction Options', style: AppTypography.heading2),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.trash_copy, color: AppColors.expense, size: 20),
              ),
              title: Text('Delete Transaction', style: AppTypography.bodyMedium.copyWith(color: AppColors.expense, fontWeight: FontWeight.bold)),
              subtitle: Text('This action cannot be undone', style: AppTypography.bodySmall),
              onTap: () {
                Navigator.pop(context); // close sheet
                _showDeleteConfirmation(transaction); // open final confirmation
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Are you sure?', style: AppTypography.heading2),
        content: Text(
          'Do you really want to delete "${transaction.title}"? Your balance will be adjusted accordingly.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodySmall),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: () {
                ref.read(transactionRepositoryProvider).deleteTransaction(transaction.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
