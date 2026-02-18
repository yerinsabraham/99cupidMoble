import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint;

/// ChatModel - Represents a chat conversation between two users
/// Ported from web app messaging system
class ChatModel {
  final String? id;
  final List<String> participants;
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String? user1Photo;
  final String? user2Photo;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;
  final DateTime createdAt;

  ChatModel({
    this.id,
    required this.participants,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    this.user1Photo,
    this.user2Photo,
    this.lastMessage,
    this.lastMessageAt,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
  }) : unreadCount = unreadCount ?? {},
       createdAt = createdAt ?? DateTime.now();

  /// Create from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants'] ?? []);

    // Handle both old and new data structures
    String user1Id;
    String user2Id;
    String user1Name;
    String user2Name;
    String? user1Photo;
    String? user2Photo;

    if (data.containsKey('participantNames')) {
      // New structure with participantNames and participantPhotos maps
      user1Id = participants.isNotEmpty ? participants[0] : '';
      user2Id = participants.length > 1 ? participants[1] : '';

      final participantNames =
          data['participantNames'] as Map<String, dynamic>? ?? {};
      user1Name = participantNames[user1Id]?.toString() ?? 'User';
      user2Name = participantNames[user2Id]?.toString() ?? 'User';

      final participantPhotos =
          data['participantPhotos'] as Map<String, dynamic>? ?? {};
      user1Photo = participantPhotos[user1Id]?.toString();
      user2Photo = participantPhotos[user2Id]?.toString();
    } else {
      // Old structure with user1Id, user2Id, etc.
      user1Id = data['user1Id'] ?? '';
      user2Id = data['user2Id'] ?? '';
      user1Name = data['user1Name'] ?? 'User';
      user2Name = data['user2Name'] ?? 'User';
      user1Photo = data['user1Photo'];
      user2Photo = data['user2Photo'];
    }

    // Handle unreadCount - it can be a Map or null
    Map<String, int> unreadCount = {};
    if (data['unreadCount'] != null) {
      try {
        final unreadData = data['unreadCount'];
        if (unreadData is Map) {
          unreadCount = Map<String, int>.from(
            unreadData.map(
              (key, value) =>
                  MapEntry(key.toString(), (value is int) ? value : 0),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error parsing unreadCount: $e');
      }
    }

    return ChatModel(
      id: doc.id,
      participants: participants,
      user1Id: user1Id,
      user2Id: user2Id,
      user1Name: user1Name,
      user2Name: user2Name,
      user1Photo: user1Photo,
      user2Photo: user2Photo,
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: unreadCount,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': {user1Id: user1Name, user2Id: user2Name},
      'participantPhotos': {user1Id: user1Photo, user2Id: user2Photo},
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get other user's ID (not current user)
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  /// Get other user's name (not current user)
  String getOtherUserName(String currentUserId) {
    return currentUserId == user1Id ? user2Name : user1Name;
  }

  /// Get other user's photo (not current user)
  String? getOtherUserPhoto(String currentUserId) {
    return currentUserId == user1Id ? user2Photo : user1Photo;
  }

  /// Get unread count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? user1Id,
    String? user2Id,
    String? user1Name,
    String? user2Name,
    String? user1Photo,
    String? user2Photo,
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      user1Name: user1Name ?? this.user1Name,
      user2Name: user2Name ?? this.user2Name,
      user1Photo: user1Photo ?? this.user1Photo,
      user2Photo: user2Photo ?? this.user2Photo,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
