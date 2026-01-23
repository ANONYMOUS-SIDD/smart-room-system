import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/modern_app_bar.dart';

/// History Screen For Viewing Completed Sales Transactions
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 350;
    final double horizontalPadding = isSmallScreen ? 16 : 20;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ModernAppBar(title: "Chat"), // Using your existing ModernAppBar
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // History Icon
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
                child: Center(child: Icon(Icons.history_outlined, size: 80, color: Colors.white)),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                "Order History",
                style: GoogleFonts.quicksand(fontSize: isSmallScreen ? 22 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
                child: Text(
                  "Transaction history and order details will be displayed here",
                  style: GoogleFonts.quicksand(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
