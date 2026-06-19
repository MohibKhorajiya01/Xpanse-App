import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/wallet.dart';
import '../../../../data/repositories/wallet_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import 'package:xpanse/data/services/settings_service.dart';
import '../../../../data/services/auth_service.dart';

class WalletManagementScreen extends ConsumerStatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  ConsumerState<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends ConsumerState<WalletManagementScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(transactionsStreamProvider); // watch for balance changes
    final wallets = ref.watch(walletsStreamProvider).value ?? [];
    final txRepo = ref.read(transactionRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          IconButton(
              icon: const Icon(Iconsax.add_square_copy),
              onPressed: () => _showAddWalletDialog()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ...wallets.map((w) {
            final currentBalance = txRepo.getTotalBalance(walletId: w.id);
            return Column(
              children: [
                _buildWalletCard(w, currentBalance),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet, double currentBalance) {
    return Dismissible(
      key: Key(wallet.id),
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
        ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(wallet.name, style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                const Icon(Iconsax.more_copy, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text('${ref.watch(settingsServiceProvider).currencySymbol}${currentBalance.toStringAsFixed(2)}',
                style: AppTypography.heading1.copyWith(color: Colors.white, fontSize: 28)),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('ID: ${wallet.id.substring(0, 4).toUpperCase()}',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                const Spacer(),
                const Icon(Iconsax.wallet_3_copy, color: Colors.white, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('New Wallet', style: AppTypography.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Wallet name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(hintText: 'Starting balance'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final bal = double.tryParse(balanceController.text) ?? 0;
              final user = ref.read(authServiceProvider).currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add wallets')));
                return;
              }
              if (name.isNotEmpty) {
                final wallet = Wallet(
                  name: name,
                  balance: bal,
                  iconCodepoint: 0xe69e,
                  colorValue: 0xFF6366F1,
                );
                ref.read(walletRepositoryProvider).addWallet(wallet);
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
