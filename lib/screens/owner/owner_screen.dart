import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/modern_app_bar.dart';

/// Owner Screen For Viewing User Requests And Order Status
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  int _currentTabIndex = 0;

  // Dummy data for current room orders (Active)
  final List<Map<String, dynamic>> _currentOrders = [
    {
      'id': '1',
      'roomNumber': '101',
      'image':
      'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&h=600&fit=crop',
      'price': '120',
      'aiPrice': '135',
      'status': 'requested',
      'requestedBy': 'John Doe',
      'date': 'Today, 10:30 AM',
      'duration': '3 nights',
      'rating': 4.8,
    },
    {
      'id': '2',
      'roomNumber': '102',
      'image':
      'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&h=600&fit=crop',
      'price': '150',
      'aiPrice': '165',
      'status': 'pending',
      'requestedBy': '-',
      'date': '-',
      'duration': '-',
      'rating': 4.5,
    },
    {
      'id': '3',
      'roomNumber': '201',
      'image':
      'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=800&h=600&fit=crop',
      'price': '200',
      'aiPrice': '220',
      'status': 'requested',
      'requestedBy': 'Alice Smith',
      'date': 'Today, 09:15 AM',
      'duration': '5 nights',
      'rating': 4.9,
    },
    {
      'id': '4',
      'roomNumber': '202',
      'image':
      'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=800&h=600&fit=crop',
      'price': '180',
      'aiPrice': '195',
      'status': 'pending',
      'requestedBy': '-',
      'date': '-',
      'duration': '-',
      'rating': 4.7,
    },
    {
      'id': '5',
      'roomNumber': '103',
      'image':
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&h=600&fit=crop',
      'price': '90',
      'aiPrice': '105',
      'status': 'requested',
      'requestedBy': 'Mike Ross',
      'date': 'Today, 11:45 AM',
      'duration': '2 nights',
      'rating': 4.3,
    },
    {
      'id': '6',
      'roomNumber': '203',
      'image':
      'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=800&h=600&fit=crop',
      'price': '250',
      'aiPrice': '275',
      'status': 'pending',
      'requestedBy': '-',
      'date': '-',
      'duration': '-',
      'rating': 4.6,
    },
  ];

  // Dummy data for order history (Booked items)
  final List<Map<String, dynamic>> _orderHistory = [
    {
      'id': 'H1',
      'roomNumber': '301',
      'image':
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&h=600&fit=crop',
      'price': '130',
      'aiPrice': '145',
      'status': 'booked',
      'customer': 'Michael Brown',
      'date': 'Dec 15',
      'duration': '3 nights',
      'totalEarned': '390',
      'rating': 4.8,
    },
    {
      'id': 'H2',
      'roomNumber': '302',
      'image':
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop',
      'price': '155',
      'aiPrice': '170',
      'status': 'booked',
      'customer': 'Sarah Johnson',
      'date': 'Dec 10',
      'duration': '2 nights',
      'totalEarned': '310',
      'rating': 4.5,
    },
    {
      'id': 'H3',
      'roomNumber': '303',
      'image':
      'https://images.unsplash.com/photo-1505691723518-36a1a0b3e6d4?w=800&h=600&fit=crop',
      'price': '210',
      'aiPrice': '230',
      'status': 'booked',
      'customer': 'Emma Davis',
      'date': 'Nov 28',
      'duration': '5 nights',
      'totalEarned': '1050',
      'rating': 4.7,
    },
    {
      'id': 'H4',
      'roomNumber': '304',
      'image':
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&h=600&fit=crop',
      'price': '95',
      'aiPrice': '110',
      'status': 'booked',
      'customer': 'David Lee',
      'date': 'Nov 25',
      'duration': '1 night',
      'totalEarned': '95',
      'rating': 4.3,
    },
    {
      'id': 'H5',
      'roomNumber': '305',
      'image':
      'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=800&h=600&fit=crop',
      'price': '260',
      'aiPrice': '290',
      'status': 'booked',
      'customer': 'Lisa Wang',
      'date': 'Nov 20',
      'duration': '3 nights',
      'totalEarned': '780',
      'rating': 4.6,
    },
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 350;
    final double horizontalPadding = isSmallScreen ? 12 : 14;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const ModernAppBar(title: "Owner Dashboard"),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // main container top margin
              const SizedBox(height: 18),

              // Main Orders Container
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle
                    Padding(
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
                                label: 'Active', // renamed
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

                    // Content (Active / History)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: _currentTabIndex == 0
                          ? _buildCurrentOrdersGrid()
                          : _buildOrderHistoryGrid(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
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

  Widget _buildCurrentOrdersGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 25,
        childAspectRatio: 0.62,
      ),
      itemCount: _currentOrders.length,
      itemBuilder: (context, index) {
        final order = _currentOrders[index];
        return _buildOrderCard(order, isCurrent: true);
      },
    );
  }

  Widget _buildOrderHistoryGrid() {
    // show only booked items in history (as requested)
    final bookedHistory = _orderHistory.where((h) => h['status'] == 'booked').toList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 25,
        childAspectRatio: 0.62,
      ),
      itemCount: bookedHistory.length,
      itemBuilder: (context, index) {
        final history = bookedHistory[index];
        return _buildOrderCard(history, isCurrent: false);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data, {required bool isCurrent}) {
    final bool isRequested = data['status'] == 'requested';
    final bool isPending = data['status'] == 'pending';
    final bool isBooked = data['status'] == 'booked';

    // defaults
    String statusText = data['status'];
    IconData statusIcon = Icons.info_outline;
    BoxDecoration statusDecoration = const BoxDecoration(
      color: Color(0xFFF1F5F9),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    bool useWhiteForeground = false;

    if (isCurrent) {
      if (isRequested) {
        statusText = 'Requested';
        statusIcon = Icons.verified_rounded;
        statusDecoration = const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );
        useWhiteForeground = true; // requested uses white foreground
      } else if (isPending) {
        statusText = 'Pending';
        statusIcon = Icons.pending_rounded;
        statusDecoration = const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );
        useWhiteForeground = true; // pending uses white foreground
      }
    } else {
      // History: only booked items are shown here (we filtered)
      if (isBooked) {
        statusText = 'Booked';
        statusIcon = Icons.check_circle_rounded;
        statusDecoration = const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );
        useWhiteForeground = true;
      }
    }

    final Color fgColor = useWhiteForeground ? Colors.white : const Color(0xFF1E293B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image (reduced height)
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.5), topRight: Radius.circular(10.5)),
              child: CachedNetworkImage(
                imageUrl: data['image'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => _buildShimmerEffect(),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: Center(child: Icon(Icons.broken_image_rounded, size: 22, color: const Color(0xFFCBD5E1))),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.attach_money_rounded, size: 14, color: const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text('Price',
                            style: GoogleFonts.quicksand(
                                fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      ]),
                      Text(data['price'],
                          style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // AI Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text('AI Price',
                            style: GoogleFonts.quicksand(
                                fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      ]),
                      Text(data['aiPrice'],
                          style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Status (same roundness/height as price boxes)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: statusDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, size: 14, color: fgColor),
                      const SizedBox(width: 8),
                      Text(statusText, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w800, color: fgColor)),
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

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          color: const Color(0xFFF1F5F9),
          child: Stack(
            children: [
              Positioned(
                left: -120 + (260 * _shimmerController.value),
                top: 0,
                bottom: 0,
                width: 90,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [
                      const Color(0xFFF1F5F9),
                      Colors.white.withOpacity(0.85),
                      const Color(0xFFF1F5F9),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}