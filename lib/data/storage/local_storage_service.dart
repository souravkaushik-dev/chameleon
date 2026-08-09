import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

class LocalStorageService {
  static const String _favoritesKey = 'chameleon_favorites';

  static const String _recentlyPlayedKey =
      'chameleon_recently_played';

  final SharedPreferencesAsync _preferences;

  LocalStorageService({
    SharedPreferencesAsync? preferences,
  }) : _preferences =
      preferences ?? SharedPreferencesAsync();

  Future<void> saveFavorites(List<Song> songs) async {
    await _saveSongs(_favoritesKey, songs);
  }

  Future<List<Song>> loadFavorites() async {
    return _loadSongs(_favoritesKey);
  }

  Future<void> saveRecentlyPlayed(List<Song> songs) async {
    await _saveSongs(_recentlyPlayedKey, songs);
  }

  Future<List<Song>> loadRecentlyPlayed() async {
    return _loadSongs(_recentlyPlayedKey);
  }

  Future<void> clearFavorites() async {
    await _preferences.remove(_favoritesKey);
  }

  Future<void> clearRecentlyPlayed() async {
    await _preferences.remove(_recentlyPlayedKey);
  }

  Future<void> _saveSongs(
      String key,
      List<Song> songs,
      ) async {
    final encoded = songs
        .map(_songToJson)
        .map(jsonEncode)
        .toList();

    await _preferences.setStringList(
      key,
      encoded,
    );
  }

  Future<List<Song>> _loadSongs(String key) async {
    final encoded = await _preferences.getStringList(key);

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    final songs = <Song>[];

    for (final item in encoded) {
      try {
        final json = jsonDecode(item);

        if (json is Map<String, dynamic>) {
          songs.add(_songFromJson(json));
        }
      } catch (_) {
        // Ignore corrupted entries.
      }
    }

    return songs;
  }

  Map<String, dynamic> _songToJson(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'thumbnailUrl': song.thumbnailUrl,
      'durationMs': song.duration?.inMilliseconds,
      'youtubeUrl': song.youtubeUrl,

      // Do NOT persist streamUrl.
      //
      // YouTube stream URLs can expire.
      'streamUrl': null,
    };
  }

  Song _songFromJson(Map<String, dynamic> json) {
    final durationMs = json['durationMs'];

    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: durationMs is int
          ? Duration(milliseconds: durationMs)
          : null,
      youtubeUrl: json['youtubeUrl'] as String?,
    );
  }
}