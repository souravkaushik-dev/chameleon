import 'package:flutter/material.dart';
import '../data/services/settings_service.dart';
import '../features/welcome/splash_screen.dart';
import 'theme/app_theme.dart';

class ChameleonApp extends StatelessWidget {
  final SettingsService settings;

  const ChameleonApp({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chameleon',

      debugShowCheckedModeBanner: false,

      theme:
      AppTheme.lightTheme,

      darkTheme:
      AppTheme.darkTheme,

      themeMode:
      ThemeMode.system,

      home: SplashScreen(
        settings: settings,
      ),
    );
  }
}