import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/countries.dart';
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
  String _selectedLookingFor = 'everyone';
  int _minAge = 18;
  int _maxAge = 50;
  String? _selectedCountry;
  String? _selectedCity;
  final _cityController = TextEditingController();
  bool _cityHasDropdown = false;
  List<String> _availableCities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Restore data from onboarding provider if user navigated back from step 2
    // or pre-fill from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingData = ref.read(onboardingProvider);
      
      // First priority: data from onboarding flow
      if (onboardingData.displayName != null && onboardingData.displayName!.isNotEmpty) {
        _nameController.text = onboardingData.displayName!;
        _ageController.text = onboardingData.age?.toString() ?? '';
        _bioController.text = onboardingData.bio ?? '';
        
        // Parse location back to country and city
        final location = onboardingData.location ?? '';
        if (location.contains(', ')) {
          final parts = location.split(', ');
          final city = parts[0];
          final country = parts[1];
          
          // Find matching country
          final countryData = allCountries.firstWhere(
            (c) => c.name == country,
            orElse: () => allCountries[0],
          );
          
          setState(() {
            _selectedCountry = country;
            if (countryData.hasPredefinedCities) {
              _cityHasDropdown = true;
              _availableCities = countryData.cities!;
              _selectedCity = countryData.cities!.contains(city) ? city : null;
            } else {
              _cityHasDropdown = false;
              _cityController.text = city;
            }
          });
        }
        
        setState(() {
          _selectedGender = onboardingData.gender ?? 'male';
          _selectedLookingFor = onboardingData.lookingFor ?? 'everyone';
          _minAge = onboardingData.ageRangeMin ?? 18;
          _maxAge = onboardingData.ageRangeMax ?? 50;
        });
      } else {
        // Second priority: existing user profile
        final userProfile = ref.read(userProfileProvider).value;
        if (userProfile != null && userProfile.displayName.isNotEmpty) {
          _nameController.text = userProfile.displayName;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate location selection
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country')),
      );
      return;
    }
    
    // Get city - either from dropdown or text input
    final city = _cityHasDropdown 
        ? _selectedCity 
        : _cityController.text.trim();
    
    if (city == null || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your city')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Store profile data in provider (don't save to Firestore yet)
      ref.read(onboardingProvider.notifier).setProfileData(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender,
        lookingFor: _selectedLookingFor,
        ageRangeMin: _minAge,
        ageRangeMax: _maxAge,
        location: '$city, $_selectedCountry',
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
        actions: [
          TextButton(
            onPressed: () async {
              // Sign out and return to login
              final authService = ref.read(authServiceProvider);
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
                const SizedBox(height: 24),
                
                // Looking For selection
                const Text(
                  'Looking For',
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
                        label: 'Men',
                        value: 'men',
                        groupValue: _selectedLookingFor,
                        onChanged: (value) {
                          setState(() => _selectedLookingFor = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderOption(
                        label: 'Women',
                        value: 'women',
                        groupValue: _selectedLookingFor,
                        onChanged: (value) {
                          setState(() => _selectedLookingFor = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderOption(
                        label: 'Everyone',
                        value: 'everyone',
                        groupValue: _selectedLookingFor,
                        onChanged: (value) {
                          setState(() => _selectedLookingFor = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Age Range Preference
                const Text(
                  'Age Preference',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_minAge - $_maxAge years',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cupidPink,
                  ),
                ),
                const SizedBox(height: 12),
                RangeSlider(
                  values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                  min: 18,
                  max: 80,
                  divisions: 62,
                  activeColor: AppColors.cupidPink,
                  inactiveColor: AppColors.warmBlush,
                  labels: RangeLabels(
                    _minAge.toString(),
                    _maxAge.toString(),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _minAge = values.start.round();
                      _maxAge = values.end.round();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Country dropdown
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: AppColors.deepPlum,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Country',
                    labelStyle: const TextStyle(color: AppColors.deepPlum),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.warmBlush),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.warmBlush),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cupidPink, width: 2),
                    ),
                  ),
                  hint: const Text(
                    'Select your country',
                    style: TextStyle(color: Colors.grey),
                  ),
                  items: allCountries.map((country) {
                    return DropdownMenuItem(
                      value: country.name,
                      child: Text(
                        country.name,
                        style: const TextStyle(
                          color: AppColors.deepPlum,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final countryData = allCountries.firstWhere((c) => c.name == value);
                    setState(() {
                      _selectedCountry = value;
                      _selectedCity = null;
                      _cityController.clear();
                      
                      if (countryData.hasPredefinedCities) {
                        _cityHasDropdown = true;
                        _availableCities = countryData.cities!;
                      } else {
                        _cityHasDropdown = false;
                        _availableCities = [];
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your country';
                    }
                    return null;
                  },
                  selectedItemBuilder: (context) {
                    return allCountries.map((country) {
                      return Text(
                        country.name,
                        style: const TextStyle(
                          color: AppColors.deepPlum,
                          fontSize: 16,
                        ),
                      );
                    }).toList();
                  },
                ),
                const SizedBox(height: 16),
                
                // City dropdown or text input based on country
                if (_selectedCountry != null) ...[
                  if (_cityHasDropdown)
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedCountry),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: AppColors.deepPlum,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'City',
                        labelStyle: const TextStyle(color: AppColors.deepPlum),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.warmBlush),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.warmBlush),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cupidPink, width: 2),
                        ),
                      ),
                      hint: const Text(
                        'Select your city',
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: _availableCities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(
                              color: AppColors.deepPlum,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your city';
                        }
                        return null;
                      },
                      selectedItemBuilder: (context) {
                        return _availableCities.map((city) {
                          return Text(
                            city,
                            style: const TextStyle(
                              color: AppColors.deepPlum,
                              fontSize: 16,
                            ),
                          );
                        }).toList();
                      },
                    )
                  else
                    AppTextField(
                      controller: _cityController,
                      labelText: 'City',
                      hintText: 'Enter your city',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                ],
                
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
