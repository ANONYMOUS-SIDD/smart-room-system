import 'package:flutter/material.dart';
import 'details.dart';

/*
CHANGELOG:
1. Fixed popup menus to match light-blue theme (background, border, text color)
2. Improved price baseline alignment using CrossAxisAlignment.baseline
3. Ensured iOS-like tan border (Color(0xFFF4EFEA)) is properly applied
4. Maintained emoji feature pills and red location icon colors
*/

/*
DEVELOPER NOTES:
This file contains the Buyer Home Screen for Smart Room Rental App.
Later when integrating Supabase, the room data will come from:
- 'rooms' table with fields: image, houseNumber, location, distance, 
  internetSpeed, features, priceNPR, created_at, water, bathroom, sunlight, is_available
- The features string can be parsed for bathroom/water/sunlight keywords
- Currency conversion will remain client-side for now
*/

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==============================
  // STATE VARIABLES
  // ==============================
  String _currency = "NPR"; // Default currency is NPR
  final int _conversionRate = 145; // 1 USD = 145 NPR for currency conversion
  String _selectedSort = "Price";
  bool _bathroomFilter = false;
  String _waterFilter = "Any";

  // GlobalKeys for popup positioning - used to calculate menu placement
  final GlobalKey _currencyButtonKey = GlobalKey();
  final GlobalKey _sortButtonKey = GlobalKey();

  // ==============================
  // SAMPLE ROOM DATA
  // ==============================
  final List<Map<String, dynamic>> _rooms = [
    {
      "image": "assets/images/room1_img.jpg",
      "houseNumber": "10801",
      "location": "Khadpu | 10 mins walk from KU Gate",
      "features": "Attached bathroom | Good Sunlight | 24/7 Water",
      "size": "12 x 15 ft²",
      "priceNPR": 5850,
      "distance": "0.8 km",
      "internetSpeed": "50 Mbps",
      "created_at": DateTime(2024, 1, 10),
      "water": "24/7 Available",
      "sunlight": "Good",
      "hasBathroom": true,
    },
    {
      "image": "assets/images/room2_img.jpg",
      "houseNumber": "20235",
      "location": "Khadpu | 8 mins walk from KU Gate",
      "features": "Attached bathroom | Moderate Sunlight | Available Water",
      "size": "14 x 16 ft²",
      "priceNPR": 6200,
      "distance": "0.6 km",
      "internetSpeed": "75 Mbps",
      "created_at": DateTime(2024, 1, 15),
      "water": "Available",
      "sunlight": "Moderate",
      "hasBathroom": true,
    },
    {
      "image": "assets/images/room1_img.jpg",
      "houseNumber": "30456",
      "location": "Sangkhu | 25 mins walk from KU Gate",
      "features": "Shared bathroom | Poor Sunlight | Limited Water",
      "size": "10 x 12 ft²",
      "priceNPR": 4500,
      "distance": "2.3 km",
      "internetSpeed": "30 Mbps",
      "created_at": DateTime(2024, 1, 5),
      "water": "Limited",
      "sunlight": "Poor",
      "hasBathroom": false,
    },
  ];

  // ==============================
  // HELPER FUNCTIONS
  // ==============================
  // Parse distance string and check if <= 2.0 km for badge display
  bool _isNearKU(String distance) {
    try {
      // Extract numeric value from distance string (e.g., "0.8 km" -> 0.8)
      final match = RegExp(r'([0-9.]+)').firstMatch(distance);
      if (match != null) {
        final km = double.parse(match.group(1)!);
        return km <= 2.0; // Distance badge logic: show only if ≤ 2.0 km
      }
    } catch (e) {
      // If parsing fails, assume not near KU
      return false;
    }
    return false;
  }

  // Currency conversion with edge case handling
  int _getConvertedPrice(int priceNPR) {
    if (_currency == "USD") {
      final converted = (priceNPR / _conversionRate).floor();
      return converted == 0
          ? 1
          : converted; // Ensure non-zero display for very small prices
    }
    return priceNPR;
  }

  // Filter and sort rooms based on current filters and sort selection
  List<Map<String, dynamic>> _getFilteredRooms() {
    List<Map<String, dynamic>> filtered = List.from(_rooms);

    // Apply bathroom filter (AND logic with water filter)
    if (_bathroomFilter) {
      filtered = filtered.where((room) => room['hasBathroom'] == true).toList();
    }

    // Apply water filter
    if (_waterFilter != "Any") {
      filtered = filtered
          .where((room) => room['water'] == _waterFilter)
          .toList();
    }

    // Apply sorting based on selected sort option
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case "Price":
          return a['priceNPR'].compareTo(
            b['priceNPR'],
          ); // Default ascending price
        case "Distance":
          // Parse distance for numeric comparison
          final aDist =
              double.tryParse(
                a['distance'].replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0;
          final bDist =
              double.tryParse(
                b['distance'].replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0;
          return aDist.compareTo(bDist);
        case "Recent":
          return b['created_at'].compareTo(a['created_at']); // Newest first
        default:
          return 0;
      }
    });

    return filtered;
  }

  // Show currency selection menu with proper positioning using GlobalKey
  void _showCurrencyMenu() async {
    final RenderBox button =
        _currencyButtonKey.currentContext?.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(
              _currencyButtonKey.currentContext!,
            ).context.findRenderObject()
            as RenderBox;

    // Calculate RelativeRect for menu positioning (appears below button)
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: _currencyButtonKey.currentContext!,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        side: const BorderSide(
          color: Color(0xFF1E6FF6),
          width: 1,
        ), // Bluish border
      ),
      color: const Color(0xFFEAF4FF), // Light blue background matching pill
      items: [
        PopupMenuItem<String>(
          value: "NPR",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NPR",
                style: TextStyle(color: Colors.blue.shade900), // Bluish text
              ),
              if (_currency == "NPR")
                Icon(
                  Icons.check,
                  color: const Color(0xFF1E6FF6),
                  size: 20,
                ), // Bluish check
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "USD",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "USD (\$)",
                style: TextStyle(color: Colors.blue.shade900), // Bluish text
              ),
              if (_currency == "USD")
                Icon(
                  Icons.check,
                  color: const Color(0xFF1E6FF6),
                  size: 20,
                ), // Bluish check
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _currency = value; // Update currency and refresh UI
        });
      }
    });
  }

  // Show sort menu with proper positioning using GlobalKey
  void _showSortMenu() async {
    final RenderBox button =
        _sortButtonKey.currentContext?.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(_sortButtonKey.currentContext!).context.findRenderObject()
            as RenderBox;

    // Calculate RelativeRect for menu positioning (appears below button)
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: _sortButtonKey.currentContext!,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        side: const BorderSide(
          color: Color(0xFF1E6FF6),
          width: 1,
        ), // Bluish border
      ),
      color: const Color(0xFFEAF4FF), // Light blue background matching pill
      items: [
        PopupMenuItem<String>(
          value: "Price",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price",
                style: TextStyle(color: Colors.blue.shade900), // Bluish text
              ),
              if (_selectedSort == "Price")
                Icon(
                  Icons.check,
                  color: const Color(0xFF1E6FF6),
                  size: 20,
                ), // Bluish check
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "Distance",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Distance",
                style: TextStyle(color: Colors.blue.shade900), // Bluish text
              ),
              if (_selectedSort == "Distance")
                Icon(
                  Icons.check,
                  color: const Color(0xFF1E6FF6),
                  size: 20,
                ), // Bluish check
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedSort = value; // Update sort and refresh UI
        });
      }
    });
  }

  // Show filters bottom sheet (unchanged from previous implementation)
  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filters",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Attached Bathroom Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Attached Bathroom Only",
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: _bathroomFilter,
                        onChanged: (value) {
                          setState(() {
                            _bathroomFilter = value;
                          });
                        },
                        activeColor: const Color(0xFF1E6FF6),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Water Availability Filter
                  const Text(
                    "Water Availability",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _waterFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Any", child: Text("Any")),
                      DropdownMenuItem(
                        value: "Available",
                        child: Text("Available"),
                      ),
                      DropdownMenuItem(
                        value: "Limited",
                        child: Text("Limited"),
                      ),
                      DropdownMenuItem(
                        value: "24/7 Available",
                        child: Text("24/7 Available"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _waterFilter = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Apply Filters Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  // ==============================
  // MAIN BUILD METHOD
  // ==============================
  @override
  Widget build(BuildContext context) {
    final filteredRooms = _getFilteredRooms();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              snap: false,
              elevation: 2,
              shadowColor: Colors.blue.shade100,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                centerTitle: false,
                expandedTitleScale: 1.3,
                title: const Text(
                  "Smart Room Rental",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E6FF6),
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                    ),
                  ),
                ),
              ),
            ),

            // Main Content
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // Location & Currency Row
                _buildLocationCurrencyRow(),

                const SizedBox(height: 20),

                // Filter Controls Row
                _buildFilterControlsRow(context),

                const SizedBox(height: 20),

                // Results Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Showing Rooms in Dhulikhel",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${filteredRooms.length} properties found",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Room Cards
                ...filteredRooms.map((room) {
                  return RoomCard(
                    imagePath: room['image'],
                    houseNumber: room['houseNumber'],
                    location: room['location'],
                    water: room['water'],
                    sunlight: room['sunlight'],
                    hasBathroom: room['hasBathroom'],
                    size: room['size'],
                    priceNPR: room['priceNPR'],
                    distance: room['distance'],
                    internetSpeed: room['internetSpeed'],
                    currency: _currency,
                    conversionRate: _conversionRate,
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

  // ==============================
  // WIDGET BUILDING METHODS
  // ==============================
  Widget _buildLocationCurrencyRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Location Pill
          Expanded(
            child: Container(
              height: 56, // Fixed height matching spec
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEAF4FF), // Very light blue background
                border: Border.all(
                  color: const Color(0xFF1E6FF6), // Bluish border
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Only the map pin icon is red (not text)
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.red.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      // Text remains normal color (blue/dark)
                      Text(
                        "Dhulikhel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.edit_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Currency Pill with GlobalKey for positioning
          Container(
            key: _currencyButtonKey,
            height: 56, // Fixed height matching spec
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFEAF4FF), // Very light blue background
              border: Border.all(
                color: const Color(0xFF1E6FF6), // Bluish border
                width: 1.5,
              ),
            ),
            child: GestureDetector(
              onTap: _showCurrencyMenu,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currency == "USD" ? "USD (\$)" : "NPR",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E6FF6), // Bluish text
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF1E6FF6), // Bluish icon
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControlsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Sort By Button with GlobalKey for positioning
          Expanded(
            child: Container(
              key: _sortButtonKey,
              height: 48, // Fixed height matching spec
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEAF4FF), // Very light blue background
                border: Border.all(
                  color: const Color(0xFF1E6FF6), // Bluish border
                  width: 1.5,
                ),
              ),
              child: GestureDetector(
                onTap: _showSortMenu,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sort By",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E6FF6), // Bluish text
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF1E6FF6), // Bluish icon
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filters Button
          Expanded(
            child: GestureDetector(
              onTap: () => _showFiltersSheet(context),
              child: Container(
                height: 48, // Fixed height matching spec
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFEAF4FF), // Very light blue background
                  border: Border.all(
                    color: const Color(0xFF1E6FF6), // Bluish border
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E6FF6), // Bluish text
                        ),
                      ),
                      Icon(
                        Icons.filter_list_rounded,
                        color: const Color(0xFF1E6FF6), // Bluish icon
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Recent Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSort = "Recent"; // Set sort to recent
                });
              },
              child: Container(
                height: 48, // Fixed height matching spec
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedSort == "Recent"
                      ? const Color(0xFFD4E6FF) // Slightly darker when active
                      : const Color(0xFFEAF4FF), // Very light blue background
                  border: Border.all(
                    color: const Color(0xFF1E6FF6), // Bluish border
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E6FF6), // Bluish text
                        ),
                      ),
                      Icon(
                        Icons.access_time_rounded,
                        color: const Color(0xFF1E6FF6), // Bluish icon
                        size: 20,
                      ),
                    ],
                  ),
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
// ROOM CARD WIDGET
// ==============================
class RoomCard extends StatelessWidget {
  final String imagePath;
  final String houseNumber;
  final String location;
  final String water;
  final String sunlight;
  final bool hasBathroom;
  final String size;
  final int priceNPR;
  final String distance;
  final String internetSpeed;
  final String currency;
  final int conversionRate;

