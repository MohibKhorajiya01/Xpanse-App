import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../data/services/auth_service.dart';
import 'package:xpanse/features/dashboard/presentation/screens/main_navigation_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getAuthErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use': return 'This email is already registered.';
        case 'invalid-email': return 'Invalid email format.';
        case 'weak-password': return 'The password is too weak.';
        case 'network-request-failed': return 'Network error. Please check your internet connection.';
        default: return e.message ?? 'Signup failed.';
      }
    }
    return 'Signup failed. Please try again.';
  }

  Future<void> _handleSignup() async {
    setState(() => _hasSubmitted = true);
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signUp(
        email,
        password,
        displayName: name,
      );

      if (cred.user != null) {
        await ref.read(authServiceProvider).sendEmailVerification();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e)),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      
      if (cred != null && cred.user != null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildOrb(300, AppColors.primary.withValues(alpha: 0.05))),
          Positioned(bottom: -100, left: -100, child: _buildOrb(400, AppColors.primary.withValues(alpha: 0.03))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Column(
                      children: [
                        AppLogo(size: 48, fontSize: 32),
                        SizedBox(height: 16),
                        Text(
                          'Create a new account',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Form(
                    key: _formKey,
                    autovalidateMode: _hasSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Full Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: AppTypography.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Full name is required';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'John Doe',
                            prefixIcon: const Icon(Iconsax.user_copy, size: 20),
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        
                        const SizedBox(height: 20),
                        
                        _buildInputLabel('Email Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTypography.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email is required';
                            if (!value.contains('@')) return 'Please enter a valid email';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'hello@example.com',
                            prefixIcon: const Icon(Iconsax.sms_copy, size: 20),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: 20),
                        
                        _buildInputLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTypography.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Must be at least 6 characters';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Iconsax.lock_copy, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Iconsax.eye_copy : Iconsax.eye_slash_copy, size: 20),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  AppButton(
                    label: 'Sign Up',
                    isLoading: _isLoading,
                    onPressed: _handleSignup,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  
                  _buildGoogleButton().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: AppTypography.bodySmall),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                          child: Text('Login', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return InkWell(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/google_logo.png',
                height: 20,
                width: 20,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Iconsax.google_copy, size: 20, color: Colors.blue);
                },
              ),
            ),
            const SizedBox(width: 12),
            Text('Continue with Google', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textPremium, fontWeight: FontWeight.w600));
  }
}
