import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:xpanse/core/theme/app_colors.dart';
import 'package:xpanse/core/theme/app_typography.dart';
import 'package:xpanse/core/widgets/glass_container.dart';
import 'package:xpanse/features/dashboard/presentation/screens/main_navigation_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _pin = '';
  final String _correctPin = '1234'; // Dummy PIN for demonstration

  void _onNumberTap(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() async {
    if (_pin == _correctPin) {
      // Success animation then navigate
      await Future.delayed(200.ms);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } else {
      // Shake animation and reset
      setState(() {
        _pin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Iconsax.lock_1_copy, size: 48, color: AppColors.primary)
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('Enter Security PIN', style: AppTypography.heading2),
            const SizedBox(height: 8),
            Text('Enter your 4-digit PIN to continue', style: AppTypography.bodySmall),
            
            const Spacer(),
            
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? AppColors.primary : AppColors.glassBorder,
                    boxShadow: index < _pin.length 
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 8)] 
                      : null,
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 20),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 20),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKeypadButton(
                        icon: Iconsax.finger_scan_copy,
                        onTap: () {
                          // Trigger Biometric
                        },
                      ),
                      _buildKeypadButton(text: '0', onTap: () => _onNumberTap('0')),
                      _buildKeypadButton(
                        icon: Iconsax.close_circle_copy,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: numbers.map((n) => _buildKeypadButton(text: n, onTap: () => _onNumberTap(n))).toList(),
    );
  }

  Widget _buildKeypadButton({String? text, IconData? icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        width: 72,
        height: 72,
        borderRadius: 20,
        child: Center(
          child: text != null
              ? Text(text, style: AppTypography.heading2)
              : Icon(icon, color: AppColors.textPremium, size: 28),
        ),
      ),
    );
  }
}

class LocalAuthentication {
}
