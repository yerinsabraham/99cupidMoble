import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// UserAccountService - Handles user account management and deletion
/// Ported from web app UserAccountService.js
class UserAccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Delete user account permanently
  /// This includes:
  /// - Firebase Auth account
  /// - User profile in Firestore
  /// - All related data (matches, chats, likes, swipes, verifications)
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'success': false, 'error': 'No user is currently logged in'};
    }

    try {
      // Step 1: Re-authenticate user based on their sign-in provider
      final providerData = user.providerData;
      
      if (providerData.any((info) => info.providerId == 'google.com')) {
        // Google Sign-In re-authentication
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return {'success': false, 'error': 'Google sign-in cancelled'};
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (providerData.any((info) => info.providerId == 'apple.com')) {
        // Apple Sign-In re-authentication
        final appleProvider = AppleAuthProvider();
        await user.reauthenticateWithProvider(appleProvider);
      } else {
        // Email/Password re-authentication
        if (user.email == null) {
          return {'success': false, 'error': 'No email found for this account'};
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Step 2: Mark user as deleted in Firestore first (soft delete)
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        await userRef.update({
          'accountStatus': 'deleted',
          'deletedAt': FieldValue.serverTimestamp(),
          'email': null,
          'photos': [],
          'bio': 'Account deleted',
          'displayName': 'Deleted User',
        });
      }

      // Step 3: Delete related data
      await _deleteUserRelatedData(user.uid);

      // Step 4: Delete Firebase Auth account
      await user.delete();

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return {'success': false, 'error': 'Incorrect password. Please try again.'};
      } else if (e.code == 'too-many-requests') {
        return {'success': false, 'error': 'Too many attempts. Please try again later.'};
      } else if (e.code == 'requires-recent-login') {
        return {'success': false, 'error': 'Please log out and log in again before deleting your account.'};
      }
      return {'success': false, 'error': e.message ?? 'Failed to delete account'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete all user-related data from Firestore
  Future<void> _deleteUserRelatedData(String userId) async {
    final batch = _firestore.batch();

    // 1. Delete matches where user is participant
    final matches1 = await _firestore
        .collection('matches')
        .where('user1Id', isEqualTo: userId)
        .get();
    final matches2 = await _firestore
        .collection('matches')
        .where('user2Id', isEqualTo: userId)
        .get();

    for (final doc in matches1.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in matches2.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete chats where user is participant
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    for (final chatDoc in chats.docs) {
      // Delete chat messages subcollection
      final messages = await _firestore
          .collection('chats')
          .doc(chatDoc.id)
          .collection('messages')
          .get();
      for (final msgDoc in messages.docs) {
        batch.delete(msgDoc.reference);
      }
      batch.delete(chatDoc.reference);
    }

    // 3. Delete likes from this user
    final likes = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId)
        .get();
    for (final doc in likes.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete swipes by this user
    final swipes = await _firestore
        .collection('swipes')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in swipes.docs) {
      batch.delete(doc.reference);
    }

    // 5. Delete verification requests
    final verifications = await _firestore
        .collection('verifications')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in verifications.docs) {
      batch.delete(doc.reference);
    }

    // 6. Delete reports authored by this user
    final reports = await _firestore
        .collection('reports')
        .where('reportingUserId', isEqualTo: userId)
        .get();
    for (final doc in reports.docs) {
      batch.delete(doc.reference);
    }

    // Commit all deletions
    await batch.commit();
  }

  /// Export user data (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'success': false, 'error': 'No user is currently logged in'};
    }

    try {
      final userData = <String, dynamic>{};

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userData['profile'] = userDoc.data();
      }

      // Get matches
      final matches1 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: user.uid)
          .get();
      final matches2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: user.uid)
          .get();
      userData['matches'] = [
        ...matches1.docs.map((d) => d.data()),
        ...matches2.docs.map((d) => d.data()),
      ];

      // Get chats
      final chats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      final chatData = <Map<String, dynamic>>[];
      for (final chatDoc in chats.docs) {
        final messages = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .get();
        chatData.add({
          ...chatDoc.data(),
          'messages': messages.docs.map((m) => m.data()).toList(),
        });
      }
      userData['chats'] = chatData;

      // Get likes
      final likes = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: user.uid)
          .get();
      userData['likes'] = likes.docs.map((d) => d.data()).toList();

      // Get swipes
      final swipes = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: user.uid)
          .get();
      userData['swipes'] = swipes.docs.map((d) => d.data()).toList();

      return {'success': true, 'data': userData};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Export user data as JSON string
  Future<String?> exportUserDataAsJson() async {
    final result = await exportUserData();
    if (result['success'] == true) {
      return const JsonEncoder.withIndent('  ').convert(result['data']);
    }
    return null;
  }

  /// Update account settings
  Future<Map<String, dynamic>> updateAccountSettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'success': false, 'error': 'No user is currently logged in'};
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update privacy settings
  Future<Map<String, dynamic>> updatePrivacySettings({
    bool? showOnlineStatus,
    bool? showLastActive,
    bool? showDistance,
    bool? showAge,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'success': false, 'error': 'No user is currently logged in'};
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (showOnlineStatus != null) {
        updates['privacy.showOnlineStatus'] = showOnlineStatus;
      }
      if (showLastActive != null) {
        updates['privacy.showLastActive'] = showLastActive;
      }
      if (showDistance != null) {
        updates['privacy.showDistance'] = showDistance;
      }
      if (showAge != null) {
        updates['privacy.showAge'] = showAge;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update notification settings
  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? matches,
    bool? messages,
    bool? likes,
    bool? promotions,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'success': false, 'error': 'No user is currently logged in'};
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (matches != null) {
        updates['notifications.matches'] = matches;
      }
      if (messages != null) {
        updates['notifications.messages'] = messages;
      }
      if (likes != null) {
        updates['notifications.likes'] = likes;
      }
      if (promotions != null) {
        updates['notifications.promotions'] = promotions;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update user's lastSeen timestamp
  /// Call this when user performs any activity in the app
  Future<void> updateLastSeen() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - this is not critical
      // Don't block user from using app if this fails
    }
  }

  /// Check if a user is currently online
  /// User is considered online if lastSeen was within the last 5 minutes
  Future<bool> isUserOnline(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data();
      if (data == null) return false;

      // Check privacy setting
      final showOnlineStatus = data['privacy']?['showOnlineStatus'] ?? true;
      if (!showOnlineStatus) return false;

      final lastSeen = data['lastSeen'];
      if (lastSeen == null) return false;

      DateTime lastSeenTime;
      if (lastSeen is Timestamp) {
        lastSeenTime = lastSeen.toDate();
      } else if (lastSeen is String) {
        lastSeenTime = DateTime.parse(lastSeen);
      } else {
        return false;
      }

      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);
      
      // User is online if lastSeen was within last 5 minutes
      return difference.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }
}

