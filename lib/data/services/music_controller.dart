import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/playback_state.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'audio_handler.dart';
import 'audio_player_service.dart';
import 'library_service.dart';
import 'playlist_service.dart';
import 'queue_service.dart';
import 'youtube_service.dart';

class MusicController extends ChangeNotifier {
  final YoutubeService _youtubeService;
  final AudioPlayerService _audioPlayerService;
  final QueueService _queueService;
  final LibraryService _libraryService;
  final PlaylistService _playlistService;

  ChameleonAudioHandler? _audioHandler;

  MusicController({
    YoutubeService? youtubeService,
    AudioPlayerService? audioPlayerService,
    QueueService? queueService,
    LibraryService? libraryService,
    PlaylistService? playlistService,
  })  : _youtubeService =
      youtubeService ?? YoutubeService(),
        _audioPlayerService =
            audioPlayerService ?? AudioPlayerService(),
        _queueService =
            queueService ?? QueueService(),
        _libraryService =
            libraryService ?? LibraryService(),
        _playlistService =
            playlistService ?? PlaylistService() {
    _bindPlayerStreams();
  }

  AudioPlayerService get audioPlayerService =>
      _audioPlayerService;

  PlaybackState _playbackState =
  const PlaybackState();
  List<Song> _searchResults = [];

  bool _isSearching = false;
  List<Song> _trendingSongs = [];

  List<Song> _suggestedSongs = [];

  List<String> _trendingArtists = [];

  bool _isHomeLoading = false;

  DateTime? _homeLastUpdated;

  Future<void>? _homeRefreshOperation;
  bool _isInitialized = false;

  bool _isInitializing = false;

  String? _errorMessage;
  int _playRequestId = 0;
  final Map<String, _CachedStream> _resolvedSongs = {};

  static const Duration _streamCacheDuration =
  Duration(minutes: 5);
  final Map<String, Future<Song>> _preloadTasks = {};

  static const int _defaultPreloadCount = 3;
  StreamSubscription<bool>? _playingSubscription;

  StreamSubscription<Duration>? _positionSubscription;

  StreamSubscription<Duration?>? _durationSubscription;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  PlaybackState get playbackState {
    return _playbackState;
  }

  List<Song> get searchResults {
    return List.unmodifiable(
      _searchResults,
    );
  }

  List<Song> get trendingSongs {
    return List.unmodifiable(
      _trendingSongs,
    );
  }

  List<Song> get suggestedSongs {
    return List.unmodifiable(
      _suggestedSongs,
    );
  }

  List<String> get trendingArtists {
    return List.unmodifiable(
      _trendingArtists,
    );
  }

  List<Song> get queue {
    return List.unmodifiable(
      _queueService.queue,
    );
  }

  List<Song> get upcomingQueue {
    return _queueService.upcoming;
  }

  List<Song> get favorites {
    return List.unmodifiable(
      _libraryService.favorites,
    );
  }

  List<Song> get recentlyPlayed {
    return List.unmodifiable(
      _libraryService.recentlyPlayed,
    );
  }

  List<Playlist> get playlists {
    return List.unmodifiable(
      _playlistService.playlists,
    );
  }

  Song? get currentSong {
    return _queueService.currentSong;
  }

  bool get isSearching {
    return _isSearching;
  }

  bool get isHomeLoading {
    return _isHomeLoading;
  }

  DateTime? get homeLastUpdated {
    return _homeLastUpdated;
  }

