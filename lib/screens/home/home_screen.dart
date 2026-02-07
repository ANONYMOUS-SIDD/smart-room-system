import 'dart:async';
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
  bool _isPriceAscending = true;
  bool _isDistanceAscending = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<bool> _refreshController = StreamController<bool>.broadcast();

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void _refreshData() {
    _refreshController.add(true);
  }

  // Show sort options dialog
  void _showSortOptionsDialog(BuildContext context, bool isSmallScreen) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 320;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.45, // Slightly smaller height
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 12.0 : isSmallScreen ? 14.0 : 18.0,
            vertical: isVerySmallScreen ? 8.0 : isSmallScreen ? 10.0 : 12.0, // Reduced vertical padding
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: isVerySmallScreen ? 32.0 : 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 6.0 : 8.0), // Reduced spacing
              Center(
                child: Text(
                  'Sort Options',
                  style: GoogleFonts.quicksand(
                    fontSize: isVerySmallScreen ? 16.0 : isSmallScreen ? 17.0 : 19.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 8.0 : 12.0), // Reduced spacing

              // Sort Options - Smaller height
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCompactSortOption(
                      'Price: Low to High',
                      Icons.arrow_upward_rounded,
                      Colors.blue,
                          () {
                        setState(() {
                          _selectedSort = "Price";
                          _isPriceAscending = true;
                        });
                        Navigator.pop(context);
                        _refreshData();
                      },
                      isSelected: _selectedSort == "Price" && _isPriceAscending,
                      isVerySmallScreen: isVerySmallScreen,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isVerySmallScreen ? 4.0 : 6.0), // Reduced spacing
                    _buildCompactSortOption(
                      'Price: High to Low',
                      Icons.arrow_downward_rounded,
                      Colors.red,
                          () {
                        setState(() {
                          _selectedSort = "Price";
                          _isPriceAscending = false;
                        });
                        Navigator.pop(context);
                        _refreshData();
                      },
                      isSelected: _selectedSort == "Price" && !_isPriceAscending,
                      isVerySmallScreen: isVerySmallScreen,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isVerySmallScreen ? 4.0 : 6.0), // Reduced spacing
                    _buildCompactSortOption(
                      'Distance: Near to Far',
                      Icons.near_me_rounded,
                      Colors.green,
                          () {
                        setState(() {
                          _selectedSort = "Distance";
                          _isDistanceAscending = true;
                        });
                        Navigator.pop(context);
                        _refreshData();
                      },
                      isSelected: _selectedSort == "Distance" && _isDistanceAscending,
                      isVerySmallScreen: isVerySmallScreen,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isVerySmallScreen ? 4.0 : 6.0), // Reduced spacing
                    _buildCompactSortOption(
                      'Distance: Far to Near',
                      Icons.north_east_rounded,
                      Colors.purple,
                          () {
                        setState(() {
                          _selectedSort = "Distance";
                          _isDistanceAscending = false;
                        });
                        Navigator.pop(context);
                        _refreshData();
                      },
                      isSelected: _selectedSort == "Distance" && !_isDistanceAscending,
                      isVerySmallScreen: isVerySmallScreen,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isVerySmallScreen ? 4.0 : 6.0), // Reduced spacing
                    _buildCompactSortOption(
                      'Recent: Newest First', // Changed text
                      Icons.access_time_rounded,
                      Colors.orange,
                          () {
                        setState(() {
                          _selectedSort = "Recent";
                        });
                        Navigator.pop(context);
                        _refreshData();
                      },
                      isSelected: _selectedSort == "Recent",
                      isVerySmallScreen: isVerySmallScreen,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 6.0 : 8.0), // Reduced spacing

              // Close Button - Black
              SizedBox(
                width: double.infinity,
                height: isVerySmallScreen ? 36.0 : isSmallScreen ? 40.0 : 44.0, // Smaller height
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Black button
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isVerySmallScreen ? 8.0 : 10.0),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.quicksand(
                      fontSize: isVerySmallScreen ? 13.0 : isSmallScreen ? 14.0 : 15.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSortOption(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        bool isSelected = false,
        required bool isVerySmallScreen,
        required bool isSmallScreen,
      }) {
    final iconSize = isVerySmallScreen ? 14.0 : isSmallScreen ? 16.0 : 18.0; // Smaller icons
    final fontSize = isVerySmallScreen ? 12.0 : isSmallScreen ? 13.0 : 14.0; // Smaller font

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          padding: EdgeInsets.all(isVerySmallScreen ? 8.0 : isSmallScreen ? 10.0 : 12.0), // Reduced padding
          height: isVerySmallScreen ? 44.0 : isSmallScreen ? 48.0 : 52.0, // Fixed smaller height
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected ? Colors.cyan : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1.0,
            ),
            color: isSelected ? color.withOpacity(0.05) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: isVerySmallScreen ? 32.0 : 36.0, // Smaller container
                height: isVerySmallScreen ? 32.0 : 36.0, // Smaller container
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 10.0 : 12.0),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : Colors.black,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.verified_rounded,
                  color: color,
                  size: isVerySmallScreen ? 16.0 : isSmallScreen ? 18.0 : 20.0, // Smaller verified icon
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFullWidthOption(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        bool isSelected = false,
        required bool isVerySmallScreen,
        required bool isSmallScreen,
      }) {
    final iconSize = isVerySmallScreen ? 16.0 : isSmallScreen ? 18.0 : 20.0;
    final containerHeight = isVerySmallScreen ? 44.0 : isSmallScreen ? 48.0 : 52.0;
    final fontSize = isVerySmallScreen ? 13.0 : isSmallScreen ? 14.0 : 15.0;
    final iconContainerSize = isVerySmallScreen ? 32.0 : isSmallScreen ? 36.0 : 40.0;
    final padding = isVerySmallScreen ? 10.0 : isSmallScreen ? 12.0 : 14.0;

    return Material(
      borderRadius: BorderRadius.circular(10.0),
      color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: SizedBox(
          height: containerHeight,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isSelected ? color : Colors.transparent, // Only show border when selected
                width: isSelected ? 1.5 : 0.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isVerySmallScreen ? 10.0 : 12.0),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.verified_rounded, // Changed to verified icon
                    color: color,
                    size: isVerySmallScreen ? 18.0 : isSmallScreen ? 20.0 : 22.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        child: StreamBuilder<bool>(
          stream: Stream<bool>.value(true).asyncExpand((_) => _refreshController.stream),
          builder: (context, refreshSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('room')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error loading rooms',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildShimmerLoading(isSmallScreen);
                }

                final rooms = snapshot.data?.docs ?? [];
                final filteredRooms = _applyFiltersAndSort(rooms);

                // If no rooms found, show empty state
                if (filteredRooms.isEmpty) {
                  return _buildNoRoomsFound();
                }

                return ListView(
                  children: [
                    // Sort Button Container
                    _buildSortContainer(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 16.0 : 20.0),

                    // Results Title with reduced gap to cards
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16.0 : 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Showing Rooms in Dhulikhel",
                            style: GoogleFonts.quicksand(
                              fontSize: isSmallScreen ? 16.0 : 18.0,
                              fontWeight: FontWeight.w700,
                              color: ModernColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            "${filteredRooms.length} properties found",
                            style: GoogleFonts.quicksand(
                              fontSize: isSmallScreen ? 13.0 : 14.0,
                              color: ModernColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 12.0 : 16.0),

                    // Room Cards from Firestore with staggered animation
                    ...filteredRooms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final roomDoc = entry.value;
                      final room = roomDoc.data() as Map<String, dynamic>;
                      return FadeInWidget(
                        delay: Duration(milliseconds: 100 + (index * 100)),
                        child: CompactRoomCardFromFirestore(
                          room: room,
                          roomDocumentId: roomDoc.id,
                          isSmallScreen: isSmallScreen,
                          onStatusUpdate: _refreshData,
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 40.0),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoRoomsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80.0,
              color: ModernColors.onSurfaceVariant,
            ),
            const SizedBox(height: 24.0),
            Text(
              'No Rooms Found',
              style: GoogleFonts.quicksand(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: ModernColors.onSurface,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Check back later for new listings',
              style: GoogleFonts.quicksand(
                fontSize: 15.0,
                color: ModernColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<DocumentSnapshot> _applyFiltersAndSort(List<DocumentSnapshot> rooms) {
    List<DocumentSnapshot> filtered = List.from(rooms);

    // Filter out rooms with status "Booked"
    filtered = filtered.where((doc) {
      final room = doc.data() as Map<String, dynamic>;
      final status = room['status']?.toString() ?? '';
      return status.toLowerCase() != 'booked';
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      final roomA = a.data() as Map<String, dynamic>;
      final roomB = b.data() as Map<String, dynamic>;

      switch (_selectedSort) {
        case "Price":
          final priceA = roomA['price'] ?? 0;
          final priceB = roomB['price'] ?? 0;
          return _isPriceAscending
              ? (priceA as int).compareTo(priceB as int)
              : (priceB as int).compareTo(priceA as int);
        case "Distance":
          final distA = _parseDistance(roomA['distance']);
          final distB = _parseDistance(roomB['distance']);
          return _isDistanceAscending
              ? distA.compareTo(distB)
              : distB.compareTo(distA);
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

  Widget _buildSortContainer(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 20.0, vertical: 8.0),
      padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 14.0 : 16.0),
        color: ModernColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isSmallScreen ? 6.0 : 8.0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(  // This line was missing closing parenthesis
          color: ModernColors.outline.withOpacity(0.15),
          width: 1.0,
        ),
      ),  // Added missing closing parenthesis here
      child: GestureDetector(
        onTap: () => _showSortOptionsDialog(context, isSmallScreen),
        child: Container(
          height: isSmallScreen ? 40.0 : 44.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10.0 : 12.0),
            color: Colors.white,
            border: Border.all(
              color: ModernColors.outline.withOpacity(0.4),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8.0 : 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 26.0 : 28.0,
                      height: isSmallScreen ? 26.0 : 28.0,
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 6.0 : 7.0),
                      ),
                      child: Icon(
                        Icons.sort_rounded,
                        size: isSmallScreen ? 15.0 : 16.0,
                        color: Colors.cyan,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                    Text(
                      _getSortDisplayText(),
                      style: GoogleFonts.quicksand(
                        fontSize: isSmallScreen ? 13.0 : 14.0,
                        fontWeight: FontWeight.w700,
                        color: ModernColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ModernColors.onSurfaceVariant.withOpacity(0.7),
                  size: isSmallScreen ? 18.0 : 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSortDisplayText() {
    switch (_selectedSort) {
      case "Price":
        return _isPriceAscending ? "Price: Low to High" : "Price: High to Low";
      case "Distance":
        return _isDistanceAscending ? "Distance: Near to Far" : "Distance: Far to Near";
      case "Recent":
        return "Newest First";
      default:
        return "Price";
    }
  }

  Widget _buildShimmerLoading(bool isSmallScreen) {
    return ListView(
      children: [
        SizedBox(height: isSmallScreen ? 12.0 : 16.0),
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 20.0),
          padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 14.0 : 16.0),
            color: Colors.white,
          ),
          child: Container(
            height: isSmallScreen ? 40.0 : 44.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 10.0 : 12.0),
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16.0 : 20.0),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200.0,
                height: 20.0,
                color: Colors.white,
              ),
              SizedBox(height: 2.0),
              Container(
                width: 150.0,
                height: 16.0,
                color: Colors.white,
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 1.0 : 16.0),
        // Shimmer cards with staggered animation
        ...List.generate(3, (index) {
          return FadeInWidget(
            delay: Duration(milliseconds: 100 + (index * 100)),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16.0 : 20.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 20.0),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    height: isSmallScreen ? 150.0 : 170.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallScreen ? 16.0 : 20.0),
                        topRight: Radius.circular(isSmallScreen ? 16.0 : 20.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 150.0,
                                    height: 20.0,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 6.0),
                                  Container(
                                    width: 200.0,
                                    height: 16.0,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60.0,
                              height: 24.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 10.0 : 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 100.0,
                              height: 28.0,
                              color: Colors.white,
                            ),
                            Container(
                              width: 100.0,
                              height: 28.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12.0 : 14.0),
                        Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int j = 0; j < 3; j++)
                                Container(
                                  width: 80.0,
                                  height: 60.0,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12.0 : 14.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80.0,
                                  height: 14.0,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 2.0),
                                Container(
                                  width: 120.0,
                                  height: 24.0,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            Container(
                              width: 100.0,
                              height: 34.0,
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
          );
        }).toList(),
      ],
    );
  }
}

// ==============================
// FADE IN WIDGET FOR STAGGERED ANIMATIONS
// ==============================
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInWidget({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0.0, _offset.value.dy * 20),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ==============================
// COMPACT ROOM CARD FROM FIRESTORE
// ==============================
class CompactRoomCardFromFirestore extends StatefulWidget {
  final Map<String, dynamic> room;
  final String roomDocumentId;
  final bool isSmallScreen;
  final VoidCallback? onStatusUpdate;

  const CompactRoomCardFromFirestore({
    super.key,
    required this.room,
    required this.roomDocumentId,
    required this.isSmallScreen,
    this.onStatusUpdate,
  });

  @override
  State<CompactRoomCardFromFirestore> createState() => _CompactRoomCardFromFirestoreState();
}

class _CompactRoomCardFromFirestoreState extends State<CompactRoomCardFromFirestore> {
  bool _imageLoading = true;
  bool _isRoomRequested = false;
  bool _isLoadingStatus = true;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;

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

  @override
  void initState() {
    super.initState();
    _checkRoomStatus();
    _startListeningToUpdates();
  }

  void _startListeningToUpdates() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('room')
        .doc(widget.roomDocumentId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && mounted) {
        final updatedData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          widget.room.clear();
          widget.room.addAll(updatedData);
          _checkRoomStatus();
        });
        widget.onStatusUpdate?.call();
      }
    }, onError: (error) {
      debugPrint("Error listening to room updates: $error");
    });
  }

  void _checkRoomStatus() {
    try {
      final status = widget.room['status']?.toString() ?? '';
      setState(() {
        _isRoomRequested = status.toLowerCase() == 'requested';
        _isLoadingStatus = false;
      });
    } catch (e) {
      debugPrint("Error checking room status: $e");
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CompactRoomCardFromFirestore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomDocumentId != widget.roomDocumentId) {
      _roomSubscription?.cancel();
      _startListeningToUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.room['images'] as List<dynamic>?)?.whereType<String>().toList() ?? [];
    final mainImage = images.isNotEmpty ? images[0] : null;

    final title = widget.room['roomName']?.toString() ?? "Unnamed Room";
    final walkTime = widget.room['walkTime']?.toString() ?? "0 min";
    final location = "$walkTime walk from KU Gate";
    final water = widget.room['water']?.toString() ?? "Available";
    final sunlight = widget.room['sunlight']?.toString() ?? "Good";
    final hasBathroom = widget.room['bathroom']?.toString() == "Yes" || widget.room['bathroom'] == true;
    final size = "${widget.room['size']?.toString() ?? '0'} Sq Ft";
    final priceNPR = widget.room['price'] is int ? widget.room['price'] as int : int.tryParse(widget.room['price']?.toString() ?? '0') ?? 0;
    final distance = _getFormattedDistance();
    final internetSpeed = "${widget.room['internet']?.toString() ?? '0'} Mbps";
    final fullLocation = widget.room['location']?.toString() ?? "Location not specified";

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 16.0 : 20.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isSmallScreen ? 16.0 : 20.0),
        color: ModernColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8.0,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.isSmallScreen ? 16.0 : 20.0),
                  topRight: Radius.circular(widget.isSmallScreen ? 16.0 : 20.0),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: widget.isSmallScreen ? 150.0 : 170.0,
                  child: mainImage != null
                      ? _buildCachedImageWithShimmer(mainImage)
                      : Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: Colors.grey.shade400,
                        size: 40.0,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isNearKU)
                Positioned(
                  top: 10.0,
                  right: 10.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: ModernColors.primary.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "Near KU Gate",
                      style: GoogleFonts.quicksand(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(widget.isSmallScreen ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              fontSize: widget.isSmallScreen ? 15.0 : 17.0,
                              fontWeight: FontWeight.w800,
                              color: ModernColors.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: widget.isSmallScreen ? 13.0 : 15.0,
                                color: Colors.red,
                              ),
                              SizedBox(width: widget.isSmallScreen ? 4.0 : 6.0),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.quicksand(
                                    fontSize: widget.isSmallScreen ? 12.0 : 13.0,
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
                    SizedBox(width: widget.isSmallScreen ? 8.0 : 10.0),
                    if (_isLoadingStatus)
                      Container(
                        width: 60.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.grey.shade300,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 12.0,
                            height: 12.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isRoomRequested
                                ? [
                              Color(0xFFFF9800),
                              Color(0xFFF57C00),
                            ]
                                : [
                              Color(0xFF4CAF50),
                              Color(0xFF2E7D32),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRoomRequested
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF4CAF50))
                                  .withOpacity(0.3),
                              blurRadius: 5.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _isRoomRequested ? "Requested" : "Available",
                          style: GoogleFonts.quicksand(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: widget.isSmallScreen ? 10.0 : 12.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        "💧 Water: $water",
                        style: GoogleFonts.quicksand(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        "☀️ Sunlight: $sunlight",
                        style: GoogleFonts.quicksand(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: widget.isSmallScreen ? 12.0 : 14.0),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: ModernColors.background.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompactSpecItem(
                        Icons.square_foot_rounded,
                        "Size",
                        size,
                        ModernColors.primary,
                        widget.isSmallScreen,
                      ),
                      Container(
                        height: 28.0,
                        width: 1.0,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.wifi_rounded,
                        "Internet",
                        internetSpeed,
                        const Color(0xFF4CAF50),
                        widget.isSmallScreen,
                      ),
                      Container(
                        height: 28.0,
                        width: 1.0,
                        color: ModernColors.outline.withOpacity(0.3),
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

                SizedBox(height: widget.isSmallScreen ? 12.0 : 14.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Monthly Rent",
                          style: GoogleFonts.quicksand(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: ModernColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "NPR",
                              style: GoogleFonts.quicksand(
                                fontSize: 12.0,
                                color: ModernColors.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3.0),
                            Text(
                              " $priceNPR",
                              style: GoogleFonts.quicksand(
                                fontSize: widget.isSmallScreen ? 20.0 : 22.0,
                                fontWeight: FontWeight.w800,
                                color: ModernColors.onSurface.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 3.0),
                            Text(
                              "/month",
                              style: GoogleFonts.quicksand(
                                fontSize: 11.0,
                                color: ModernColors.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 34.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
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
                            blurRadius: 5.0,
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
                                'status': _isRoomRequested ? 'Requested' : 'Available',
                              },
                              roomDocumentId: widget.roomDocumentId,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isSmallScreen ? 14.0 : 16.0,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 34),
                          elevation: 0,
                        ),
                        child: Text(
                          "View Details",
                          style: GoogleFonts.quicksand(
                            fontSize: 11.0,
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
                size: 40.0,
              ),
            ),
          ),
          imageBuilder: (context, imageProvider) {
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
          size: isSmallScreen ? 18.0 : 20.0,
          color: color,
        ),
        const SizedBox(height: 6.0),
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 11.0,
            color: ModernColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3.0),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: isSmallScreen ? 11.0 : 12.0,
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
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0056CC);
  static const Color primaryContainer = Color(0xFFE3F2FD);

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF2F2F7);

  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color onSurfaceVariant = Color(0xFF8E8E93);

  static const Color outline = Color(0xFFC7C7CC);
}