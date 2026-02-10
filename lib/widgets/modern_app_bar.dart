import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// DESIGN SYSTEM COLOR PALETTE FOR APPLICATION UI
class ModernColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color primaryContainer = Color(0xFFEEF2FF);
}

/// CUSTOM APPLICATION BAR WITH DECORATIVE ELEMENTS AND GRADIENTS
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  const ModernAppBar({
    super.key,
    required this.title,
    this.showAddButton = false,
    this.onAddPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50.0);

  Widget _buildFloatingShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAppBarDecoration(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModernColors.primary.withOpacity(0.05),
            ModernColors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12.0),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            left: 20,
            child: _buildFloatingShape(25, ModernColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 10,
            right: 40,
            child: _buildFloatingShape(40, ModernColors.primary.withOpacity(0.06)),
          ),
          Positioned(
            top: 30,
            left: 100,
            child: _buildFloatingShape(30, ModernColors.primary.withOpacity(0.1)),
          ),
          Positioned(
            top: 5,
            right: 80,
            child: _buildFloatingShape(15, ModernColors.primary.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -5,
            left: 120,
            child: _buildFloatingShape(20, ModernColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -15,
            right: 5,
            child: _buildFloatingShape(35, ModernColors.primary.withOpacity(0.06)),
          ),
          Positioned(
            top: -25,
            right: 15,
            child: _buildFloatingShape(50, ModernColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            top: 55,
            left: 5,
            child: _buildFloatingShape(10, ModernColors.primary.withOpacity(0.1)),
          ),
          Positioned(
            top: -5,
            left: 180,
            child: _buildFloatingShape(22, ModernColors.primary.withOpacity(0.07)),
          ),
          Positioned(
            bottom: 25,
            left: 50,
            child: _buildFloatingShape(18, ModernColors.primary.withOpacity(0.09)),
          ),
          Positioned(
            top: 15,
            right: 20,
            child: _buildFloatingShape(14, ModernColors.primary.withOpacity(0.12)),
          ),
          Positioned(
            top: 5,
            left: 50,
            child: _buildFloatingShape(16, ModernColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            top: 40,
            right: 100,
            child: _buildFloatingShape(12, ModernColors.primary.withOpacity(0.1)),
          ),
          Positioned(
            bottom: 0,
            left: 30,
            child: _buildFloatingShape(22, ModernColors.primary.withOpacity(0.06)),
          ),
          Positioned(
            bottom: 40,
            right: 10,
            child: _buildFloatingShape(18, ModernColors.primary.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(15.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        toolbarHeight: 60,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.0),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.quicksand(
            letterSpacing: 1.0,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ModernColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: showAddButton
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                      color: ModernColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              onPressed: onAddPressed ?? () {},
              tooltip: 'Add New Room',
            ),
          ),
        ]
            : null,
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12.0),
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildAppBarDecoration(context),
              ),
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ModernColors.outline.withOpacity(0.8),
                      ModernColors.outline.withOpacity(0.4),
                      ModernColors.outline.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}