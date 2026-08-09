import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_theme.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,

      scaffoldBackgroundColor:
      AppColors.lightBackground,

      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: AppColors.lightPrimary,
        secondary: AppColors.accent,
      ),

      textTheme: AppTextTheme.light,

      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      dividerColor: Colors.transparent,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      pageTransitionsTheme:
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android:
          CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:
          CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      scaffoldBackgroundColor:
      AppColors.darkBackground,

      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        primary: AppColors.darkPrimary,
        secondary: AppColors.accent,
      ),

      textTheme: AppTextTheme.dark,

      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      dividerColor: Colors.transparent,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      pageTransitionsTheme:
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android:
          CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:
          CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}