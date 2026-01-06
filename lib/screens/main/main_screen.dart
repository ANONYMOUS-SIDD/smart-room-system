import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../owner/owner_screen.dart';
import '../user/profile_screen.dart';

/// Main Screen Container With Persistent Bottom Navigation Bar
/// Houses Primary Application Tabs: Home, Pending, History, And Profile
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  /// Build Screen Widgets For Each Navigation Tab
  List<Widget> _buildScreens() {
    return [
      const HomeScreen(), // Home Tab - Product Management
      OwnerScreen(), // Pending Tab - Credit Sales Management
      const HistoryScreen(), // History Tab - Completed Sales Records
      const ProfileScreen(), // Profile Tab - User Account Management
    ];
  }

  /// Build Navigation Bar Items With Consistent Styling
  List<PersistentBottomNavBarItem> _navBarsItems() {
    const activeColor = Colors.pink; // Active Tab Color
    const inactiveColor = Color(0xFF6B7280); // Inactive Tab Color

    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_rounded, size: 24),
        title: "Home",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.hourglass_top_rounded, size: 24),
        title: "Pending",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.shopping_cart_rounded, size: 24),
        title: "History",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_rounded, size: 24),
        title: "Profile",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarStyle: NavBarStyle.style1, // Classic Bottom Navigation Style
      backgroundColor: Colors.white, // White Navigation Bar Background
      resizeToAvoidBottomInset: true, // Adjust For On-Screen Keyboard
      stateManagement: true, // Maintain Tab State
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Compact Padding
      decoration: NavBarDecoration(
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)), // Top Border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -3), // Top Shadow For Depth
          ),
        ],
      ),
    );
  }
}
