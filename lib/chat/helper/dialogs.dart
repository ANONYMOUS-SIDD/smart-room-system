import 'package:flutter/material.dart';

class Dialogs {
  // Displays A Snackbar With The Provided Message
  static void showSnackbar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.blue.withOpacity(.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Displays A Loading Dialog With Circular Progress Indicator
  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(strokeWidth: 1),
      ),
    );
  }
}