  const RoomCard({
    super.key,
    required this.imagePath,
    required this.houseNumber,
    required this.location,
    required this.water,
    required this.sunlight,
    required this.hasBathroom,
    required this.size,
    required this.priceNPR,
    required this.distance,
    required this.internetSpeed,
    required this.currency,
    required this.conversionRate,
  });

  // Helper to check if distance <= 2.0 km for badge display
  bool get _isNearKU {
    try {
      final match = RegExp(r'([0-9.]+)').firstMatch(distance);
      if (match != null) {
        final km = double.parse(match.group(1)!);
        return km <= 2.0; // Distance badge logic: show only if ≤ 2.0 km
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // Get display price based on selected currency
  int get _displayPrice {
    if (currency == "USD") {
      final converted = (priceNPR / conversionRate).floor();
      return converted == 0
          ? 1
          : converted; // Ensure non-zero display for very small prices
    }
    return priceNPR;
  }

  // Get currency symbol for display
  String get _currencySymbol {
    return currency == "USD" ? "\$" : "NPR";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12, // Subtle shadow
            offset: const Offset(0, 6),
          ),
        ],
        // iOS-like tan border - applied at container level
        border: Border.all(
          color: const Color(0xFFF4EFEA), // Exact tan color
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Conditional Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              // Near KU Gate Badge (only show if distance <= 2.0 km)
              if (_isNearKU)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100, width: 1),
                    ),
                    child: Text(
                      "Near KU Gate",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E6FF6),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Room Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // House Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "House No: $houseNumber",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "4.2",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location row with red icon only
                Row(
                  children: [
                    // Only the location icon is red (not text)
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700, // Text is normal color
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Features Pills with Emojis (keeping same background colors)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasBathroom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD), // Light blue tint
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "🚿 Attached bathroom", // Emoji added
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Light green tint
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "💧 Water: $water", // Emoji added
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0), // Light orange tint
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "☀️ Sunlight: $sunlight", // Emoji added
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Room Specifications Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSpecItem(
                        Icons.square_foot_rounded,
                        "Room Size",
                        size,
                        const Color(0xFF2196F3),
                      ),
                      _buildSpecItem(
                        Icons.wifi_rounded,
                        "Internet",
                        internetSpeed,
                        const Color(0xFF4CAF50),
                      ),
                      _buildSpecItem(
                        Icons.directions_walk_rounded,
                        "Distance",
                        distance,
                        const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Price and Action Button with proper baseline alignment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Display with baseline alignment
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Monthly Rent",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        // Using Row with CrossAxisAlignment.baseline for perfect alignment
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _currencySymbol,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              " $_displayPrice",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "/ month",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // View Details Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(
                              room: {
                                'image': imagePath,
                                // include extra images (if you have them). Fallback to the main image:
                                'images': [imagePath],
                                'houseNumber': houseNumber,
                                'location': location,
                                'distance': distance,
                                'internetSpeed': internetSpeed,
                                'priceNPR': priceNPR,
                                'water': water,
                                'sunlight': sunlight,
                                'hasBathroom': hasBathroom,
                                'size': size,
                                'created_at': DateTime.now(),
                                // optional: 'description': '...'
                              },
                              currency: currency,
                              conversionRate: conversionRate,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(fontWeight: FontWeight.w600),
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

  // Helper to build specification item
  Widget _buildSpecItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF37474F),
          ),
        ),
      ],
    );
  }
}
