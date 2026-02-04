import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/app_button.dart';

/// Photo Upload Screen - Step 2: Upload profile photos
class PhotoUploadScreen extends ConsumerStatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  ConsumerState<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends ConsumerState<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File?> _photos = List<File?>.filled(6, null);
  bool _isUploading = false;

  Future<void> _pickImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _photos[index] = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    setState(() {
      _photos[index] = null;
    });
  }

  Future<String> _uploadPhoto(File photo, String userId, int index) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profileImages/$userId/photo_$index.jpg');
    
    await storageRef.putFile(photo);
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveAndContinue() async {
    debugPrint('PhotoUpload: Continue button clicked');
    
    // Count photos
    final photosToUpload = _photos.where((p) => p != null).toList();
    debugPrint('PhotoUpload: ${photosToUpload.length} photos to upload');
    
    // Require at least one photo
    if (photosToUpload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Get current user from Firebase Auth directly
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      if (user == null) {
        debugPrint('PhotoUpload: No user found!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in again')),
          );
          context.go('/login');
        }
        return;
      }

      debugPrint('PhotoUpload: Starting upload for user ${user.uid}');

      // Upload photos to Firebase Storage
      final List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        if (_photos[i] != null) {
          debugPrint('PhotoUpload: Uploading photo $i');
          final url = await _uploadPhoto(_photos[i]!, user.uid, i);
          photoUrls.add(url);
          debugPrint('PhotoUpload: Photo $i uploaded: $url');
        }
      }

      debugPrint('PhotoUpload: All ${photoUrls.length} photos uploaded, storing in provider');

      // Store photo URLs in provider (don't save to Firestore yet)
      ref.read(onboardingProvider.notifier).setPhotos(photoUrls);

      debugPrint('PhotoUpload: Navigating to interests screen');

      if (mounted) {
        context.go('/onboarding/interests');
      }
    } catch (e) {
      debugPrint('PhotoUpload: Error - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = _photos.where((p) => p != null).length;
    
    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepPlum),
          onPressed: () => context.go('/onboarding/setup'),
        ),
        title: const Text(
          'Add Photos',
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: 0.66,
                    backgroundColor: AppColors.warmBlush,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cupidPink),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Step 2 of 3',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.deepPlum.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Show your best self',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Add at least 1 photo (up to 6)',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.deepPlum.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Photo grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return _PhotoTile(
                    photo: _photos[index],
                    onTap: () => _pickImage(index),
                    onRemove: _photos[index] != null
                        ? () => _removePhoto(index)
                        : null,
                    isPrimary: index == 0 && _photos[index] != null,
                  );
                },
              ),
            ),
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    '$photoCount/6 photos added',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.deepPlum.withOpacity(0.6),
                    ),
                  ),
                  if (photoCount == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Please add at least 1 photo to continue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: _isUploading || photoCount == 0
                          ? null
                          : () {
                              debugPrint('PhotoUpload: Button tapped, calling _saveAndContinue');
                              _saveAndContinue();
                            },
                      text: _isUploading ? 'Uploading...' : 'Continue',
                    ),
                  ),
                ],
              ),
                ),
              ],
            ),
          ),
          // Loading overlay when uploading
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.cupidPink),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Uploading photos...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final File? photo;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool isPrimary;

  const _PhotoTile({
    this.photo,
    required this.onTap,
    this.onRemove,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warmBlush,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppColors.cupidPink : AppColors.warmBlush,
            width: isPrimary ? 3 : 1,
          ),
        ),
        child: photo != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      photo!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isPrimary)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cupidPink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MAIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (onRemove != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: AppColors.deepPlum.withOpacity(0.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.deepPlum.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
