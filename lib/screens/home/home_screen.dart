import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ==============================
  // SAMPLE ROOM DATA
  // ==============================
  final List<Map<String, dynamic>> _rooms = [
    {
      "image": "assets/images/room1_img.jpg",
      "houseNumber": "10801",
      "title": "Modern Cozy Room",
      "location": "10 mins walk from KU Gate",
      "features": "Attached bathroom | Good Sunlight | 24/7 Water",
      "size": "120 Sq Ft",
      "priceNPR": 5850,
      "distance": "0.8 km",
      "internetSpeed": "50 Mbps",
      "created_at": DateTime(2024, 1, 10),
      "water": "24/7 Available",
      "sunlight": "Good",
      "hasBathroom": true,
      "status": "Available",
    },
    {
      "image": "assets/images/room2_img.jpg",
      "houseNumber": "20235",
      "title": "Spacious Studio",
      "location": "8 mins walk from KU Gate",
      "features": "Attached bathroom | Moderate Sunlight | Available Water",
      "size": "130 Sq Ft",
      "priceNPR": 6200,
      "distance": "0.6 km",
      "internetSpeed": "75 Mbps",
      "created_at": DateTime(2024, 1, 15),
      "water": "Available",
      "sunlight": "Moderate",
      "hasBathroom": true,
      "status": "Requested",
    },
    {
      "image": "assets/images/room1_img.jpg",
      "houseNumber": "30456",
      "title": "Premium Room",
      "location": "25 mins walk from KU Gate",
      "features": "Shared bathroom | Poor Sunlight | Limited Water",
      "size": "110 Sq Ft",
      "priceNPR": 4500,
      "distance": "2.3 km",
      "internetSpeed": "30 Mbps",
      "created_at": DateTime(2024, 1, 5),
      "water": "Limited",
      "sunlight": "Poor",
      "hasBathroom": false,
      "status": "Available",
    },
  ];

  // Filter and sort rooms based on current filters and sort selection
  List<Map<String, dynamic>> _getFilteredRooms() {
    List<Map<String, dynamic>> filtered = List.from(_rooms);

    // Apply bathroom filter
    if (_bathroomFilter) {
      filtered = filtered.where((room) => room['hasBathroom'] == true).toList();
    }

    // Apply water filter
    if (_waterFilter != "Any") {
      filtered = filtered.where((room) => room['water'] == _waterFilter).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case "Price":
          return a['priceNPR'].compareTo(b['priceNPR']);
        case "Distance":
          final aDist = double.tryParse(a['distance'].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          final bDist = double.tryParse(b['distance'].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return aDist.compareTo(bDist);
        case "Recent":
          return b['created_at'].compareTo(a['created_at']);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = _getFilteredRooms();
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
        child: CustomScrollView(
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
                      const SizedBox(height: 2), // Reduced from 4px to 2px
                      Text(
                        "${filteredRooms.length} properties found",
                        style: GoogleFonts.quicksand(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: ModernColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600, // Made bolder (was w500)
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 10 : 16), // Reduced gap from 16/20 to 12/16

                // Room Cards
                ...filteredRooms.map((room) {
                  return CompactRoomCard(
                    imagePath: room['image'],
                    title: room['title'],
                    location: room['location'],
                    water: room['water'],
                    sunlight: room['sunlight'],
                    hasBathroom: room['hasBathroom'],
                    size: room['size'],
                    priceNPR: room['priceNPR'],
                    distance: room['distance'],
                    internetSpeed: room['internetSpeed'],
                    status: room['status'],
                    isSmallScreen: isSmallScreen,
                  );
                }).toList(),

                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactIOSFilterContainer(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12), // Reduced padding for compactness
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
          width: 1.0, // Thinner border for iOS-like appearance
        ),
      ),
      child: Row(
        children: [
          // Price Button with Dollar Icon in Container
          Expanded(
            child: Container(
              height: isSmallScreen ? 40 : 44, // More compact height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: Colors.white,
                border: Border.all(
                  color: ModernColors.outline.withOpacity(0.4), // Thinner iOS-like border
                  width: 1.0, // Thinner border
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10, // Reduced horizontal padding
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Dollar Icon Container
                        Container(
                          width: isSmallScreen ? 26 : 28, // Smaller container
                          height: isSmallScreen ? 26 : 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.08), // Lighter background
                            borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 7),
                          ),
                          child: Icon(
                            Icons.attach_money_rounded,
                            size: isSmallScreen ? 15 : 16, // Smaller icon
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8), // Reduced spacing
                        Text(
                          _selectedSort,
                          style: GoogleFonts.quicksand(
                            fontSize: isSmallScreen ? 13 : 14, // Slightly smaller font
                            fontWeight: FontWeight.w700,
                            color: ModernColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ModernColors.onSurfaceVariant.withOpacity(0.7),
                      size: isSmallScreen ? 18 : 20, // Smaller arrow
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: isSmallScreen ? 6 : 8), // Reduced spacing between buttons

          // Filters Button with Filter Icon in Container
          Expanded(
            child: Container(
              height: isSmallScreen ? 40 : 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: Colors.white,
                border: Border.all(
                  color: ModernColors.outline.withOpacity(0.4), // Thinner iOS-like border
                  width: 1.0, // Thinner border
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
                            color: const Color(0xFF4CAF50).withOpacity(0.08), // Lighter background
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
}

// ==============================
// COMPACT ROOM CARD WIDGET
// ==============================
class CompactRoomCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;
  final String water;
  final String sunlight;
  final bool hasBathroom;
  final String size;
  final int priceNPR;
  final String distance;
  final String internetSpeed;
  final String status;
  final bool isSmallScreen;

  const CompactRoomCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.water,
    required this.sunlight,
    required this.hasBathroom,
    required this.size,
    required this.priceNPR,
    required this.distance,
    required this.internetSpeed,
    required this.status,
    required this.isSmallScreen,
  });

  // Check if distance <= 2.0 km for badge display
  bool get _isNearKU {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                  topRight: Radius.circular(isSmallScreen ? 16 : 20),
                ),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: isSmallScreen ? 150 : 170,
                  fit: BoxFit.cover,
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
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: ModernColors.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Location with RED icon
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: isSmallScreen ? 13 : 15,
                                color: Colors.red,
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.quicksand(
                                    fontSize: isSmallScreen ? 12 : 13,
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
                    SizedBox(width: isSmallScreen ? 8 : 10),
                    // Status Badge with Pink Gradient for Available
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: status == "Available"
                            ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF6B6B), // Coral red
                            Color(0xFFFF5252), // Bright red
                          ],
                        )
                            : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF9A3D), // Orange
                            Color(0xFFFF7B00), // Dark orange
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: status == "Available"
                                ? const Color(0xFFFF5252).withOpacity(0.3)
                                : const Color(0xFFFF7B00).withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        status,
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

                SizedBox(height: isSmallScreen ? 10 : 12),

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
                          fontWeight: FontWeight.w700, // Made bolder (was w600)
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
                          fontWeight: FontWeight.w700, // Made bolder (was w600)
                          color: const Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 12 : 14),

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
                        size,
                        ModernColors.primary,
                        isSmallScreen,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.wifi_rounded,
                        "Internet",
                        internetSpeed,
                        const Color(0xFF4CAF50),
                        isSmallScreen,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                      _buildCompactSpecItem(
                        Icons.directions_walk_rounded,
                        "Distance",
                        distance,
                        const Color(0xFFFF9800),
                        isSmallScreen,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 14),

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
                              " $priceNPR",
                              style: GoogleFonts.quicksand(
                                fontSize: isSmallScreen ? 20 : 22,
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

                    // Small View Details Button
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(
                                room: {
                                  'image': imagePath,
                                  'images': [imagePath],
                                  'houseNumber': '30456',
                                  'location': location,
                                  'distance': distance,
                                  'internetSpeed': internetSpeed,
                                  'priceNPR': priceNPR,
                                  'water': water,
                                  'sunlight': sunlight,
                                  'hasBathroom': hasBathroom,
                                  'size': size,
                                  'created_at': DateTime.now(),
                                },
                                currency: "NPR",
                                conversionRate: 145,
                              ),
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
                            horizontal: isSmallScreen ? 14 : 16,
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
            color: ModernColors.onSurface.withOpacity(0.8), // Reduced boldness of color
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