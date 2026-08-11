import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SettingsService extends ChangeNotifier {
  static const String _themeModeKey = 'chameleon_theme_mode';
  static const String _accentColorKey = 'chameleon_accent_color';

  static const String _crossfadeKey = 'chameleon_crossfade';
  static const String _gaplessKey = 'chameleon_gapless';
  static const String _autoplayKey = 'chameleon_autoplay';
  static const String _highQualityKey = 'chameleon_high_quality';
  static const String _normalizeKey = 'chameleon_normalize';

  static const String _animatedArtworkKey =
      'chameleon_animated_artwork';
  static const String _miniPlayerKey = 'chameleon_mini_player';
  static const String _keepScreenAwakeKey =
      'chameleon_keep_screen_awake';

  static const String _saveSearchesKey = 'chameleon_save_searches';
  static const String _notificationsKey = 'chameleon_notifications';
  static const String _wifiOnlyKey = 'chameleon_wifi_only';

  static const String _downloadQualityKey =
      'chameleon_download_quality';
  static const String _recentLimitKey = 'chameleon_recent_limit';

  static const String _sleepTimerKey = 'chameleon_sleep_timer';
  static const String _sleepTimerEndKey =
      'chameleon_sleep_timer_end';
  static const String _sleepTimerEndOfSongKey =
      'chameleon_sleep_timer_end_of_song';
  static const ThemeMode defaultThemeMode = ThemeMode.system;
  static const int defaultAccentColor = 0xFF7C4DFF;

  static const bool defaultCrossfade = false;
  static const bool defaultGapless = true;
  static const bool defaultAutoplay = true;
  static const bool defaultHighQuality = true;
  static const bool defaultNormalize = false;

  static const bool defaultAnimatedArtwork = true;
  static const bool defaultMiniPlayer = true;
  static const bool defaultKeepScreenAwake = false;

  static const bool defaultSaveSearches = true;
  static const bool defaultNotifications = true;
  static const bool defaultWifiOnly = true;

  static const String defaultDownloadQuality = 'High';
  static const int defaultRecentLimit = 50;

  static const List<String> downloadQualities = <String>[
    'Low',
    'Medium',
    'High',
  ];

  static const List<int> recentLimitOptions = <int>[
    25,
    50,
    100,
  ];
  final SharedPreferencesAsync _preferences =
  SharedPreferencesAsync();
  ThemeMode _themeMode = defaultThemeMode;
  int _accentColor = defaultAccentColor;

  bool _crossfade = defaultCrossfade;
  bool _gapless = defaultGapless;
  bool _autoplay = defaultAutoplay;
  bool _highQuality = defaultHighQuality;
  bool _normalize = defaultNormalize;

  bool _animatedArtwork = defaultAnimatedArtwork;
  bool _miniPlayer = defaultMiniPlayer;
  bool _keepScreenAwake = defaultKeepScreenAwake;

  bool _saveSearches = defaultSaveSearches;
  bool _notifications = defaultNotifications;
  bool _wifiOnly = defaultWifiOnly;

  String _downloadQuality = defaultDownloadQuality;
  int _recentLimit = defaultRecentLimit;

  Duration? _sleepTimerDuration;
  DateTime? _sleepTimerEnd;
  bool _sleepTimerEndOfSong = false;

  Timer? _sleepTimerTicker;

  bool _initialized = false;
  Future<void>? _initialization;
  bool get isInitialized => _initialized;

  ThemeMode get themeMode => _themeMode;

  int get accentColor => _accentColor;

  Color get accentColorValue => Color(_accentColor);

  bool get crossfade => _crossfade;

  bool get gapless => _gapless;

  bool get autoplay => _autoplay;

  bool get highQuality => _highQuality;

  bool get normalize => _normalize;

  bool get animatedArtwork => _animatedArtwork;

  bool get miniPlayer => _miniPlayer;

  bool get keepScreenAwake => _keepScreenAwake;

  bool get saveSearches => _saveSearches;

  bool get notifications => _notifications;

  bool get wifiOnly => _wifiOnly;

  String get downloadQuality => _downloadQuality;

  int get recentLimit => _recentLimit;

  Duration? get sleepTimerDuration => _sleepTimerDuration;

  DateTime? get sleepTimerEnd => _sleepTimerEnd;

  bool get sleepTimerEndOfSong => _sleepTimerEndOfSong;

  bool get sleepTimerActive =>
      _sleepTimerEnd != null || _sleepTimerEndOfSong;

  Duration? get sleepTimerRemaining {
    final end = _sleepTimerEnd;

    if (end == null) {
      return null;
    }

    final remaining = end.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      return Duration.zero;
    }

    return remaining;
  }
  Future<void> initialize() {
    final running = _initialization;
    if (running != null) {
      return running;
    }

    final operation = _initializeInternal();
    _initialization = operation;

    return operation.whenComplete(() {
      if (identical(_initialization, operation)) {
        _initialization = null;
      }
    });
  }

  Future<void> _initializeInternal() async {
    if (_initialized) {
      return;
    }

    final theme = await _preferences.getString(_themeModeKey);

    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => defaultThemeMode,
    };

    final accent = await _preferences.getInt(_accentColorKey);
    if (accent != null && _isValidArgbColor(accent)) {
      _accentColor = accent;
    } else {
      _accentColor = defaultAccentColor;
    }

    _crossfade =
        await _preferences.getBool(_crossfadeKey) ??
            defaultCrossfade;

    _gapless =
        await _preferences.getBool(_gaplessKey) ??
            defaultGapless;

    _autoplay =
        await _preferences.getBool(_autoplayKey) ??
            defaultAutoplay;

    _highQuality =
        await _preferences.getBool(_highQualityKey) ??
            defaultHighQuality;

    _normalize =
        await _preferences.getBool(_normalizeKey) ??
            defaultNormalize;

    _animatedArtwork =
        await _preferences.getBool(_animatedArtworkKey) ??
            defaultAnimatedArtwork;

    _miniPlayer =
        await _preferences.getBool(_miniPlayerKey) ??
            defaultMiniPlayer;

    _keepScreenAwake =
        await _preferences.getBool(_keepScreenAwakeKey) ??
            defaultKeepScreenAwake;

    _saveSearches =
        await _preferences.getBool(_saveSearchesKey) ??
            defaultSaveSearches;

    _notifications =
        await _preferences.getBool(_notificationsKey) ??
            defaultNotifications;

    _wifiOnly =
        await _preferences.getBool(_wifiOnlyKey) ??
            defaultWifiOnly;

    final storedQuality =
    await _preferences.getString(_downloadQualityKey);

    _downloadQuality =
    _isValidDownloadQuality(storedQuality)
        ? storedQuality!
        : defaultDownloadQuality;

    final storedRecentLimit =
    await _preferences.getInt(_recentLimitKey);

    _recentLimit =
    _isValidRecentLimit(storedRecentLimit)
        ? storedRecentLimit!
        : defaultRecentLimit;

    await _loadSleepTimer();

    _initialized = true;
    _syncSleepTimerTicker();

    notifyListeners();
  }
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    await _preferences.setString(
      _themeModeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );

    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    final value = color.toARGB32();

    if (!_isValidArgbColor(value)) {
      return;
    }

    _accentColor = value;

    await _preferences.setInt(
      _accentColorKey,
      value,
    );

    notifyListeners();
  }
  Future<void> setCrossfade(bool value) async {
    _crossfade = value;
    await _preferences.setBool(_crossfadeKey, value);
    notifyListeners();
  }

  Future<void> setGapless(bool value) async {
    _gapless = value;
    await _preferences.setBool(_gaplessKey, value);
    notifyListeners();
  }

  Future<void> setAutoplay(bool value) async {
    _autoplay = value;
    await _preferences.setBool(_autoplayKey, value);
    notifyListeners();
  }

  Future<void> setHighQuality(bool value) async {
    _highQuality = value;
    await _preferences.setBool(_highQualityKey, value);
    notifyListeners();
  }

  Future<void> setNormalize(bool value) async {
    _normalize = value;
    await _preferences.setBool(_normalizeKey, value);
    notifyListeners();
  }
  Future<void> setAnimatedArtwork(bool value) async {
    _animatedArtwork = value;
    await _preferences.setBool(
      _animatedArtworkKey,
      value,
    );
    notifyListeners();
  }

  Future<void> setMiniPlayer(bool value) async {
    _miniPlayer = value;
    await _preferences.setBool(
      _miniPlayerKey,
      value,
    );
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool value) async {
    _keepScreenAwake = value;
    await _preferences.setBool(
      _keepScreenAwakeKey,
      value,
    );
    notifyListeners();
  }
  Future<void> setSaveSearches(bool value) async {
    _saveSearches = value;

    await _preferences.setBool(
      _saveSearchesKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;

    await _preferences.setBool(
      _notificationsKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;

    await _preferences.setBool(
      _wifiOnlyKey,
      value,
    );

    notifyListeners();
  }
  Future<void> setDownloadQuality(String value) async {
    if (!_isValidDownloadQuality(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Download quality must be one of: '
            '${downloadQualities.join(', ')}',
      );
    }

    _downloadQuality = value;

    await _preferences.setString(
      _downloadQualityKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setRecentLimit(int value) async {
    if (!_isValidRecentLimit(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Recent limit must be one of: '
            '${recentLimitOptions.join(', ')}',
      );
    }

    _recentLimit = value;

    await _preferences.setInt(
      _recentLimitKey,
      value,
    );

    notifyListeners();
  }
  Future<void> _loadSleepTimer() async {
    final sleepMinutes =
    await _preferences.getInt(_sleepTimerKey);

    final sleepEndMillis =
    await _preferences.getInt(_sleepTimerEndKey);

    final endOfSong =
        await _preferences.getBool(
          _sleepTimerEndOfSongKey,
        ) ??
            false;

    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
    _sleepTimerEndOfSong = false;

    if (sleepEndMillis != null && sleepEndMillis > 0) {
      final end = DateTime.fromMillisecondsSinceEpoch(
        sleepEndMillis,
      );

      if (end.isAfter(DateTime.now())) {
        _sleepTimerEnd = end;

        if (sleepMinutes != null && sleepMinutes > 0) {
          _sleepTimerDuration = Duration(
            minutes: sleepMinutes,
          );
        }
      } else {
        await _clearPersistedSleepTimer();
      }
    }

    if (_sleepTimerEnd == null && endOfSong) {
      _sleepTimerEndOfSong = true;
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    if (duration <= Duration.zero) {
      await clearSleepTimer();
      return;
    }

    _sleepTimerDuration = duration;
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimerEndOfSong = false;

    await _preferences.setInt(
      _sleepTimerKey,
      duration.inMinutes,
    );

    await _preferences.setInt(
      _sleepTimerEndKey,
      _sleepTimerEnd!.millisecondsSinceEpoch,
    );

    await _preferences.setBool(
      _sleepTimerEndOfSongKey,
      false,
    );

    _syncSleepTimerTicker();
    notifyListeners();
  }

  Future<void> setSleepTimerEndOfSong() async {
    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
    _sleepTimerEndOfSong = true;

    await _preferences.remove(_sleepTimerKey);
    await _preferences.remove(_sleepTimerEndKey);

    await _preferences.setBool(
      _sleepTimerEndOfSongKey,
      true,
    );

    _syncSleepTimerTicker();
    notifyListeners();
  }

  Future<void> clearSleepTimer() async {
    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
    _sleepTimerEndOfSong = false;

    await _clearPersistedSleepTimer();

    _syncSleepTimerTicker();
    notifyListeners();
  }

  Future<void> _clearPersistedSleepTimer() async {
    await _preferences.remove(_sleepTimerKey);
    await _preferences.remove(_sleepTimerEndKey);
    await _preferences.setBool(
      _sleepTimerEndOfSongKey,
      false,
    );
  }
  void _syncSleepTimerTicker() {
    _sleepTimerTicker?.cancel();

    if (_sleepTimerEnd == null) {
      return;
    }

    _sleepTimerTicker = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        final remaining = sleepTimerRemaining;

        if (remaining == null) {
          _sleepTimerTicker?.cancel();
          return;
        }

        if (remaining <= Duration.zero) {
          _sleepTimerTicker?.cancel();
        }

        notifyListeners();
      },
    );
  }
  Future<void> reset() async {
    await Future.wait([
      _preferences.remove(_themeModeKey),
      _preferences.remove(_accentColorKey),
      _preferences.remove(_crossfadeKey),
      _preferences.remove(_gaplessKey),
      _preferences.remove(_autoplayKey),
      _preferences.remove(_highQualityKey),
      _preferences.remove(_normalizeKey),
      _preferences.remove(_animatedArtworkKey),
      _preferences.remove(_miniPlayerKey),
      _preferences.remove(_keepScreenAwakeKey),
      _preferences.remove(_saveSearchesKey),
      _preferences.remove(_notificationsKey),
      _preferences.remove(_wifiOnlyKey),
      _preferences.remove(_downloadQualityKey),
      _preferences.remove(_recentLimitKey),
      _preferences.remove(_sleepTimerKey),
      _preferences.remove(_sleepTimerEndKey),
      _preferences.remove(_sleepTimerEndOfSongKey),
    ]);

    _themeMode = defaultThemeMode;
    _accentColor = defaultAccentColor;

    _crossfade = defaultCrossfade;
    _gapless = defaultGapless;
    _autoplay = defaultAutoplay;
    _highQuality = defaultHighQuality;
    _normalize = defaultNormalize;

    _animatedArtwork = defaultAnimatedArtwork;
    _miniPlayer = defaultMiniPlayer;
    _keepScreenAwake = defaultKeepScreenAwake;

    _saveSearches = defaultSaveSearches;
    _notifications = defaultNotifications;
    _wifiOnly = defaultWifiOnly;

    _downloadQuality = defaultDownloadQuality;
    _recentLimit = defaultRecentLimit;

    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
    _sleepTimerEndOfSong = false;

    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;

    notifyListeners();
  }
  static bool _isValidArgbColor(int value) {
    return value >= 0 && value <= 0xFFFFFFFF;
  }

  static bool _isValidDownloadQuality(String? value) {
    return value != null &&
        downloadQualities.contains(value);
  }

  static bool _isValidRecentLimit(int? value) {
    return value != null &&
        recentLimitOptions.contains(value);
  }
  @override
  void dispose() {
    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;
    super.dispose();
  }
}
