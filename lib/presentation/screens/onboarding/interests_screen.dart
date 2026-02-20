import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
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

    // Store interests in provider and navigate to disability step
    ref.read(onboardingProvider.notifier).setInterests(_selectedInterests.toList());
    debugPrint('Interests: Stored ${_selectedInterests.length} interests, navigating to disability step');

    if (mounted) {
      context.go('/onboarding/disability');
    }
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
                    value: 0.75,
                    backgroundColor: AppColors.warmBlush,
                    valueColor: AlwaysStoppedAnimation(AppColors.cupidPink),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Step 3 of 4',
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
                      onPressed: _selectedInterests.length < 3
                          ? null
                          : _complete,
                      text: 'Next',
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
