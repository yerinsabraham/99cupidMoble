import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_model.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../widgets/common/loading_indicator.dart';

/// MessagesScreen - Displays list of chats
/// Ported from web app MessagesPageV2.jsx
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<ChatModel>> _getChatsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirebaseCollections.chats)
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading chats: $error');
          return null;
        })
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();

      // Sort by last message time
      chats.sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      return chats;
    }).handleError((error) {
      debugPrint('Error mapping chats: $error');
      return <ChatModel>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble, color: AppColors.cupidPink, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepPlum,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chats List
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: _getChatsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingIndicator());
                  }

                  // Handle errors silently - show empty state instead
                  if (snapshot.hasError) {
                    debugPrint('Chat stream error: ${snapshot.error}');
                  }

                  final chats = snapshot.data ?? [];
                  
                  // Filter by search query
                  final filteredChats = chats.where((chat) {
                    final otherUserName = chat.getOtherUserName(currentUserId);
                    return otherUserName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.warmBlush,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: AppColors.cupidPink,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepPlum,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start swiping to find matches\nand begin conversations!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final otherUserName = chat.getOtherUserName(currentUserId);
                      final otherUserPhoto = chat.getOtherUserPhoto(currentUserId);
                      final unreadCount = chat.getUnreadCount(currentUserId);
                      final hasUnread = unreadCount > 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push('/chat/${chat.id}');
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: hasUnread 
                                    ? AppColors.warmBlush.withValues(alpha: 0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: hasUnread 
                                    ? Border.all(
                                        color: AppColors.cupidPink.withValues(alpha: 0.3),
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: hasUnread
                                        ? AppColors.cupidPink.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.04),
                                    blurRadius: hasUnread ? 15 : 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Premium Avatar with online indicator
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: otherUserPhoto == null
                                              ? const LinearGradient(
                                                  colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.cupidPink.withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage: otherUserPhoto != null
                                              ? NetworkImage(otherUserPhoto)
                                              : null,
                                          child: otherUserPhoto == null
                                              ? Text(
                                                  otherUserName.isNotEmpty 
                                                      ? otherUserName[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      if (hasUnread)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFFF6B9D), AppColors.cupidPink],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.cupidPink.withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 22,
                                              minHeight: 22,
                                            ),
                                            child: Text(
                                              unreadCount > 9 ? '9+' : '$unreadCount',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),

                                  // Chat Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                otherUserName,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                                  color: AppColors.deepPlum,
                                                  letterSpacing: -0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (chat.lastMessageAt != null)
                                              Text(
                                                _formatTime(chat.lastMessageAt!),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                                  color: hasUnread 
                                                      ? AppColors.cupidPink 
                                                      : Colors.grey[500],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          chat.lastMessage ?? 'Start the conversation! 💬',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                            color: hasUnread 
                                                ? AppColors.deepPlum.withValues(alpha: 0.8)
                                                : Colors.grey[600],
                                            height: 1.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Chevron
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey[400],
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
