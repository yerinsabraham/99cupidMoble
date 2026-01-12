import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/onboarding/profile_setup_screen.dart';
import '../presentation/screens/onboarding/photo_upload_screen.dart';
import '../presentation/screens/onboarding/interests_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/edit_profile_screen.dart';
import '../presentation/screens/settings/blocked_users_screen.dart';
import '../presentation/screens/verification/verification_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/profile/user_profile_screen.dart';
import '../presentation/providers/auth_provider.dart';

/// GoRouter configuration with authentication guards
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseUserProvider);
  final userProfile = ref.watch(userProfileProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      
      // Don't redirect if on splash screen - let it handle navigation
      if (currentPath == '/splash') {
        return null;
      }
      
      final isLoading = authState.isLoading || userProfile.isLoading;
      final user = authState.value;
      final profile = userProfile.value;
      
      debugPrint('Router: path=$currentPath, isLoading=$isLoading, user=${user?.uid}, profile=${profile?.name}');
      
      // If still loading, don't redirect - wait for data
      if (isLoading) {
        debugPrint('Router: Still loading, no redirect');
        return null;
      }
      
      final isAuthenticated = user != null;
      final isOnAuthPage = currentPath.startsWith('/login') ||
          currentPath.startsWith('/signup');
      final isOnOnboarding = currentPath.startsWith('/onboarding');
      final isOnHome = currentPath.startsWith('/home');
      
      // Check if profile is complete - either by flag OR by having essential fields
      bool profileComplete = false;
      if (profile != null) {
        final hasName = profile.name.isNotEmpty;
        final hasGender = profile.gender.isNotEmpty;
        final hasPhotos = profile.photos.isNotEmpty;
        profileComplete = profile.profileSetupComplete || (hasName && hasGender && hasPhotos);
        debugPrint('Router: profileSetupComplete=${profile.profileSetupComplete}, hasName=$hasName, hasGender=$hasGender, hasPhotos=$hasPhotos, profileComplete=$profileComplete');
      }
      
      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isOnAuthPage && currentPath != '/splash') {
        debugPrint('Router: Not authenticated, redirecting to login');
        return '/login';
      }
      
      // If authenticated and on home, trust the splash screen's decision
      // Only redirect away from home if profile is definitely null (not just loading)
      if (isAuthenticated && isOnHome && profile == null && !userProfile.isLoading) {
        debugPrint('Router: On home but no profile found, redirecting to onboarding');
        return '/onboarding/setup';
      }
      
      // If authenticated but profile incomplete and not on home, redirect to onboarding
      if (isAuthenticated && !profileComplete && !isOnOnboarding && !isOnAuthPage && !isOnHome) {
        debugPrint('Router: Profile incomplete, redirecting to onboarding');
        return '/onboarding/setup';
      }
      
      // If authenticated with complete profile and on auth/onboarding page, go to home
      if (isAuthenticated && profileComplete && (isOnAuthPage || isOnOnboarding)) {
        debugPrint('Router: Profile complete, redirecting to home');
        return '/home';
      }
      
      debugPrint('Router: No redirect needed');
      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/photos',
        builder: (context, state) => const PhotoUploadScreen(),
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return UserProfileScreen(userId: userId);
        },
      ),
    ],
  );
});
