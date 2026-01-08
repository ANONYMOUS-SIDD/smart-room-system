import 'package:flutter/material.dart';

/*
INTEGRATION GUIDE:
To use this screen from HomeScreen/RoomCard, modify the View Details button's onPressed:
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailsScreen(
        room: {
          'image': imagePath,
          'images': [imagePath], // Provide list of images if available
          'houseNumber': houseNumber,
          'location': location,
          'distance': distance,
          'internetSpeed': internetSpeed,
          'priceNPR': priceNPR,
          'water': water,
          'sunlight': sunlight,
          'hasBathroom': hasBathroom,
          'created_at': DateTime.now(),
        },
        currency: currency,
        conversionRate: conversionRate,
      ),
    ),
  );
}
*/

/*
DEVELOPER NOTES:
This file contains the Room Details Screen for Smart Room Rental App.
Expected Supabase fields for full integration:
- 'image' (primary image URL)
- 'images' (List<String> of image URLs)
- 'houseNumber', 'location', 'distance', 'internetSpeed'
- 'priceNPR' (numeric), 'water', 'sunlight', 'hasBathroom' (boolean)
- 'description' (optional, string for room description)
- 'created_at' (DateTime)
*/

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  final String currency;
  final int conversionRate;

  const DetailsScreen({
    super.key,
    required this.room,
    required this.currency,
    required this.conversionRate,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  // PageController for full-screen image viewer swiping
  late PageController _pageController;
  int _currentImageIndex = 0;

  // Get list of images from room data, defaulting to single image if not provided
  List<String> get _images {
    if (widget.room['images'] is List<String>) {
      return widget.room['images'] as List<String>;
    } else if (widget.room['images'] is List<dynamic>) {
      return (widget.room['images'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }
    // Fallback to single image if no list provided
    return [widget.room['image']];
  }

  // Calculate display price based on selected currency (same logic as HomeScreen)
  int get _displayPrice {
    final priceNPR = widget.room['priceNPR'] ?? 0;
    if (widget.currency == "USD") {
      final converted = (priceNPR / widget.conversionRate).floor();
      return converted == 0 ? 1 : converted;
    }
    return priceNPR;
  }

  // Get currency symbol for display
  String get _currencySymbol {
    return widget.currency == "USD" ? "\$" : "NPR";
  }

  // Generate formatted price with thousand separators
  String get _formattedPrice {
    return _displayPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize PageController for full-screen image viewer
    _pageController = PageController(initialPage: _currentImageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Open full-screen image viewer at specified index
  void _openFullScreenImageViewer(int initialIndex) {
    setState(() {
      _currentImageIndex = initialIndex;
      _pageController = PageController(initialPage: initialIndex);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          images: _images,
          initialIndex: initialIndex,
          pageController: _pageController,
          onIndexChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // White background with subtle elevation
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF1E6FF6), // Primary blue color
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Room Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E6FF6), // Consistent with HomeScreen
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: const Color(0xFF1E6FF6)),
            onPressed: () {
              // Share functionality placeholder
              // TODO: Implement share functionality when integrating
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image Section
                    _buildHeroImageSection(),

                    // Thumbnail Row
                    _buildThumbnailRow(),

                    // Room Details Section
                    _buildRoomDetailsSection(),

                    // Amenities Section
                    _buildAmenitiesSection(),

                    // Description Section
                    _buildDescriptionSection(),

                    // Spacing for bottom buttons
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ==============================
  // WIDGET BUILDING METHODS
  // ==============================

  // Hero Image Section (large main image)
  Widget _buildHeroImageSection() {
    return GestureDetector(
      onTap: () => _openFullScreenImageViewer(0),
      child: Hero(
        tag: 'room_${widget.room['houseNumber']}',
        child: Container(
          width: double.infinity,
          height: 250, // Aspect ratio ~16:9
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Image.asset(
              widget.room['image'] ?? 'assets/images/room1_img.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(
                      Icons.home_work_rounded,
                      size: 60,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Thumbnail Row (horizontal scrollable)
  Widget _buildThumbnailRow() {
    final images = _images;
    final totalImages = images.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Thumbnail 1 (always show at least one)
          _buildThumbnail(0),

          if (totalImages > 1) ...[
            const SizedBox(width: 12),
            _buildThumbnail(1),
          ],

          if (totalImages > 2) ...[
            const SizedBox(width: 12),
            _buildThumbnail(2),
          ],

          // If more than 3 images, show +N overlay on last thumbnail
          if (totalImages > 3) ...[
            const SizedBox(width: 12),
            _buildMoreImagesThumbnail(totalImages - 3),
          ] else if (totalImages == 0)

          // Fallback if no images at all
            const SizedBox(),
        ],
      ),
    );
  }

  // Individual Thumbnail Widget
  Widget _buildThumbnail(int index) {
    final images = _images;
    if (index >= images.length) return const SizedBox();

    return GestureDetector(
      onTap: () {
        // Animate scale on tap
        _openFullScreenImageViewer(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity(),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E6FF6).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(
                      Icons.photo_rounded,
                      size: 24,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // +N More Images Thumbnail
  Widget _buildMoreImagesThumbnail(int additionalCount) {
    return GestureDetector(
      onTap: () => _openFullScreenImageViewer(2), // Start from 3rd image
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1E6FF6).withOpacity(0.8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "+$additionalCount",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Text(
                "More",
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Room Details Section
  Widget _buildRoomDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // House Number Heading
          Text(
            "House No: ${widget.room['houseNumber'] ?? 'N/A'}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3A8A),
            ),
          ),

          const SizedBox(height: 12),

          // Location Row with red icon
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: Colors.red.shade700, // Red icon only
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.room['location'] ?? 'Location not specified',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800, // Normal text color
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Distance and Internet Speed Row
          Row(
            children: [
              Icon(
                Icons.directions_walk_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                widget.room['distance'] ?? 'Distance not specified',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 20),
              Icon(Icons.wifi_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                widget.room['internetSpeed'] ?? 'Speed not specified',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Price Display with perfect baseline alignment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF8FAFF),
              border: Border.all(
                color: const Color(0xFF1E6FF6).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Monthly Rent",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    // Baseline aligned price row (same as HomeScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _currencySymbol,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          " $_formattedPrice",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "/ month",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                // Rating badge (static for now)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "4.2/5.0",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
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
  }

  // Amenities Section with Emoji Pills
  Widget _buildAmenitiesSection() {
    // Core amenities from room data
    final List<Map<String, dynamic>> coreAmenities = [
      if (widget.room['hasBathroom'] == true)
        {
          'emoji': '🚿',
          'label': 'Attached bathroom',
          'color': const Color(0xFFE3F2FD),
          'textColor': const Color(0xFF1565C0),
        },
      {
        'emoji': '💧',
        'label': 'Water: ${widget.room['water'] ?? 'N/A'}',
        'color': const Color(0xFFE8F5E9),
        'textColor': const Color(0xFF2E7D32),
      },
      {
        'emoji': '☀️',
        'label': 'Sunlight: ${widget.room['sunlight'] ?? 'N/A'}',
        'color': const Color(0xFFFFF3E0),
        'textColor': const Color(0xFFF57C00),
      },
    ];

    // Additional synthesized amenities (common in rental rooms)
    final List<Map<String, dynamic>> additionalAmenities = [
      {
        'emoji': '📶',
        'label': 'Wi-Fi',
        'color': const Color(0xFFE3F2FD),
        'textColor': const Color(0xFF1565C0),
      },
      {
        'emoji': '🔥',
        'label': 'Water heater',
        'color': const Color(0xFFFFF3E0),
        'textColor': const Color(0xFFF57C00),
      },
      {
        'emoji': '⚡',
        'label': 'Power backup',
        'color': const Color(0xFFE8F5E9),
        'textColor': const Color(0xFF2E7D32),
      },
      {
        'emoji': '🅿️',
        'label': 'Parking',
        'color': const Color(0xFFF3E5F5),
        'textColor': const Color(0xFF7B1FA2),
      },
      {
        'emoji': '🔒',
        'label': 'Security',
        'color': const Color(0xFFE0F2F1),
        'textColor': const Color(0xFF00796B),
      },
      {
        'emoji': '🧹',
        'label': 'Cleaning service',
        'color': const Color(0xFFFFF8E1),
        'textColor': const Color(0xFFF57C00),
      },
    ];

    final allAmenities = [...coreAmenities, ...additionalAmenities];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amenities",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allAmenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: amenity['color'],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (amenity['textColor'] as Color).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amenity['emoji']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: amenity['textColor'] as Color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Description Section
  Widget _buildDescriptionSection() {
    // Generate description based on room data if not provided
    String description =
        widget.room['description'] ??
            "Cozy ${widget.room['size'] ?? 'room'} located near KU with ${widget.room['sunlight']?.toString().toLowerCase() ?? 'good'} sunlight and ${widget.room['water']?.toString().toLowerCase() ?? '24/7'} water availability. Perfect for students seeking comfortable living near Kathmandu University.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Description",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // Bottom Action Bar (Chat and Pay buttons)
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat Button (outlined style)
            Expanded(
              flex: 4,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement chat functionality when integrating
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFEAF4FF,
                  ), // Light blue background
                  foregroundColor: const Color(0xFF1E6FF6), // Blue text/icon
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFF1E6FF6),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Chat",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Pay with eSewa Button (filled style)
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement eSewa payment when integrating
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6FF6), // Blue background
                  foregroundColor: Colors.white, // White text/icon
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // eSewa logo placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/esewa_logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Pay with eSewa",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================
// FULL-SCREEN IMAGE VIEWER WIDGET
// ==============================
class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final PageController pageController;
  final Function(int) onIndexChanged;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.pageController,
    required this.onIndexChanged,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    widget.pageController.addListener(_pageListener);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_pageListener);
    super.dispose();
  }

  void _pageListener() {
    if (widget.pageController.page?.round() != _currentPage) {
      setState(() {
        _currentPage = widget.pageController.page?.round() ?? _currentPage;
      });
      widget.onIndexChanged(_currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Horizontal PageView for swiping images
          PageView.builder(
            controller: widget.pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              widget.onIndexChanged(index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Close on image tap (alternative to X button)
                  Navigator.pop(context);
                },
                child: Center(
                  child: Image.asset(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 60,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Page Indicator (top-center)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_currentPage + 1} / ${widget.images.length}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Close Button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Colors.white,
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