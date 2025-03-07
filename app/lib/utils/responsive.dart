import 'package:flutter/material.dart';

class Responsive {
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > 600;
  }
}
