import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app.dart';
import 'data/services/music_controller_provider.dart';
import 'data/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId:
    'com.studios.chameleon.audio',
    androidNotificationChannelName:
    'Chameleon Music',
    androidNotificationChannelDescription:
    'Music playback controls',
    androidNotificationOngoing: true,
    androidNotificationIcon:
    'mipmap/ic_launcher',
    androidResumeOnClick: true,
  );

  final musicController =
      MusicControllerProvider.instance;

  await musicController.initialize();

  final settings = SettingsService();

  await settings.initialize();

  runApp(
    ChameleonApp(
      settings: settings,
      audioPlayerService:
      musicController.audioPlayerService,
    ),
  );
}