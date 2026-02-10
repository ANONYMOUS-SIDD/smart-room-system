import 'package:flutter/material.dart';

import '../../../themes/colors.dart';

/// STYLED CONTAINER FOR GROUPING FORM INPUT FIELDS WITH CONSISTENT DESIGN
class InputContainer extends StatelessWidget {
  final List<Widget> children;

  const InputContainer({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// THIN DIVIDER FOR VISUAL SEPARATION BETWEEN INPUT FIELDS WITHIN CONTAINER
class InputDivider extends StatelessWidget {
  const InputDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.3,
      color: Colors.grey.shade400,
    );
  }
}