  bool get isInitialized {
    return _isInitialized;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get hasNext {
    return _queueService.hasNext;
  }

  bool get hasPrevious {
    return _queueService.hasPrevious;
  }

  bool isFavorite(
      Song song,
      ) {
    return _libraryService.isFavorite(
      song.id,
    );
  }
  String _streamCacheKey(
      String songId,
      ) {
    if (kIsWeb) {
      return '${songId}_web';
    }

    if (Platform.isIOS) {
      return '${songId}_ios';
    }

    if (Platform.isAndroid) {
      return '${songId}_android';
    }

    if (Platform.isMacOS) {
      return '${songId}_macos';
    }

    return '${songId}_other';
  }
  void attachAudioHandler(
      ChameleonAudioHandler handler,
      ) {
    _audioHandler = handler;

    handler.onNext = next;
    handler.onPrevious = previous;

    final current = currentSong;

    if (current != null) {
      handler.updateSong(
        current,
      );
    }
  }
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (_isInitializing) {
      return;
    }

    _isInitializing = true;

    _errorMessage = null;

    notifyListeners();

    try {
      await Future.wait([
        _libraryService.initialize(),
        _playlistService.initialize(),
      ]);

      await refreshHome();

      _isInitialized = true;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isInitializing = false;

      notifyListeners();
    }
  }
  Future<void> refreshHome() async {
    final runningOperation =
        _homeRefreshOperation;

    if (runningOperation != null) {
      return runningOperation;
    }

    final operation =
    _performHomeRefresh();

    _homeRefreshOperation =
        operation;

    try {
      await operation;
    } finally {
      if (identical(
        _homeRefreshOperation,
        operation,
      )) {
        _homeRefreshOperation = null;
      }
    }
  }
  Future<void> _performHomeRefresh() async {
    _isHomeLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      const queries = <String>[
        'trending music',
        'trending songs',
        'popular songs',
        'new music',
        'viral songs',
      ];

      final batches = <List<Song>>[];

      for (final query in queries) {
        try {
          final results =
          await _youtubeService.search(
            query,
            limit: 20,
          );

          batches.add(
            results,
          );
        } catch (_) {
          // Ignore individual discovery failures.
        }
      }
      final songs = <Song>[];

      final seenIds = <String>{};

      for (final batch in batches) {
        for (final song in batch) {
          final id = song.id.trim();

          if (id.isEmpty) {
            continue;
          }

          if (!seenIds.add(id)) {
            continue;
          }

          songs.add(song);
        }
      }
      _trendingSongs =
          songs.take(40).toList();
      final artists = <String>[];

      final seenArtists = <String>{};

      for (final song in _trendingSongs) {
        final artist =
        song.artist.trim();

        if (artist.isEmpty) {
          continue;
        }

        final key =
        artist.toLowerCase();

        if (!seenArtists.add(key)) {
          continue;
        }

        artists.add(artist);

        if (artists.length >= 20) {
          break;
        }
      }

      _trendingArtists = artists;
      await _loadSuggestedSongs(
        _trendingSongs,
      );

      _homeLastUpdated =
          DateTime.now();
      unawaited(
        preloadSongs(
          _trendingSongs,
          count: _defaultPreloadCount,
        ),
      );

      unawaited(
        preloadSongs(
          _suggestedSongs,
          count: _defaultPreloadCount,
        ),
      );
    } catch (error) {
      _errorMessage =
          error.toString();
    } finally {
      _isHomeLoading = false;

      notifyListeners();
    }
  }
  String _normalizeTitle(
      String value,
      ) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'\(official.*?\)',
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'\[official.*?\]',
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'\(lyrics?.*?\)',
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'\[lyrics?.*?\]',
      ),
      '',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }
  List<Song> _removeDuplicateTitles(
      List<Song> songs,
      ) {
    final result = <Song>[];

    final seenTitles = <String>{};

    for (final song in songs) {
      final normalizedTitle =
      _normalizeTitle(
        song.title,
      );

      if (normalizedTitle.isEmpty) {
        continue;
      }

      if (!seenTitles.add(
        normalizedTitle,
      )) {
        continue;
      }

      result.add(song);
    }

    return result;
  }
  List<String> _extractArtists(
      List<Song> songs,
      ) {
    final artists = <String>[];

    final seen = <String>{};

    for (final song in songs) {
      final artist =
      song.artist.trim();

      if (artist.isEmpty) {
        continue;
      }

      final key =
      artist.toLowerCase();

      if (!seen.add(key)) {
        continue;
      }

      artists.add(artist);

      if (artists.length >= 30) {
        break;
      }
    }

    return artists;
  }
  Future<void> _loadSuggestedSongs(
      List<Song> trending,
      ) async {
    if (trending.isEmpty) {
      _suggestedSongs = [];
      return;
    }

    final suggestions = <Song>[];

    final seenIds = <String>{};

    final trendingIds =
    trending.map(
          (song) => song.id,
    ).toSet();

    final artists =
    _extractArtists(
      trending,
    ).take(8).toList();

    if (artists.isNotEmpty) {
      final artistBatches =
      await Future.wait(
        artists.map(
              (artist) =>
              _youtubeService.search(
                '$artist official songs',
                limit: 12,
              ),
        ),
      );

      for (final batch
      in artistBatches) {
        for (final song in batch) {
          if (song.id.isEmpty) {
            continue;
          }

          if (trendingIds.contains(
            song.id,
          )) {
            continue;
          }

          if (!seenIds.add(
            song.id,
          )) {
            continue;
          }

          suggestions.add(song);

          if (suggestions.length >= 30) {
            break;
          }
        }

        if (suggestions.length >= 30) {
          break;
        }
      }
    }

    if (suggestions.length < 24) {
      for (final song
      in trending.skip(10)) {
        if (seenIds.add(song.id)) {
          suggestions.add(song);
        }

        if (suggestions.length >= 30) {
          break;
        }
      }
    }

    final currentId =
        currentSong?.id;

    if (currentId != null) {
      suggestions.removeWhere(
            (song) =>
        song.id == currentId,
      );
    }

    _suggestedSongs =
        _removeDuplicateTitles(
          suggestions,
        ).take(30).toList();
  }
  Future<void> refreshLibrary() async {
    try {
      _errorMessage = null;

      await Future.wait([
        _libraryService.initialize(),
        _playlistService.initialize(),
      ]);

      await refreshHome();

      notifyListeners();
    } catch (error) {
      _errorMessage =
          error.toString();

      notifyListeners();
    }
  }
  void _bindPlayerStreams() {
    _playingSubscription =
        _audioPlayerService.playingStream.listen(
              (isPlaying) {
            _updatePlayback(
              isPlaying: isPlaying,
              status: isPlaying
                  ? PlaybackStatus.playing
                  : PlaybackStatus.paused,
            );
          },
        );

    _positionSubscription =
        _audioPlayerService.positionStream.listen(
              (position) {
            _updatePlayback(
              position: position,
            );
          },
        );

    _durationSubscription =
        _audioPlayerService.durationStream.listen(
              (duration) {
            if (duration == null ||
                duration <= Duration.zero) {
              return;
            }

            debugPrint(
              '🎵 CONTROLLER DURATION: $duration',
            );

            _updatePlayback(
              duration: duration,
            );
          },
        );

    _playerStateSubscription =
        _audioPlayerService.playerStateStream.listen(
              (state) {
            switch (
            state.processingState) {
              case ProcessingState.idle:
                _updatePlayback(
                  status: PlaybackStatus.idle,
                );
                break;

              case ProcessingState.loading:
                _updatePlayback(
                  status:
                  PlaybackStatus.loading,
                );
                break;

              case ProcessingState.buffering:
                _updatePlayback(
                  status:
                  PlaybackStatus.buffering,
                );
                break;

              case ProcessingState.ready:
                _updatePlayback(
                  status: state.playing
                      ? PlaybackStatus.playing
                      : PlaybackStatus.paused,
                );
                break;

              case ProcessingState.completed:
                _handleTrackCompleted();
                break;
            }
          },
        );
  }
  Future<void> _handleTrackCompleted() async {
    _updatePlayback(
      status: PlaybackStatus.completed,
      isPlaying: false,
    );

    if (!hasNext) {
      return;
    }

    try {
      await next();
    } catch (error) {
      _errorMessage =
          error.toString();

      _updatePlayback(
        status: PlaybackStatus.error,
        isPlaying: false,
      );
    }
  }
  void _updatePlayback({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    Song? currentSong,
  }) {
    _playbackState =
        _playbackState.copyWith(
          status: status,
          position: position,
          duration: duration,
          isPlaying: isPlaying,
          currentSong: currentSong,
        );

    notifyListeners();
  }
  Future<void> search(
      String query,
      ) async {
    final trimmedQuery =
    query.trim();

    if (trimmedQuery.isEmpty) {
      _searchResults = [];
      _errorMessage = null;

      notifyListeners();

      return;
    }

    _isSearching = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final results =
      await _youtubeService.search(
        trimmedQuery,
        limit: 40,
      );

      _searchResults =
          _deduplicate(results);

      unawaited(
        preloadSongs(
          _searchResults,
          count: _defaultPreloadCount,
        ),
      );
    } catch (error) {
      _searchResults = [];

      _errorMessage =
          error.toString();
    } finally {
      _isSearching = false;

      notifyListeners();
    }
  }
  void clearSearch() {
    _searchResults = [];

    _errorMessage = null;

    notifyListeners();
  }
  List<Song> _deduplicate(
      List<Song> songs,
      ) {
    final result = <Song>[];

    final ids = <String>{};

    for (final song in songs) {
      final id = song.id.trim();

      if (id.isEmpty) {
        continue;
      }

      if (!ids.add(id)) {
        continue;
      }

      result.add(song);
    }

    return result;
  }
  Future<Song> resolveSong(
      Song song,
      ) async {
    final existingUrl =
    song.streamUrl?.trim();

    if (existingUrl != null &&
        existingUrl.isNotEmpty) {
      return song;
    }

    final cacheKey =
    _streamCacheKey(
      song.id,
    );
    final cached =
    _resolvedSongs[cacheKey];

    if (cached != null &&
        cached.isValid) {
      return song.copyWith(
        streamUrl: cached.url,
      );
    }

    if (cached != null) {
      _resolvedSongs.remove(
        cacheKey,
      );
    }
    final existingTask =
    _preloadTasks[cacheKey];

    if (existingTask != null) {
      return existingTask;
    }
    final task =
    _resolveFreshSong(song);

    _preloadTasks[cacheKey] =
        task;

    try {
      final resolved =
      await task;

      final resolvedUrl =
      resolved.streamUrl?.trim();

      if (resolvedUrl == null ||
          resolvedUrl.isEmpty) {
        throw Exception(
          'Unable to resolve audio stream.',
        );
      }

      _resolvedSongs[cacheKey] =
          _CachedStream(
            url: resolvedUrl,
            createdAt: DateTime.now(),
          );

      return resolved;
    } finally {
      if (identical(
        _preloadTasks[cacheKey],
        task,
      )) {
        _preloadTasks.remove(
          cacheKey,
        );
      }
    }
  }
  Future<Song> _resolveFreshSong(
      Song song,
      ) async {
    final streamUrl =
    await _youtubeService
        .getAudioStreamUrl(
      song.id,
    );

    final trimmedUrl =
    streamUrl.trim();

    if (trimmedUrl.isEmpty) {
      throw Exception(
        'Unable to resolve audio stream.',
      );
    }

    return song.copyWith(
      streamUrl: trimmedUrl,
    );
  }
  Future<void> preloadSongs(
      List<Song> songs, {
        int count =
            _defaultPreloadCount,
      }) async {
    if (songs.isEmpty ||
        count <= 0) {
      return;
    }

    final uniqueSongs =
    <String, Song>{};

    for (final song in songs) {
      final id = song.id.trim();

      if (id.isEmpty) {
        continue;
      }

      if (uniqueSongs.containsKey(id)) {
        continue;
      }

      uniqueSongs[id] = song;

      if (uniqueSongs.length >= count) {
        break;
      }
    }

    if (uniqueSongs.isEmpty) {
      return;
    }

    await Future.wait(
      uniqueSongs.values.map(
            (song) async {
          try {
            await resolveSong(song);
          } catch (_) {
            // Preload is best-effort.
          }
        },
      ),
    );
  }
  void _preloadNextSong() {
    final current =
        _queueService.currentSong;

    if (current == null) {
      return;
    }

    final songs =
        _queueService.queue;

    final index =
    songs.indexWhere(
          (song) =>
      song.id == current.id,
    );

    if (index < 0 ||
        index + 1 >= songs.length) {
      return;
    }

    unawaited(
      preloadSongs(
        [
          songs[index + 1],
        ],
        count: 1,
      ),
    );
  }
  void _invalidateStream(
      String songId,
      ) {
    _resolvedSongs.remove(
      _streamCacheKey(songId),
    );
  }
  Future<void> playSong(
      Song song, {
        List<Song>? sourceQueue,
      }) async {
    final requestId =
    ++_playRequestId;

    _errorMessage = null;

    _updatePlayback(
      currentSong: song,
      status: PlaybackStatus.loading,
      position: Duration.zero,
      isPlaying: false,
    );

    try {
      if (sourceQueue != null &&
          sourceQueue.isNotEmpty) {
        final index =
        sourceQueue.indexWhere(
              (item) =>
          item.id == song.id,
        );

        _queueService.setQueue(
          sourceQueue,
          startIndex:
          index >= 0
              ? index
              : 0,
        );
      } else {
        final current =
            _queueService.currentSong;

        if (current == null ||
            current.id != song.id) {
          _queueService.setQueue(
            [song],
            startIndex: 0,
          );
        }
      }

      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }
      Song resolvedSong;

      try {
        resolvedSong =
        await resolveSong(
          song,
        );
      } catch (_) {
        _invalidateStream(
          song.id,
        );

        if (!_isCurrentRequest(
          requestId,
        )) {
          return;
        }

        resolvedSong =
        await _resolveFreshSong(
          song,
        );
      }

      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }
      _queueService.replaceCurrent(
        resolvedSong,
      );

      _audioHandler?.updateSong(
        resolvedSong,
      );

      _updatePlayback(
        currentSong: resolvedSong,
        status: PlaybackStatus.loading,
      );
      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      try {
        await _audioPlayerService
            .playSong(
          resolvedSong,
        );
      } catch (error) {
        if (!_isCurrentRequest(
          requestId,
        )) {
          return;
        }

        debugPrint(
          '🔴 PLAYBACK FAILED: $error',
        );

        _invalidateStream(
          resolvedSong.id,
        );

        final freshSong =
        await _resolveFreshSong(
          song,
        );

        if (!_isCurrentRequest(
          requestId,
        )) {
          return;
        }

        final freshUrl =
        freshSong.streamUrl?.trim();

        if (freshUrl == null ||
            freshUrl.isEmpty) {
          throw Exception(
            'Unable to resolve a playable audio stream.',
          );
        }

        _resolvedSongs[
        _streamCacheKey(
          song.id,
        )] = _CachedStream(
          url: freshUrl,
          createdAt: DateTime.now(),
        );

        _queueService.replaceCurrent(
          freshSong,
        );

        _audioHandler?.updateSong(
          freshSong,
        );

        await _audioPlayerService
            .playSong(
          freshSong,
        );

        resolvedSong =
            freshSong;
      }

      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }
      unawaited(
        _libraryService
            .addToRecentlyPlayed(
          resolvedSong,
        ),
      );
      _updatePlayback(
        currentSong: resolvedSong,
        status: PlaybackStatus.playing,
        isPlaying: true,
      );
      //_preloadNextSong();
    } catch (error) {
      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      _errorMessage =
          error.toString();

      _updatePlayback(
        status: PlaybackStatus.error,
        isPlaying: false,
      );

      rethrow;
    }
  }
  bool _isCurrentRequest(
      int requestId,
      ) {
    return requestId ==
        _playRequestId;
  }
  Future<void> play() async {
    await _audioPlayerService.play();
  }
  Future<void> pause() async {
    await _audioPlayerService.pause();
  }
  Future<void> togglePlayPause() async {
    if (_playbackState.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
  Future<void> seek(
      Duration position,
      ) async {
    await _audioPlayerService.seek(
      position,
    );
  }
  Future<void> next() async {
    final song =
    _queueService.next();

    if (song == null) {
      return;
    }

    await playSong(
      song,
      sourceQueue:
      _queueService.queue,
    );
  }
  Future<void> previous() async {
    final song =
    _queueService.previous();

    if (song == null) {
      await seek(
        Duration.zero,
      );

      return;
    }

    await playSong(
      song,
      sourceQueue:
      _queueService.queue,
    );
  }
  void setQueue(
      List<Song> songs, {
        int startIndex = 0,
      }) {
    if (songs.isEmpty) {
      _queueService.clear();

      notifyListeners();

      return;
    }

    final safeIndex =
    startIndex.clamp(
      0,
      songs.length - 1,
    );

    _queueService.setQueue(
      songs,
      startIndex: safeIndex,
    );

    notifyListeners();
  }
  void addToQueue(
      Song song,
      ) {
    _queueService.add(
      song,
    );

    notifyListeners();
  }
  void addAllToQueue(
      List<Song> songs,
      ) {
    if (songs.isEmpty) {
      return;
    }

    _queueService.addAll(
      songs,
    );

    notifyListeners();
  }
  void removeFromQueue(
      int index,
      ) {
    _queueService.removeAt(
      index,
    );

    notifyListeners();
  }
  void clearQueue() {
    _queueService.clear();

    notifyListeners();
  }
  Future<void> toggleFavorite(
      Song song,
      ) async {
    await _libraryService
        .toggleFavorite(
      song,
    );

    notifyListeners();
  }
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
  }) async {
    final trimmed =
    name.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    await _playlistService
        .createPlaylist(
      name: trimmed,
      description: description,
    );

    await _playlistService
        .initialize();

    Playlist? createdPlaylist;

    for (final playlist
    in _playlistService
        .playlists
        .reversed) {
      if (playlist.name ==
          trimmed) {
        createdPlaylist =
            playlist;
        break;
      }
    }

    notifyListeners();

    return createdPlaylist;
  }
  Future<void> deletePlaylist(
      String playlistId,
      ) async {
    await _playlistService
        .deletePlaylist(
      playlistId,
    );

    notifyListeners();
  }
  Future<void> renamePlaylist(
      String playlistId,
      String name,
      ) async {
    final trimmedName =
    name.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    await _playlistService
        .renamePlaylist(
      playlistId,
      trimmedName,
    );

    notifyListeners();
  }
  Future<void> addToPlaylist(
      String playlistId,
      Song song,
      ) async {
    await _playlistService
        .addSong(
      playlistId,
      song,
    );

    notifyListeners();
  }
  Future<void> removeFromPlaylist(
      String playlistId,
      String songId,
      ) async {
    await _playlistService
        .removeSong(
      playlistId,
      songId,
    );

    notifyListeners();
  }
  Playlist? getPlaylist(
      String playlistId,
      ) {
    return _playlistService
        .getPlaylist(
      playlistId,
    );
  }
  Future<void> stop() async {
    _playRequestId++;

    // Cancel outstanding preload/resolution work for the current song.
    _invalidateStream(
      currentSong?.id ?? '',
    );

    await _audioPlayerService.stop();

    _updatePlayback(
      status: PlaybackStatus.idle,
      isPlaying: false,
      position: Duration.zero,
    );
  }
  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }
  Future<void> disposeController() async {
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();

    _resolvedSongs.clear();
    _preloadTasks.clear();

    await _audioPlayerService.dispose();

    _youtubeService.dispose();

    super.dispose();
  }
  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _resolvedSongs.clear();
    _preloadTasks.clear();

    _youtubeService.dispose();

    super.dispose();
  }
}
class _CachedStream {
  final String url;

  final DateTime createdAt;

  const _CachedStream({
    required this.url,
    required this.createdAt,
  });

  bool get isValid {
    return DateTime.now()
        .difference(createdAt) <
        const Duration(
          minutes: 5,
        );
  }
}