import 'dart:async';

import '../models/song.dart';
import '../storage/local_storage_service.dart';
import 'settings_service.dart';

class LibraryService {
  final LocalStorageService _storage;
  final SettingsService _settingsService;

  final List<Song> _favorites = [];
  final List<Song> _recentlyPlayed = [];

  static const String _legacyFavoriteCleanupKey =
      'chameleon_legacy_favorite_cleanup_v1';

  LibraryService({
    LocalStorageService? storage,
    SettingsService? settingsService,
  })  : _storage = storage ?? LocalStorageService(),
        _settingsService = settingsService ?? SettingsService() {
    _settingsService.addListener(_onSettingsChanged);
  }

  List<Song> get favorites {
    return List.unmodifiable(_favorites);
  }

  List<Song> get recentlyPlayed {
    return List.unmodifiable(_recentlyPlayed);
  }

  int get recentLimit => _settingsService.recentLimit;

  bool isFavorite(String songId) {
    return _favorites.any(
          (song) => song.id == songId,
    );
  }

  Future<void> initialize() async {
    final favorites = await _storage.loadFavorites();
    final recentlyPlayed = await _storage.loadRecentlyPlayed();

    _favorites
      ..clear()
      ..addAll(favorites);

    _recentlyPlayed
      ..clear()
      ..addAll(recentlyPlayed);

    _applyRecentLimit();
    await _removeLegacyTestFavorite();
    await _storage.saveRecentlyPlayed(
      _recentlyPlayed,
    );
  }

  Future<void> _removeLegacyTestFavorite() async {
    final alreadyCleaned = await _storage.getBool(
      _legacyFavoriteCleanupKey,
    );

    if (alreadyCleaned == true) {
      return;
    }
    _favorites.removeWhere(
          (song) => song.id == 'a5uQMwRMHcs',
    );

    await _storage.saveFavorites(
      _favorites,
    );

    await _storage.setBool(
      _legacyFavoriteCleanupKey,
      true,
    );
  }

  Future<void> toggleFavorite(
      Song song,
      ) async {
    if (isFavorite(song.id)) {
      _favorites.removeWhere(
            (item) => item.id == song.id,
      );
    } else {
      _favorites.add(song);
    }

    await _storage.saveFavorites(
      _favorites,
    );
  }

  Future<void> addToRecentlyPlayed(
      Song song,
      ) async {
    _recentlyPlayed.removeWhere(
          (item) => item.id == song.id,
    );

    _recentlyPlayed.insert(
      0,
      song,
    );

    _applyRecentLimit();

    await _storage.saveRecentlyPlayed(
      _recentlyPlayed,
    );
  }

  void _applyRecentLimit() {
    final limit = _settingsService.recentLimit.clamp(
      1,
      500,
    );

    if (_recentlyPlayed.length <= limit) {
      return;
    }

    _recentlyPlayed.removeRange(
      limit,
      _recentlyPlayed.length,
    );
  }

  void _onSettingsChanged() {
    _applyRecentLimit();
    unawaited(
      _storage.saveRecentlyPlayed(
        _recentlyPlayed,
      ),
    );
  }

  Future<void> clearFavorites() async {
    _favorites.clear();

    await _storage.clearFavorites();
  }

  Future<void> clearRecentlyPlayed() async {
    _recentlyPlayed.clear();

    await _storage.clearRecentlyPlayed();
  }

  Future<void> dispose() async {
    _settingsService.removeListener(_onSettingsChanged);
  }
}
