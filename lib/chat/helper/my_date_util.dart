import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class MyDateUtil {
  // Formats Time From Milliseconds Since Epoch To Human Readable Time
  static String getFormattedTime({
    required BuildContext context,
    required String time,
  }) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);
  }

  // Formats Message Time With Date If Not Today
  static String getMessageTime({
    required String time,
  }) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    final String formattedTime = DateFormat('h:mm a').format(sent);

    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return formattedTime;
    }

    final String formattedDate = now.year == sent.year
        ? '${sent.day} ${_getMonth(sent)}'
        : '${sent.day} ${_getMonth(sent)} ${sent.year}';

    return '$formattedTime - $formattedDate';
  }

  // Gets Last Message Time For Chat User Card Display
  static String getLastMessageTime({
    required BuildContext context,
    required String time,
    bool showYear = false,
  }) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return TimeOfDay.fromDateTime(sent).format(context);
    }

    return showYear
        ? '${sent.day} ${_getMonth(sent)} ${sent.year}'
        : '${sent.day} ${_getMonth(sent)}';
  }

  // Formats Last Active Time Of User In Chat Screen
  static String getLastActiveTime({
    required BuildContext context,
    required String lastActive,
  }) {
    final int i = int.tryParse(lastActive) ?? -1;

    if (i == -1) return 'Last Seen Not Available';

    DateTime time = DateTime.fromMillisecondsSinceEpoch(i);
    DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return 'Last Seen Today At $formattedTime';
    }

    if ((now.difference(time).inHours / 24).round() == 1) {
      return 'Last Seen Yesterday At $formattedTime';
    }

    String month = _getMonth(time);

    return 'Last Seen On ${time.day} $month At $formattedTime';
  }

  // Converts Month Number To Month Name Abbreviation
  static String _getMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sept';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return 'NA';
  }
}