import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class Helpers {
  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatPrice(double price) {
    if (price == 0) return 'Free / Exchange Only';
    return '\$${price.toStringAsFixed(2)}';
  }

  static String getConditionIcon(double rating) {
    if (rating >= 4.5) return '✨';
    if (rating >= 3.5) return '👍';
    if (rating >= 2.5) return '📖';
    if (rating >= 1.5) return '⚠️';
    return '📕';
  }

  static Color getConditionColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.teal;
    if (rating >= 2.5) return Colors.orange;
    if (rating >= 1.5) return Colors.deepOrange;
    return Colors.red;
  }
}