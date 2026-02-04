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

/// EditProfileScreen - Edit user profile
/// Ported from web app EditProfilePage.jsx
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

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
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _jobController.dispose();
    _educationController.dispose();
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
          _isLoading = false;
        });
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
      builder: (context) => AlertDialog(
        title: const Text('Add Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

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
    } catch (e) {
      debugPrint('Error adding photo: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to upload photo')));
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _photos.removeAt(index);
      });
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
      body: SingleChildScrollView(
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

            const SizedBox(height: 32),
          ],
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
}
