import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/services/music_controller_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MusicControllerProvider.instance.initialize();

  runApp(const ChameleonApp());
}