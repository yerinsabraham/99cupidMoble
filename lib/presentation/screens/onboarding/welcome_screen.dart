import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_button.dart';

/// Welcome Screen - Shows for first-time users after signup
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top spacing
              const SizedBox(height: 20),
              
              // Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Okay, Real Talk 💬',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepPlum,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Main message
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? AppColors.cupidPink.withOpacity(0.1)
                          : AppColors.cupidPink.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cupidPink.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMessageText(
                            'We built this because dating apps got too expensive.',
                            isDark,
                            isFirst: true,
                          ),
                          const SizedBox(height: 20),
                          _buildMessageText(
                            'My wife and I met online — Philippines to Canada — and we wanted to make sure no one else had to pay ridiculous prices just to meet someone.',
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildMessageText(
                            'We\'re brand new, so it\'s a little quiet right now.\nBut you paid nothing to be here and only 99¢ a month for full access.',
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cupidPink.withOpacity(0.15),
                                  AppColors.deepPlum.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: AppColors.cupidPink,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your profile will be featured as new members join.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : AppColors.deepPlum,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Thanks for being early. That matters.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cupidPink,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom button
              Column(
                children: [
                  AppButton(
                    text: 'Start searching for love →',
                    onPressed: () {
                      context.go('/onboarding/setup');
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Let\'s create your profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                        ? Colors.white.withOpacity(0.6)
                        : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageText(String text, bool isDark, {bool isFirst = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white.withOpacity(0.9) : AppColors.grey800,
        height: 1.6,
        fontWeight: isFirst ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }
}
