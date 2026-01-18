import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/constants/firebase_collections.dart';

/// AuthService - Handles Firebase Authentication
/// Mirrors web app auth logic exactly
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Server client ID for Android (Web client ID from Firebase)
    // iOS uses clientId from GoogleService-Info.plist automatically
    serverClientId:
        '302226954210-7tid7scm7q0duh4pdkj2094o8f8esmn7.apps.googleusercontent.com',
  );

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Send email verification
      await user.sendEmailVerification();

      // Create user document in Firestore
      final userModel = UserModel.fromAuthUser(
        user.uid,
        email,
        displayName: displayName,
        emailVerified: user.emailVerified,
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toFirestore());

      if (kDebugMode) {
        print('✅ User signed up: ${user.email}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Sign up error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print('✅ User signed in: ${userCredential.user?.email}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Sign in error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception('Google sign-in failed');

      // Check if user document exists
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      // Create user document if it doesn't exist
      if (!userDoc.exists) {
        final userModel = UserModel.fromAuthUser(
          user.uid,
          user.email!,
          displayName: user.displayName,
          photoURL: user.photoURL,
          emailVerified: user.emailVerified,
        );

        await _firestore
            .collection(FirebaseCollections.users)
            .doc(user.uid)
            .set(userModel.toFirestore());
      }

      if (kDebugMode) {
        print('✅ Google sign-in successful: ${user.email}');
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google sign-in error: $e');
      }
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Password reset error: ${e.code} - ${e.message}');
      }
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (kDebugMode) {
          print('✅ Verification email sent to: ${user.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email verification error: $e');
      }
      rethrow;
    }
  }

  /// Reload current user (to check email verification status)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Stream of user profile
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update(data);

      if (kDebugMode) {
        print('✅ User profile updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Profile update error: $e');
      }
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);

      if (kDebugMode) {
        print('✅ User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete Firestore document
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .delete();

      // Delete Firebase Auth account
      await user.delete();

      if (kDebugMode) {
        print('✅ Account deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Account deletion error: $e');
      }
      rethrow;
    }
  }
}
