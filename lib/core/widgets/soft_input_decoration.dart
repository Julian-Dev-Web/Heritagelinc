import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Keeps every TextFormField across Login/Register visually identical
/// without repeating InputDecoration code in each screen.
InputDecoration softInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.5),
    prefixIcon: Icon(icon, color: AppColors.textGrey, size: 21),
    suffixIcon: suffixIcon,
  );
}