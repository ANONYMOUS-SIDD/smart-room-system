import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoomDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailsBottomSheet({
    super.key,
    required this.room,
  });

  @override
  State<RoomDetailsBottomSheet> createState() => _RoomDetailsBottomSheetState();
}

class _RoomDetailsBottomSheetState extends State<RoomDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _selectedImageIndex = 0;
  bool _isViewingFullImage = false;

  List<String> get _images {
    final imagesData = widget.room['images'];
    if (imagesData is List) {
      return imagesData.whereType<String>().toList();
    }
    return [];
  }

  bool get _isNearKU {
    try {
      final distance = widget.room['distance']?.toString() ?? "0.0";
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeSheet() {
    _controller.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  void _viewFullImage(int index) {
    setState(() {
      _selectedImageIndex = index;
      _isViewingFullImage = true;
    });
  }

  void _closeImageViewer() {
    setState(() {
      _isViewingFullImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _closeSheet,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on content
            child: DraggableScrollableSheet(
              initialChildSize: isTablet ? 0.75 : 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: [isTablet ? 0.75 : 0.85],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: ModernColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildContent(scrollController, isSmallScreen, isTablet),
                      if (_isViewingFullImage)
                        _buildFullImageViewer(isSmallScreen, isTablet),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController, bool isSmallScreen, bool isTablet) {
    final room = widget.room;
    final images = _images;

    // Data extraction with fallbacks
    final title = room['roomName']?.toString() ?? "Unnamed Room";
    final walkTime = room['walkTime']?.toString() ?? "0 min";
    final location = "$walkTime walk from KU Gate";
    final water = room['water']?.toString() ?? "Available";
    final sunlight = room['sunlight']?.toString() ?? "Good";
    final hasBathroom = room['bathroom']?.toString() == "Yes" || room['bathroom'] == true;
    final size = "${room['size']?.toString() ?? '0'} Sq Ft";
    final priceNPR = room['price'] is int ? room['price'] as int : int.tryParse(room['price']?.toString() ?? '0') ?? 0;
    final distance = _getFormattedDistance();
    final internetSpeed = "${room['internet']?.toString() ?? '0'} Mbps";
    final fullLocation = room['location']?.toString() ?? "Location not specified";
    final latitude = room['latitude'];
    final longitude = room['longitude'];

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with drag handle
        SliverToBoxAdapter(
          child: _buildHeader(isSmallScreen, isTablet),
        ),

        // Main Image
        SliverToBoxAdapter(
          child: _buildMainImageSection(images, isSmallScreen, isTablet),
        ),

        // Thumbnails Row - Centered
        if (images.length > 1)
          SliverToBoxAdapter(
            child: _buildThumbnailsSection(images, isSmallScreen, isTablet),
          ),

        // Main Room Card with everything
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
              vertical: isTablet ? 20 : 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: ModernColors.surface,
                borderRadius: BorderRadius.circular(isTablet ? 18 : (isSmallScreen ? 14 : 16)),
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
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 20 : (isSmallScreen ? 12 : 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Title and Available Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Room Title
                              Text(
                                title,
                                style: GoogleFonts.quicksand(
                                  fontSize: isTablet ? 20 : (isSmallScreen ? 15 : 17),
                                  fontWeight: FontWeight.w800,
                                  color: ModernColors.onSurface,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: isTablet ? 8 : (isSmallScreen ? 6 : 6)),

                              // Location with RED icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: isTablet ? 16 : (isSmallScreen ? 13 : 15),
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.quicksand(
                                        fontSize: isTablet ? 14 : (isSmallScreen ? 12 : 13),
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

                        SizedBox(width: isTablet ? 16 : (isSmallScreen ? 8 : 10)),

                        // Available Status Button (Pink Gradient)
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
                            "Available",
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

                    SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 14)),

                    // Room Specifications Grid
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : (isSmallScreen ? 12 : 12),
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ModernColors.background.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 8 : 10)),
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
                            isTablet,
                          ),
                          Container(
                            height: isTablet ? 32 : (isSmallScreen ? 24 : 28),
                            width: 1,
                            color: ModernColors.outline.withOpacity(0.3),
                          ),
                          _buildCompactSpecItem(
                            Icons.wifi_rounded,
                            "Internet",
                            internetSpeed,
                            const Color(0xFF4CAF50),
                            isSmallScreen,
                            isTablet,
                          ),
                          Container(
                            height: isTablet ? 32 : (isSmallScreen ? 24 : 28),
                            width: 1,
                            color: ModernColors.outline.withOpacity(0.3),
                          ),
                          _buildCompactSpecItem(
                            Icons.directions_walk_rounded,
                            "Distance",
                            distance,
                            const Color(0xFFFF9800),
                            isSmallScreen,
                            isTablet,
                          ),
                        ],
                      ),
                    ),

                    // Monthly Rent Section with Compare Button
                    Padding(
                      padding: EdgeInsets.only(
                        top: isTablet ? 20 : (isSmallScreen ? 16 : 18),
                        bottom: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                          vertical: isTablet ? 10 : (isSmallScreen ? 8 : 10),
                        ),
                        decoration: BoxDecoration(
                          color: ModernColors.surface,
                          borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                          border: Border.all(
                            color: ModernColors.outline.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Monthly Rent Details
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Monthly Rent",
                                  style: GoogleFonts.quicksand(
                                    fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
                                    fontWeight: FontWeight.w700,
                                    color: ModernColors.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 4 : (isSmallScreen ? 2 : 3)),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "NPR",
                                      style: GoogleFonts.quicksand(
                                        fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
                                        color: ModernColors.onSurfaceVariant.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 6 : (isSmallScreen ? 3 : 4)),
                                    Text(
                                      " $priceNPR",
                                      style: GoogleFonts.quicksand(
                                        fontSize: isTablet ? 22 : (isSmallScreen ? 18 : 20),
                                        fontWeight: FontWeight.w800,
                                        color: ModernColors.onSurface, // Black color
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 6 : (isSmallScreen ? 3 : 4)),
                                    Text(
                                      "/month",
                                      style: GoogleFonts.quicksand(
                                        fontSize: isTablet ? 13 : (isSmallScreen ? 11 : 12),
                                        color: ModernColors.onSurfaceVariant.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Compare Button (Green Gradient)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF4CAF50), // Green
                                    Color(0xFF2E7D32), // Dark Green
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Compare",
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
                      ),
                    ),

                    // Divider before Additional Amenities
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : (isSmallScreen ? 12 : 14)),
                      child: Divider(
                        height: 1,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                    ),

                    // Additional Amenities
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Additional Amenities",
                          style: GoogleFonts.quicksand(
                            fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 16),
                            fontWeight: FontWeight.w700,
                            color: ModernColors.onSurface,
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : (isSmallScreen ? 10 : 12)),

                        // First Row: Water & Sunlight
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Water Pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : (isSmallScreen ? 10 : 10),
                                vertical: isTablet ? 8 : (isSmallScreen ? 5 : 5),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                              ),
                              child: Text(
                                "💧 Water: $water",
                                style: GoogleFonts.quicksand(
                                  fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 11),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),

                            // Sunlight Pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : (isSmallScreen ? 10 : 10),
                                vertical: isTablet ? 8 : (isSmallScreen ? 5 : 5),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                              ),
                              child: Text(
                                "☀️ Sunlight: $sunlight",
                                style: GoogleFonts.quicksand(
                                  fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 11),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF57C00),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isTablet ? 12 : (isSmallScreen ? 8 : 10)),

                        // Second Row: Bathroom & Windows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bathroom Pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : (isSmallScreen ? 10 : 10),
                                vertical: isTablet ? 8 : (isSmallScreen ? 5 : 5),
                              ),
                              decoration: BoxDecoration(
                                color: hasBathroom ?
                                const Color(0xFFE3F2FD) : // Light blue for attached
                                const Color(0xFFF5F5F5), // Light grey for shared
                                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                              ),
                              child: Text(
                                hasBathroom ? "🚽 Bathroom: Attached" : "🚽 Bathroom: Shared",
                                style: GoogleFonts.quicksand(
                                  fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 11),
                                  fontWeight: FontWeight.w700,
                                  color: hasBathroom ?
                                  const Color(0xFF2196F3) : // Blue for attached
                                  const Color(0xFF757575), // Grey for shared
                                ),
                              ),
                            ),

                            // Windows Pill
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : (isSmallScreen ? 10 : 10),
                                vertical: isTablet ? 8 : (isSmallScreen ? 5 : 5),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                              ),
                              child: Text(
                                "🪟 Windows: 5",
                                style: GoogleFonts.quicksand(
                                  fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 11),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9C27B0),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 16)),

                        // Amenity Windows (Laundry, Wi-Fi, Parking, Security, Cleaning)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAmenityWindow(
                              Icons.local_laundry_service_rounded,
                              "Laundry",
                              const Color(0xFF9C27B0),
                              isSmallScreen,
                              isTablet,
                            ),
                            _buildAmenityWindow(
                              Icons.wifi_rounded,
                              "Wi-Fi",
                              const Color(0xFF2196F3),
                              isSmallScreen,
                              isTablet,
                            ),
                            _buildAmenityWindow(
                              Icons.local_parking_rounded,
                              "Parking",
                              const Color(0xFF795548),
                              isSmallScreen,
                              isTablet,
                            ),
                            if (!isSmallScreen) ...[
                              _buildAmenityWindow(
                                Icons.security_rounded,
                                "Security",
                                const Color(0xFFF44336),
                                isSmallScreen,
                                isTablet,
                              ),
                              _buildAmenityWindow(
                                Icons.cleaning_services_rounded,
                                "Cleaning",
                                const Color(0xFFFF9800),
                                isSmallScreen,
                                isTablet,
                              ),
                            ],
                          ],
                        ),

                        // For small screens, show the last 2 windows in a second row
                        if (isSmallScreen) ...[
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAmenityWindow(
                                Icons.security_rounded,
                                "Security",
                                const Color(0xFFF44336),
                                isSmallScreen,
                                isTablet,
                              ),
                              SizedBox(width: 20),
                              _buildAmenityWindow(
                                Icons.cleaning_services_rounded,
                                "Cleaning",
                                const Color(0xFFFF9800),
                                isSmallScreen,
                                isTablet,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Location Details Section (Separate Card)
        SliverToBoxAdapter(
          child: _buildLocationSection(
            fullLocation: fullLocation,
            latitude: latitude,
            longitude: longitude,
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          ),
        ),

        // Action Buttons - Chat and Book with Gradients
        SliverToBoxAdapter(
          child: _buildActionButtons(isSmallScreen, isTablet),
        ),

        // Bottom spacing
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet ? 20 : (isSmallScreen ? 15 : 20)),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isSmallScreen, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
        vertical: isTablet ? 20 : 16,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: isTablet ? 50 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isTablet ? 16 : (isSmallScreen ? 8 : 12)),
          // Center aligned title
          Center(
            child: Text(
              "Room Details",
              style: GoogleFonts.quicksand(
                fontSize: isTablet ? 24 : (isSmallScreen ? 18 : 20),
                fontWeight: FontWeight.w800,
                color: ModernColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageSection(List<String> images, bool isSmallScreen, bool isTablet) {
    if (images.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20)),
        child: Container(
          height: isTablet ? 250 : (isSmallScreen ? 180 : 200),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(isTablet ? 18 : (isSmallScreen ? 14 : 16)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  size: isTablet ? 50 : 40,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  "No Images Available",
                  style: GoogleFonts.quicksand(
                    fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _viewFullImage(0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20)),
            child: Container(
              height: isTablet ? 250 : (isSmallScreen ? 180 : 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 18 : (isSmallScreen ? 14 : 16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isTablet ? 18 : (isSmallScreen ? 14 : 16)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: images[0],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            Icons.photo_library_rounded,
                            size: isTablet ? 50 : 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: isTablet ? 16 : 10,
                      right: isTablet ? 16 : 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                          vertical: isTablet ? 8 : (isSmallScreen ? 5 : 6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                        ),
                        child: Text(
                          "${images.length} photos",
                          style: GoogleFonts.quicksand(
                            fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 12),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Near KU Gate Badge (if applicable)
        if (_isNearKU)
          Positioned(
            top: isTablet ? 16 : 10,
            left: isTablet ? 24 : (isSmallScreen ? 16 : 20),
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
    );
  }

  Widget _buildThumbnailsSection(List<String> images, bool isSmallScreen, bool isTablet) {
    final itemWidth = isTablet ? 80.0 : (isSmallScreen ? 60.0 : 70.0);
    final itemHeight = isTablet ? 80.0 : (isSmallScreen ? 60.0 : 70.0);
    final borderRadius = isTablet ? 14.0 : (isSmallScreen ? 10.0 : 12.0);

    return Padding(
      padding: EdgeInsets.only(
        top: isTablet ? 20 : (isSmallScreen ? 12 : 16),
        left: isTablet ? 24 : (isSmallScreen ? 16 : 20),
        right: isTablet ? 24 : (isSmallScreen ? 16 : 20),
      ),
      child: SizedBox(
        height: itemHeight,
        child: Center(
          child: images.length <= 3
              ? _buildCenteredThumbnails(images, itemWidth, itemHeight, borderRadius, isSmallScreen, isTablet)
              : _buildScrollableThumbnails(images, itemWidth, itemHeight, borderRadius, isSmallScreen, isTablet),
        ),
      ),
    );
  }

  Widget _buildCenteredThumbnails(
      List<String> images,
      double itemWidth,
      double itemHeight,
      double borderRadius,
      bool isSmallScreen,
      bool isTablet,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: images.asMap().entries.map((entry) {
        final index = entry.key;
        final imageUrl = entry.value;
        return GestureDetector(
          onTap: () => _viewFullImage(index),
          child: Padding(
            padding: EdgeInsets.only(
              right: index < images.length - 1 ? (isTablet ? 12 : (isSmallScreen ? 8 : 10)) : 0,
            ),
            child: Container(
              width: itemWidth,
              height: itemHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: ModernColors.outline.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade100,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: isTablet ? 30 : 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScrollableThumbnails(
      List<String> images,
      double itemWidth,
      double itemHeight,
      double borderRadius,
      bool isSmallScreen,
      bool isTablet,
      ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _viewFullImage(index),
          child: Padding(
            padding: EdgeInsets.only(
              right: index < images.length - 1 ? (isTablet ? 12 : (isSmallScreen ? 8 : 10)) : 0,
              left: index == 0 ? (isTablet ? 12 : (isSmallScreen ? 8 : 10)) : 0,
            ),
            child: Container(
              width: itemWidth,
              height: itemHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: ModernColors.outline.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade100,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: isTablet ? 30 : 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullImageViewer(bool isSmallScreen, bool isTablet) {
    final images = _images;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
                  vertical: isTablet ? 20 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _closeImageViewer,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      "${_selectedImageIndex + 1}/${images.length}",
                      style: GoogleFonts.quicksand(
                        fontSize: isTablet ? 18 : (isSmallScreen ? 15 : 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 40), // For symmetry
                  ],
                ),
              ),
            ),

            // Image Viewer
            Expanded(
              child: PageView.builder(
                itemCount: images.length,
                controller: PageController(initialPage: _selectedImageIndex),
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    maxScale: 3.0,
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : (isSmallScreen ? 16 : 20)),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade800,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade800,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: isTablet ? 50 : 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Thumbnails at bottom
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isTablet ? 24 : 20,
                  left: isTablet ? 24 : (isSmallScreen ? 16 : 20),
                  right: isTablet ? 24 : (isSmallScreen ? 16 : 20),
                ),
                child: SizedBox(
                  height: isTablet ? 70 : (isSmallScreen ? 50 : 60),
                  child: Center(
                    child: images.length <= 3
                        ? _buildCenteredBottomThumbnails(images, isSmallScreen, isTablet)
                        : _buildScrollableBottomThumbnails(images, isSmallScreen, isTablet),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredBottomThumbnails(List<String> images, bool isSmallScreen, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: images.asMap().entries.map((entry) {
        final index = entry.key;
        final imageUrl = entry.value;
        final thumbnailSize = isTablet ? 65.0 : (isSmallScreen ? 45.0 : 55.0);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedImageIndex = index;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(right: index < images.length - 1 ? 10 : 0),
            child: Container(
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedImageIndex == index
                      ? ModernColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScrollableBottomThumbnails(List<String> images, bool isSmallScreen, bool isTablet) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      itemBuilder: (context, index) {
        final thumbnailSize = isTablet ? 65.0 : (isSmallScreen ? 45.0 : 55.0);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedImageIndex = index;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(right: index < images.length - 1 ? 10 : 0),
            child: Container(
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedImageIndex == index
                      ? ModernColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSpecItem(
      IconData icon,
      String title,
      String value,
      Color color,
      bool isSmallScreen,
      bool isTablet,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: isTablet ? 26 : (isSmallScreen ? 18 : 20),
          color: color,
        ),
        SizedBox(height: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 11),
            color: ModernColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isTablet ? 4 : (isSmallScreen ? 2 : 3)),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: isTablet ? 16 : (isSmallScreen ? 11 : 12),
            fontWeight: FontWeight.w800,
            color: ModernColors.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityWindow(IconData icon, String label, Color color, bool isSmallScreen, bool isTablet) {
    final size = isTablet ? 60.0 : (isSmallScreen ? 40.0 : 45.0);
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 8 : 10)),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: isTablet ? 28 : (isSmallScreen ? 18 : 20),
            color: color,
          ),
        ),
        SizedBox(height: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: isTablet ? 13 : (isSmallScreen ? 9 : 10),
            fontWeight: FontWeight.w700,
            color: ModernColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection({
    required String fullLocation,
    required dynamic latitude,
    required dynamic longitude,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    final hasCoordinates = latitude != null && longitude != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
        vertical: isTablet ? 12 : 8,
      ),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : (isSmallScreen ? 16 : 20)),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(isTablet ? 18 : (isSmallScreen ? 14 : 16)),
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
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: isTablet ? 22 : (isSmallScreen ? 18 : 20),
                  color: Colors.red,
                ),
                SizedBox(width: isTablet ? 10 : (isSmallScreen ? 6 : 8)),
                Text(
                  "Location Details",
                  style: GoogleFonts.quicksand(
                    fontSize: isTablet ? 22 : (isSmallScreen ? 16 : 18),
                    fontWeight: FontWeight.w800,
                    color: ModernColors.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : (isSmallScreen ? 8 : 12)),
            Text(
              fullLocation,
              style: GoogleFonts.quicksand(
                fontSize: isTablet ? 18 : (isSmallScreen ? 13 : 15),
                color: ModernColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),

            if (hasCoordinates) ...[
              SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 16)),
              Container(
                height: isTablet ? 180 : (isSmallScreen ? 120 : 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                  color: ModernColors.background,
                  border: Border.all(
                    color: ModernColors.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: isTablet ? 50 : (isSmallScreen ? 32 : 40),
                        color: ModernColors.primary,
                      ),
                      SizedBox(height: isTablet ? 12 : (isSmallScreen ? 6 : 8)),
                      Text(
                        "Map View Available",
                        style: GoogleFonts.quicksand(
                          fontSize: isTablet ? 18 : (isSmallScreen ? 13 : 14),
                          fontWeight: FontWeight.w700,
                          color: ModernColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        "(Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)})",
                        style: GoogleFonts.quicksand(
                          fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 16)),
            SizedBox(
              width: double.infinity,
              height: isTablet ? 56 : (isSmallScreen ? 42 : 48),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open in Maps
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  Icons.directions_rounded,
                  size: isTablet ? 22 : 18,
                ),
                label: Text(
                  "Get Directions",
                  style: GoogleFonts.quicksand(
                    fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
        vertical: isTablet ? 16 : (isSmallScreen ? 12 : 16),
      ),
      child: Row(
        children: [
          // Chat Button with Purple Gradient
          Expanded(
            child: Container(
              height: isTablet ? 50 : (isSmallScreen ? 40 : 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9C27B0), // Purple
                    Color(0xFF7B1FA2), // Dark Purple
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement chat
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      size: isTablet ? 20 : (isSmallScreen ? 16 : 18),
                    ),
                    SizedBox(width: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
                    Text(
                      "Chat",
                      style: GoogleFonts.quicksand(
                        fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: isTablet ? 12 : (isSmallScreen ? 8 : 10)),

          // Book Button with Dark Blue Gradient
          Expanded(
            child: Container(
              height: isTablet ? 50 : (isSmallScreen ? 40 : 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1565C0), // Dark Blue
                    Color(0xFF0D47A1), // Darker Blue
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement booking
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_rounded,
                      size: isTablet ? 20 : (isSmallScreen ? 16 : 18),
                    ),
                    SizedBox(width: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
                    Text(
                      "Book",
                      style: GoogleFonts.quicksand(
                        fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14),
                        fontWeight: FontWeight.w800,
                      ),
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

// Modern Colors Palette (same as your card)
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