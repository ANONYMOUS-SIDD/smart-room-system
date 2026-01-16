import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/modern_app_bar.dart';
import 'owner_room_details_dialog.dart';

/// Owner Screen For Viewing User Requests And Order Status
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  int _currentTabIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 350;
    final double horizontalPadding = isSmallScreen ? 12 : 14;
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const ModernAppBar(title: "Owner Dashboard"),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              // Toggle Container
              Container(
                margin: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            icon: Icons.event_available_rounded,
                            label: 'Active',
                            isSelected: _currentTabIndex == 0,
                            onTap: () => setState(() => _currentTabIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: _buildToggleButton(
                            icon: Icons.history_rounded,
                            label: 'History',
                            isSelected: _currentTabIndex == 1,
                            onTap: () => setState(() => _currentTabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Section
              currentUserId == null
                  ? _buildLoginRequired()
                  : _currentTabIndex == 0
                  ? _buildActiveSection(isSmallScreen, currentUserId)
                  : _buildHistorySection(isSmallScreen, currentUserId),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.login_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please Login',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to login to view your rooms',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection(bool isSmallScreen, String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('ownerId', isEqualTo: currentUserId)
          .where('bookingStatus', isEqualTo: 'requested')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading(isSmallScreen);
        }

        final bookings = snapshot.data!.docs;
        final bookingCount = bookings.length;

        if (bookingCount == 0) {
          return _buildEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No active requests',
            subtitle: 'Booking requests will appear here',
          );
        }

        return Column(
          children: [
            // Results Title - REDUCED LEFT MARGIN
            Padding(
              padding: EdgeInsets.only(
                left: 12, // Reduced from 16/20 to 12
                right: isSmallScreen ? 30 : 90,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Active Booking Requests",
                    style: GoogleFonts.quicksand(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$bookingCount requests pending",
                    style: GoogleFonts.quicksand(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Room Cards
            ...bookings.map((bookingDoc) {
              final booking = bookingDoc.data() as Map<String, dynamic>;
              final roomDocumentId = booking['roomDocumentId']?.toString() ?? '';

              return StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('room').doc(roomDocumentId).snapshots(),
                builder: (context, roomSnapshot) {
                  if (roomSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildBookingCardShimmer(isSmallScreen);
                  }

                  if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
                    return _buildMissingRoomCard(
                      booking: booking,
                      isSmallScreen: isSmallScreen,
                    );
                  }

                  final room = roomSnapshot.data!.data() as Map<String, dynamic>;
                  // Add booking info to room data
                  final roomWithBooking = Map<String, dynamic>.from(room);
                  roomWithBooking['bookingId'] = booking['bookingId'];
                  roomWithBooking['userEmail'] = booking['userEmail'];
                  roomWithBooking['bookingDate'] = booking['bookingDate'];
                  roomWithBooking['bookingStatus'] = booking['bookingStatus'];
                  roomWithBooking['userId'] = booking['userId'];

                  return CompactRoomCardFromFirestore(
                    room: roomWithBooking,
                    roomDocumentId: roomDocumentId,
                    isSmallScreen: isSmallScreen,
                    isOwnerView: true,
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildHistorySection(bool isSmallScreen, String currentUserId) {
    return Column(
      children: [
        // Results Title - REDUCED LEFT MARGIN
        Padding(
          padding: EdgeInsets.only(
            left: 12, // Reduced from 16/20 to 12
            right: isSmallScreen ? 30 : 150,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking History",
                style: GoogleFonts.quicksand(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "0 bookings",
                style: GoogleFonts.quicksand(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),

        // Show only empty state for now
        _buildEmptyState(
          icon: Icons.history_rounded,
          title: 'No Booking History',
          subtitle: 'Completed bookings will appear here',
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Gradient selectedGradient = label == 'Active'
        ? const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)])
        : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? selectedGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isSmallScreen) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          // Results Title Shimmer
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: isSmallScreen ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 150,
                  height: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Room Cards Shimmer
          for (int i = 0; i < 3; i++)
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    height: isSmallScreen ? 150 : 170,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                        topRight: Radius.circular(isSmallScreen ? 16 : 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 150,
                                    height: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 200,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 24,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 100,
                              height: 28,
                              color: Colors.white,
                            ),
                            Container(
                              width: 100,
                              height: 28,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int j = 0; j < 3; j++)
                                Container(
                                  width: 80,
                                  height: 60,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 120,
                                  height: 24,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            Container(
                              width: 100,
                              height: 34,
                              color: Colors.white,
                            ),
                          ],
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
  }

  Widget _buildBookingCardShimmer(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingRoomCard({
    required Map<String, dynamic> booking,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking ID: ${booking['bookingId'] ?? 'Unknown'}",
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Room data not found",
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF44336),
                      Color(0xFFD32F2F),
                    ],
                  ),
                ),
                child: Text(
                  "Room Missing",
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 12),
          Text(
            "User: ${booking['userEmail'] ?? 'Unknown'}",
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Status: ${booking['bookingStatus'] ?? 'Unknown'}",
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "User ID: ${booking['userId'] ?? 'Unknown'}",
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// UPDATED ROOM CARD WITH OWNER VIEW
// ==============================
class CompactRoomCardFromFirestore extends StatefulWidget {
  final Map<String, dynamic> room;
  final String roomDocumentId;
  final bool isSmallScreen;
  final bool isOwnerView;

  const CompactRoomCardFromFirestore({
    super.key,
    required this.room,
    required this.roomDocumentId,
    required this.isSmallScreen,
    this.isOwnerView = false,
  });

  @override
  State<CompactRoomCardFromFirestore> createState() => _CompactRoomCardFromFirestoreState();
}

class _CompactRoomCardFromFirestoreState extends State<CompactRoomCardFromFirestore> {
  bool _imageLoading = true;
  String? _userName; // Store fetched user name

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Find this code in your CompactRoomCardFromFirestore class and replace it:

  Future<void> _fetchUserName() async {
    if (widget.isOwnerView && widget.room['userId'] != null) {
      try {
        final userId = widget.room['userId'].toString();

        // Fetch user document from Firestore collection 'User' with document ID = userId
        final userDoc = await FirebaseFirestore.instance
            .collection('User') // Note: Capital 'U'
            .doc(userId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;

          // Get the name from 'Name' field (capital N)
          final String? fetchedName = userData['Name']?.toString();

          if (fetchedName != null && fetchedName.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userName = fetchedName;
              });
            }
          } else {
            // Fallback to email if no name found
            _fallbackToEmail();
          }
        } else {
          // User document doesn't exist
          _fallbackToEmail();
        }
      } catch (e) {
        print('Error fetching user name: $e');
        _fallbackToEmail();
      }
    } else {
      _fallbackToEmail();
    }
  }

  void _fallbackToEmail() {
    if (mounted) {
      final email = widget.room['userEmail']?.toString() ?? '';
      if (email.isNotEmpty) {
        // Extract name from email as fallback
        final emailParts = email.split('@').first;
        setState(() {
          _userName = emailParts
              .replaceAll('.', ' ')
              .split(' ')
              .map((part) => part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : '')
              .join(' ')
              .trim();
        });
      } else {
        setState(() {
          _userName = 'User';
        });
      }
    }
  }

  void _setFallbackName() {
    if (mounted) {
      setState(() {
        final email = widget.room['userEmail']?.toString() ?? '';
        if (email.isNotEmpty) {
          // Extract name from email
          final emailParts = email.split('@').first;
          _userName = emailParts
              .replaceAll('.', ' ')
              .split(' ')
              .map((part) => part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : '')
              .join(' ')
              .trim();
        } else {
          _userName = 'Unknown User';
        }
      });
    }
  }

  // Check if distance <= 2.0 km for badge display
  bool get _isNearKU {
    final distance = _getFormattedDistance();
    try {
      final match = RegExp(r'([0-9.]+)').firstMatch(distance);
      if (match != null) {
        final km = double.parse(match.group(1)!);
        return km <= 2.0;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  String _getFormattedDistance() {
    final distance = widget.room['distance']?.toString() ?? "0.0";
    if (!distance.toLowerCase().contains('km')) {
      return '$distance km';
    }
    return distance;
  }

  String _getStatus() {
    if (widget.isOwnerView) {
      // For owner view, use bookingStatus from booking data
      return widget.room['bookingStatus']?.toString().toLowerCase() ?? 'requested';
    } else {
      // For regular view, use room status
      return widget.room['status']?.toString().toLowerCase() ?? 'available';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'Requested';
      case 'booked':
        return 'Booked';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Available';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return const Color(0xFFFF9800); // Orange
      case 'booked':
        return const Color(0xFF7C3AED); // Purple
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      case 'rejected':
        return const Color(0xFF6B7280); // Grey
      case 'pending':
        return const Color(0xFFF59E0B); // Yellow
      default: // Available
        return const Color(0xFF4CAF50); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get image from Firestore
    final images = (widget.room['images'] as List<dynamic>?)?.whereType<String>().toList() ?? [];
    final mainImage = images.isNotEmpty ? images[0] : null;

    // Get data from Firestore with proper fallbacks
    final title = widget.room['roomName']?.toString() ?? "Unnamed Room";
    final walkTime = widget.room['walkTime']?.toString() ?? "0 min";
    final location = "$walkTime walk from KU Gate";
    final water = widget.room['water']?.toString() ?? "Available";
    final sunlight = widget.room['sunlight']?.toString() ?? "Good";
    final size = "${widget.room['size']?.toString() ?? '0'} Sq Ft";
    final priceNPR = widget.room['price'] is int ? widget.room['price'] as int : int.tryParse(widget.room['price']?.toString() ?? '0') ?? 0;
    final distance = _getFormattedDistance();
    final internetSpeed = "${widget.room['internet']?.toString() ?? '0'} Mbps";
    final status = _getStatus();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 16 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isSmallScreen ? 16 : 20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0).withOpacity(0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with improved caching and shimmer
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.isSmallScreen ? 16 : 20),
                  topRight: Radius.circular(widget.isSmallScreen ? 16 : 20),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: widget.isSmallScreen ? 150 : 170,
                  child: mainImage != null
                      ? _buildCachedImageWithShimmer(mainImage)
                      : Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              // Near KU Gate Badge
              if (_isNearKU)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "Near KU Gate",
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Room Details Section
          Padding(
            padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.quicksand(
                              fontSize: widget.isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Location with RED icon - walk time from Firestore
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: widget.isSmallScreen ? 13 : 15,
                                color: Colors.red,
                              ),
                              SizedBox(width: widget.isSmallScreen ? 4 : 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.quicksand(
                                    fontSize: widget.isSmallScreen ? 12 : 13,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Show user name with icon (for owner view)
                          if (widget.isOwnerView && widget.room['userId'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded, // Person icon
                                    size: widget.isSmallScreen ? 13 : 15, // Same size as location icon
                                    color: const Color(0xFF4F46E5), // Purple color
                                  ),
                                  SizedBox(width: widget.isSmallScreen ? 4 : 6),
                                  Expanded(
                                    child: Text(
                                      _userName ?? "Loading...",
                                      style: GoogleFonts.quicksand(
                                        fontSize: widget.isSmallScreen ? 12 : 13, // Same size as location
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600, // Same weight as location
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: widget.isSmallScreen ? 8 : 10),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _getStatusColor(status),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(status).withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: widget.isSmallScreen ? 10 : 12),

                // Features Pills - Water at left, Sunlight at right (made bolder)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Water (made bolder)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "💧 Water: $water",
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),

                    // Right side - Sunlight (made bolder)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "☀️ Sunlight: $sunlight",
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: widget.isSmallScreen ? 12 : 14),

                // Room Specifications Grid - Reduced boldness of value color
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompactSpecItem(
                        Icons.square_foot_rounded,
                        "Size",
                        size,
                        const Color(0xFF007AFF),
                        widget.isSmallScreen,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFE2E8F0).withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.wifi_rounded,
                        "Internet",
                        internetSpeed,
                        const Color(0xFF4CAF50),
                        widget.isSmallScreen,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFE2E8F0).withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.directions_walk_rounded,
                        "Distance",
                        distance,
                        const Color(0xFFFF9800),
                        widget.isSmallScreen,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: widget.isSmallScreen ? 12 : 14),

                // Price and Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Monthly Rent",
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "NPR",
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                color: const Color(0xFF64748B).withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              " $priceNPR",
                              style: GoogleFonts.quicksand(
                                fontSize: widget.isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B).withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "/month",
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                color: const Color(0xFF64748B).withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Small View Details Button
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => OwnerRoomDetailsDialog(
                              room: widget.room,
                              roomDocumentId: widget.roomDocumentId,
                              bookingId: widget.room['bookingId']?.toString() ?? '',
                              userId: widget.room['userId']?.toString() ?? '',
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isSmallScreen ? 14 : 16,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 34),
                          elevation: 0,
                        ),
                        child: Text(
                          "View Details",
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedImageWithShimmer(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cached Network Image
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
            child: _buildImageShimmer(),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(
                Icons.image_not_supported_rounded,
                color: Colors.grey.shade400,
                size: 40,
              ),
            ),
          ),
          imageBuilder: (context, imageProvider) {
            // Image loaded successfully
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _imageLoading) {
                setState(() {
                  _imageLoading = false;
                });
              }
            });

            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        color: Colors.white,
      ),
    );
  }

  // Helper to build compact specification item with reduced boldness of value color
  Widget _buildCompactSpecItem(
      IconData icon,
      String title,
      String value,
      Color color,
      bool isSmallScreen,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 18 : 20,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: isSmallScreen ? 11 : 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B).withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}