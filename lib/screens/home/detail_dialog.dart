// Room Details Bottom Sheet - Complete Production Solution
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../chat/models/chat_user.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import 'book_room.dart';

class RoomDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> room;
  final String? roomDocumentId;

  const RoomDetailsBottomSheet({
    super.key,
    required this.room,
    this.roomDocumentId,
  });

  @override
  State<RoomDetailsBottomSheet> createState() => _RoomDetailsBottomSheetState();
}

class _RoomDetailsBottomSheetState extends State<RoomDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  // Animation Controllers For Smooth Transitions
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Image Viewing State Variables
  int _selectedImageIndex = 0;
  bool _isViewingFullImage = false;

  // Room Booking Status Variables
  bool _isRoomRequested = false;

  // Map Related State Variables
  final _currentMapType = ValueNotifier<MapType>(MapType.normal);
  final _mapController = Completer<GoogleMapController>();
  final _currentLatLng = ValueNotifier<LatLng?>(null);
  final _polylines = ValueNotifier<Set<Polyline>>({});
  LatLng? _destination;
  bool _polylineDrawn = false;

  // Helper Method To Extract Images From Room Data
  List<String> get _images {
    final imagesData = widget.room['images'];
    if (imagesData is List) {
      return imagesData.whereType<String>().toList();
    }
    return [];
  }

  // Method To Start Chat With Room Owner
  Future<void> _startChatWithOwner() async {
    try {
      final chatService = Get.find<ChatService>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please Login To Chat', style: GoogleFonts.quicksand()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get Owner Session ID From Room Data Or Firestore
      String? ownerSessionId = widget.room['sessionId']?.toString();

      if (ownerSessionId == null && widget.roomDocumentId != null) {
        try {
          final roomDoc = await FirebaseFirestore.instance
              .collection('room')
              .doc(widget.roomDocumentId!)
              .get();

          ownerSessionId = roomDoc.data()?['sessionId']?.toString();
        } catch (e) {
          // Log Error But Continue With Fallback
        }
      }

      if (ownerSessionId == null || ownerSessionId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could Not Find Room Owner', style: GoogleFonts.quicksand()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validate Not Chatting With Self
      if (ownerSessionId == currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You Cannot Chat With Yourself', style: GoogleFonts.quicksand()),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      // Close Bottom Sheet Before Navigation
      Navigator.pop(context);

      // Show Loading Indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        // Get Or Create Conversation With Owner
        final conversation = await chatService.getOrCreateConversation(ownerSessionId);

        // Get Owner User Details
        ChatUser? ownerUser = await chatService.getUserById(ownerSessionId);

        if (ownerUser == null) {
          // Create Temporary User Profile For Owner
          ownerUser = ChatUser.createTemporary(
            userId: ownerSessionId,
            name: widget.room['roomName']?.toString() ?? 'Room Owner',
            email: widget.room['ownerEmail']?.toString() ?? '',
            phone: widget.room['ownerPhone']?.toString() ?? '',
            profilePath: widget.room['ownerImage']?.toString() ?? '',
          );
        }

        // Close Loading Dialog
        Get.back();

        // Navigate To Chat Screen
        await Get.to(
              () => ChatScreen(
            conversation: conversation,
            otherUser: ownerUser!,
          ),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );

      } catch (e) {
        Get.back(); // Close Loading Dialog
        Get.snackbar(
          'Error',
          'Failed To Start Chat: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something Went Wrong: $e', style: GoogleFonts.quicksand()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check If Room Is Near KU Gate Based On Distance
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

  // Format Distance With Proper Units
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

    // Initialize Animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Initialize Destination Coordinates If Available
    final hasCoordinates = widget.room['latitude'] != null && widget.room['longitude'] != null;
    if (hasCoordinates) {
      final destinationLat = double.tryParse(widget.room['latitude'].toString());
      final destinationLng = double.tryParse(widget.room['longitude'].toString());
      if (destinationLat != null && destinationLng != null) {
        _destination = LatLng(destinationLat, destinationLng);
      }
    }

    // Get User Location And Draw Polyline
    _getLocationAndDrawPolyline();

    // Check Room Status From Passed Data
    _checkRoomStatus();
  }

  // Check Room Status From Room Data
  void _checkRoomStatus() {
    try {
      final status = widget.room['status']?.toString() ?? '';
      setState(() {
        _isRoomRequested = status.toLowerCase() == 'requested';
      });
    } catch (e) {
      setState(() {
        _isRoomRequested = false;
      });
    }
  }

  // Get Current Location And Draw Polyline To Destination
  Future<void> _getLocationAndDrawPolyline() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _currentLatLng.value = LatLng(position.latitude, position.longitude);

        // Draw Polyline Immediately If Destination Exists
        if (_destination != null && !_polylineDrawn) {
          await _drawDirectPolyline();
        }
      }
    } catch (e) {
      // Location Error Handled Silently
    }
  }

  // Draw Polyline Between Current Location And Destination
  Future<void> _drawDirectPolyline() async {
    if (_currentLatLng.value == null || _destination == null) return;

    try {
      // Try OSRM API For Detailed Walking Route
      final String url = 'https://router.project-osrm.org/route/v1/foot/'
          '${_currentLatLng.value!.longitude},${_currentLatLng.value!.latitude};'
          '${_destination!.longitude},${_destination!.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();

          _polylines.value = {
            Polyline(
              polylineId: const PolylineId("walk_path"),
              points: points,
              color: const Color(0xFF667EEA),
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              patterns: [PatternItem.dash(10), PatternItem.gap(5)],
            ),
          };
          _polylineDrawn = true;
          return;
        }
      }
    } catch (e) {
      // Fallback To Straight Line If OSRM Fails
    }

    // Draw Straight Line As Fallback
    _polylines.value = {
      Polyline(
        polylineId: const PolylineId("walk_path"),
        points: [_currentLatLng.value!, _destination!],
        color: const Color(0xFF667EEA),
        width: 3,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
    _polylineDrawn = true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Close Bottom Sheet With Animation
  void _closeSheet() {
    _animationController.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  // Open Full Screen Image Viewer
  void _viewFullImage(int index) {
    setState(() {
      _selectedImageIndex = index;
      _isViewingFullImage = true;
    });
  }

  // Close Full Screen Image Viewer
  void _closeImageViewer() {
    setState(() {
      _isViewingFullImage = false;
    });
  }

  // Toggle Between Map Types (Normal/Satellite)
  void _toggleMapType() {
    _currentMapType.value = _currentMapType.value == MapType.normal ? MapType.satellite : MapType.normal;
  }

  // Center Map On Current Location
  Future<void> _goToCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng currentLocation = LatLng(position.latitude, position.longitude);

      _currentLatLng.value = currentLocation;

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 16),
      );

      // Redraw Polyline With New Location
      if (_destination != null) {
        await _drawDirectPolyline();
      }
    } catch (e) {
      // Location Error Handled Silently
    }
  }

  // Open Destination In Google Maps App
  Future<void> _openInGoogleMaps() async {
    final latitude = widget.room['latitude'];
    final longitude = widget.room['longitude'];
    if (latitude != null && longitude != null) {
      final lat = double.tryParse(latitude.toString());
      final lng = double.tryParse(longitude.toString());
      if (lat != null && lng != null) {
        final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could Not Launch Google Maps',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Open Booking Confirmation Dialog
  void _openBookingConfirmation() {
    if (_isRoomRequested) return;

    showDialog(
      context: context,
      builder: (context) => BookingConfirmationDialog(
        room: widget.room,
        roomDocumentId: widget.roomDocumentId,
      ),
    ).then((_) {
      _refreshRoomStatus();
    });
  }

  // Refresh Room Status From Firestore
  Future<void> _refreshRoomStatus() async {
    try {
      final firestore = FirebaseFirestore.instance;
      if (widget.roomDocumentId != null && widget.roomDocumentId!.isNotEmpty) {
        final roomDoc = await firestore.collection('room').doc(widget.roomDocumentId!).get();

        if (roomDoc.exists) {
          final roomData = roomDoc.data() as Map<String, dynamic>;
          final status = roomData['status']?.toString() ?? '';

          setState(() {
            _isRoomRequested = status.toLowerCase() == 'requested';
          });
        }
      }
    } catch (e) {
      // Error Handled Silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;

    return AnimatedBuilder(
      animation: _animationController,
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
            onTap: () {},
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

  // Main Content Builder
  Widget _buildContent(ScrollController scrollController, bool isSmallScreen, bool isTablet) {
    final room = widget.room;

    // Extract Room Data With Fallbacks
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
    final fullLocation = room['location']?.toString() ?? "Location Not Specified";
    final latitude = room['latitude'];
    final longitude = room['longitude'];

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Section
        SliverToBoxAdapter(
          child: _buildHeader(isSmallScreen, isTablet),
        ),

        // Main Image Section
        SliverToBoxAdapter(
          child: _buildMainImageSection(isSmallScreen, isTablet),
        ),

        // Thumbnails Section
        if (_images.length > 1)
          SliverToBoxAdapter(
            child: _buildThumbnailsSection(isSmallScreen, isTablet),
          ),

        // Room Details Card
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
                    // Room Title And Status Row
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

                              // Location Information
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

                        // Room Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
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
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _isRoomRequested ? "Requested" : "Available",
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

                    // Monthly Rent Section
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
                            // Rent Details
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
                                        color: ModernColors.onSurface,
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

                            // Compare Button
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
                                    Color(0xFF4CAF50),
                                    Color(0xFF2E7D32),
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

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : (isSmallScreen ? 12 : 14)),
                      child: Divider(
                        height: 1,
                        color: ModernColors.outline.withOpacity(0.3),
                      ),
                    ),

                    // Additional Amenities Section
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

                        // Water And Sunlight Pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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

                        // Bathroom And Windows Pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : (isSmallScreen ? 10 : 10),
                                vertical: isTablet ? 8 : (isSmallScreen ? 5 : 5),
                              ),
                              decoration: BoxDecoration(
                                color: hasBathroom
                                    ? const Color(0xFFE3F2FD)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                              ),
                              child: Text(
                                hasBathroom ? "🚽 Bathroom: Attached" : "🚽 Bathroom: Shared",
                                style: GoogleFonts.quicksand(
                                  fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 11),
                                  fontWeight: FontWeight.w700,
                                  color: hasBathroom
                                      ? const Color(0xFF2196F3)
                                      : const Color(0xFF757575),
                                ),
                              ),
                            ),
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

                        // Amenity Icons
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

                        // Extra Icons For Small Screens
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

        // Location Section
        SliverToBoxAdapter(
          child: _buildLocationSection(
            fullLocation: fullLocation,
            latitude: latitude,
            longitude: longitude,
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          ),
        ),

        // Action Buttons Section
        SliverToBoxAdapter(
          child: _buildActionButtons(isSmallScreen, isTablet),
        ),

        // Bottom Spacing
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet ? 20 : (isSmallScreen ? 15 : 20)),
        ),
      ],
    );
  }

  // Header With Drag Handle
  Widget _buildHeader(bool isSmallScreen, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
        vertical: isTablet ? 20 : 16,
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: isTablet ? 50 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isTablet ? 16 : (isSmallScreen ? 8 : 12)),
          // Title
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

  // Main Image Section
  Widget _buildMainImageSection(bool isSmallScreen, bool isTablet) {
    final images = _images;

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
                    // Image Count Badge
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

        // Near KU Gate Badge
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

  // Thumbnails Section
  Widget _buildThumbnailsSection(bool isSmallScreen, bool isTablet) {
    final images = _images;
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

  // Centered Thumbnails For Few Images
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

  // Scrollable Thumbnails For Many Images
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

  // Full Screen Image Viewer
  Widget _buildFullImageViewer(bool isSmallScreen, bool isTablet) {
    final images = _images;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Column(
          children: [
            // Header With Close Button
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
                    const SizedBox(width: 40), // For Symmetry
                  ],
                ),
              ),
            ),

            // Interactive Image Viewer
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

            // Bottom Thumbnails
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

  // Centered Bottom Thumbnails
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

  // Scrollable Bottom Thumbnails
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

  // Compact Specification Item
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

  // Amenity Window Icon
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

  // Location Section With Map
  Widget _buildLocationSection({
    required String fullLocation,
    required dynamic latitude,
    required dynamic longitude,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    final hasCoordinates = latitude != null && longitude != null;
    final destinationLat = hasCoordinates ? double.tryParse(latitude.toString()) : null;
    final destinationLng = hasCoordinates ? double.tryParse(longitude.toString()) : null;
    final destination = hasCoordinates && destinationLat != null && destinationLng != null
        ? LatLng(destinationLat, destinationLng)
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : (isSmallScreen ? 8 : 10),
        vertical: isTablet ? 12 : 8,
      ),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : (isSmallScreen ? 12 : 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 18 : (isSmallScreen ? 14 : 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: isTablet ? 22 : (isSmallScreen ? 18 : 20),
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
                  Text(
                    "Location",
                    style: GoogleFonts.quicksand(
                      fontSize: isTablet ? 22 : (isSmallScreen ? 16 : 18),
                      fontWeight: FontWeight.w800,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ).createShader(
                          const Rect.fromLTWH(0, 0, 200, 70),
                        ),
                    ),
                  ),
                ],
              ),
            ),

            if (hasCoordinates && destination != null) ...[
              // Google Map Container
              Container(
                height: isTablet ? 380 : (isSmallScreen ? 280 : 320),
                width: double.infinity,
                margin: EdgeInsets.only(
                  bottom: isTablet ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                  child: Stack(
                    children: [
                      // Google Map
                      ValueListenableBuilder<MapType>(
                        valueListenable: _currentMapType,
                        builder: (context, mapType, _) {
                          return GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: destination,
                              zoom: 15,
                            ),
                            onMapCreated: (controller) async {
                              if (!_mapController.isCompleted) {
                                _mapController.complete(controller);
                              }

                              if (_currentLatLng.value != null && !_polylineDrawn && destination != null) {
                                _drawDirectPolyline();
                              }

                              if (_currentLatLng.value != null) {
                                final bounds = LatLngBounds(
                                  southwest: LatLng(
                                    min(destination.latitude, _currentLatLng.value!.latitude),
                                    min(destination.longitude, _currentLatLng.value!.longitude),
                                  ),
                                  northeast: LatLng(
                                    max(destination.latitude, _currentLatLng.value!.latitude),
                                    max(destination.longitude, _currentLatLng.value!.longitude),
                                  ),
                                );

                                await controller.animateCamera(
                                  CameraUpdate.newLatLngBounds(bounds, 50),
                                );
                              } else {
                                await controller.animateCamera(
                                  CameraUpdate.newLatLngZoom(destination, 15),
                                );
                              }
                            },
                            polylines: _polylines.value,
                            markers: {
                              Marker(
                                markerId: const MarkerId('destination'),
                                position: destination,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                infoWindow: InfoWindow(
                                  title: 'Room Location',
                                  snippet: fullLocation,
                                ),
                              ),
                              if (_currentLatLng.value != null)
                                Marker(
                                  markerId: const MarkerId('current_location'),
                                  position: _currentLatLng.value!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                  infoWindow: const InfoWindow(
                                    title: 'Your Location',
                                  ),
                                ),
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            mapType: mapType,
                            minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
                          );
                        },
                      ),

                      // Map Controls
                      Positioned(
                        bottom: 12,
                        right: 8,
                        child: Column(
                          children: [
                            // Satellite Toggle Button
                            ValueListenableBuilder<MapType>(
                              valueListenable: _currentMapType,
                              builder: (context, mapType, _) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _toggleMapType,
                                    icon: Icon(
                                      Icons.satellite_rounded,
                                      color: mapType == MapType.satellite
                                          ? const Color(0xFF667EEA)
                                          : Colors.grey.shade700,
                                      size: 16,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Current Location Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _goToCurrentLocation,
                                icon: const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF667EEA),
                                  size: 16,
                                ),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Open In Google Maps Button
            if (hasCoordinates) ...[
              SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 16)),
              Container(
                height: isTablet ? 56 : (isSmallScreen ? 42 : 48),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3498DB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: _openInGoogleMaps,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                    ),
                  ),
                  icon: Icon(
                    Icons.directions_rounded,
                    size: isTablet ? 22 : 18,
                  ),
                  label: Text(
                    "Open In Google Maps",
                    style: GoogleFonts.quicksand(
                      fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Action Buttons (Chat And Book)
  Widget _buildActionButtons(bool isSmallScreen, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
        vertical: isTablet ? 16 : (isSmallScreen ? 12 : 16),
      ),
      child: Row(
        children: [
          // Chat With Owner Button
          Expanded(
            child: Container(
              height: isTablet ? 50 : (isSmallScreen ? 40 : 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9C27B0),
                    Color(0xFF7B1FA2),
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
                onPressed: _startChatWithOwner,
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
                      "Chat With Owner",
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

          // Book Room Button
          Expanded(
            child: Container(
              height: isTablet ? 50 : (isSmallScreen ? 40 : 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 12 : (isSmallScreen ? 10 : 12)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isRoomRequested
                      ? [
                    Colors.grey.shade400,
                    Colors.grey.shade600,
                  ]
                      : [
                    Color(0xFF1565C0),
                    Color(0xFF0D47A1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRoomRequested ? Colors.grey : const Color(0xFF1565C0)).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isRoomRequested ? null : _openBookingConfirmation,
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
                      _isRoomRequested ? Icons.block : Icons.bookmark_rounded,
                      size: isTablet ? 20 : (isSmallScreen ? 16 : 18),
                    ),
                    SizedBox(width: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
                    Text(
                      _isRoomRequested ? "Requested" : "Book",
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

// Modern Color Palette
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