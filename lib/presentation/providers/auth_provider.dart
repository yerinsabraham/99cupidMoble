import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current Firebase User Provider
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current User Profile Provider
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider).value;
  
  if (firebaseUser == null) {
    return Stream.value(null);
  }
  
  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfileStream(firebaseUser.uid);
});

/// Authentication State
class AuthState {
  final User? firebaseUser;
  final UserModel? userProfile;
  final bool isLoading;
  final String? error;

  AuthState({
    this.firebaseUser,
    this.userProfile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => firebaseUser != null;
  bool get isProfileComplete => userProfile?.profileSetupComplete ?? false;

  AuthState copyWith({
    User? firebaseUser,
    UserModel? userProfile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth State Notifier
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    return AuthState();
  }

  /// Sign up with email
  /// Returns true if successful, false if failed (check state.error for message)
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Sign in with email
  /// Returns true if successful, false if failed (check state.error for message)
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Sign in with Google
  /// Returns true if successful, false if failed (check state.error for message)
  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.signInWithGoogle();
      
      state = state.copyWith(isLoading: false);
      return true;
    } on UserCancelledException catch (_) {
      // User cancelled - this is not an error, just reset loading state
      state = state.copyWith(isLoading: false, error: null);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Sign in with Apple
  /// Returns true if successful, false if failed (check state.error for message)
  Future<bool> signInWithApple() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.signInWithApple();
      
      state = state.copyWith(isLoading: false);
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or other Apple-specific error
      if (e.code == AuthorizationErrorCode.canceled) {
        state = state.copyWith(isLoading: false, error: null);
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Apple sign-in failed. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Apple sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Send password reset email
  /// Returns true if successful, false if failed (check state.error for message)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.sendPasswordResetEmail(email);
      
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _authService.signOut();
      
      state = state.copyWith(
        isLoading: false,
        firebaseUser: null,
        userProfile: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed. Please try again.',
      );
    }
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. If you signed up with Google, please use the Google sign-in button.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Try signing in with a different method.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Auth State Notifier Provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
