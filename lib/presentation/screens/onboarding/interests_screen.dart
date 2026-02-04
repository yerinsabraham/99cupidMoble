import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/app_button.dart';

/// Interests Selection Screen - Step 3: Choose interests
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  final Set<String> _selectedInterests = {};
  bool _isLoading = false;

  static const List<String> _availableInterests = [
    '🎬 Movies',
    '🎵 Music',
    '📚 Reading',
    '🎮 Gaming',
    '⚽ Sports',
    '🍳 Cooking',
    '✈️ Travel',
    '📸 Photography',
    '🎨 Art',
    '💪 Fitness',
    '🧘 Yoga',
    '🏃 Running',
    '🏊 Swimming',
    '🎭 Theater',
    '🎤 Singing',
    '💃 Dancing',
    '🍕 Food',
    '☕ Coffee',
    '🍷 Wine',
    '🌱 Nature',
    '🐕 Pets',
    '🎯 Darts',
    '♟️ Chess',
    '🎲 Board Games',
    '🎸 Guitar',
    '🥁 Drums',
    '🎹 Piano',
    '📱 Technology',
    '🔬 Science',
    '🌍 Environment',
    '🎓 Learning',
    '📖 Writing',
    '🎬 Netflix',
    '🍿 Cinema',
    '🎪 Comedy',
    '🎁 Shopping',
    '🌺 Gardening',
    '🚴 Cycling',
    '⛺ Camping',
    '🏔️ Hiking',
  ];

  Future<void> _complete() async {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 interests')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      if (user == null) {
        debugPrint('Interests: No user found!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in again')),
          );
          context.go('/login');
        }
        return;
      }
      
      debugPrint('Interests: User found: ${user.uid}');

      // Store interests in provider
      ref.read(onboardingProvider.notifier).setInterests(_selectedInterests.toList());

      // Get all onboarding data collected across all steps
      final onboardingData = ref.read(onboardingProvider);
      final profileData = onboardingData.toMap(user.uid, user.email ?? '');

      debugPrint('Interests: Saving complete profile data:');
      debugPrint('  - Name: ${profileData['displayName']}');
      debugPrint('  - Age: ${profileData['age']}');
      debugPrint('  - Gender: ${profileData['gender']}');
      debugPrint('  - Location: ${profileData['location']}');
      debugPrint('  - Bio: ${profileData['bio']}');
      debugPrint('  - Photos: ${profileData['photos']?.length ?? 0}');
      debugPrint('  - Interests: ${profileData['interests']?.length ?? 0}');
      debugPrint('  - Profile Complete: ${profileData['profileSetupComplete']}');

      // Save everything to Firestore in one operation
      await authService.updateUserProfile(user.uid, profileData);

      debugPrint('Interests: Profile saved successfully to Firestore');

      // Clear onboarding data
      ref.read(onboardingProvider.notifier).clear();

      if (mounted) {
        // Show success dialog
        await _showSuccessDialog();
        
        // Navigate to home screen
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving interests: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto-close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo
                Image.asset(
                  'assets/icons/applogo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                
                // Success message
                const Text(
                  'Profile Complete!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Celebration emoji
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 20),
                
                // Description
                const Text(
                  'Your profile has been saved successfully.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.deepPlum,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'You can edit it anytime from Settings.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.deepPlum.withOpacity(0.6),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Call to action
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cupidPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Let's start discovering matches!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cupidPink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepPlum),
          onPressed: () => context.go('/onboarding/photos'),
        ),
        title: const Text(
          'Your Interests',
          style: TextStyle(color: AppColors.deepPlum),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final authService = AuthService();
              await authService.signOut();
              if (mounted) context.go('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.cupidPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: AppColors.warmBlush,
                    valueColor: AlwaysStoppedAnimation(AppColors.cupidPink),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Step 3 of 3',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.deepPlum.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'What do you love?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Select at least 3 interests',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.deepPlum.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Interests grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(interest);
                          } else {
                            _selectedInterests.add(interest);
                          }
                        });
                      },
                      child: Chip(
                        label: Text(
                          interest,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.deepPlum,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? AppColors.cupidPink
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.cupidPink
                              : AppColors.warmBlush,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    '${_selectedInterests.length} interests selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.deepPlum.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: _isLoading || _selectedInterests.length < 3
                          ? null
                          : _complete,
                      text: _isLoading ? 'Completing...' : 'Complete Profile',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
