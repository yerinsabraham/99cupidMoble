import 'package:cloud_firestore/cloud_firestore.dart';

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
  })  : unreadCount = unreadCount ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// Create from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants'] ?? []);

    // Support both data models:
    // - Web creates user1Id/user2Id/user1Name/etc.
    // - Older Flutter chats may only have participantNames/participantPhotos
    String u1Id = data['user1Id'] ?? '';
    String u2Id = data['user2Id'] ?? '';
    String u1Name = data['user1Name'] ?? 'User';
    String u2Name = data['user2Name'] ?? 'User';
    String? u1Photo = data['user1Photo'];
    String? u2Photo = data['user2Photo'];

    // Fallback: derive from participants + participantNames/participantPhotos
    if (u1Id.isEmpty && participants.length >= 2) {
      u1Id = participants[0];
      u2Id = participants[1];
      final names = data['participantNames'] as Map<String, dynamic>?;
      final photos = data['participantPhotos'] as Map<String, dynamic>?;
      if (names != null) {
        u1Name = (names[u1Id] as String?) ?? 'User';
        u2Name = (names[u2Id] as String?) ?? 'User';
      }
      if (photos != null) {
        u1Photo = photos[u1Id] as String?;
        u2Photo = photos[u2Id] as String?;
      }
    }

    return ChatModel(
      id: doc.id,
      participants: participants,
      user1Id: u1Id,
      user2Id: u2Id,
      user1Name: u1Name,
      user2Name: u2Name,
      user1Photo: u1Photo,
      user2Photo: u2Photo,
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(
        (data['unreadCount'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v is int) ? v : (v as num?)?.toInt() ?? 0),
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1Photo': user1Photo,
      'user2Photo': user2Photo,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
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
