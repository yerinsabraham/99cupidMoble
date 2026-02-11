import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
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

  Future<void> _showSearchUsersDialog(BuildContext context) async {
    final TextEditingController searchController = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Chats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPlum,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.deepPlum),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(IconlyLight.search, color: AppColors.cupidPink),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cupidPink, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  // Trigger rebuild
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildRealSearchList(searchController, currentUserId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealSearchList(TextEditingController searchController, String currentUserId) {
    return StreamBuilder<List<ChatModel>>(
      stream: _getChatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No chats yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          );
        }

        final searchQuery = searchController.text.toLowerCase();
        final chats = snapshot.data!;
        final filteredChats = chats.where((chat) {
          final otherUserName = chat.getOtherUserName(currentUserId).toLowerCase();
          return searchQuery.isEmpty || otherUserName.contains(searchQuery);
        }).toList();

        if (filteredChats.isEmpty) {
          return Center(
            child: Text(
              'No matching chats',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            final otherUserName = chat.getOtherUserName(currentUserId);
            final otherUserPhoto = chat.getOtherUserPhoto(currentUserId);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: otherUserPhoto != null
                    ? NetworkImage(otherUserPhoto)
                    : null,
                backgroundColor: AppColors.warmBlush,
                child: otherUserPhoto == null
                    ? Text(
                        otherUserName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.cupidPink,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                otherUserName,
                style: const TextStyle(
                  color: AppColors.deepPlum,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat/${chat.id}');
              },
            );
          },
        );
      },
    );
  }

  Future<void> _createOrOpenChat(String otherUserId, String otherUserName, String? otherUserPhoto) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check if chat already exists
      final existingChats = await _firestore
          .collection(FirebaseCollections.chats)
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String? existingChatId;
      for (var doc in existingChats.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          existingChatId = doc.id;
          break;
        }
      }

      if (existingChatId != null) {
        // Open existing chat
        if (mounted) {
          context.push('/chat/$existingChatId');
        }
      } else {
        // Create new chat
        final chatData = {
          'participants': [currentUser.uid, otherUserId],
          'participantNames': {
            currentUser.uid: currentUser.displayName ?? 'User',
            otherUserId: otherUserName,
          },
          'participantPhotos': {
            currentUser.uid: currentUser.photoURL,
            otherUserId: otherUserPhoto,
          },
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': {currentUser.uid: 0, otherUserId: 0},
        };

        final chatDoc = await _firestore
            .collection(FirebaseCollections.chats)
            .add(chatData);

        if (mounted) {
          context.push('/chat/${chatDoc.id}');
        }
      }
    } catch (e) {
      debugPrint('Error creating/opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        })
        .handleError((error) {
          debugPrint('Error mapping chats: $error');
          return <ChatModel>[];
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: Column(
        children: [
          // Pink Header with Chat title
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cupidPink,
                  AppColors.cupidPink.withOpacity(0.9),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header Row with title and search
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              IconlyLight.search,
                              color: AppColors.deepPlum,
                              size: 20,
                            ),
                            onPressed: () => _showSearchUsersDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Message List with rounded top and bottom gradient
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<ChatModel>>(
                  stream: _getChatsStream(),
                  builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                              ),
                              child: const Center(child: LoadingIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            debugPrint('Chat stream error: ${snapshot.error}');
                          }

                          final chats = snapshot.data ?? [];

                          // Filter by search query
                          final filteredChats = chats.where((chat) {
                            final otherUserName = chat.getOtherUserName(
                              currentUserId,
                            );
                            return otherUserName.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            );
                          }).toList();

                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Handle indicator
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 8,
                                  ),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                                if (filteredChats.isEmpty)
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: AppColors.warmBlush,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
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
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      itemCount: filteredChats.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 0),
                                      itemBuilder: (context, index) {
                                        final chat = filteredChats[index];
                                        final otherUserName = chat
                                            .getOtherUserName(currentUserId);
                                        final otherUserPhoto = chat
                                            .getOtherUserPhoto(currentUserId);
                                        final unreadCount = chat.getUnreadCount(
                                          currentUserId,
                                        );
                                        final hasUnread = unreadCount > 0;

                                        return InkWell(
                                          onTap: () =>
                                              context.push('/chat/${chat.id}'),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                // User Avatar
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundImage:
                                                      otherUserPhoto != null
                                                      ? NetworkImage(
                                                          otherUserPhoto,
                                                        )
                                                      : null,
                                                  backgroundColor: AppColors
                                                      .cupidPink
                                                      .withOpacity(0.2),
                                                  child: otherUserPhoto == null
                                                      ? Text(
                                                          otherUserName
                                                                  .isNotEmpty
                                                              ? otherUserName[0]
                                                                    .toUpperCase()
                                                              : '?',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: AppColors
                                                                    .cupidPink,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 16),

                                                // Message Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              otherUserName,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppColors
                                                                    .deepPlum,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          if (chat.lastMessageAt !=
                                                              null)
                                                            Text(
                                                              _formatTime(
                                                                chat.lastMessageAt!,
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[500],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              chat.lastMessage ??
                                                                  'Start the conversation! 💬',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          if (hasUnread)
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .done_all,
                                                                  size: 16,
                                                                  color: AppColors
                                                                      .cupidPink,
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                // Bottom white blur gradient
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.7),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')} PM';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')} PM';
    }
  }
}
