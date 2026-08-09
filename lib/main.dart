import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/services/music_controller_provider.dart';
import 'data/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MusicControllerProvider
      .instance
      .initialize();

  final settings =
  SettingsService();

  await settings.initialize();

  runApp(
    ChameleonApp(
      settings: settings,
    ),
  );
}