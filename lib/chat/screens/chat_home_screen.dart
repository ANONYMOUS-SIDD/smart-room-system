// lib/chat/screens/chat_home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/toast_service.dart';
import '../../../widgets/modern_app_bar.dart';
import '../models/chat_user.dart';
import '../models/conversation.dart';
import 'chat_screen.dart';
import '../widgets/profile_image.dart';

class ChatHomeScreen extends StatefulWidget {
  final String? preSelectedUserId;

  const ChatHomeScreen({super.key, this.preSelectedUserId});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final ChatService _chatService = Get.find();
  final AuthService _authService = Get.find();
  final ToastService _toastService = ToastService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _activeTab = 'all';
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};
  String _searchQuery = '';
  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;
  StreamSubscription? _conversationsSubscription;
  Map<String, ChatUser?> _cachedUsers = {};
  Timer? _refreshTimer;
  Map<String, Conversation> _userConversationMap = {};

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();

    print('🎯 ChatHomeScreen loaded for user: ${_chatService.currentUserId}');
    _subscribeToConversations();
    _preloadUserStatus();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _refreshTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cachedUsers.clear();
    _userConversationMap.clear();
    super.dispose();
  }

  void _subscribeToConversations() {
    _conversationsSubscription = _chatService.getUserConversations().listen(
          (conversations) {
        print('📥 Received ${conversations.length} conversations');
        _processConversations(conversations);
        setState(() {});
      },
      onError: (error) {
        print('❌ Error in conversations stream: $error');
      },
    );
  }

  void _processConversations(List<Conversation> conversations) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    _userConversationMap.clear();

    for (final conversation in conversations) {
      final otherUserId = conversation.user1Id == currentUserId
          ? conversation.user2Id
          : conversation.user1Id;

      if (!_userConversationMap.containsKey(otherUserId) ||
          conversation.lastMessageTime.isAfter(
            _userConversationMap[otherUserId]!.lastMessageTime,
          )) {
        _userConversationMap[otherUserId] = conversation;
      }
    }

    print('✅ Grouped into ${_userConversationMap.length} unique users');
  }

  Future<void> _preloadUserStatus() async {
    try {
      final currentUserId = _chatService.currentUserId;
      if (currentUserId == null) return;

      for (final userId in _userConversationMap.keys) {
        final user = await _chatService.getUserById(userId);
        if (user != null) {
          _cachedUsers[userId] = user;
        }
      }
      print('✅ Pre-loaded ${_cachedUsers.length} users');
    } catch (e) {
      print('❌ Error preloading users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: ModernAppBar(
        title: _isSelectionMode
            ? '${_selectedConversations.length} Selected'
            : 'Chats',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Manual refresh triggered');
          setState(() {
            _cachedUsers.clear();
            _userConversationMap.clear();
          });
          await _preloadUserStatus();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: ModernColors.primary,
        child: Column(
          children: [
            _buildSearchBar(),
            if (_searchQuery.isEmpty) _buildCompactTabs(),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildUserList()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isSelectionMode ? _buildModernSelectionBar() : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        cursorColor: ModernColors.primary,
        cursorHeight: 18,
        cursorWidth: 1.5,
        cursorRadius: const Radius.circular(1),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search conversations...',
          hintStyle: GoogleFonts.quicksand(
            color: ModernColors.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: ModernColors.onSurfaceVariant,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: ModernColors.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              _searchFocusNode.unfocus();
            },
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        style: GoogleFonts.quicksand(
          fontSize: 15,
          color: ModernColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCompactTabs() {
    return Container(
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildCompactTab('all', 'All Chats', Icons.forum_rounded),
            const SizedBox(width: 8),
            _buildCompactTab('unread', 'Unread', Icons.mark_email_unread_rounded),
            const SizedBox(width: 8),
            _buildCompactTab('favorite', 'Favourite', Icons.star_rounded),
          ],
        )
    );
  }

  Widget _buildCompactTab(String value, String label, IconData icon) {
    final isActive = _activeTab == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                colors: [ModernColors.primary, ModernColors.primaryDark],
              )
                  : null,
              color: isActive ? null : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: ModernColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? Colors.white : ModernColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isActive ? Colors.white : ModernColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Conversation>>(
      stream: _chatService.getUserConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final conversations = snapshot.data!;
        _processConversations(conversations);

        final userEntries = _userConversationMap.entries.toList();
        final filteredUsers = _filterUsersByTab(userEntries);

        filteredUsers.sort(
              (a, b) => b.value.lastMessageTime.compareTo(a.value.lastMessageTime),
        );

        if (filteredUsers.isEmpty) {
          return _buildEmptyStateForTab();
        }

        return AnimatedList(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          initialItemCount: filteredUsers.length,
          itemBuilder: (context, index, animation) {
            final entry = filteredUsers[index];
            final conversation = entry.value;
            final otherUserId = entry.key;
            final isSelected = _selectedConversations.contains(
              conversation.conversationId,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: _buildChatItem(otherUserId, conversation, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatItem(String userId, Conversation conversation, bool isSelected) {
    return FutureBuilder<ChatUser?>(
      future: _getUserWithCache(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerChatItem();
        }

        if (!userSnapshot.hasData || userSnapshot.hasError) {
          return const SizedBox();
        }

        final user = userSnapshot.data!;
        final currentUserId = _chatService.currentUserId ?? '';
        final unreadCount = conversation.unreadCount[currentUserId] ?? 0;
        final isUnread = unreadCount > 0;
        final isFavorite = conversation.isFavorite[currentUserId] ?? false;

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('User')
              .where('SessionId', isEqualTo: userId)
              .snapshots(),
          builder: (context, statusSnapshot) {
            bool isUserOnline = user.isOnline;

            if (statusSnapshot.hasData && statusSnapshot.data!.docs.isNotEmpty) {
              final data = statusSnapshot.data!.docs.first.data() as Map<String, dynamic>;
              isUserOnline = data['isOnline'] ?? false;
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleConversationSelection(conversation.conversationId);
                  } else {
                    _openChatScreen(conversation, user);
                  }
                },
                onLongPress: () => _showChatOptions(conversation, user),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ModernColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Profile image with shimmer effect
                      if (userSnapshot.connectionState == ConnectionState.waiting)
                        Shimmer.fromColors(
                          baseColor: ModernColors.outline.withOpacity(0.3),
                          highlightColor: ModernColors.surface,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Stack(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isUserOnline
                                    ? Border.all(
                                  color: const Color(0xFF00C853),
                                  width: 2,
                                )
                                    : null,
                              ),
                              child: ClipOval(
                                child: ProfileImage(
                                  size: 52,
                                  imageUrl: user.profilePath,
                                ),
                              ),
                            ),
                            if (isUserOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C853),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ModernColors.background,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            if (isFavorite)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA726),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ModernColors.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row with name and time - using fixed height container
                            Container(
                              height: 20, // Fixed height to center everything
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        user.name,
                                        style: GoogleFonts.quicksand(
                                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w800, // Both are w800 now
                                          fontSize: 15,
                                          color: ModernColors.onSurface,
                                          letterSpacing: -0.2,
                                          height: 1.0, // Fixed line height
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      _formatTimestamp(conversation.lastMessageTime),
                                      style: GoogleFonts.quicksand(
                                        fontSize: isUnread ? 12 : 11, // Slightly larger for unread
                                        color: isUnread ? Colors.black : ModernColors.onSurfaceVariant.withOpacity(0.9),
                                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600, // Bolder for unread
                                        height: 1.0, // Fixed line height
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4), // Reduced spacing
                            // Message preview and unread count row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conversation.lastMessage,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.quicksand(
                                      color: isUnread ? Colors.black : ModernColors.onSurfaceVariant.withOpacity(0.95),
                                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600, // Bolder for unread
                                      fontSize: isUnread ? 14 : 13, // Slightly larger for unread
                                      letterSpacing: isUnread ? -0.05 : -0.1, // Slightly tighter letter spacing for unread
                                    ),
                                  ),
                                ),
                                // Show unread count below the time (on the right side)
                                if (isUnread && unreadCount > 0)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          ModernColors.primary,
                                          ModernColors.primaryDark,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                                      style: GoogleFonts.quicksand(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900, // Made bolder
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                if (_isSelectionMode)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? ModernColors.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? ModernColors.primary
                                            : ModernColors.outline.withOpacity(0.5),
                                        width: isSelected ? 0 : 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                        : null,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 10,
      separatorBuilder: (context, index) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: ModernColors.outline.withOpacity(0.3),
          highlightColor: ModernColors.surface,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildShimmerChatItem() {
    return Shimmer.fromColors(
        baseColor: ModernColors.outline.withOpacity(0.3),
        highlightColor: ModernColors.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildSearchResults() {
    final userEntries = _userConversationMap.entries.toList();
    final searchQuery = _searchQuery.toLowerCase();

    if (userEntries.isEmpty) {
      return _buildEmptySearchState();
    }

    final filteredUsers = userEntries.where((entry) {
      final userId = entry.key;
      final user = _cachedUsers[userId];
      if (user == null) return false;

      final userName = user.name.toLowerCase();
      final userEmail = user.email.toLowerCase();
      return userName.contains(searchQuery) || userEmail.contains(searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final entry = filteredUsers[index];
        final conversation = entry.value;
        final userId = entry.key;

        return _buildChatItem(userId, conversation, false);
      },
    );
  }

  Widget _buildModernSelectionBar() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSelectionButton(
                    icon: Icons.mark_email_read_rounded,
                    label: 'Mark Read',
                    color: ModernColors.primary,
                    onTap: _markSelectedAsRead,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionButton(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: const Color(0xFFEF5350),
                    onTap: _showModernDeleteDialog,
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildSelectionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: ModernColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No Messages Yet',
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ModernColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with room owners',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ModernColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForTab() {
    String message = '';
    IconData icon = Icons.chat_bubble_outline_rounded;

    switch (_activeTab) {
      case 'unread':
        message = 'No unread messages';
        icon = Icons.mark_email_read_rounded;
        break;
      case 'favorite':
        message = 'No favourite conversations';
        icon = Icons.star_outline_rounded;
        break;
      default:
        message = 'No conversations';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: ModernColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ModernColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: ModernColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No Results Found',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ModernColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ModernColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 20),
          Text(
            'Something Went Wrong',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ModernColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshUserList,
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<MapEntry<String, Conversation>> _filterUsersByTab(
      List<MapEntry<String, Conversation>> userEntries) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return [];

    switch (_activeTab) {
      case 'unread':
        return userEntries.where((entry) {
          final conversation = entry.value;
          final unreadCount = conversation.unreadCount[currentUserId] ?? 0;
          return unreadCount > 0;
        }).toList();
      case 'favorite':
        return userEntries.where((entry) {
          final conversation = entry.value;
          return conversation.isFavorite[currentUserId] ?? false;
        }).toList();
      default:
        return userEntries;
    }
  }

  Future<ChatUser?> _getUserWithCache(String userId) async {
    if (_cachedUsers.containsKey(userId)) {
      return _cachedUsers[userId];
    }

    final user = await _chatService.getUserById(userId);
    if (user != null) {
      _cachedUsers[userId] = user;
    }
    return user;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final amPm = timestamp.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $amPm';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _refreshUserList() {
    setState(() {
      _cachedUsers.clear();
      _userConversationMap.clear();
    });
    _preloadUserStatus();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedConversations.clear();
      }
    });
  }

  void _toggleConversationSelection(String conversationId) {
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
        if (_selectedConversations.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  void _showChatOptions(Conversation conversation, ChatUser user) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    final unreadCount = conversation.unreadCount[currentUserId] ?? 0;
    final isUnread = unreadCount > 0;
    final isFavorite = conversation.isFavorite[currentUserId] ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8), // Reduced from 12
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ModernColors.outline.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16), // Reduced from 20
              // User info section - made more compact
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced from 20
                child: Row(
                  children: [
                    Container(
                      width: 48, // Reduced from 56
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: ProfileImage(
                          size: 48, // Reduced from 56
                          imageUrl: user.profilePath,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Reduced from 16
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.quicksand(
                              fontSize: 16, // Reduced from 18
                              fontWeight: FontWeight.w700,
                              color: ModernColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: GoogleFonts.quicksand(
                              fontSize: 12, // Reduced from 13
                              fontWeight: FontWeight.w700, // Made bold
                              color: Colors.black, // Made black
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Reduced from 20
              // Options section - made more compact
              _buildCompactBottomSheetOption(
                icon: isFavorite ? Icons.star : Icons.star_outline,
                iconColor: const Color(0xFFFFA726),
                title: isFavorite ? 'Remove from Favourites' : 'Add to Favourites',
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite(conversation);
                },
              ),
              _buildCompactBottomSheetOption(
                icon: isUnread ? Icons.mark_email_read : Icons.mark_email_unread,
                iconColor: ModernColors.primary,
                title: isUnread ? 'Mark as Read' : 'Mark as Unread',
                onTap: () {
                  Navigator.pop(context);
                  if (isUnread) {
                    _markConversationAsRead(conversation);
                  } else {
                    _markConversationAsUnread(conversation);
                  }
                },
              ),
              _buildCompactBottomSheetOption(
                icon: Icons.delete,
                iconColor: const Color(0xFFEF5350),
                title: 'Delete Conversation',
                onTap: () {
                  Navigator.pop(context);
                  _showModernDeleteDialogSingle(conversation);
                },
              ),
              const SizedBox(height: 8), // Reduced from 12
              // Cancel button - made more compact
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced from 20
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 14
                      backgroundColor: ModernColors.outline.withOpacity(0.3), // Reduced opacity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Reduced from 12
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 14, // Reduced from 15
                        color: ModernColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Reduced from 24
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactBottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
          child: Row(
            children: [
              Container(
                width: 36, // Reduced from 40
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08), // Reduced opacity
                  borderRadius: BorderRadius.circular(8), // Reduced from 10
                ),
                child: Icon(icon, color: iconColor, size: 20), // Reduced from 22
              ),
              const SizedBox(width: 12), // Reduced from 16
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 14, // Reduced from 15
                    fontWeight: FontWeight.w600,
                    color: ModernColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _openChatScreen(Conversation conversation, ChatUser otherUser) {
    _chatService.markMessagesAsRead(conversation.conversationId);
    Get.to(
          () => ChatScreen(
        conversation: conversation,
        otherUser: otherUser,
      ),
      transition: Transition.rightToLeft,
    );
  }

  void _markSelectedAsRead() {
    if (_selectedConversations.isEmpty) return;

    for (final conversationId in _selectedConversations) {
      _chatService.markMessagesAsRead(conversationId);
    }

    _toastService.showSuccessMessage(
      'Marked ${_selectedConversations.length} conversation${_selectedConversations.length > 1 ? 's' : ''} as read',
    );

    _selectedConversations.clear();
    _toggleSelectionMode();
  }

  void _showModernDeleteDialog() {
    if (_selectedConversations.isEmpty) return;

    final count = _selectedConversations.length;
    showDialog(
      context: context,
      builder: (context) => _buildModernDialog(
        context: context, // Pass context here
        title: 'Delete ${count > 1 ? 'Conversations' : 'Conversation'}',
        message: 'Are you sure want to delete ${count > 1 ? 'these $count conversations?' : 'this conversation?'}',
        primaryButtonText: 'Delete',
        primaryButtonColor: const Color(0xFFEF5350),
        primaryAction: () async {
          for (final conversationId in _selectedConversations) {
            await _chatService.deleteConversation(conversationId);
          }
          _toastService.showSuccessMessage(
            'Deleted $count conversation${count > 1 ? 's' : ''}',
          );
          _selectedConversations.clear();
          _toggleSelectionMode();
        },
        secondaryButtonText: 'Cancel',
      ),
    );
  }

  void _showModernDeleteDialogSingle(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => _buildModernDialog(
        context: context, // Pass context here
        title: 'Delete Conversation',
        message: 'Are you sure want to delete this conversation?',
        primaryButtonText: 'Delete',
        primaryButtonColor: const Color(0xFFEF5350),
        primaryAction: () async {
          try {
            await _chatService.deleteConversation(conversation.conversationId);
            _toastService.showSuccessMessage('Conversation deleted');
          } catch (e) {
            _toastService.showErrorMessage('Failed to delete conversation');
          }
        },
        secondaryButtonText: 'Cancel',
      ),
    );
  }

  Widget _buildModernDialog({
    required BuildContext context, // Add BuildContext parameter
    required String title,
    required String message,
    required String primaryButtonText,
    required Color primaryButtonColor,
    required VoidCallback primaryAction,
    required String secondaryButtonText,
  }) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title - reduced font size
            Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ModernColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message - made black and bold
            Text(
              message,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w800, // Made bolder (w800)
                color: Colors.black, // Made black
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Buttons - reduced height
            Row(
              children: [
                // Cancel Button (Purple like tabs) - Now only closes dialog
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(), // Use context parameter
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ModernColors.primary, ModernColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: ModernColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              secondaryButtonText,
                              style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete Button (Red like tabs)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        primaryAction();
                        Navigator.of(context).pop(); // Also close dialog after delete action
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryButtonColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: primaryButtonColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              primaryButtonText,
                              style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
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
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Conversation conversation) async {
    try {
      final currentUserId = _chatService.currentUserId;
      if (currentUserId == null) return;

      final newFavoriteStatus = !(conversation.isFavorite[currentUserId] ?? false);

      await _chatService.toggleFavorite(
        conversation.conversationId,
        currentUserId,
        newFavoriteStatus,
      );

      _toastService.showSuccessMessage(
        newFavoriteStatus ? 'Added to Favourites' : 'Removed from Favourites',
      );
    } catch (e) {
      _toastService.showErrorMessage('Failed to update favourites');
    }
  }

  Future<void> _markConversationAsRead(Conversation conversation) async {
    try {
      await _chatService.markMessagesAsRead(conversation.conversationId);
      _toastService.showSuccessMessage('Marked as Read');
    } catch (e) {
      _toastService.showErrorMessage('Failed to mark as read');
    }
  }

  Future<void> _markConversationAsUnread(Conversation conversation) async {
    try {
      await _chatService.markConversationAsUnread(conversation.conversationId);
      _toastService.showSuccessMessage('Marked as Unread');
    } catch (e) {
      _toastService.showErrorMessage('Failed to mark as unread');
    }
  }

  void _deleteConversation(Conversation conversation) {
    _showModernDeleteDialogSingle(conversation);
  }
}