import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/repositories/wallet_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/services/auth_service.dart';
import 'category_management_screen.dart';
import 'wallet_management_screen.dart';
import 'package:xpanse/features/auth/presentation/screens/splash_screen.dart';
import 'package:xpanse/features/auth/presentation/screens/login_screen.dart';
import 'package:xpanse/data/services/firestore_service.dart';
import '../../../../data/models/transaction.dart';
import '../../../../data/models/budget.dart';

import '../../../../data/services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);
    ref.watch(transactionsStreamProvider); // monitor transactions for real-time wallet balance updates
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileSection(context, ref),
            const SizedBox(height: 32),
            _buildSettingsGroup('Account', [
              _buildSettingItem(
                Iconsax.user_copy, 
                'Personal Information',
                onTap: () => _showPersonalInformationDialog(context, ref),
              ),
              _buildSettingItem(
                Iconsax.wallet_2_copy, 
                'Wallets Management',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletManagementScreen())),
              ),
              _buildSettingItem(
                Iconsax.category_copy, 
                'Categories',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagementScreen())),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsGroup('Preferences', [
              _buildSettingItem(
                Iconsax.global_copy, 
                'Currency', 
                trailing: settings.currency,
                onTap: () => _showCurrencyPicker(context),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSettingsGroup('Danger Zone', [
              _buildSettingItem(
                Iconsax.trash_copy, 
                'Clear All Data', 
                color: AppColors.expense,
                onTap: () => _showClearDataDialog(context, ref),
              ),
              _buildSettingItem(
                Iconsax.user_remove_copy, 
                'Delete Account', 
                color: AppColors.expense,
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            ]),
            const SizedBox(height: 40),
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  void _showPersonalInformationDialog(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.read(userDisplayNameProvider);
    final controller = TextEditingController(text: nameAsync.valueOrNull ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Edit Profile', style: AppTypography.heading2),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final user = ref.read(authServiceProvider).currentUser;
                if (user != null) {
                  await user.updateDisplayName(newName);
                  await ref.read(firestoreServiceProvider).saveUserProfile(user.uid, newName, user.email ?? '');
                  ref.invalidate(userDisplayNameProvider);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final settings = ref.read(settingsServiceProvider);
    final currencies = ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'JPY (¥)'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Currency', style: AppTypography.heading2),
            const SizedBox(height: 16),
            ...currencies.map((c) => ListTile(
              title: Text(c, style: AppTypography.bodyMedium),
              trailing: settings.currency == c ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () async {
                await settings.setCurrency(c);
                if (context.mounted) Navigator.pop(context);
                setState(() {});
              },
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Clear All Data?', style: AppTypography.heading2.copyWith(color: AppColors.expense)),
        content: Text('This will delete all your transactions, budgets, and custom categories. Are you sure?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close first dialog
              _showFinalConfirmationDialog(context, ref);
            },
            child: Text('Next', style: AppTypography.bodyMedium.copyWith(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Last Warning!', style: AppTypography.heading2.copyWith(color: AppColors.expense)),
        content: Text('This action cannot be undone. Are you absolutely certain?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, Stop!', style: AppTypography.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              await _performDataClear(ref);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Yes, Clear Everything', style: AppTypography.bodyMedium.copyWith(color: AppColors.expense, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataClear(WidgetRef ref) async {
    // Clear Transactions and Budgets entirely
    await Hive.box<Transaction>('transactions').clear();
    await Hive.box<Budget>('budgets').clear();
    
    // Clear and Re-seed Categories and Wallets
    await ref.read(categoryRepositoryProvider).seedDefaultCategories(force: true);
    await ref.read(walletRepositoryProvider).seedDefaultWallets(force: true);
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Delete your account?', style: AppTypography.heading2.copyWith(color: AppColors.expense)),
        content: const Text(
          'This will permanently delete your profile, transactions, and all synced data. You cannot undo this action.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showReauthenticateDialog(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReauthenticateDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final user = ref.read(authServiceProvider).currentUser;
    bool isGoogleUser = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(isGoogleUser ? 'Confirm with Google' : 'Confirm Identity', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isGoogleUser 
                  ? 'Please sign in with Google again to confirm account deletion.'
                  : 'Please enter your account password to confirm account deletion.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (!isGoogleUser) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter account password',
                    prefixIcon: Icon(Iconsax.lock_copy, size: 20),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final password = passwordController.text.trim();
                if (!isGoogleUser && password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password is required')),
                  );
                  return;
                }

                setDialogState(() => isLoading = true);
                try {
                  final authService = ref.read(authServiceProvider);
                  
                  // Step 2: Re-authenticate
                  if (isGoogleUser) {
                    await authService.reauthenticate();
                  } else {
                    await authService.reauthenticate(password: password);
                  }
                  
                  // Step 3: Delete data & account
                  await _performDataClear(ref);
                  await authService.deleteAccount();

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  if (context.mounted) {
                    String error = e.toString();
                    if (error.contains('wrong-password')) {
                      error = 'Incorrect password. Please enter the password you set for this account.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: AppColors.expense),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isGoogleUser ? 'Confirm with Google' : 'Confirm Delete', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final nameAsync = ref.watch(userDisplayNameProvider);
    final displayName = nameAsync.valueOrNull?.trim().isNotEmpty == true ? nameAsync.value : null;
    final email = user?.email ?? '';

    // Avatar initial: pehle display name ka pehla letter, warna email ka.
    String avatarInitial = '';
    if (displayName != null && displayName.trim().isNotEmpty) {
      avatarInitial = displayName.trim()[0].toUpperCase();
    } else if (email.isNotEmpty) {
      avatarInitial = email.trim()[0].toUpperCase();
    }

    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                avatarInitial.isNotEmpty ? avatarInitial : 'U',
                style: AppTypography.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName ?? 'Guest User',
            style: AppTypography.heading2,
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.sms_copy, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      email,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (user == null)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              child: Text('Login to sync your data', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
            ),
          
          if (user != null) ...[
            const SizedBox(height: 32),
            _buildMyWalletsProfile(context, ref),
          ],
        ],
      ),
    );
  }

  static Widget _buildMyWalletsProfile(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsStreamProvider).value ?? [];
    final txRepo = ref.read(transactionRepositoryProvider);
    final currency = ref.watch(settingsServiceProvider).currencySymbol;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Wallets', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletManagementScreen())),
              child: Text('Manage', style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: wallets.isEmpty 
            ? Center(child: Text('No wallets found', style: AppTypography.bodySmall))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final w = wallets[index];
                  final balance = txRepo.getTotalBalance(walletId: w.id);
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(w.name, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary), maxLines: 1),
                        const SizedBox(height: 4),
                        Text('$currency${balance.toStringAsFixed(0)}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {bool hasSwitch = false, bool value = false, ValueChanged<bool>? onChanged, String? trailing, VoidCallback? onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTypography.bodyMedium.copyWith(color: color))),
            if (trailing != null)
              Text(trailing, style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
            if (hasSwitch)
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
              ),
            if (!hasSwitch && trailing == null)
              Icon(Iconsax.arrow_right_3_copy, size: 16, color: color ?? AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  static Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    return TextButton(
      onPressed: () async {
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (route) => false,
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.logout_copy, color: AppColors.expense, size: 20),
          const SizedBox(width: 8),
          Text('Logout', style: AppTypography.bodyMedium.copyWith(color: AppColors.expense, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
