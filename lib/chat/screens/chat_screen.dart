// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add Supabase import

import '../models/chat_user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../widgets/profile_image.dart';
import '../helper/my_date_util.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final ChatUser otherUser;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FocusNode _focusNode = FocusNode();
  final SupabaseClient _supabase = Supabase.instance.client; // Supabase client

  bool _isUploading = false;
  bool _isTyping = false;
  bool _showSendButton = false;
  String? _selectedMessageId;
  List<ChatMessage> _messages = [];
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _userStatusSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  late ChatUser _otherUser;
  DateTime? _lastSeenFromMessage;

  @override
  void initState() {
    super.initState();
    _otherUser = widget.otherUser;
    print('🚀 ChatScreen opened with: ${_otherUser.name}');
    _initializeChat();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _userStatusSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _stopTypingIndicator();
    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.trim().isNotEmpty && !_showSendButton) {
      setState(() => _showSendButton = true);
    } else if (_messageController.text.trim().isEmpty && _showSendButton) {
      setState(() => _showSendButton = false);
    }
  }

  void _initializeChat() {
    _loadMessages();
    _subscribeToUserStatus();
    _subscribeToTypingIndicator();
    _markMessagesAsRead();
  }

  void _loadMessages() {
    _messagesSubscription?.cancel();

    _messagesSubscription = _chatService
        .getMessages(widget.conversation.conversationId)
        .listen((messages) {
      if (mounted) {
        // Find last message from other user for last seen
        final otherUserMessages = messages.where((msg) => msg.senderId == _otherUser.id);
        if (otherUserMessages.isNotEmpty) {
          final lastMessage = otherUserMessages.reduce((a, b) =>
          a.timestamp.isAfter(b.timestamp) ? a : b);
          _lastSeenFromMessage = lastMessage.timestamp;
        }

        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    }, onError: (error) {
      print('❌ Error in messages stream: $error');
    });
  }

  void _subscribeToUserStatus() {
    _userStatusSubscription?.cancel();

    _userStatusSubscription = _firestore
        .collection('User')
        .where('SessionId', isEqualTo: _otherUser.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final data = snapshot.docs.first.data();
        final isOnline = data['isOnline'] ?? false;
        final lastSeen = data['lastSeen'] != null
            ? (data['lastSeen'] as Timestamp).toDate()
            : null;

        // Update other user's status using copyWith
        setState(() {
          _otherUser = _otherUser.copyWith(
            isOnline: isOnline,
            lastSeen: lastSeen,
          );
        });
        print('👤 User status updated: ${isOnline ? 'Online' : 'Offline'}');
      }
    }, onError: (error) {
      print('❌ Error in user status stream: $error');
    });
  }

  void _subscribeToTypingIndicator() {
    _typingSubscription?.cancel();

    // Listen for typing indicators
    _typingSubscription = _firestore
        .collection('chat_users')
        .doc(widget.conversation.conversationId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final typing = data['typing'] as Map<String, dynamic>? ?? {};
        final otherUserId = _otherUser.id;

        setState(() {
          _isTyping = typing[otherUserId] == true;
        });

        if (_isTyping) {
          print('⌨️ ${_otherUser.name} is typing...');
        }
      }
    });
  }

  void _markMessagesAsRead() {
    // Mark all messages as read when opening chat
    _chatService.markMessagesAsRead(widget.conversation.conversationId);
    print('✅ Messages marked as read');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTypingIndicator() {
    _typingTimer?.cancel();

    // Send typing indicator
    _firestore
        .collection('chat_users')
        .doc(widget.conversation.conversationId)
        .update({
      'typing.${_chatService.currentUserId}': true,
      'updatedAt': Timestamp.now(),
    }).catchError((e) {
      print('❌ Error sending typing indicator: $e');
    });

    // Set timer to stop typing after 3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), _stopTypingIndicator);
  }

  void _stopTypingIndicator() {
    _typingTimer?.cancel();

    _firestore
        .collection('chat_users')
        .doc(widget.conversation.conversationId)
        .update({
      'typing.${_chatService.currentUserId}': false,
      'updatedAt': Timestamp.now(),
    }).catchError((e) {
      print('❌ Error stopping typing indicator: $e');
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    // Stop typing indicator
    _stopTypingIndicator();

    // Create optimistic message
    final optimisticMessage = ChatMessage(
      messageId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.conversationId,
      senderId: currentUserId,
      receiverId: _otherUser.id,
      message: message,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      isDeleted: false,
    );

    // Add optimistic message immediately
    setState(() {
      _messages.insert(0, optimisticMessage);
      _messageController.clear();
      _showSendButton = false;
    });

    _scrollToBottom();
    FocusScope.of(context).unfocus();

    try {
      // Send actual message
      await _chatService.sendTextMessage(
        receiverId: _otherUser.id,
        text: message,
      );

      // Refresh messages list
      _loadMessages();

      // Update conversation list in home screen
      Get.find<ChatService>().getUserConversations();

      print('✅ Message sent successfully');

    } catch (e) {
      // Remove optimistic message on error
      setState(() {
        _messages.removeWhere((msg) => msg.messageId.startsWith('temp_'));
      });

      _showErrorSnackbar('Failed to send message: $e');
    }
  }

  Future<void> _sendImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await _uploadAndSendImage(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await _uploadAndSendImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      print('📤 Starting image upload to Supabase...');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final currentUserId = _chatService.currentUserId ?? 'unknown';
      final fileName = 'chat_${currentUserId}_$timestamp.jpg';
      final filePath = 'chat_images/$fileName';

      print('📁 Uploading file: $fileName to bucket: chat_images');

      // Upload to Supabase Storage
      final fileBytes = await imageFile.readAsBytes();
      final uploadResponse = await _supabase.storage
          .from('chat_images')
          .uploadBinary(filePath, fileBytes, fileOptions: FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ));

      print('✅ Image uploaded to Supabase: $uploadResponse');

      // Get public URL
      final imageUrl = _supabase.storage
          .from('chat_images')
          .getPublicUrl(filePath);

      print('🔗 Image URL: $imageUrl');

      // Send image URL to Firebase
      await _chatService.sendImageMessage(
        receiverId: _otherUser.id,
        imageUrl: imageUrl, // Pass the Supabase URL
      );

      print('✅ Image sent successfully via Firebase');

    } catch (e) {
      print('❌ Error uploading/sending image: $e');
      _showErrorSnackbar('Failed to send image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.quicksand(fontSize: 13)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatLastSeenTime(DateTime? lastSeen) {
    if (lastSeen == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastSeenDate = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    if (lastSeenDate == today) {
      return 'Today at ${DateFormat('h:mm a').format(lastSeen)}';
    } else if (lastSeenDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat('h:mm a').format(lastSeen)}';
    } else {
      return DateFormat('MMM d at h:mm a').format(lastSeen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _selectedMessageId = null);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              // Typing indicator
              if (_isTyping)
                Container(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 0.5),
                        ),
                        child: ClipOval(
                          child: _otherUser.profilePath.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: _otherUser.profilePath,
                            fit: BoxFit.cover,
                          )
                              : Icon(Icons.person, size: 16, color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildTypingDot(0),
                            const SizedBox(width: 2),
                            _buildTypingDot(1),
                            const SizedBox(width: 2),
                            _buildTypingDot(2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages List
              Expanded(
                child: _buildMessagesList(),
              ),

              // Uploading indicator
              if (_isUploading)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploading...',
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Message Input
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      titleSpacing: 0,
      toolbarHeight: 64,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black87,
            size: 24,
          ),
          splashRadius: 20,
          padding: EdgeInsets.zero,
        ),
      ),
      title: GestureDetector(
        onTap: _showUserProfile,
        child: Row(
          children: [
            // Profile Image (Increased size)
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _otherUser.isOnline ? Colors.green : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: _otherUser.profilePath.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: _otherUser.profilePath,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.person, size: 22, color: Colors.grey),
                  ),
                )
                    : Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.person, size: 22, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // User Name
                  Text(
                    _otherUser.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Small gap
                  // Last Seen status (from last message of other user)
                  Builder(
                    builder: (context) {
                      String statusText = '';

                      if (_otherUser.isOnline) {
                        statusText = 'Online';
                      } else {
                        // Use last message timestamp if available, otherwise use lastSeen from user data
                        final lastSeenTime = _lastSeenFromMessage ?? _otherUser.lastSeen;
                        if (lastSeenTime != null) {
                          statusText = _formatLastSeenTime(lastSeenTime);
                        } else {
                          statusText = 'Offline';
                        }
                      }

                      return Text(
                        statusText,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: _otherUser.isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade50,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start chatting with ${_otherUser.name}',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _chatService.currentUserId;
        final isOptimistic = message.messageId.startsWith('temp_');
        final showDateHeader = _shouldShowDateHeader(index, message);
        final isImage = message.type == MessageType.image;
        final messageTime = DateFormat('h:mm a').format(message.timestamp);
        final showTime = _selectedMessageId == message.messageId;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedMessageId == message.messageId) {
                _selectedMessageId = null;
              } else {
                _selectedMessageId = message.messageId;
              }
            });
          },
          child: Column(
            children: [
              // Date header
              if (showDateHeader) _buildDateHeader(message.timestamp),

              // Message bubble
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 50 : 8,
                  right: isMe ? 8 : 50,
                  bottom: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe && _shouldShowAvatar(index))
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 2),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200, width: 0.5),
                          ),
                          child: ClipOval(
                            child: _otherUser.profilePath.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: _otherUser.profilePath,
                              fit: BoxFit.cover,
                            )
                                : Icon(Icons.person, size: 12, color: Colors.grey.shade400),
                          ),
                        ),
                      ),

                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // Message bubble
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              color: isMe ? Colors.blue : Colors.grey.shade100,
                            ),
                            child: isImage
                                ? _buildImageMessage(message)
                                : _buildTextMessage(message, isMe, isOptimistic),
                          ),
                          // Timestamp (only shows when clicked) - Made bold
                          if (showTime)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isMe && !isOptimistic && message.isRead)
                                    const Icon(
                                      Icons.done_all_rounded,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                  if (isMe && !isOptimistic && message.isRead)
                                    const SizedBox(width: 3),
                                  Text(
                                    messageTime,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w700, // Made bold
                                    ),
                                  ),
                                  if (isOptimistic)
                                    const SizedBox(width: 4),
                                  if (isOptimistic)
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowDateHeader(int index, ChatMessage message) {
    if (index == _messages.length - 1) return true;

    final nextMessage = _messages[index + 1];
    final currentDate = DateTime(
      message.timestamp.year,
      message.timestamp.month,
      message.timestamp.day,
    );
    final nextDate = DateTime(
      nextMessage.timestamp.year,
      nextMessage.timestamp.month,
      nextMessage.timestamp.day,
    );

    return currentDate != nextDate;
  }

  bool _shouldShowAvatar(int index) {
    if (index == _messages.length - 1) return true;

    final currentMessage = _messages[index];
    final nextMessage = _messages[index + 1];

    return nextMessage.senderId != currentMessage.senderId ||
        (nextMessage.timestamp.difference(currentMessage.timestamp).inMinutes > 5);
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        )
    );
  }

  Widget _buildImageMessage(ChatMessage message) {
    return GestureDetector(
        onTap: () => _showImageFullscreen(message.message),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            maxHeight: 200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Use CachedNetworkImage for Supabase URLs
                CachedNetworkImage(
                  imageUrl: message.message,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 200,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey.shade400,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildTextMessage(ChatMessage message, bool isMe, bool isOptimistic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message.message,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : Colors.grey.shade900,
                height: 1.3,
              ),
            ),
          ),
          if (isOptimistic)
            const SizedBox(width: 6),
          if (isOptimistic)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Plus button for attachments (Reduced size)
          GestureDetector(
            onTap: _showAttachmentBottomSheet,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.blue.shade700,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text field
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Only request focus when user taps the text field
                FocusScope.of(context).requestFocus(_focusNode);
              },
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 44,
                  minHeight: 44,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Center(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      minLines: 1,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _startTypingIndicator();
                        } else {
                          _stopTypingIndicator();
                        }
                      },
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                      cursorColor: Colors.blue,
                      cursorWidth: 1.5,
                      cursorHeight: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _showSendButton ? Colors.blue : Colors.grey.shade300,
              boxShadow: _showSendButton
                  ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: IconButton(
              onPressed: _showSendButton ? _sendMessage : null,
              icon: Icon(
                Icons.send_rounded,
                color: _showSendButton ? Colors.white : Colors.grey.shade500,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentBottomSheet() {
    // Unfocus before opening bottom sheet
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: false,
      builder: (context) {
        return GestureDetector(
          onTap: () {}, // Prevent tap from propagating
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),

                // Main container - Very compact
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Camera option - Compact with Dark Pink
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context); // Close bottom sheet
                              _takePhoto();
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD81B60), // Dark Pink
                                      borderRadius: BorderRadius.circular(10), // Rounded rectangle
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD81B60).withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Camera',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Vertical divider
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),

                      // Gallery option - Compact with Purple
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context); // Close bottom sheet
                              _sendImage();
                            },
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8E24AA), // Purple
                                      borderRadius: BorderRadius.circular(10), // Rounded rectangle
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8E24AA).withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.image_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Gallery',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    ).then((value) {
      // This runs when the bottom sheet is closed
      // Ensure keyboard doesn't pop up automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
      });
    });
  }

  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.white60,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button at top right
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Profile Photo - Increased size
              Container(
                width: 80, // Increased from 60
                height: 80, // Increased from 60
                margin: const EdgeInsets.only(top: 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _otherUser.profilePath.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: _otherUser.profilePath,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10), // Reduced from 12

              // Person Name (small bold black)
              Text(
                _otherUser.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12), // Reduced from 16

              // Email - Centered with pink icon, made bolder
              if (_otherUser.email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email,
                        size: 13,
                        color: Colors.pink.shade400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _otherUser.email,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700, // Made bolder (was w600)
                            color: Colors.grey.shade800, // Darker for better visibility
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_otherUser.email.isNotEmpty && _otherUser.phone.isNotEmpty)
                const SizedBox(height: 6), // Reduced from 8

              // Phone - Centered with green icon, black bold text
              if (_otherUser.phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone,
                        size: 13,
                        color: Colors.green.shade500,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _otherUser.phone,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _makeCall() {
    // TODO: Implement voice call
    Get.snackbar(
      'Coming Soon',
      'Voice call feature will be available soon!',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _makeVideoCall() {
    // TODO: Implement voice call
    Get.snackbar(
      'Coming Soon',
      'Video call feature will be available soon!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Chat',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to clear all messages in this chat?',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.quicksand()),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: Implement clear chat functionality
              Get.snackbar(
                'Coming Soon',
                'Clear chat feature will be available soon!',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            child: Text(
              'Clear',
              style: GoogleFonts.quicksand(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}