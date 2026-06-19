import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:xpanse/core/theme/app_colors.dart';
import 'package:xpanse/core/widgets/glass_container.dart';
import 'package:xpanse/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'dashboard_screen.dart';
import 'package:xpanse/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:xpanse/features/budget/presentation/screens/budget_screen.dart';
import 'package:xpanse/features/settings/presentation/screens/settings_screen.dart';

import 'package:flutter_animate/flutter_animate.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const StatisticsScreen(), 
    const BudgetScreen(), 
    const SettingsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        child: GlassContainer(
          height: 70,
          borderRadius: 25,
          blur: 0, // Disable blur for faster performance on bottom nav
          color: AppColors.surfaceDark.withValues(alpha: 0.9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Iconsax.home_2_copy, Iconsax.home_copy),
              _buildNavItem(1, Iconsax.chart_21_copy, Iconsax.chart_copy),
              _buildNavItem(2, Iconsax.wallet_3_copy, Iconsax.wallet_copy),
              _buildNavItem(3, Iconsax.user_copy, Iconsax.user_copy),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ) : null,
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
