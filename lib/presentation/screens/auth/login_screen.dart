import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Login Screen - Mobile-optimized authentication UI
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Check user profile and navigate accordingly
  Future<void> _navigateAfterAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists && userDoc.data()?['profileSetupComplete'] == true) {
        context.go('/home');
      } else {
        context.go('/onboarding/setup');
      }
    } catch (e) {
      debugPrint('Error checking profile: $e');
      if (mounted) context.go('/onboarding/setup');
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    
    if (success) {
      await _navigateAfterAuth();
    } else {
      if (mounted) {
        // Get user-friendly error message from auth state
        final errorMessage = ref.read(authNotifierProvider).error ?? 
            'Login failed. Please try again.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    
    if (success) {
      await _navigateAfterAuth();
    } else {
      if (mounted) {
        final errorMessage = ref.read(authNotifierProvider).error ?? 
            'Google sign-in failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Image.asset(AppAssets.logo, width: 50, fit: BoxFit.contain),
                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      AppStrings.appTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.grey600),
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    AppTextField(
                      controller: _emailController,
                      hintText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.emailRequired;
                        }
                        if (!value.contains('@')) {
                          return AppStrings.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    AppTextField(
                      controller: _passwordController,
                      hintText: AppStrings.password,
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.passwordRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.push('/forgot-password');
                        },
                        child: Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(
                            color: AppColors.cupidPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    AppButton(
                      text: AppStrings.login,
                      onPressed: authState.isLoading ? null : _handleEmailLogin,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.grey300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.grey300)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Sign In Button
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : _handleGoogleLogin,
                      icon: Image.asset(
                        AppAssets.googleIcon,
                        height: 24,
                        width: 24,
                      ),
                      label: Text(AppStrings.continueWithGoogle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.grey800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.grey300),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.dontHaveAccount,
                          style: TextStyle(color: AppColors.grey600),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/signup');
                          },
                          child: Text(
                            AppStrings.signup,
                            style: TextStyle(
                              color: AppColors.cupidPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
