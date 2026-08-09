import 'package:flutter/material.dart';

import '../navigation/bottom_nav.dart';
import 'theme/app_theme.dart';

class ChameleonApp extends StatelessWidget {
  const ChameleonApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chameleon',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.system,

      home: const BottomNav(),
    );
  }
}