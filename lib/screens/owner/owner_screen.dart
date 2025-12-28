import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/modern_app_bar.dart';

/// Owner Screen For Viewing User Requests And Order Status
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 350;
    final double horizontalPadding = isSmallScreen ? 16 : 20;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ModernAppBar(title: "Owner Dashboard"), // Using your existing ModernAppBar
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Owner Icon Section
            Container(
              margin: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 30),
              child: Column(
                children: [
                  // Owner Icon
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [const Color(0xFF007AFF), const Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                        BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                      ],
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                    child: Center(child: Icon(Icons.person_outline_rounded, size: 80, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    "Owner Dashboard",
                    style: GoogleFonts.quicksand(fontSize: isSmallScreen ? 22 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
                    child: Text(
                      "User Requests and Order Status will be displayed here",
                      style: GoogleFonts.quicksand(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Coming Soon Section
            Container(
              margin: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 2),
                    ),
                    child: Icon(Icons.rocket_launch_rounded, size: 30, color: const Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Advanced Analytics Coming Soon",
                    style: GoogleFonts.quicksand(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Detailed user requests, order tracking, and performance metrics will be available in the next update",
                    style: GoogleFonts.quicksand(fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
