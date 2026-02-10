import 'package:flutter/material.dart';

/// AUTHENTICATION SCREEN UTILITY CLASS FOR RESPONSIVE DESIGN AND BACKGROUND ELEMENTS
class AuthUtils {

  /// CALCULATE HEIGHT VALUE AS PERCENTAGE OF SCREEN HEIGHT FOR RESPONSIVE LAYOUT
  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  /// CALCULATE WIDTH VALUE AS PERCENTAGE OF SCREEN WIDTH FOR RESPONSIVE LAYOUT
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// RETRIEVE KEYBOARD BOTTOM INSET FOR PROPER VIEW ADJUSTMENT
  static double getBottomInset(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// CREATE BACKGROUND RADIAL GRADIENTS FOR AUTHENTICATION SCREEN VISUAL ENHANCEMENT
  static List<Widget> buildBackgroundGradients(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return [
      Positioned(
        top: -height * 0.15,
        right: -width * 0.1,
        child: Container(
          width: width * 0.5,
          height: width * 0.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [const Color(0xFF007AFF).withOpacity(0.08), Colors.transparent]
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -height * 0.1,
        left: -width * 0.1,
        child: Container(
          width: width * 0.4,
          height: width * 0.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [const Color(0xFFFF9500).withOpacity(0.06), Colors.transparent]
            ),
          ),
        ),
      ),
    ];
  }
}