import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/firebase_collections.dart';

/// Splash Screen - Initial loading screen with logo
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for a minimum time to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Get current user directly from Firebase Auth (not from provider)
    // This ensures we get the actual current state after app reinstall
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    debugPrint('Splash: currentUser = ${currentUser?.uid}');
    
    // Navigate based on auth state
    if (currentUser != null) {
      // Fetch user profile directly from Firestore to check profileSetupComplete
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(currentUser.uid)
            .get();
        
        if (!mounted) return;
        
        if (userDoc.exists) {
          final data = userDoc.data();
          debugPrint('Splash: User doc exists, data = $data');
          
          // Check if profile is complete - either by explicit flag OR by having essential fields
          final profileComplete = data?['profileSetupComplete'] ?? false;
          final hasName = data?['name'] != null && (data?['name'] as String).isNotEmpty;
          final hasBirthday = data?['dateOfBirth'] != null || data?['birthday'] != null;
          final hasGender = data?['gender'] != null;
          final hasPhotos = data?['photos'] != null && (data?['photos'] as List).isNotEmpty;
          
          // Consider profile complete if flag is true OR if essential fields exist
          final isProfileUsable = profileComplete || (hasName && hasBirthday && hasGender && hasPhotos);
          
          debugPrint('Splash: profileComplete=$profileComplete, hasName=$hasName, hasBirthday=$hasBirthday, hasGender=$hasGender, hasPhotos=$hasPhotos');
          debugPrint('Splash: isProfileUsable=$isProfileUsable');
          
          if (isProfileUsable) {
            // User has a usable profile, go to home
            // Also update profileSetupComplete to true if it wasn't
            if (!profileComplete) {
              await FirebaseFirestore.instance
                  .collection(FirebaseCollections.users)
                  .doc(currentUser.uid)
                  .update({'profileSetupComplete': true});
            }
            context.go('/home');
          } else {
            // User needs to complete onboarding
            context.go('/onboarding/setup');
          }
        } else {
          debugPrint('Splash: No user document found');
          // No user document, needs onboarding
          context.go('/onboarding/setup');
        }
      } catch (e) {
        debugPrint('Error checking profile: $e');
        // Default to onboarding on error
        context.go('/onboarding/setup');
      }
    } else {
      debugPrint('Splash: No user logged in, going to login');
      // No user logged in, go to login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main content - centered logo
            Expanded(
              child: Center(
                child: Image.asset(
                  AppAssets.logo,
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // App name at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Text(
                '99cupid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
