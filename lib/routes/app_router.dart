import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/onboarding/welcome_screen.dart';
import '../presentation/screens/onboarding/profile_setup_screen.dart';
import '../presentation/screens/onboarding/photo_upload_screen.dart';
import '../presentation/screens/onboarding/interests_screen.dart';
import '../presentation/screens/onboarding/disability_step_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/edit_profile_screen.dart';
import '../presentation/screens/settings/blocked_users_screen.dart';
import '../presentation/screens/verification/verification_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/profile/user_profile_screen.dart';
import '../presentation/screens/games/cultural_games_screen.dart';
import '../presentation/screens/games/mini_games_screen.dart';
import '../presentation/screens/games/live_game_screen.dart';

/// GoRouter configuration - Simple routing without reactive redirects
/// Navigation logic is handled by individual screens (splash screen handles initial routing)
/// This prevents the router from being recreated when auth/profile state changes
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const WelcomeScreen(),
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
        path: '/onboarding/disability',
        builder: (context, state) => const DisabilityStepScreen(),
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
        builder: (context, state) => EditProfileScreen(
          scrollToSection: state.uri.queryParameters['section'],
        ),
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
      GoRoute(
        path: '/cultural-games',
        builder: (context, state) => const CulturalGamesScreen(),
      ),
      GoRoute(
        path: '/mini-games',
        builder: (context, state) => const MiniGamesScreen(),
      ),
      GoRoute(
        path: '/live-game/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return LiveGameScreen(sessionId: sessionId);
        },
      ),
    ],
  );
});
