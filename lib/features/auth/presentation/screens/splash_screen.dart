import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/services/sync_service.dart';
import 'onboarding_screen.dart';
import 'package:xpanse/features/dashboard/presentation/screens/main_navigation_screen.dart';
import 'verify_email_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = await FirebaseAuth.instance.authStateChanges().first;

    if (user != null) {
      // perform synchronization before entering the main app
      try {
        await ref.read(syncServiceProvider).syncAll(user.uid);
      } catch (_) {
        // ignore errors, we still proceed
      }
    }

    Widget destination;
    if (user != null) {
      if (user.emailVerified || user.providerData.any((p) => p.providerId == 'google.com')) {
        destination = const MainNavigationScreen();
      } else {
        destination = const VerifyEmailScreen();
      }
    } else {
      destination = const OnboardingScreen();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: 500.ms,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.wallet_2_copy,
                size: 60,
                color: Colors.white,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .shimmer(delay: 800.ms, duration: 1.seconds),
            
            const SizedBox(height: 24),
            
            Text(
              'Xpanse',
              style: AppTypography.heading1.copyWith(
                letterSpacing: 2,
                fontSize: 40,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms)
            .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              'Premium Financial Management',
              style: AppTypography.bodySmall,
            )
            .animate()
            .fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
