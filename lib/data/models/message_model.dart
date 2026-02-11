import 'package:cloud_firestore/cloud_firestore.dart';

/// MessageModel - Represents a message in a chat
/// Ported from web app messaging system
class MessageModel {
  final String? id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String text;
  final DateTime timestamp;
  final bool read;
  final String? type; // 'text', 'image', 'video', etc.
  final String? imageUrl; // URL for image messages
  final String? fileUrl; // URL for file attachments

  MessageModel({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.text,
    DateTime? timestamp,
    this.read = false,
    this.type,
    this.imageUrl,
    this.fileUrl,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'User',
      senderPhoto: data['senderPhoto'],
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      if (type != null) 'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };
  }

  /// Check if message is an image
  bool get isImage => type == 'image' && imageUrl != null;

  /// Check if message is from current user
  bool isMine(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Format timestamp for display
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    String? text,
    DateTime? timestamp,
    bool? read,
    String? type,
    String? imageUrl,
    String? fileUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }
}
