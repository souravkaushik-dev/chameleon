import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistService {
  static const String _playlistsKey =
      'chameleon_playlists';
  static const String _legacyCleanupKey =
      'chameleon_legacy_test_cleanup_v1';

  final SharedPreferencesAsync _preferences;

  final List<Playlist> _playlists = [];

  PlaylistService({
    SharedPreferencesAsync? preferences,
  }) : _preferences =
      preferences ?? SharedPreferencesAsync();
  List<Playlist> get playlists {
    return List.unmodifiable(_playlists);
  }
  Future<void> initialize() async {
    final stored =
    await _preferences.getStringList(
      _playlistsKey,
    );

    _playlists.clear();

    if (stored == null || stored.isEmpty) {
      return;
    }

    for (final item in stored) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is! Map) {
          continue;
        }

        final json =
        Map<String, dynamic>.from(decoded);

        final playlist =
        _playlistFromJson(json);
        if (playlist.id.trim().isEmpty) {
          continue;
        }

        if (playlist.name.trim().isEmpty) {
          continue;
        }

        _playlists.add(playlist);
      } catch (_) {
      }
    }
    await _removeLegacyTestPlaylists();
  }
  Future<void> _removeLegacyTestPlaylists() async {
    final alreadyCleaned =
    await _preferences.getBool(
      _legacyCleanupKey,
    );

    if (alreadyCleaned == true) {
      return;
    }
    _playlists.removeWhere(
          (playlist) =>
      playlist.name.trim().toLowerCase() ==
          'chameleon test',
    );

    await _save();

    await _preferences.setBool(
      _legacyCleanupKey,
      true,
    );
  }
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return null;
    }

    final playlist = Playlist(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      name: trimmedName,
      description:
      description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    );

    _playlists.add(playlist);

    await _save();

    return playlist;
  }
  Future<void> deletePlaylist(
      String playlistId,
      ) async {
    final before = _playlists.length;

    _playlists.removeWhere(
          (playlist) =>
      playlist.id == playlistId,
    );

    if (_playlists.length == before) {
      return;
    }

    await _save();
  }
  Playlist? getPlaylist(
      String playlistId,
      ) {
    for (final playlist in _playlists) {
      if (playlist.id == playlistId) {
        return playlist;
      }
    }

    return null;
  }
  Future<void> addSong(
      String playlistId,
      Song song,
      ) async {
    final index =
    _playlists.indexWhere(
          (playlist) =>
      playlist.id == playlistId,
    );

    if (index == -1) {
      return;
    }

    final playlist = _playlists[index];

    final exists = playlist.songs.any(
          (item) => item.id == song.id,
    );

    if (exists) {
      return;
    }

    _playlists[index] =
        playlist.copyWith(
          songs: [
            ...playlist.songs,
            song,
          ],
        );

    await _save();
  }
  Future<void> addSongs(
      String playlistId,
      List<Song> songs,
      ) async {
    final index =
    _playlists.indexWhere(
          (playlist) =>
      playlist.id == playlistId,
    );

    if (index == -1 ||
        songs.isEmpty) {
      return;
    }

    final playlist = _playlists[index];

    final existingIds = playlist.songs
        .map((song) => song.id)
        .toSet();

    final newSongs = <Song>[];

    for (final song in songs) {
      if (existingIds.add(song.id)) {
        newSongs.add(song);
      }
    }

    if (newSongs.isEmpty) {
      return;
    }

    _playlists[index] =
        playlist.copyWith(
          songs: [
            ...playlist.songs,
            ...newSongs,
          ],
        );

    await _save();
  }
  Future<void> removeSong(
      String playlistId,
      String songId,
      ) async {
    final index =
    _playlists.indexWhere(
          (playlist) =>
      playlist.id == playlistId,
    );

    if (index == -1) {
      return;
    }

    final playlist = _playlists[index];

    final updatedSongs =
    playlist.songs
        .where(
          (song) =>
      song.id != songId,
    )
        .toList();

    if (updatedSongs.length ==
        playlist.songs.length) {
      return;
    }

    _playlists[index] =
        playlist.copyWith(
          songs: updatedSongs,
        );

    await _save();
  }
  Future<void> renamePlaylist(
      String playlistId,
      String name,
      ) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    final index =
    _playlists.indexWhere(
          (playlist) =>
      playlist.id == playlistId,
    );

    if (index == -1) {
      return;
    }

    _playlists[index] =
        _playlists[index].copyWith(
          name: trimmedName,
        );

    await _save();
  }
  Future<void> clear() async {
    _playlists.clear();

    await _preferences.remove(
      _playlistsKey,
    );
  }
  Future<void> _save() async {
    final encoded = _playlists
        .map(_playlistToJson)
        .map(jsonEncode)
        .toList();

    await _preferences.setStringList(
      _playlistsKey,
      encoded,
    );
  }
  Map<String, dynamic> _playlistToJson(
      Playlist playlist,
      ) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'description':
      playlist.description,
      'artworkUrl':
      playlist.artworkUrl,
      'songs': playlist.songs
          .map(_songToJson)
          .toList(),
    };
  }
  Playlist _playlistFromJson(
      Map<String, dynamic> json,
      ) {
    final songs = <Song>[];

    final storedSongs =
    json['songs'];

    if (storedSongs is List) {
      for (final item in storedSongs) {
        if (item is! Map) {
          continue;
        }

        try {
          final songJson =
          Map<String, dynamic>.from(
            item,
          );

          final song =
          _songFromJson(songJson);

          if (song.id.isEmpty) {
            continue;
          }

          songs.add(song);
        } catch (_) {
        }
      }
    }

    return Playlist(
      id: json['id']?.toString() ?? '',
      name:
      json['name']?.toString() ??
          'Untitled playlist',
      description:
      json['description']
          ?.toString(),
      artworkUrl:
      json['artworkUrl']
          ?.toString(),
      songs: songs,
    );
  }
  Map<String, dynamic> _songToJson(
      Song song,
      ) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'thumbnailUrl':
      song.thumbnailUrl,
      'durationMs':
      song.duration?.inMilliseconds,
      'youtubeUrl':
      song.youtubeUrl,
      'streamUrl': null,
    };
  }
  Song _songFromJson(
      Map<String, dynamic> json,
      ) {
    final durationMs =
    json['durationMs'];

    return Song(
      id:
      json['id']?.toString() ?? '',
      title:
      json['title']?.toString() ??
          'Unknown title',
      artist:
      json['artist']?.toString() ??
          'Unknown artist',
      album:
      json['album']?.toString(),
      thumbnailUrl:
      json['thumbnailUrl']
          ?.toString(),
      duration: durationMs is num
          ? Duration(
        milliseconds:
        durationMs.toInt(),
      )
          : null,
      youtubeUrl:
      json['youtubeUrl']
          ?.toString(),
    );
  }
}