import 'package:flutter/material.dart';

/// Single source of truth for HeritageLinc's color palette.
/// Pulled from the logo: teal pin, gold heritage arch, deep green text.
class AppColors {
  AppColors._(); // prevents instantiation

  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color emerald = Color(0xFF10B981);
  static const Color deepTeal = Color(0xFF064E3B);

  // Heritage gold, lifted from the arch in the logo — use sparingly,
  // for accents like fare highlights or "featured tour" badges.
  static const Color heritageGold = Color(0xFFC9A227);

  static const Color background = Color(0xFFF7FAF9);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color danger = Color(0xFFDC2626);
}
