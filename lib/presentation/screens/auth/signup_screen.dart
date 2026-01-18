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

/// SignUp Screen - User registration
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created! Let\'s set up your profile.'),
            backgroundColor: AppColors.success,
          ),
        );
        // New users always go to onboarding
        context.go('/onboarding/setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      await _navigateAfterAuth();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google sign-in failed'),
            backgroundColor: AppColors.error,
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

                    // Title
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'Find your perfect match',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.grey600),
                    ),
                    const SizedBox(height: 28),

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
                        if (value.length < 6) {
                          return AppStrings.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    AppTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Sign Up Button
                    AppButton(
                      text: AppStrings.signup,
                      onPressed: authState.isLoading ? null : _handleSignUp,
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

                    // Google Sign Up Button
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : _handleGoogleSignUp,
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

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccount,
                          style: TextStyle(color: AppColors.grey600),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: Text(
                            AppStrings.login,
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
