import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/modern_app_bar.dart';
import 'detail_dialog.dart';
import 'owner_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==============================
  // STATE VARIABLES
  // ==============================
  String _selectedSort = "Price";
  bool _bathroomFilter = false;
  String _waterFilter = "Any";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: ModernAppBar(
        title: "Smart Room Rental",
        showAddButton: true,
        onAddPressed: () {
          showDialog(
            context: context,
            builder: (context) => const OwnerSectionDialog(),
          );
        },
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('room')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading(isSmallScreen);
            }

            final rooms = snapshot.data!.docs;
            final filteredRooms = _applyFiltersAndSort(rooms);

            return CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Compact iOS-like Container for Price & Filter
                    _buildCompactIOSFilterContainer(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Results Title with reduced gap to cards
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Showing Rooms in Dhulikhel",
                            style: GoogleFonts.quicksand(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: ModernColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${filteredRooms.length} properties found",
                            style: GoogleFonts.quicksand(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: ModernColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 1 : 16),

                    // Room Cards from Firestore
                    ...filteredRooms.map((roomDoc) {
                      final room = roomDoc.data() as Map<String, dynamic>;
                      return CompactRoomCardFromFirestore(
                        room: room,
                        isSmallScreen: isSmallScreen,
                      );
                    }).toList(),

                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<DocumentSnapshot> _applyFiltersAndSort(List<DocumentSnapshot> rooms) {
    List<DocumentSnapshot> filtered = List.from(rooms);

    // Apply bathroom filter
    if (_bathroomFilter) {
      filtered = filtered.where((doc) {
        final room = doc.data() as Map<String, dynamic>;
        final bathroom = room['bathroom'];
        return bathroom == "Yes" || bathroom == true;
      }).toList();
    }

    // Apply water filter
    if (_waterFilter != "Any") {
      filtered = filtered.where((doc) {
        final room = doc.data() as Map<String, dynamic>;
        return room['water'] == _waterFilter;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      final roomA = a.data() as Map<String, dynamic>;
      final roomB = b.data() as Map<String, dynamic>;

      switch (_selectedSort) {
        case "Price":
          final priceA = roomA['price'] ?? 0;
          final priceB = roomB['price'] ?? 0;
          return (priceA as int).compareTo(priceB as int);
        case "Distance":
          final distA = _parseDistance(roomA['distance']);
          final distB = _parseDistance(roomB['distance']);
          return distA.compareTo(distB);
        case "Recent":
          final dateA = roomA['createdAt'] as Timestamp?;
          final dateB = roomB['createdAt'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        default:
          return 0;
      }
    });

    return filtered;
  }

  double _parseDistance(dynamic distance) {
    if (distance == null) return 0.0;

    String distanceStr;
    if (distance is String) {
      distanceStr = distance;
    } else if (distance is int || distance is double) {
      return distance.toDouble();
    } else {
      return 0.0;
    }

    try {
      final match = RegExp(r'([0-9.]+)').firstMatch(distanceStr);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    } catch (e) {
      return 0.0;
    }
    return 0.0;
  }

  Widget _buildCompactIOSFilterContainer(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        color: ModernColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isSmallScreen ? 6 : 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: ModernColors.outline.withOpacity(0.15),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Price Button with Dollar Icon in Container
          Expanded(
            child: Container(
              height: isSmallScreen ? 40 : 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: Colors.white,
                border: Border.all(
                  color: ModernColors.outline.withOpacity(0.4),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Dollar Icon Container
                        Container(
                          width: isSmallScreen ? 26 : 28,
                          height: isSmallScreen ? 26 : 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 7),
                          ),
                          child: Icon(
                            Icons.attach_money_rounded,
                            size: isSmallScreen ? 15 : 16,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          _selectedSort,
                          style: GoogleFonts.quicksand(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: ModernColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ModernColors.onSurfaceVariant.withOpacity(0.7),
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: isSmallScreen ? 6 : 8),

          // Filters Button with Filter Icon in Container
          Expanded(
            child: Container(
              height: isSmallScreen ? 40 : 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: Colors.white,
                border: Border.all(
                  color: ModernColors.outline.withOpacity(0.4),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Filter Icon Container
                        Container(
                          width: isSmallScreen ? 26 : 28,
                          height: isSmallScreen ? 26 : 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 7),
                          ),
                          child: Icon(
                            Icons.filter_alt_rounded,
                            size: isSmallScreen ? 15 : 16,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          "Filters",
                          style: GoogleFonts.quicksand(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: ModernColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ModernColors.onSurfaceVariant.withOpacity(0.7),
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isSmallScreen) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: isSmallScreen ? 12 : 16),
              Container(
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: isSmallScreen ? 40 : 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Container(
                        height: isSmallScreen ? 40 : 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 20,
                      color: Colors.white,
                    ),
                    SizedBox(height: 2),
                    Container(
                      width: 150,
                      height: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 1 : 16),
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
                                      SizedBox(height: 6),
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
                              padding: EdgeInsets.all(12),
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
                                    SizedBox(height: 2),
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
              SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }
}

// ==============================
// COMPACT ROOM CARD FROM FIRESTORE
// ==============================
class CompactRoomCardFromFirestore extends StatefulWidget {
  final Map<String, dynamic> room;
  final bool isSmallScreen;

  const CompactRoomCardFromFirestore({
    super.key,
    required this.room,
    required this.isSmallScreen,
  });

  @override
  State<CompactRoomCardFromFirestore> createState() => _CompactRoomCardFromFirestoreState();
}

class _CompactRoomCardFromFirestoreState extends State<CompactRoomCardFromFirestore> {
  bool _imageLoading = true;

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
    // If distance doesn't contain "km", add it
    if (!distance.toLowerCase().contains('km')) {
      return '$distance km';
    }
    return distance;
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
    final hasBathroom = widget.room['bathroom']?.toString() == "Yes" || widget.room['bathroom'] == true;
    final size = "${widget.room['size']?.toString() ?? '0'} Sq Ft";
    final priceNPR = widget.room['price'] is int ? widget.room['price'] as int : int.tryParse(widget.room['price']?.toString() ?? '0') ?? 0;
    final distance = _getFormattedDistance(); // Now properly formatted with "km"
    final internetSpeed = "${widget.room['internet']?.toString() ?? '0'} Mbps";
    final fullLocation = widget.room['location']?.toString() ?? "Location not specified";

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 16 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isSmallScreen ? 16 : 20),
        color: ModernColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: ModernColors.outline.withOpacity(0.15),
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
                      color: ModernColors.primary.withOpacity(0.95),
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
                            title, // Room name from Firestore
                            style: GoogleFonts.quicksand(
                              fontSize: widget.isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: ModernColors.onSurface,
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
                                  location, // Walk time from Firestore
                                  style: GoogleFonts.quicksand(
                                    fontSize: widget.isSmallScreen ? 12 : 13,
                                    color: ModernColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: widget.isSmallScreen ? 8 : 10),
                    // Status Badge with Pink Gradient for Available (hardcoded as requested)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF6B6B), // Coral red
                            Color(0xFFFF5252), // Bright red
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Available", // Hardcoded as requested
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
                        "💧 Water: $water", // Water from Firestore
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
                        "☀️ Sunlight: $sunlight", // Sunlight from Firestore
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
                    color: ModernColors.background.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompactSpecItem(
                        Icons.square_foot_rounded,
                        "Size",
                        size, // Size from Firestore
                        ModernColors.primary,
                        widget.isSmallScreen,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.wifi_rounded,
                        "Internet",
                        internetSpeed, // Internet from Firestore
                        const Color(0xFF4CAF50),
                        widget.isSmallScreen,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.directions_walk_rounded,
                        "Distance",
                        distance, // Distance from Firestore with "km"
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
                            color: ModernColors.onSurfaceVariant,
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
                                color: ModernColors.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              " $priceNPR", // Price from Firestore
                              style: GoogleFonts.quicksand(
                                fontSize: widget.isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.w800,
                                color: ModernColors.onSurface.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "/month",
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                color: ModernColors.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Small View Details Button - UPDATED TO USE BOTTOM SHEET
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ModernColors.primary,
                            ModernColors.primaryDark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ModernColors.primary.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Show the new bottom sheet instead of navigating to DetailsScreen
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => RoomDetailsBottomSheet(
                              room: {
                                'images': images,
                                'roomName': title,
                                'location': fullLocation,
                                'distance': distance,
                                'internet': widget.room['internet'],
                                'price': priceNPR,
                                'water': water,
                                'sunlight': sunlight,
                                'bathroom': hasBathroom,
                                'size': widget.room['size']?.toString() ?? '0',
                                'walkTime': walkTime,
                                'latitude': widget.room['latitude'],
                                'longitude': widget.room['longitude'],
                                'aiPrice': widget.room['aiPrice'],
                              },
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
            color: ModernColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: isSmallScreen ? 11 : 12,
            fontWeight: FontWeight.w800,
            color: ModernColors.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

// Modern Colors Palette
class ModernColors {
  static const Color primary = Color(0xFF007AFF); // iOS blue
  static const Color primaryDark = Color(0xFF0056CC);
  static const Color primaryContainer = Color(0xFFE3F2FD);

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF2F2F7);

  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color onSurfaceVariant = Color(0xFF8E8E93);

  static const Color outline = Color(0xFFC7C7CC);
}