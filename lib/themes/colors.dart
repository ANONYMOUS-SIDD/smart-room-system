import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color secondaryPurple = Color(0xFF8B5CF6);

  static const Color nameIconColor = Color(0xFF34C759);
  static const Color phoneIconColor = Color(0xFFDC241F);
  static const Color emailIconColor = Color(0xFF007AFF);
  static const Color passwordIconColor = Color(0xFFFF9500);
  static const Color confirmPasswordIconColor = Color(0xFF5856D6);

  static const Color successGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color warningOrange = Color(0xFFFF9500);

  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color hintTextColor = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE5E5E5);

  static const List<Color> buttonGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
  static const List<Color> textGradient = [
    Color(0xFF6366F1),
    Color(0xFFFF6B95),
  ];

  // Returns Hint Text Color Based On Theme Context
  static Color getHintTextColor(BuildContext context) {
    return Colors.grey.shade700;
  }

  // Returns Border Color Based On Theme Context
  static Color getBorderColor(BuildContext context) {
    return Colors.grey.shade300;
  }
}