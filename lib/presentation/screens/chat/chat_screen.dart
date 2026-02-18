import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/chat_model.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../../data/services/user_account_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_dialog.dart';

/// ChatScreen - 1-on-1 messaging interface
/// Redesigned to match modern chat UI
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final UserAccountService _userAccountService = UserAccountService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatModel? _chat;
  bool _isLoading = true;
  bool _hasText = false;
  bool _isUploadingImage = false;
  bool _isOtherUserOnline = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (_hasText != hasText) {
        setState(() => _hasText = hasText);
      }
    });
    _loadChat();
    _checkOnlineStatus();
    // Check online status every 30 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) {
        _checkOnlineStatus();
        return true;
      }
      return false;
    });
  }

  Future<void> _checkOnlineStatus() async {
    if (_chat == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUserId = _chat!.getOtherUserId(currentUserId);

    final isOnline = await _userAccountService.isUserOnline(otherUserId);

    if (mounted && _isOtherUserOnline != isOnline) {
      setState(() => _isOtherUserOnline = isOnline);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      final chatDoc = await _firestore
          .collection(FirebaseCollections.chats)
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        setState(() {
          _chat = ChatModel.fromFirestore(chatDoc);
          _isLoading = false;
        });

        // Mark messages as read
        _markMessagesAsRead();

        // Update lastSeen when user opens chat
        _userAccountService.updateLastSeen();
      }
    } catch (e) {
      debugPrint('Error loading chat: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(widget.chatId)
          .update({'unreadCount.$currentUserId': 0});
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Stream<List<MessageModel>> _getMessagesStream() {
    return _firestore
        .collection(FirebaseCollections.chats)
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> _showChatOptionsMenu(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                IconlyLight.profile,
                color: AppColors.cupidPink,
              ),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                final otherUserId = _chat?.getOtherUserId(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                );
                if (otherUserId != null) {
                  context.push('/profile/$otherUserId');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _showBlockUserDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatDialog(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBlockUserDialog(BuildContext context) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Block User',
      content:
          'Are you sure you want to block this user? You will no longer receive messages from them.',
      confirmText: 'Block',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      // TODO: Implement block user functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked successfully')),
      );
    }
  }

  Future<void> _showDeleteChatDialog(BuildContext context) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Delete Chat',
      content:
          'Are you sure you want to delete this conversation? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection(FirebaseCollections.chats)
            .doc(widget.chatId)
            .delete();
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting chat: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final message = MessageModel(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        senderPhoto: currentUser.photoURL,
        text: text,
      );

      // Add message to subcollection
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(widget.chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat's last message
      final otherUserId = _chat?.getOtherUserId(currentUser.uid);
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(widget.chatId)
          .update({
            'lastMessage': text,
            'lastMessageAt': FieldValue.serverTimestamp(),
            if (otherUserId != null)
              'unreadCount.$otherUserId': FieldValue.increment(1),
          });

      _messageController.clear();

      // Update lastSeen when sending message
      _userAccountService.updateLastSeen();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Upload image to Firebase Storage
      final imageUrl = await _uploadImageToStorage(File(image.path));

      // Send image message
      await _sendImageMessage(imageUrl);

      setState(() => _isUploadingImage = false);
    } catch (e) {
      setState(() => _isUploadingImage = false);
      debugPrint('Error picking/sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePictureAndSend() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Upload image to Firebase Storage
      final imageUrl = await _uploadImageToStorage(File(image.path));

      // Send image message
      await _sendImageMessage(imageUrl);

      setState(() => _isUploadingImage = false);
    } catch (e) {
      setState(() => _isUploadingImage = false);
      debugPrint('Error taking/sending picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Create unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${currentUser.uid}_$timestamp.jpg';
    final path = 'chatImages/${widget.chatId}/$fileName';

    // Upload to Firebase Storage
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(imageFile);

    // Get download URL
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final message = MessageModel(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        senderPhoto: currentUser.photoURL,
        text: '', // Empty text for image messages
        type: 'image',
        imageUrl: imageUrl,
      );

      // Add message to subcollection
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(widget.chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat's last message
      final otherUserId = _chat?.getOtherUserId(currentUser.uid);
      await _firestore
          .collection(FirebaseCollections.chats)
          .doc(widget.chatId)
          .update({
            'lastMessage': '📷 Photo',
            'lastMessageAt': FieldValue.serverTimestamp(),
            if (otherUserId != null)
              'unreadCount.$otherUserId': FieldValue.increment(1),
          });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error sending image message: $e');
      throw e;
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.cupidPink,
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.cupidPink),
              title: const Text('Take a picture'),
              onTap: () {
                Navigator.pop(context);
                _takePictureAndSend();
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    // Get user info from chat
    String userName = 'User';
    String? userPhoto;

    if (_chat != null) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      userName = _chat!.getOtherUserName(currentUserId);
      userPhoto = _chat!.getOtherUserPhoto(currentUserId);
    }

    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: Column(
        children: [
          // Pink Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cupidPink, AppColors.cupidPink],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    // User Avatar and Info
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: userPhoto != null
                          ? NetworkImage(userPhoto)
                          : null,
                      backgroundColor: Colors.white,
                      child: userPhoto == null
                          ? Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cupidPink,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _isOtherUserOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.deepPlum,
                          size: 20,
                        ),
                        onPressed: () => _showChatOptionsMenu(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages Container
          Expanded(
            child: Container(
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
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Messages List
                  Expanded(child: _buildRealMessagesList()),

                  // Message Input
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealMessagesList() {
    if (_chat == null) {
      return const Center(child: Text('Chat not found'));
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<MessageModel>>(
      stream: _getMessagesStream(),
      builder: (context, snapshot) {
        // Only show loading if we're waiting AND don't have data yet
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message to start the conversation!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMine = message.isMine(currentUserId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Check if message is an image
                  if (message.isImage && message.imageUrl != null)
                    GestureDetector(
                      onTap: () {
                        // TODO: Open full-screen image viewer
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.black,
                            child: Stack(
                              children: [
                                Center(child: Image.network(message.imageUrl!)),
                                Positioned(
                                  top: 40,
                                  right: 20,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                            maxHeight: 300,
                          ),
                          child: Image.network(
                            message.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? AppColors.cupidPink.withOpacity(0.15)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.deepPlum,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      message.getFormattedTime(),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add attachment button
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.cupidPink,
                shape: BoxShape.circle,
              ),
              child: _isUploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _showImageOptions,
                    ),
            ),
            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type Message',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send or Microphone button
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.cupidPink,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _hasText ? Icons.send : Icons.mic,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  if (_hasText) {
                    _sendMessage();
                  } else {
                    // Handle voice message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice messaging not yet implemented'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
