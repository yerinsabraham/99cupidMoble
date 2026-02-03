import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Profile Setup Screen - Step 1: Basic Information
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedGender = 'male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill display name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile != null && userProfile.displayName.isNotEmpty) {
        _nameController.text = userProfile.displayName;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Store profile data in provider (don't save to Firestore yet)
      ref.read(onboardingProvider.notifier).setProfileData(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender,
        location: _locationController.text.trim(),
      );

      if (mounted) {
        context.go('/onboarding/photos');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: AppColors.deepPlum),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: AppColors.warmBlush,
                  valueColor: const AlwaysStoppedAnimation(AppColors.cupidPink),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Step 1 of 3',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.deepPlum.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name field
                AppTextField(
                  controller: _nameController,
                  labelText: 'Your Name',
                  hintText: 'Enter your display name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Age field
                AppTextField(
                  controller: _ageController,
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 18 || age > 100) {
                      return 'Please enter a valid age (18-100)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Gender selection
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _GenderOption(
                        label: 'Male',
                        value: 'male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() => _selectedGender = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderOption(
                        label: 'Female',
                        value: 'female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() => _selectedGender = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderOption(
                        label: 'Other',
                        value: 'other',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() => _selectedGender = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Location field
                AppTextField(
                  controller: _locationController,
                  labelText: 'Location',
                  hintText: 'City, Country',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Bio field
                AppTextField(
                  controller: _bioController,
                  labelText: 'Bio (Optional)',
                  hintText: 'Tell others about yourself...',
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    text: _isLoading ? 'Saving...' : 'Continue',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _GenderOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
              color: isSelected ? Colors.white : AppColors.deepPlum,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
