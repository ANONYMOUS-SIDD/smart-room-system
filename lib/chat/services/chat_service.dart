// lib/chat/services/chat_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../../screens/owner/owner_room_details_dialog.dart';

class ChatService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SupabaseClient _supabase;

  // Collections - MATCHING YOUR FIRESTORE SCHEMA
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('User');
  final CollectionReference _chatsCollection = FirebaseFirestore.instance
      .collection('chats');
  final CollectionReference _conversationsCollection = FirebaseFirestore
      .instance
      .collection('chat_users'); // Changed to match your schema

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  @override
  void onInit() {
    super.onInit();
    print('ChatService initialized');
    try {
      _supabase = Supabase.instance.client;
    } catch (e) {
      print('Supabase init error: $e');
    }
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Generate conversation ID - matching your schema
  String _generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> userExists(String userId) async {
    try {
      print('🔍 Checking if user exists: $userId');

      if (userId.isEmpty) return false;

      // Check by SessionId (Firebase UID)
      final querySnapshot = await _usersCollection
          .where('SessionId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('✅ User exists by SessionId');
        return true;
      }

      // Check by document ID (numeric ID)
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        print('✅ User exists by document ID');
        return true;
      }

      print('❌ User does not exist: $userId');
      return false;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  // Get or create conversation - FIXED FOR YOUR SCHEMA
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
  print('📞 SIMPLE getOrCreateConversation called with: $otherUserId');

  final senderId = currentUserId;
  if (senderId == null) {
    print('❌ No sender ID - user not logged in');
    throw Exception('User not logged in');
  }

  print('👤 Sender ID: $senderId, Other user ID: $otherUserId');
  
  // Generate conversation ID (simple way)
  final conversationId = '${senderId}_$otherUserId';
  if (senderId.compareTo(otherUserId) > 0) {
    final conversationId = '${otherUserId}_$senderId';
  }
  
  print('🎯 Conversation ID: $conversationId');

  try {
    // Check if conversation exists
    final doc = await _conversationsCollection.doc(conversationId).get();

    if (doc.exists) {
      print('✅ Found existing conversation');
      return Conversation.fromFirestore(doc);
    }

    print('🔄 Creating new conversation...');
    
    // SIMPLE conversation data
    final conversationData = {
      'conversationId': conversationId,
      'user1Id': senderId,
      'user2Id': otherUserId,
      'users': [senderId, otherUserId],
      'lastMessage': 'Say hello! 👋',
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': senderId,
      'unreadCount': {senderId: 0, otherUserId: 0},
      'isFavorite': {senderId: false, otherUserId: false},
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    // Save to Firestore
    await _conversationsCollection.doc(conversationId).set(conversationData);
    print('✅ Conversation created successfully');

    // Create welcome message
    await _createWelcomeMessage(conversationId, senderId, otherUserId);

    return Conversation.fromFirestore(
      await _conversationsCollection.doc(conversationId).get()
    );
    
  } catch (e) {
    print('❌ Error: $e');
    // Even on error, return a dummy conversation so navigation continues
    return Conversation(
      conversationId: conversationId,
      user1Id: senderId,
      user2Id: otherUserId,
      lastMessage: 'Start chatting...',
      lastMessageTime: DateTime.now(),
      lastMessageSenderId: senderId,
      unreadCount: {senderId: 0, otherUserId: 0},
      isFavorite: {senderId: false, otherUserId: false},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

  Future<void> _createWelcomeMessage(
    String conversationId,
    String senderId,
    String receiverId,
  ) async {
    try {
      final messageId = 'welcome_${DateTime.now().millisecondsSinceEpoch}';
      final welcomeMessage = ChatMessage(
        messageId: messageId,
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        message: 'Hello! Let\'s chat about the room.',
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDeleted: false,
      );

      await _chatsCollection.doc(messageId).set(welcomeMessage.toFirestore());
      print('Welcome message created in chats collection');
    } catch (e) {
      print('Could not create welcome message: $e');
    }
  }

  // Get user by ID - IMPROVED FOR YOUR SCHEMA
  // Update the getUserById method to handle SessionId properly
  Future<ChatUser?> getUserById(String userId) async {
  try {
    print('🔍 getUserById called with: $userId');

    if (userId.isEmpty) {
      print('❌ User ID is empty');
      return null;
    }

    // Try by SessionId first (Firebase UID)
    final querySnapshot = await _usersCollection
        .where('SessionId', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      print('✅ User found by SessionId! Name: ${data['Name']}');
      return ChatUser.fromFirestore(data);
    }

    // Try by document ID as fallback
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      print('✅ User found by document ID! Name: ${data['Name']}');
      return ChatUser.fromFirestore(data);
    }

    print('⚠️ User not found in User collection, creating temporary...');
    
    // Create temporary user - ROOM OWNER MIGHT NOT BE IN USER COLLECTION
    return ChatUser(
      id: userId,
      name: 'Room Owner',  // Default name
      email: '',
      phone: '',
      sessionId: userId,   // This is the Firebase UID
      profilePath: '',
      createdAt: DateTime.now(),
      isOnline: false,
      lastSeen: DateTime.now(),
    );
    
  } catch (e) {
    print('❌ Error in getUserById: $e');
    
    // Return temporary user on error
    return ChatUser(
      id: userId,
      name: 'Room Owner',
      email: '',
      phone: '',
      sessionId: userId,
      profilePath: '',
      createdAt: DateTime.now(),
      isOnline: false,
      lastSeen: DateTime.now(),
    );
  }
}
  // Send text message
  Future<void> sendTextMessage({
    required String receiverId,
    required String text,
  }) async {
    final senderId = currentUserId;
    if (senderId == null || text.trim().isEmpty) return;

    try {
      // Get or create conversation
      final conversation = await getOrCreateConversation(receiverId);

      final messageId =
          '${DateTime.now().millisecondsSinceEpoch}_${senderId.substring(0, 6)}';
      final timestamp = DateTime.now();

      final message = ChatMessage(
        messageId: messageId,
        conversationId: conversation.conversationId,
        senderId: senderId,
        receiverId: receiverId,
        message: text.trim(),
        type: MessageType.text,
        timestamp: timestamp,
        isRead: false,
        isDeleted: false,
      );

      // Add message to chats collection
      await _chatsCollection.doc(messageId).set(message.toFirestore());

      // Update conversation in chat_users collection
      await _conversationsCollection.doc(conversation.conversationId).update({
        'lastMessage': text.trim(),
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': senderId,
        'unreadCount.$receiverId': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      print('Message sent: $text');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for conversation from chats collection
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _chatsCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error in getMessages stream: $error');
        })
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  // Get user conversations from chat_users collection
  Stream<List<Conversation>> getUserConversations() {
  final user = currentUserId;
  if (user == null) {
    print('❌ No current user for conversations');
    return Stream.value([]);
  }

  print('📥 Loading conversations for user: $user');

  return _conversationsCollection
      .where('users', arrayContains: user)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .handleError((error) {
        print('⚠️ Stream error: $error');
        return Stream.value([]);
      })
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          print('📭 No conversations found for user: $user');
          return [];
        }
        print('✅ Found ${snapshot.docs.length} conversations');
        return snapshot.docs
            .map((doc) {
              try {
                return Conversation.fromFirestore(doc);
              } catch (e) {
                print('⚠️ Error parsing conversation: $e');
                return null;
              }
            })
            .where((conv) => conv != null)
            .cast<Conversation>()
            .toList();
      });
}

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final user = currentUserId;
    if (user == null) return;

    try {
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount.$user': 0,
        'updatedAt': Timestamp.now(),
      });
      print('Marked messages as read');
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required String receiverId,
    required File imageFile,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) return;

    try {
      _isUploading = true;

      final conversation = await getOrCreateConversation(receiverId);

      final messageId =
          '${DateTime.now().millisecondsSinceEpoch}_${senderId.substring(0, 6)}';
      final timestamp = DateTime.now();

      // For now, we'll just send a placeholder text for images
      // You can implement Supabase upload later
      final message = ChatMessage(
        messageId: messageId,
        conversationId: conversation.conversationId,
        senderId: senderId,
        receiverId: receiverId,
        message: '[Image]',
        type: MessageType.image,
        timestamp: timestamp,
        isRead: false,
        isDeleted: false,
      );

      await _chatsCollection.doc(messageId).set(message.toFirestore());

      await _conversationsCollection.doc(conversation.conversationId).update({
        'lastMessage': 'Image',
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': senderId,
        'unreadCount.$receiverId': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      print('Image placeholder sent');
    } catch (e) {
      print('Error sending image: $e');
      rethrow;
    } finally {
      _isUploading = false;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(
    String conversationId,
    String userId,
    bool isFavorite,
  ) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'isFavorite.$userId': isFavorite,
        'updatedAt': Timestamp.now(),
      });
      print('Toggled favorite: $isFavorite');
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Mark conversation as unread
  Future<void> markConversationAsUnread(String conversationId) async {
    final user = currentUserId;
    if (user == null) return;

    try {
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount.$user': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
      print('Marked conversation as unread');
    } catch (e) {
      print('Error marking as unread: $e');
      rethrow;
    }
  }

  // Initialize chat system
  Future<void> initializeChatSystem() async {
    try {
      print('Initializing chat system...');

      final currentId = currentUserId;
      if (currentId == null) {
        print('No user logged in');
        return;
      }

      print('Chat system initialized for user: $currentId');
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  // Check if collections exist
  Future<void> checkCollections() async {
    try {
      print('Checking Firestore collections...');

      final usersTest = await _usersCollection.limit(1).get();
      print(
        'Users collection: ${usersTest.docs.isNotEmpty ? "Exists" : "Empty"}',
      );

      final conversationsTest = await _conversationsCollection.limit(1).get();
      print(
        'chat_users collection: ${conversationsTest.docs.isNotEmpty ? "Exists" : "Empty"}',
      );

      final chatsTest = await _chatsCollection.limit(1).get();
      print(
        'chats collection: ${chatsTest.docs.isNotEmpty ? "Exists" : "Empty"}',
      );

      print('Collections check complete');
    } catch (e) {
      print('Error checking collections: $e');
    }
  }

  // Ensure collections exist
  Future<void> ensureCollectionsExist() async {
    try {
      await checkCollections();
    } catch (e) {
      print('Error ensuring collections exist: $e');
    }
  }

  Future<void> debugAllCollections() async {
    print('\n=== DEBUGGING ALL COLLECTIONS ===');

    try {
      // Check User collection
      print('🔍 Checking User collection...');
      final userDocs = await _usersCollection.limit(3).get();
      print('   Found ${userDocs.docs.length} user documents');
      for (var doc in userDocs.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        print(
          '   - ${doc.id}: ${data['Name']} (SessionId: ${data['SessionId']})',
        );
      }

      // Check chat_users collection
      print('🔍 Checking chat_users collection...');
      final convDocs = await _conversationsCollection.limit(3).get();
      print('   Found ${convDocs.docs.length} conversations');
      for (var doc in convDocs.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        print('   - ${doc.id}: ${data['user1Id']} ↔ ${data['user2Id']}');
      }

      // Check chats collection
      print('🔍 Checking chats collection...');
      final chatDocs = await _chatsCollection.limit(3).get();
      print('   Found ${chatDocs.docs.length} messages');

      print('=== END DEBUG ===\n');
    } catch (e) {
      print('❌ Error debugging collections: $e');
    }
  }
}
