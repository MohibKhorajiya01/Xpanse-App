import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/firestore_service.dart';
import 'package:xpanse/features/dashboard/presentation/screens/main_navigation_screen.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  bool _canResendEmail = true;
  int _secondsLeft = 0;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final isVerified = await ref.read(authServiceProvider).isEmailVerified();
    if (isVerified && !_isVerified) {
      _timer?.cancel();
      setState(() => _isVerified = true);
      
      // Save profile only AFTER verification is successful
      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser != null) {
        await ref.read(firestoreServiceProvider).saveUserProfile(
          currentUser.uid,
          currentUser.displayName ?? 'User',
          currentUser.email ?? '',
        );
      }
      
      // Wait for success animation to play before redirecting
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      setState(() {
        _canResendEmail = false;
        _secondsLeft = 60;
      });
      
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft == 0) {
          timer.cancel();
          if (mounted) setState(() => _canResendEmail = true);
        } else {
          if (mounted) setState(() => _secondsLeft--);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New verification link sent to your inbox!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.expense),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.5, 0.5)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Verification State Icon
                  Center(
                    child: _isVerified 
                    ? _buildSuccessIcon()
                    : _buildWaitingIcon(),
                  ),

                  const SizedBox(height: 48),

                  // Status Text
                  Text(
                    _isVerified ? 'Verification Successful!' : 'Check your inbox',
                    style: AppTypography.heading1,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms),

                  const SizedBox(height: 16),

                  Text(
                    _isVerified 
                      ? 'Welcome to Xpanse! Redirecting to your dashboard...' 
                      : 'We have sent a verification link to:\n${user?.email ?? "your email"}',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  if (!_isVerified) ...[
                    // Instruction Card
                    _buildInstructionCard().animate().slideY(begin: 0.2, curve: Curves.easeOutBack),

                    const Spacer(),

                    // Actions
                    AppButton(
                      label: _canResendEmail ? 'Resend Verification Email' : 'Resend in ${_secondsLeft}s',
                      onPressed: _canResendEmail ? () => _resendVerificationEmail() : null,
                      color: _canResendEmail ? AppColors.primary : AppColors.surfaceDark,
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                      },
                      child: Text(
                        'Cancel & Sign Out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ] else ...[
                    const Spacer(),
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1500.ms)
           .fadeOut(duration: 1500.ms),

          const Icon(
            Iconsax.sms_tracking_copy,
            size: 60,
            color: AppColors.primary,
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.income,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 80,
        color: Colors.white,
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildInstructionCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        children: [
          _buildStepRow(1, 'Open your email application'),
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
            child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 20, color: Colors.white24)),
          ),
          _buildStepRow(2, 'Tap the verification link'),
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
            child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 20, color: Colors.white24)),
          ),
          _buildStepRow(3, 'Come back to this screen'),
        ],
      ),
    );
  }

  Widget _buildStepRow(int number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPremium),
          ),
        ),
      ],
    );
  }
}
