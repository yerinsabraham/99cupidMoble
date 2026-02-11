import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
import '../common/policy_webview_screen.dart';

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
  bool _acceptedTerms = false;

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

  void _openPolicyPage(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyWebViewScreen(
          title: title,
          url: url,
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to continue'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    
    final success = await ref
        .read(authNotifierProvider.notifier)
        .signUpWithEmail(
          email: email,
          password: _passwordController.text,
        );

    if (success) {
      if (mounted) {
        // Show verification email notification
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.mark_email_read,
                    color: isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verify Your Email',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.deepPlum,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A verification email has been sent to:',
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.7) : AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please check your inbox and verify your email address. '
                    'If you don\'t see the email, check your spam folder.',
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.7) : AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cupidPink.withOpacity(isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Make sure the email address is correct',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white.withOpacity(0.8) : AppColors.grey700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                AppButton(
                  text: 'Continue',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/onboarding/welcome');
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      if (mounted) {
        // Get user-friendly error message from auth state
        final errorMessage = ref.read(authNotifierProvider).error ?? 
            'Sign up failed. Please try again.';
        
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

  Future<void> _handleGoogleSignUp() async {
    final success = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    
    if (success) {
      await _navigateAfterAuth();
    } else {
      // Only show error if there's an actual error (not user cancellation)
      final errorMessage = ref.read(authNotifierProvider).error;
      if (mounted && errorMessage != null) {
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

  Future<void> _handleAppleSignUp() async {
    final success = await ref.read(authNotifierProvider.notifier).signInWithApple();
    
    if (success) {
      await _navigateAfterAuth();
    } else {
      // Only show error if there's an actual error (not user cancellation)
      final errorMessage = ref.read(authNotifierProvider).error;
      if (mounted && errorMessage != null) {
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
                        // Enhanced email validation
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return AppStrings.invalidEmail;
                        }
                        // Check for common typos/issues
                        final trimmedValue = value.trim();
                        if (trimmedValue.contains('..') || 
                            trimmedValue.startsWith('.') || 
                            trimmedValue.endsWith('.')) {
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
                          return AppStrings.confirmPasswordRequired;
                        }
                        if (value != _passwordController.text) {
                          return AppStrings.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Terms & Conditions Acceptance
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                            activeColor: AppColors.cupidPink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey700,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: AppColors.cupidPink,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _openPolicyPage(
                                            'Terms & Conditions',
                                            'https://99cupid.com/terms',
                                          ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppColors.cupidPink,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _openPolicyPage(
                                            'Privacy Policy',
                                            'https://99cupid.com/privacy-policy',
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    AppButton(
                      text: AppStrings.signup,
                      onPressed: (authState.isLoading || !_acceptedTerms) ? null : _handleSignUp,
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
                    const SizedBox(height: 16),

                    // Apple Sign Up Button
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : _handleAppleSignUp,
                      icon: Icon(
                        Icons.apple,
                        size: 24,
                        color: authState.isLoading ? AppColors.grey400 : AppColors.grey800,
                      ),
                      label: Text(AppStrings.continueWithApple),
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
