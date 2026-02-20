import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/app_button.dart';

/// Disability / Inclusive Dating Screen - Step 4: Accessibility & Inclusion
class DisabilityStepScreen extends ConsumerStatefulWidget {
  const DisabilityStepScreen({super.key});

  @override
  ConsumerState<DisabilityStepScreen> createState() =>
      _DisabilityStepScreenState();
}

class _DisabilityStepScreenState extends ConsumerState<DisabilityStepScreen> {
  bool _hasDisability = false;
  final Set<String> _selectedTypes = {};
  final _descriptionController = TextEditingController();
  String _visibility = 'matches_only';
  String _preference = 'open_to_all';
  bool _showBadge = false;
  bool _isLoading = false;

  static const List<Map<String, String>> _disabilityOptions = [
    {'value': 'physical', 'label': 'Physical'},
    {'value': 'visual', 'label': 'Visual'},
    {'value': 'hearing', 'label': 'Hearing'},
    {'value': 'cognitive', 'label': 'Cognitive'},
    {'value': 'mental_health', 'label': 'Mental Health'},
    {'value': 'chronic_illness', 'label': 'Chronic Illness'},
    {'value': 'neurodivergent', 'label': 'Neurodivergent'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> _visibilityOptions = [
    {'value': 'public', 'label': 'Everyone', 'desc': 'Visible to all users'},
    {
      'value': 'matches_only',
      'label': 'Matches Only',
      'desc': 'Shown after matching'
    },
    {
      'value': 'private',
      'label': 'Private',
      'desc': 'Only you can see this'
    },
  ];

  static const List<Map<String, String>> _preferenceOptions = [
    {
      'value': 'open_to_all',
      'label': 'Open to All',
      'desc': 'No preference on disability status'
    },
    {
      'value': 'prefer_disabled',
      'label': 'Prefer Disabled',
      'desc': 'Prefer matching with disabled users'
    },
    {
      'value': 'prefer_non_disabled',
      'label': 'Prefer Non-Disabled',
      'desc': 'Prefer matching with non-disabled users'
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;

      if (user == null) {
        debugPrint('DisabilityStep: No user found!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in again')),
          );
          context.go('/login');
        }
        return;
      }

      debugPrint('DisabilityStep: User found: ${user.uid}');

      // Store disability data in provider
      ref.read(onboardingProvider.notifier).setDisabilityData(
            hasDisability: _hasDisability,
            disabilityTypes: _selectedTypes.toList(),
            disabilityDescription: _descriptionController.text.trim(),
            disabilityVisibility: _visibility,
            disabilityPreference: _preference,
            showBadgeOnProfile: _showBadge,
          );

      // Get all onboarding data collected across all steps
      final onboardingData = ref.read(onboardingProvider);
      final profileData = onboardingData.toMap(user.uid, user.email ?? '');

      debugPrint('DisabilityStep: Saving complete profile data:');
      debugPrint('  - Name: ${profileData['displayName']}');
      debugPrint('  - Age: ${profileData['age']}');
      debugPrint('  - Gender: ${profileData['gender']}');
      debugPrint('  - Location: ${profileData['location']}');
      debugPrint('  - Bio: ${profileData['bio']}');
      debugPrint('  - Photos: ${profileData['photos']?.length ?? 0}');
      debugPrint('  - Interests: ${profileData['interests']?.length ?? 0}');
      debugPrint('  - Has Disability: ${profileData['hasDisability']}');
      debugPrint(
          '  - Profile Complete: ${profileData['profileSetupComplete']}');

      // Save everything to Firestore in one operation
      await authService.updateUserProfile(user.uid, profileData);

      debugPrint('DisabilityStep: Profile saved successfully to Firestore');

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
          SnackBar(content: Text('Error saving profile: $e')),
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
                Image.asset(
                  'assets/icons/applogo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
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
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your profile has been saved successfully.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.deepPlum,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
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
          onPressed: () => context.go('/onboarding/interests'),
        ),
        title: const Text(
          'Inclusive Dating',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: AppColors.warmBlush,
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.cupidPink),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Step 4 of 4',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.deepPlum.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inclusive Dating',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We celebrate all abilities. This step is optional.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.deepPlum.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Do you have a disability? toggle
                    _buildSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Do you identify as having a disability?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepPlum,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildToggleButton('Yes', _hasDisability, () {
                                setState(() => _hasDisability = true);
                              }),
                              const SizedBox(width: 12),
                              _buildToggleButton('No', !_hasDisability, () {
                                setState(() => _hasDisability = false);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (_hasDisability) ...[
                      const SizedBox(height: 16),

                      // Disability types
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Type of Disability',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select all that apply',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.deepPlum.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _disabilityOptions.map((option) {
                                final isSelected = _selectedTypes
                                    .contains(option['value']);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTypes
                                            .remove(option['value']);
                                      } else {
                                        _selectedTypes
                                            .add(option['value']!);
                                      }
                                    });
                                  },
                                  child: Chip(
                                    label: Text(
                                      option['label']!,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.deepPlum,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
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
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tell us more (optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descriptionController,
                              maxLines: 3,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Share anything you\'d like others to know...',
                                hintStyle: TextStyle(
                                  color:
                                      AppColors.deepPlum.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppColors.softIvory,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColors.warmBlush),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColors.warmBlush),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.cupidPink,
                                      width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Visibility
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Who can see this?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_visibilityOptions).map((option) {
                              final isSelected =
                                  _visibility == option['value'];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _visibility = option['value']!;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.cupidPink
                                              .withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.cupidPink
                                            : AppColors.warmBlush,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: isSelected
                                              ? AppColors.cupidPink
                                              : AppColors.deepPlum
                                                  .withOpacity(0.4),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                option['label']!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors
                                                          .cupidPink
                                                      : AppColors
                                                          .deepPlum,
                                                ),
                                              ),
                                              Text(
                                                option['desc']!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .deepPlum
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Badge toggle
                      _buildSectionCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Show Inclusive Badge',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepPlum,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Display a small badge on your profile',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.deepPlum
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _showBadge,
                              onChanged: (v) =>
                                  setState(() => _showBadge = v),
                              activeColor: AppColors.cupidPink,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dating preference
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dating Preference',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_preferenceOptions).map((option) {
                              final isSelected =
                                  _preference == option['value'];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _preference = option['value']!;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.cupidPink
                                              .withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.cupidPink
                                            : AppColors.warmBlush,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: isSelected
                                              ? AppColors.cupidPink
                                              : AppColors.deepPlum
                                                  .withOpacity(0.4),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                option['label']!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors
                                                          .cupidPink
                                                      : AppColors
                                                          .deepPlum,
                                                ),
                                              ),
                                              Text(
                                                option['desc']!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .deepPlum
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (!_hasDisability)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'You can always update this later in Settings',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.deepPlum.withOpacity(0.5),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: _isLoading ? null : _complete,
                      text: _isLoading ? 'Saving...' : 'Complete Profile',
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPlum.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildToggleButton(
      String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cupidPink : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.cupidPink : AppColors.warmBlush,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.deepPlum,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
