import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeModeKey =
      'chameleon_theme_mode';

  static const String _accentColorKey =
      'chameleon_accent_color';

  static const String _crossfadeKey =
      'chameleon_crossfade';

  static const String _gaplessKey =
      'chameleon_gapless';

  static const String _autoplayKey =
      'chameleon_autoplay';

  static const String _highQualityKey =
      'chameleon_high_quality';

  static const String _normalizeKey =
      'chameleon_normalize';

  static const String _animatedArtworkKey =
      'chameleon_animated_artwork';

  static const String _miniPlayerKey =
      'chameleon_mini_player';

  static const String _keepScreenAwakeKey =
      'chameleon_keep_screen_awake';

  static const String _saveSearchesKey =
      'chameleon_save_searches';

  static const String _notificationsKey =
      'chameleon_notifications';

  static const String _wifiOnlyKey =
      'chameleon_wifi_only';

  static const String _downloadQualityKey =
      'chameleon_download_quality';

  static const String _recentLimitKey =
      'chameleon_recent_limit';

  final SharedPreferencesAsync _preferences =
  SharedPreferencesAsync();

  ThemeMode _themeMode = ThemeMode.system;

  int _accentColor = 0xFF7C4DFF;

  bool _crossfade = false;
  bool _gapless = true;
  bool _autoplay = true;
  bool _highQuality = true;
  bool _normalize = false;
  bool _animatedArtwork = true;
  bool _miniPlayer = true;
  bool _keepScreenAwake = false;
  bool _saveSearches = true;
  bool _notifications = true;
  bool _wifiOnly = true;

  String _downloadQuality = 'High';

  int _recentLimit = 50;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  ThemeMode get themeMode => _themeMode;

  int get accentColor => _accentColor;

  Color get accentColorValue =>
      Color(_accentColor);

  bool get crossfade => _crossfade;

  bool get gapless => _gapless;

  bool get autoplay => _autoplay;

  bool get highQuality => _highQuality;

  bool get normalize => _normalize;

  bool get animatedArtwork =>
      _animatedArtwork;

  bool get miniPlayer => _miniPlayer;

  bool get keepScreenAwake =>
      _keepScreenAwake;

  bool get saveSearches => _saveSearches;

  bool get notifications =>
      _notifications;

  bool get wifiOnly => _wifiOnly;

  String get downloadQuality =>
      _downloadQuality;

  int get recentLimit => _recentLimit;

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  Future<void> initialize() async {
    final theme =
    await _preferences.getString(
      _themeModeKey,
    );

    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;

      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      default:
        _themeMode = ThemeMode.system;
    }

    final accent =
    await _preferences.getInt(
      _accentColorKey,
    );

    if (accent != null) {
      _accentColor = accent;
    }

    _crossfade =
        await _preferences.getBool(
          _crossfadeKey,
        ) ??
            false;

    _gapless =
        await _preferences.getBool(
          _gaplessKey,
        ) ??
            true;

    _autoplay =
        await _preferences.getBool(
          _autoplayKey,
        ) ??
            true;

    _highQuality =
        await _preferences.getBool(
          _highQualityKey,
        ) ??
            true;

    _normalize =
        await _preferences.getBool(
          _normalizeKey,
        ) ??
            false;

    _animatedArtwork =
        await _preferences.getBool(
          _animatedArtworkKey,
        ) ??
            true;

    _miniPlayer =
        await _preferences.getBool(
          _miniPlayerKey,
        ) ??
            true;

    _keepScreenAwake =
        await _preferences.getBool(
          _keepScreenAwakeKey,
        ) ??
            false;

    _saveSearches =
        await _preferences.getBool(
          _saveSearchesKey,
        ) ??
            true;

    _notifications =
        await _preferences.getBool(
          _notificationsKey,
        ) ??
            true;

    _wifiOnly =
        await _preferences.getBool(
          _wifiOnlyKey,
        ) ??
            true;

    _downloadQuality =
        await _preferences.getString(
          _downloadQualityKey,
        ) ??
            'High';

    _recentLimit =
        await _preferences.getInt(
          _recentLimitKey,
        ) ??
            50;

    notifyListeners();
  }

  // ===========================================================================
  // THEME
  // ===========================================================================

  Future<void> setThemeMode(
      ThemeMode mode,
      ) async {
    _themeMode = mode;

    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await _preferences.setString(
      _themeModeKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // ACCENT COLOR
  // ===========================================================================

  Future<void> setAccentColor(
      Color color,
      ) async {
    _accentColor = color.toARGB32();

    await _preferences.setInt(
      _accentColorKey,
      _accentColor,
    );

    notifyListeners();
  }

  // ===========================================================================
  // PLAYBACK
  // ===========================================================================

  Future<void> setCrossfade(
      bool value,
      ) async {
    _crossfade = value;

    await _preferences.setBool(
      _crossfadeKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setGapless(
      bool value,
      ) async {
    _gapless = value;

    await _preferences.setBool(
      _gaplessKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setAutoplay(
      bool value,
      ) async {
    _autoplay = value;

    await _preferences.setBool(
      _autoplayKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setHighQuality(
      bool value,
      ) async {
    _highQuality = value;

    await _preferences.setBool(
      _highQualityKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setNormalize(
      bool value,
      ) async {
    _normalize = value;

    await _preferences.setBool(
      _normalizeKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // PLAYER
  // ===========================================================================

  Future<void> setAnimatedArtwork(
      bool value,
      ) async {
    _animatedArtwork = value;

    await _preferences.setBool(
      _animatedArtworkKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setMiniPlayer(
      bool value,
      ) async {
    _miniPlayer = value;

    await _preferences.setBool(
      _miniPlayerKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setKeepScreenAwake(
      bool value,
      ) async {
    _keepScreenAwake = value;

    await _preferences.setBool(
      _keepScreenAwakeKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  Future<void> setSaveSearches(
      bool value,
      ) async {
    _saveSearches = value;

    await _preferences.setBool(
      _saveSearchesKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  Future<void> setNotifications(
      bool value,
      ) async {
    _notifications = value;

    await _preferences.setBool(
      _notificationsKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // DOWNLOADS
  // ===========================================================================

  Future<void> setWifiOnly(
      bool value,
      ) async {
    _wifiOnly = value;

    await _preferences.setBool(
      _wifiOnlyKey,
      value,
    );

    notifyListeners();
  }

  Future<void> setDownloadQuality(
      String value,
      ) async {
    _downloadQuality = value;

    await _preferences.setString(
      _downloadQualityKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // LIBRARY
  // ===========================================================================

  Future<void> setRecentLimit(
      int value,
      ) async {
    _recentLimit = value;

    await _preferences.setInt(
      _recentLimitKey,
      value,
    );

    notifyListeners();
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  Future<void> reset() async {
    await _preferences.remove(
      _themeModeKey,
    );

    await _preferences.remove(
      _accentColorKey,
    );

    await _preferences.remove(
      _crossfadeKey,
    );

    await _preferences.remove(
      _gaplessKey,
    );

    await _preferences.remove(
      _autoplayKey,
    );

    await _preferences.remove(
      _highQualityKey,
    );

    await _preferences.remove(
      _normalizeKey,
    );

    await _preferences.remove(
      _animatedArtworkKey,
    );

    await _preferences.remove(
      _miniPlayerKey,
    );

    await _preferences.remove(
      _keepScreenAwakeKey,
    );

    await _preferences.remove(
      _saveSearchesKey,
    );

    await _preferences.remove(
      _notificationsKey,
    );

    await _preferences.remove(
      _wifiOnlyKey,
    );

    await _preferences.remove(
      _downloadQualityKey,
    );

    await _preferences.remove(
      _recentLimitKey,
    );

    _themeMode = ThemeMode.system;
    _accentColor = 0xFF7C4DFF;

    _crossfade = false;
    _gapless = true;
    _autoplay = true;
    _highQuality = true;
    _normalize = false;

    _animatedArtwork = true;
    _miniPlayer = true;
    _keepScreenAwake = false;

    _saveSearches = true;
    _notifications = true;

    _wifiOnly = true;
    _downloadQuality = 'High';

    _recentLimit = 50;

    notifyListeners();
  }
}