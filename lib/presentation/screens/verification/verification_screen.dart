import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/verification_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_dialog.dart';

/// VerificationScreen - Handle user verification (phone, photo, ID)
/// Ported from web app VerificationPage.jsx
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final VerificationService _verificationService = VerificationService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  Map<String, dynamic> _status = {};
  
  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final result = await _verificationService.getUserVerificationStatus(currentUser.uid);
      
      if (result['success'] == true) {
        setState(() {
          _status = {
            'phone': result['isPhoneVerified'] == true ? 'approved' : 
                    (result['verification']?['phone'] ?? 'none'),
            'photo': result['isPhotoVerified'] == true ? 'approved' : 
                    (result['verification']?['photo'] ?? 'none'),
            'id': result['isIDVerified'] == true ? 'approved' : 
                  (result['verification']?['id'] ?? 'none'),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading verification status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      appBar: AppBar(
        title: const Text(
          'Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPlum,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepPlum),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cupidPink, AppColors.deepPlum],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Get Verified',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified profiles get 3x more matches',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Trust Score
            _buildTrustScore(),
            
            const SizedBox(height: 24),
            
            // Verification Options
            const Text(
              'Verification Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepPlum,
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone verification removed - requires real SMS integration
            // To re-enable, integrate Firebase Phone Auth or Twilio
            
            _buildVerificationCard(
              type: 'photo',
              title: 'Photo Verification',
              description: 'Take a selfie to prove you\'re real',
              icon: Icons.camera_alt,
              status: _status['photo'] ?? 'none',
              onTap: () => _startPhotoVerification(),
            ),
            
            _buildVerificationCard(
              type: 'id',
              title: 'ID Verification',
              description: 'Upload a government-issued ID',
              icon: Icons.badge,
              status: _status['id'] ?? 'none',
              onTap: () => _startIDVerification(),
            ),
            
            const SizedBox(height: 24),
            
            // Benefits
            const Text(
              'Benefits of Verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepPlum,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildBenefitItem(
              icon: Icons.trending_up,
              title: 'Higher Visibility',
              description: 'Verified profiles appear higher in search results',
            ),
            _buildBenefitItem(
              icon: Icons.favorite,
              title: 'More Matches',
              description: 'Users trust and match with verified profiles more',
            ),
            _buildBenefitItem(
              icon: Icons.verified,
              title: 'Trust Badge',
              description: 'Get a verified badge on your profile',
            ),
            _buildBenefitItem(
              icon: Icons.security,
              title: 'Enhanced Security',
              description: 'Your account is more secure when verified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScore() {
    int score = 0;
    if (_status['phone'] == 'approved') score++;
    if (_status['photo'] == 'approved') score++;
    if (_status['id'] == 'approved') score++;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 3,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    score == 3 ? Colors.green : 
                    score >= 1 ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
              Text(
                '$score/3',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: score == 3 ? Colors.green : 
                         score >= 1 ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trust Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score == 3 ? 'Fully Verified!' :
                  score == 2 ? 'Almost there! Complete one more.' :
                  score == 1 ? 'Good start! Keep verifying.' :
                  'Not verified yet. Start now!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSmallBadge('Phone', _status['phone'] == 'approved'),
                    const SizedBox(width: 8),
                    _buildSmallBadge('Photo', _status['photo'] == 'approved'),
                    const SizedBox(width: 8),
                    _buildSmallBadge('ID', _status['id'] == 'approved'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String label, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: verified ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: verified ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required String status,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Verified';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Not Started';
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: status == 'approved' ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmBlush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.cupidPink, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status != 'approved') ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warmBlush,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.cupidPink, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Phone verification removed due to mock OTP security risk
  /// To re-enable: integrate Firebase Phone Auth or Twilio SMS
  /*
  Future<void> _startPhoneVerification() async {
    final phoneController = TextEditingController();
    String? errorText;
    
    final phone = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              title: Text(
                'Phone Verification',
                style: TextStyle(color: isDark ? Colors.white : AppColors.deepPlum),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your phone number:',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: '+1 234 567 8900',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.phone,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      errorText: errorText,
                      helperText: 'Include country code (e.g., +1)',
                      helperStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    onChanged: (value) {
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final phone = phoneController.text.trim();
                    // Validate phone number format
                    if (phone.isEmpty) {
                      setState(() => errorText = 'Phone number is required');
                      return;
                    }
                    if (!phone.startsWith('+')) {
                      setState(() => errorText = 'Phone must start with country code (e.g., +1)');
                      return;
                    }
                    // Remove all non-digit characters except +
                    final digitsOnly = phone.replaceAll(RegExp(r'[^\d+]'), '');
                    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
                      setState(() => errorText = 'Please enter a valid phone number');
                      return;
                    }
                    Navigator.pop(context, phone);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.cupidPink),
                  child: const Text('Send Code', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (phone != null && phone.isNotEmpty) {
      // In a real app, you'd send an actual SMS here
      // For now, we'll simulate it with a mock OTP
      final mockOtp = '123456';
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final result = await _verificationService.submitPhoneVerification(
          currentUser.uid,
          phone,
          mockOtp,
        );
        
        if (result['success'] == true) {
          // Show OTP verification dialog
          if (mounted) {
            _showOTPDialog(phone);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send verification code. Please try again.'),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _showOTPDialog(String phone) async {
    final otpController = TextEditingController();
    String? errorText;
    
    final otp = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              title: Text(
                'Enter Verification Code',
                style: TextStyle(color: isDark ? Colors.white : AppColors.deepPlum),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 6-digit code sent to',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  Text(
                    phone,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(For demo: use 123456)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      border: const OutlineInputBorder(),
                      counterText: '',
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final otp = otpController.text.trim();
                    // Validate OTP format
                    if (otp.isEmpty) {
                      setState(() => errorText = 'Please enter the verification code');
                      return;
                    }
                    if (otp.length != 6) {
                      setState(() => errorText = 'Code must be 6 digits');
                      return;
                    }
                    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                      setState(() => errorText = 'Code must contain only numbers');
                      return;
                    }
                    Navigator.pop(context, otp);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.cupidPink),
                  child: const Text('Verify', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (otp != null && otp.isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: LoadingIndicator()),
          );
        }

        final result = await _verificationService.verifyPhoneOTP(
          currentUser.uid,
          phone,
          otp,
        );

        // Close loading indicator
        if (mounted) {
          Navigator.pop(context);
        }

        if (result['success'] == true) {
          _loadVerificationStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Provide user-friendly error messages
          String errorMessage;
          final error = result['error']?.toString() ?? '';
          
          if (error.contains('Invalid OTP') || error.contains('invalid')) {
            errorMessage = 'The verification code you entered is incorrect. Please try again.';
          } else if (error.contains('expired') || error.contains('OTP expired')) {
            errorMessage = 'The verification code has expired. Please request a new code.';
          } else if (error.contains('No pending verification')) {
            errorMessage = 'No verification request found. Please start verification again.';
          } else {
            errorMessage = 'Verification failed. Please try again or request a new code.';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
  }
  */

  Future<void> _startPhotoVerification() async {
    // Check camera permission first
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required for verification')),
          );
        }
        return;
      }
      if (result.isPermanentlyDenied) {
        if (mounted) {
          final openSettings = await showAppConfirmDialog(
            context,
            title: 'Camera Permission Required',
            content: 'Please enable camera access in Settings to take verification photos.',
            confirmText: 'Open Settings',
          );
          if (openSettings == true) {
            await openAppSettings();
          }
        }
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Photo Verification',
            style: TextStyle(color: isDark ? Colors.white : AppColors.deepPlum),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, size: 60, color: AppColors.cupidPink),
              const SizedBox(height: 16),
              Text(
                'Take a selfie to verify your identity',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure your face is clearly visible and well-lit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.cupidPink),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Take Selfie', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image == null) return;

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        // Upload to Firebase Storage
        final fileName = 'verification_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child('users/${currentUser.uid}/verification/$fileName');
        await ref.putFile(File(image.path));
        final downloadUrl = await ref.getDownloadURL();

        // Submit verification
        final result = await _verificationService.submitPhotoVerification(
          currentUser.uid,
          downloadUrl,
        );

        if (result['success'] == true) {
          _loadVerificationStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo submitted for verification!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error submitting photo verification: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit photo')),
          );
        }
      }
    }
  }

  Future<void> _startIDVerification() async {
    // Check camera permission first
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required for verification')),
          );
        }
        return;
      }
      if (result.isPermanentlyDenied) {
        if (mounted) {
          final openSettings = await showAppConfirmDialog(
            context,
            title: 'Camera Permission Required',
            content: 'Please enable camera access in Settings to take ID photos.',
            confirmText: 'Open Settings',
          );
          if (openSettings == true) {
            await openAppSettings();
          }
        }
        return;
      }
    }

    final idType = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'ID Verification',
            style: TextStyle(color: isDark ? Colors.white : AppColors.deepPlum),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select ID type:',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.credit_card,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  'Driver\'s License',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () => Navigator.pop(context, 'drivers_license'),
              ),
              ListTile(
                leading: Icon(
                  Icons.badge,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  'Passport',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () => Navigator.pop(context, 'passport'),
              ),
              ListTile(
                leading: Icon(
                  Icons.card_membership,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  'National ID',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () => Navigator.pop(context, 'national_id'),
              ),
            ],
          ),
        );
      },
    );

    if (idType == null) return;

    try {
      // Take photo of ID front
      final XFile? frontImage = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (frontImage == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Upload to Firebase Storage
      final fileName = 'id_front_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/${currentUser.uid}/verification/$fileName');
      await ref.putFile(File(frontImage.path));
      final downloadUrl = await ref.getDownloadURL();

      // Submit verification
      final result = await _verificationService.submitIDVerification(
        currentUser.uid,
        idType,
        downloadUrl,
      );

      if (result['success'] == true) {
        _loadVerificationStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID submitted for verification!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error submitting ID verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit ID')),
        );
      }
    }
  }
}
