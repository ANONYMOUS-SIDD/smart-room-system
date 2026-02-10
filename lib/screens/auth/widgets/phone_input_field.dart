import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../themes/colors.dart';

/// SPECIALIZED PHONE NUMBER INPUT FIELD WITH PHONE ICON FOR MOBILE NUMBER INPUT
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;

  const PhoneInputField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPhoneIconContainer(),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              cursorColor: AppColors.primaryBlue,
              cursorHeight: 20,
              cursorWidth: 2,
              cursorRadius: const Radius.circular(3),
              decoration: _buildInputDecoration(context),
              validator: validator,
              maxLength: 10,
              buildCounter: (
                  BuildContext context, {
                    required int currentLength,
                    required int? maxLength,
                    required bool isFocused,
                  }) =>
              null,
            ),
          ),
        ],
      ),
    );
  }

  /// BUILD PHONE ICON CONTAINER WITH STYLED BACKGROUND AND PHONE ICON
  Widget _buildPhoneIconContainer() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.phoneIconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.phone_outlined,
        color: AppColors.phoneIconColor,
        size: 20,
      ),
    );
  }

  /// BUILD INPUT DECORATION WITH CONSISTENT STYLING FOR PHONE INPUT FIELD
  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.quicksand(
        color: AppColors.getHintTextColor(context),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
      border: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      helperText: ' ',
      helperStyle: const TextStyle(
        height: 0.8,
        color: Colors.transparent,
      ),
      errorStyle: GoogleFonts.quicksand(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.errorRed,
        height: 1.0,
      ),
      contentPadding: const EdgeInsets.only(top: 15),
      isDense: true,
      alignLabelWithHint: true,
    );
  }
}