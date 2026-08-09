import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // LIGHT
  // ---------------------------------------------------------------------------

  static const lightBackground = Color(0xFFF7F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSoft = Color(0xFFF0F0ED);

  static const lightPrimary = Color(0xFF171717);
  static const lightSecondary = Color(0xFF777773);
  static const lightMuted = Color(0xFFAAA9A3);

  // ---------------------------------------------------------------------------
  // DARK
  // ---------------------------------------------------------------------------

  static const darkBackground = Color(0xFF101110);
  static const darkSurface = Color(0xFF191A18);
  static const darkSurfaceSoft = Color(0xFF222320);

  static const darkPrimary = Color(0xFFF5F5F1);
  static const darkSecondary = Color(0xFFA5A59F);
  static const darkMuted = Color(0xFF686963);

  // ---------------------------------------------------------------------------
  // SHARED
  // ---------------------------------------------------------------------------

  static const accent = Color(0xFF9AAA68);

  static const lightDivider = Color(0xFFE9E9E5);
  static const darkDivider = Color(0xFF292A27);
}