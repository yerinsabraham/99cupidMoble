import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/firebase_collections.dart';

/// SwipeService - Handles swipe, like, and match operations
/// Ported from web app SwipeService.js
class SwipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a swipe action
  Future<Map<String, dynamic>> recordSwipe(
    String userId,
    String targetUserId,
    String direction,
  ) async {
    try {
      final swipeData = {
        'userId': userId,
        'targetUserId': targetUserId,
        'direction': direction,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(FirebaseCollections.swipes)
          .add(swipeData);

      if (kDebugMode) {
        print('✅ Swipe recorded: $direction on $targetUserId');
      }

      return {'success': true, 'id': docRef.id};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recording swipe: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if user has already swiped on a target user
  Future<bool> hasSwipedOn(String userId, String targetUserId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.swipes)
          .where('userId', isEqualTo: userId)
          .where('targetUserId', isEqualTo: targetUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking swipe status: $e');
      }
      return false;
    }
  }

  /// Get all profiles swiped by user
  Future<List<Map<String, dynamic>>> getSwipedProfiles(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.swipes)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting swiped profiles: $e');
      }
      return [];
    }
  }

  /// Like a user (record like action and check for match)
  Future<Map<String, dynamic>> likeUser(
    String fromUserId,
    String toUserId,
    Map<String, dynamic> fromUserData,
    Map<String, dynamic> toUserData,
  ) async {
    try {
      // Record the like
      final likeData = {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(FirebaseCollections.likes).add(likeData);

      // Check if there's a mutual like (match)
      final mutualLikeSnapshot = await _firestore
          .collection(FirebaseCollections.likes)
          .where('fromUserId', isEqualTo: toUserId)
          .where('toUserId', isEqualTo: fromUserId)
          .get();

      if (mutualLikeSnapshot.docs.isNotEmpty) {
        // Create a match
        final matchData = await createMatch(
          fromUserId,
          toUserId,
          fromUserData,
          toUserData,
        );

        if (kDebugMode) {
          print('🎉 Match created!');
        }

        return {'success': true, 'match': matchData};
      }

      return {'success': true, 'match': null};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error liking user: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Pass on a user (swipe left)
  Future<Map<String, dynamic>> passOnUser(String userId, String targetUserId) async {
    return await recordSwipe(userId, targetUserId, 'left');
  }

  /// Create a match between two users
  Future<Map<String, dynamic>> createMatch(
    String user1Id,
    String user2Id,
    Map<String, dynamic> user1Data,
    Map<String, dynamic> user2Data,
  ) async {
    try {
      // Create chat first
      final chatData = {
        'user1Id': user1Id,
        'user2Id': user2Id,
        'user1Name': user1Data['displayName'] ?? 'User',
        'user2Name': user2Data['displayName'] ?? 'User',
        'user1Photo': user1Data['photoURL'],
        'user2Photo': user2Data['photoURL'],
        'participants': [user1Id, user2Id],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'lastMessage': null,
        'unreadCount': {
          user1Id: 0,
          user2Id: 0,
        },
      };

      final chatDocRef = await _firestore
          .collection(FirebaseCollections.chats)
          .add(chatData);

      // Create match
      final matchData = {
        'user1Id': user1Id,
        'user2Id': user2Id,
        'user1Name': user1Data['displayName'] ?? 'User',
        'user2Name': user2Data['displayName'] ?? 'User',
        'user1Photo': user1Data['photoURL'],
        'user2Photo': user2Data['photoURL'],
        'chatId': chatDocRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final matchDocRef = await _firestore
          .collection(FirebaseCollections.matches)
          .add(matchData);

      if (kDebugMode) {
        print('✅ Match created between $user1Id and $user2Id');
      }

      return {
        'success': true,
        'isMatch': true,
        'matchId': matchDocRef.id,
        'chatId': chatDocRef.id,
        'match': {' id': matchDocRef.id, ...matchData},
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating match: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all matches for a user
  Future<List<Map<String, dynamic>>> getUserMatches(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.matches)
          .get();

      final matches = snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['user1Id'] == userId || data['user2Id'] == userId;
          })
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      return matches;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user matches: $e');
      }
      return [];
    }
  }
}
