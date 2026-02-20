import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_dialog.dart';

/// EditProfileScreen - Edit user profile
/// Ported from web app EditProfilePage.jsx
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Optional section to auto-scroll to after load (e.g. 'inclusive_dating')
  final String? scrollToSection;

  const EditProfileScreen({super.key, this.scrollToSection});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inclusiveDatingKey = GlobalKey();

  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _jobController;
  late TextEditingController _educationController;

  List<String> _photos = [];
  List<String> _interests = [];
  String _gender = 'other';
  String _lookingFor = 'everyone';
  int _minAge = 18;
  int _maxAge = 50;
  int _maxDistance = 50;

  // Disability fields
  bool _hasDisability = false;
  List<String> _disabilityTypes = [];
  String _disabilityDescription = '';
  String _disabilityVisibility = 'private';
  String _disabilityPreference = 'no_preference';
  bool _showBadgeOnProfile = true;
  late TextEditingController _disabilityDescController;

  final List<String> _availableInterests = [
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
    '💼 Career',
    '🎓 Learning',
    '🏖️ Beach',
    '🏔️ Hiking',
    '🎿 Skiing',
    '🏄 Surfing',
    '🧗 Climbing',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _jobController = TextEditingController();
    _educationController = TextEditingController();
    _disabilityDescController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    _disabilityDescController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nameController.text = data['displayName'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _locationController.text = data['location'] ?? '';
          _jobController.text = data['job'] ?? '';
          _educationController.text = data['education'] ?? '';
          _photos = List<String>.from(data['photos'] ?? []);
          _interests = List<String>.from(data['interests'] ?? []);
          _gender = data['gender'] ?? 'other';
          _lookingFor = data['lookingFor'] ?? 'everyone';
          _minAge = data['preferences']?['ageRange']?['min'] ?? 18;
          _maxAge = data['preferences']?['ageRange']?['max'] ?? 50;
          _maxDistance = data['preferences']?['maxDistance'] ?? 50;

          // Load disability data
          _hasDisability = data['hasDisability'] ?? false;
          _disabilityTypes = List<String>.from(data['disabilityTypes'] ?? []);
          _disabilityDescription = data['disabilityDescription'] ?? '';
          _disabilityDescController.text = _disabilityDescription;
          _disabilityVisibility = data['disabilityVisibility'] ?? 'private';
          _disabilityPreference = data['disabilityPreference'] ?? 'no_preference';
          _showBadgeOnProfile = data['showBadgeOnProfile'] ?? true;

          _isLoading = false;
        });

        // Auto-scroll to section if requested
        if (widget.scrollToSection == 'inclusive_dating') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _inclusiveDatingKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 6 photos allowed')));
      return;
    }

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Photo',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.deepPlum,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink,
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.87) : AppColors.grey900,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: isDark ? AppColors.cupidPink.withOpacity(0.9) : AppColors.cupidPink,
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.87) : AppColors.grey900,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        // User cancelled or permissions denied
        // Show helpful message for permission issues
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera
                    ? 'Camera access required. Please allow camera permissions in Settings.'
                    : 'Photo library access required. Please allow photo permissions in Settings.',
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  // On iOS, users need to manually go to Settings
                  showAppInfoDialog(
                    context,
                    title: 'Enable Permissions',
                    content: 'To upload photos, please enable ${source == ImageSource.camera ? "Camera" : "Photos"} access in:\n'
                        '\nSettings > 99cupid > ${source == ImageSource.camera ? "Camera" : "Photos"}',
                    icon: Icons.settings,
                  );
                },
              ),
            ),
          );
        }
        return;
      }

      setState(() => _isSaving = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Upload to Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(
        'users/${currentUser.uid}/photos/$fileName',
      );
      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        _photos.add(downloadUrl);
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('Error adding photo: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        // Provide more specific error messages
        String errorMessage = 'Failed to upload photo';
        if (e.toString().contains('permission') || e.toString().contains('denied')) {
          errorMessage = 'Permission denied. Please enable ${source == ImageSource.camera ? "camera" : "photo"} access in Settings.';
        } else if (e.toString().contains('storage')) {
          errorMessage = 'Storage error. Please check your device storage.';
        }
        
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

  Future<void> _removePhoto(int index) async {
    // Prevent removing the last photo
    if (_photos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one photo'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Remove Photo',
      content: 'Are you sure you want to remove this photo?',
      confirmText: 'Remove',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() {
        _photos.removeAt(index);
      });
      
      // Show reminder to save changes
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo removed. Remember to tap Save to keep changes.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else if (_interests.length < 10) {
        _interests.add(interest);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 interests allowed')),
        );
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one photo is required')),
      );
      return;
    }

    if (_interests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'job': _jobController.text.trim(),
        'education': _educationController.text.trim(),
        'photos': _photos,
        'interests': _interests,
        'gender': _gender,
        'lookingFor': _lookingFor,
        'preferences': {
          'ageRange': {'min': _minAge, 'max': _maxAge},
          'maxDistance': _maxDistance,
        },
        // Disability fields
        'hasDisability': _hasDisability,
        'disabilityTypes': _disabilityTypes,
        'disabilityDescription': _disabilityDescController.text.trim(),
        'disabilityVisibility': _disabilityVisibility,
        'disabilityPreference': _disabilityPreference,
        'showBadgeOnProfile': _showBadgeOnProfile,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepPlum),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.cupidPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Photos Section
            _buildSectionHeader(
              'Photos',
              subtitle: 'Drag to reorder. First photo is your main photo.',
            ),
            _buildPhotosGrid(),

            const SizedBox(height: 24),

            // Basic Info Section
            _buildSectionHeader('Basic Info'),
            _buildInputField(
              controller: _nameController,
              label: 'Name',
              hint: 'Enter your name',
              icon: IconlyLight.profile,
            ),
            _buildInputField(
              controller: _bioController,
              label: 'Bio',
              hint: 'Tell us about yourself...',
              icon: IconlyLight.edit,
              maxLines: 4,
            ),
            _buildInputField(
              controller: _locationController,
              label: 'Location',
              hint: 'City, Country',
              icon: IconlyLight.location,
            ),
            _buildInputField(
              controller: _jobController,
              label: 'Job',
              hint: 'What do you do?',
              icon: IconlyLight.work,
            ),
            _buildInputField(
              controller: _educationController,
              label: 'Education',
              hint: 'Where did you study?',
              icon: Icons.school_outlined,
            ),

            const SizedBox(height: 24),

            // Gender Section
            _buildSectionHeader('I am'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildChoiceChip(
                    'Male',
                    'male',
                    _gender,
                    (v) => setState(() => _gender = v),
                  ),
                  _buildChoiceChip(
                    'Female',
                    'female',
                    _gender,
                    (v) => setState(() => _gender = v),
                  ),
                  _buildChoiceChip(
                    'Other',
                    'other',
                    _gender,
                    (v) => setState(() => _gender = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Looking For Section
            _buildSectionHeader('Looking for'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildChoiceChip(
                    'Men',
                    'men',
                    _lookingFor,
                    (v) => setState(() => _lookingFor = v),
                  ),
                  _buildChoiceChip(
                    'Women',
                    'women',
                    _lookingFor,
                    (v) => setState(() => _lookingFor = v),
                  ),
                  _buildChoiceChip(
                    'Everyone',
                    'everyone',
                    _lookingFor,
                    (v) => setState(() => _lookingFor = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildPreferenceSlider(
              label: 'Age Range',
              value: '$_minAge - $_maxAge',
              child: RangeSlider(
                values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                min: 18,
                max: 80,
                divisions: 62,
                activeColor: AppColors.cupidPink,
                labels: RangeLabels('$_minAge', '$_maxAge'),
                onChanged: (values) {
                  setState(() {
                    _minAge = values.start.round();
                    _maxAge = values.end.round();
                  });
                },
              ),
            ),
            _buildPreferenceSlider(
              label: 'Maximum Distance',
              value: '$_maxDistance km',
              child: Slider(
                value: _maxDistance.toDouble(),
                min: 1,
                max: 200,
                divisions: 199,
                activeColor: AppColors.cupidPink,
                label: '$_maxDistance km',
                onChanged: (value) {
                  setState(() => _maxDistance = value.round());
                },
              ),
            ),

            const SizedBox(height: 24),

            // Interests Section
            _buildSectionHeader(
              'Interests',
              subtitle: 'Select up to 10 interests',
            ),
            _buildInterestsGrid(),

            const SizedBox(height: 24),

            // Disability & Inclusion Section
            Container(
              key: _inclusiveDatingKey,
              child: _buildSectionHeader(
                'Inclusive Dating',
                subtitle: 'Optional - Help us create a more inclusive community',
              ),
            ),
            _buildDisabilitySection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPlum,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _photos.length + 1,
        itemBuilder: (context, index) {
          if (index == _photos.length) {
            return _buildAddPhotoButton();
          }
          return _buildPhotoItem(index);
        },
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _photos[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cupidPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Main',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cupidPink.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warmBlush,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.cupidPink,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey600),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: AppColors.cupidPink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cupidPink, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: Colors.white,
      selectedColor: AppColors.cupidPink,
      side: BorderSide(
        color: isSelected
            ? AppColors.cupidPink
            : AppColors.deepPlum.withOpacity(0.2),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.deepPlum,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPreferenceSlider({
    required String label,
    required String value,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepPlum,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.cupidPink,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableInterests.map((interest) {
          final isSelected = _interests.contains(interest);
          return FilterChip(
            label: Text(interest),
            selected: isSelected,
            onSelected: (_) => _toggleInterest(interest),
            backgroundColor: Colors.white,
            selectedColor: AppColors.warmBlush,
            checkmarkColor: AppColors.cupidPink,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.cupidPink : AppColors.deepPlum,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.cupidPink : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // DISABILITY & INCLUSION SECTION
  // ──────────────────────────────────────────────

  static const List<Map<String, String>> _disabilityOptions = [
    {'value': 'physical', 'label': '🦽 Physical Mobility'},
    {'value': 'visual', 'label': '👓 Visual'},
    {'value': 'hearing', 'label': '👂 Hearing'},
    {'value': 'chronic_illness', 'label': '💊 Chronic Illness'},
    {'value': 'mental_health', 'label': '🧠 Mental Health'},
    {'value': 'neurodivergent', 'label': '🧩 Neurodivergent'},
    {'value': 'other', 'label': '✨ Other'},
    {'value': 'prefer_not_to_specify', 'label': '🤐 Prefer not to say'},
  ];

  static const List<Map<String, String>> _visibilityOptions = [
    {'value': 'public', 'label': 'Everyone', 'icon': 'eye', 'desc': 'Visible on your profile'},
    {'value': 'matches', 'label': 'Matches Only', 'icon': 'people', 'desc': 'Only after you match'},
    {'value': 'private', 'label': 'Private', 'icon': 'lock', 'desc': 'Hidden from everyone'},
  ];

  static const List<Map<String, String>> _preferenceOptions = [
    {'value': 'no_preference', 'label': 'No Preference', 'desc': 'Open to anyone'},
    {'value': 'open', 'label': 'Disability Confident', 'desc': 'Open to dating people with disabilities'},
    {'value': 'prefer', 'label': 'Prefer', 'desc': 'Prefer partners with disabilities'},
    {'value': 'only', 'label': 'Only', 'desc': 'Only interested in partners with disabilities'},
  ];

  Widget _buildDisabilitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8B4FE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF7C3AED), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This section is completely optional. You control who sees it and can change it anytime.',
                    style: TextStyle(
                      color: Color(0xFF6B21A8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Do you have a disability?
          const Text(
            'Do you identify as a person with a disability?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _hasDisability = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _hasDisability
                          ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                          : null,
                      color: _hasDisability ? null : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _hasDisability ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _hasDisability = false;
                    _disabilityTypes = [];
                    _disabilityDescController.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: !_hasDisability
                          ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                          : null,
                      color: !_hasDisability ? null : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'No',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: !_hasDisability ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // If yes, show disability types
          if (_hasDisability) ...[
            const SizedBox(height: 20),
            const Text(
              'Select all that apply:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _disabilityOptions.map((option) {
                final isSelected = _disabilityTypes.contains(option['value']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _disabilityTypes.remove(option['value']);
                      } else {
                        _disabilityTypes.add(option['value']!);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                          : null,
                      color: isSelected ? null : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      option['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Description
            const SizedBox(height: 20),
            const Text(
              'Share more about your needs (optional):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _disabilityDescController,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(color: Colors.black, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Anything potential partners should know...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
              ),
            ),

            // Visibility
            const SizedBox(height: 16),
            const Text(
              'Who can see this?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            ..._visibilityOptions.map((option) {
              final isSelected = _disabilityVisibility == option['value'];
              IconData iconData;
              switch (option['icon']) {
                case 'eye':
                  iconData = Icons.visibility;
                  break;
                case 'people':
                  iconData = Icons.people;
                  break;
                default:
                  iconData = Icons.lock;
              }
              return GestureDetector(
                onTap: () => setState(() => _disabilityVisibility = option['value']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 20, color: isSelected ? Colors.white : Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['label']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              option['desc']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Badge toggle
          if (_hasDisability) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: Color(0xFF8B5CF6), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Show badge on profile cards',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Display your badge when others swipe',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _showBadgeOnProfile,
                    onChanged: (v) => setState(() => _showBadgeOnProfile = v),
                    activeColor: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],

          // Matching preference (for everyone)
          const SizedBox(height: 20),
          const Text(
            'Dating preference:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          ..._preferenceOptions.map((option) {
            final isSelected = _disabilityPreference == option['value'];
            return GestureDetector(
              onTap: () => setState(() => _disabilityPreference = option['value']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                      : null,
                  color: isSelected ? null : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['label']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            option['desc']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
