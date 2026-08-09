import 'package:flutter/material.dart';

import '../data/services/settings_service.dart';
import '../navigation/bottom_nav.dart';
import 'theme/app_theme.dart';

class ChameleonApp extends StatelessWidget {
  final SettingsService settings;

  const ChameleonApp({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Chameleon',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,

          darkTheme: AppTheme.darkTheme,

          // Now controlled by Settings.
          themeMode: settings.themeMode,

          home: BottomNav(
            settings: settings,
          ),
        );
      },
    );
  }
}