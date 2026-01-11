import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  _LocationPickerDialogState createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  LatLng? _currentLatLng;
  LatLng? _selectedLatLng;
  bool _isLoading = true;
  String? _locationAddress;
  String _errorMessage = '';

  // Navigation Info
  String _walkTime = "0 min";
  String _distance = "0.00 km";

  // Map type control
  MapType _currentMapType = MapType.normal;

  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _selectedLatLng = _currentLatLng;
        _isLoading = false;
        _locationAddress = _formatCoordinates(position.latitude, position.longitude);
        _updateMarkers();
      });

      // Automatically center on current location as soon as map opens
      if (_currentLatLng != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = 'Error: $e'; _isLoading = false; });
    }
  }

  // --- OSRM Walking Logic ---
  Future<void> _fetchWalkingPath(LatLng destination) async {
    if (_currentLatLng == null) return;

    final url = 'https://router.project-osrm.org/route/v1/foot/'
        '${_currentLatLng!.longitude},${_currentLatLng!.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];

        double distMeters = route['distance'].toDouble();
        double mins = (distMeters / 80) * 1.1;

        final coords = route['geometry']['coordinates'] as List;
        List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();

        points.insert(0, _currentLatLng!);
        points.add(destination);

        setState(() {
          _distance = "${(distMeters / 1000).toStringAsFixed(2)} km";
          _walkTime = "${mins.round()} min";
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId("walk_path"),
            points: points,
            color: const Color(0xFF667EEA),
            width: 5,
            jointType: JointType.round,
          ));
        });
      }
    } catch (e) {
      debugPrint("OSRM Error: $e");
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLatLng = location;
      _locationAddress = _formatCoordinates(location.latitude, location.longitude);
      _updateMarkers();
    });
    _fetchWalkingPath(location);
  }

  void _updateMarkers() {
    _markers.clear();
    if (_selectedLatLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('selected'),
        position: _selectedLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
  }

  String _formatCoordinates(double lat, double lng) =>
      '${lat.abs().toStringAsFixed(6)}° ${lat >= 0 ? 'N' : 'S'}, ${lng.abs().toStringAsFixed(6)}° ${lng >= 0 ? 'E' : 'W'}';

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentLatLng != null) {
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        height: screenHeight * 0.95,
        width: screenWidth,
        margin: EdgeInsets.only(top: screenHeight * 0.05),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildMapView(),
                    const SizedBox(height: 12),
                    _buildLocationInfo(isSmallScreen),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              radius: 18,
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Pick Destination",
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng ?? const LatLng(0, 0),
                zoom: 15,
              ),
              onMapCreated: (c) {
                if (!_controller.isCompleted) _controller.complete(c);
                _mapController = c;
              },
              onTap: _onMapTap,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: _currentMapType,
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 36,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                    _currentMapType == MapType.satellite
                        ? Icons.public
                        : Icons.satellite_alt_rounded,
                    color: _currentMapType == MapType.satellite
                        ? const Color(0xFF667EEA)
                        : Colors.grey.shade700,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
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
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _locationAddress ?? "Selecting...",
                    style: GoogleFonts.quicksand(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey.shade200,
            width: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _compactInfoTile(
                  Icons.directions_walk_rounded,
                  "Distance",
                  _distance,
                  const Color(0xFF667EEA),
                  isSmallScreen,
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _compactInfoTile(
                  Icons.timer_outlined,
                  "Time",
                  _walkTime,
                  const Color(0xFFFF5722),
                  isSmallScreen,
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey.shade200,
            width: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _compactOutlinedButton(
                    "Cancel",
                    Colors.grey.shade700,
                    Icons.cancel_outlined,
                        () => Navigator.pop(context),
                    isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Expanded(
                  child: _compactGradientButton(
                    "Confirm",
                    [const Color(0xFF2C3E50), const Color(0xFF3498DB)],
                    Icons.verified_rounded,
                        () {
                      if (_selectedLatLng != null) {
                        Navigator.pop(context, {
                          'address': _locationAddress,
                          'latitude': _selectedLatLng!.latitude,
                          'longitude': _selectedLatLng!.longitude,
                          'distance': _distance,
                          'walkTime': _walkTime,
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInfoTile(IconData icon, String label, String value, Color color, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: isSmallScreen ? 10 : 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _compactGradientButton(String text, List<Color> colors, IconData icon, VoidCallback onTap, bool isSmallScreen) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmallScreen ? 36 : 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isSmallScreen ? 14 : 16),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Text(
              text,
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactOutlinedButton(String text, Color color, IconData icon, VoidCallback onTap, bool isSmallScreen) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmallScreen ? 36 : 38,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 14 : 16),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Text(
              text,
              style: GoogleFonts.quicksand(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}