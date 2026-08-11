import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
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
    'drawable/ic_notification',
    androidResumeOnClick: true,
  );

  final musicController =
      MusicControllerProvider.instance;

  await musicController.initialize();

  final settings =
  SettingsService();

  await settings.initialize();

  runApp(
    ScreenUtilPlusInit(
      designSize:
      const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (
          context,
          child,
          ) {
        return ChameleonApp(
          settings: settings,
          audioPlayerService:
          musicController.audioPlayerService,
        );
      },
    ),
  );
}