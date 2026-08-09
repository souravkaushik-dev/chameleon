import '../models/song.dart';
import '../storage/local_storage_service.dart';

class LibraryService {
  final LocalStorageService _storage;

  final List<Song> _favorites = [];
  final List<Song> _recentlyPlayed = [];

  static const String _legacyFavoriteCleanupKey =
      'chameleon_legacy_favorite_cleanup_v1';

  LibraryService({
    LocalStorageService? storage,
  }) : _storage =
      storage ?? LocalStorageService();
  List<Song> get favorites {
    return List.unmodifiable(_favorites);
  }

  List<Song> get recentlyPlayed {
    return List.unmodifiable(_recentlyPlayed);
  }
  Future<void> initialize() async {
    final favorites =
    await _storage.loadFavorites();

    final recentlyPlayed =
    await _storage.loadRecentlyPlayed();

    _favorites
      ..clear()
      ..addAll(favorites);

    _recentlyPlayed
      ..clear()
      ..addAll(recentlyPlayed);

    // Remove the old backend-test favorite once.
    await _removeLegacyTestFavorite();
  }
  Future<void> _removeLegacyTestFavorite() async {
    final alreadyCleaned =
    await _storage.getBool(
      _legacyFavoriteCleanupKey,
    );

    if (alreadyCleaned == true) {
      return;
    }

    // Old backend test song:
    // Daft Punk - Instant Crush
    // YouTube ID: a5uQMwRMHcs
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
  bool isFavorite(String songId) {
    return _favorites.any(
          (song) => song.id == songId,
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

    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed.removeLast();
    }

    await _storage.saveRecentlyPlayed(
      _recentlyPlayed,
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
}