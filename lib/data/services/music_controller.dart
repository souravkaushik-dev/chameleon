import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/playback_state.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'audio_player_service.dart';
import 'library_service.dart';
import 'playlist_service.dart';
import 'queue_service.dart';
import 'youtube_service.dart';

class MusicController extends ChangeNotifier {
  // ===========================================================================
  // SERVICES
  // ===========================================================================

  final YoutubeService _youtubeService;
  final AudioPlayerService _audioPlayerService;
  final QueueService _queueService;
  final LibraryService _libraryService;
  final PlaylistService _playlistService;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

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

  // ===========================================================================
  // PLAYBACK
  // ===========================================================================

  PlaybackState _playbackState =
  const PlaybackState();

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  List<Song> _searchResults = [];

  bool _isSearching = false;

  // ===========================================================================
  // HOME DISCOVERY
  // ===========================================================================

  List<Song> _trendingSongs = [];

  List<Song> _suggestedSongs = [];

  List<String> _trendingArtists = [];

  bool _isHomeLoading = false;

  DateTime? _homeLastUpdated;

  Future<void>? _homeRefreshOperation;

  // ===========================================================================
  // GENERAL STATE
  // ===========================================================================

  bool _isInitialized = false;

  bool _isInitializing = false;

  String? _errorMessage;

  // ===========================================================================
  // PLAYER STREAMS
  // ===========================================================================

  StreamSubscription<bool>? _playingSubscription;

  StreamSubscription<Duration>? _positionSubscription;

  StreamSubscription<Duration?>? _durationSubscription;

  StreamSubscription<PlayerState>? _playerStateSubscription;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  PlaybackState get playbackState {
    return _playbackState;
  }

  List<Song> get searchResults {
    return List.unmodifiable(_searchResults);
  }

  List<Song> get trendingSongs {
    return List.unmodifiable(_trendingSongs);
  }

  List<Song> get suggestedSongs {
    return List.unmodifiable(_suggestedSongs);
  }

  List<String> get trendingArtists {
    return List.unmodifiable(_trendingArtists);
  }

  List<Song> get queue {
    return List.unmodifiable(
      _queueService.queue,
    );
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

  bool isFavorite(Song song) {
    return _libraryService.isFavorite(
      song.id,
    );
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

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

  // ===========================================================================
  // HOME REFRESH
  // ===========================================================================

  Future<void> refreshHome() async {
    final runningOperation =
        _homeRefreshOperation;

    if (runningOperation != null) {
      return runningOperation;
    }

    final operation =
    _performHomeRefresh();

    _homeRefreshOperation = operation;

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

  // ===========================================================================
  // PERFORM HOME REFRESH
  // ===========================================================================

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

          batches.add(results);
        } catch (_) {
          // Ignore an individual failed
          // discovery query.
        }
      }

      // -----------------------------------------------------------------------
      // MERGE RESULTS
      // -----------------------------------------------------------------------

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

      // -----------------------------------------------------------------------
      // TRENDING
      // -----------------------------------------------------------------------

      _trendingSongs =
          songs.take(40).toList();

      // -----------------------------------------------------------------------
      // ARTISTS
      // -----------------------------------------------------------------------

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

      // -----------------------------------------------------------------------
      // SUGGESTIONS
      // -----------------------------------------------------------------------

      await _loadSuggestedSongs(
        _trendingSongs,
      );

      _homeLastUpdated =
          DateTime.now();
    } catch (error) {
      _errorMessage =
          error.toString();
    } finally {
      _isHomeLoading = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // REMOVE DUPLICATE TITLES
  // ===========================================================================

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

  // ===========================================================================
  // NORMALIZE TITLE
  // ===========================================================================

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
      RegExp(
        r'\s+',
      ),
      ' ',
    )
        .trim();
  }

  // ===========================================================================
  // ARTIST EXTRACTION
  // ===========================================================================

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

  // ===========================================================================
  // SUGGESTIONS
  // ===========================================================================

  Future<void> _loadSuggestedSongs(
      List<Song> trending,
      ) async {
    if (trending.isEmpty) {
      _suggestedSongs = [];
      return;
    }

    final suggestions = <Song>[];

    final seenIds = <String>{};

    final trendingIds = trending
        .map(
          (song) => song.id,
    )
        .toSet();

    // -------------------------------------------------------------------------
    // SEARCH MULTIPLE TRENDING ARTISTS
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // FALLBACK TO TRENDING RESULTS
    // -------------------------------------------------------------------------

    if (suggestions.length < 24) {
      for (final song
      in trending.skip(10)) {
        if (seenIds.add(
          song.id,
        )) {
          suggestions.add(song);
        }

        if (suggestions.length >= 30) {
          break;
        }
      }
    }

    // -------------------------------------------------------------------------
    // DON'T RECOMMEND CURRENT SONG
    // -------------------------------------------------------------------------

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

  // ===========================================================================
  // LIBRARY REFRESH
  // ===========================================================================

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

  // ===========================================================================
  // PLAYER STREAMS
  // ===========================================================================

  void _bindPlayerStreams() {
    _playingSubscription =
        _audioPlayerService
            .playingStream
            .listen(
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
        _audioPlayerService
            .positionStream
            .listen(
              (position) {
            _updatePlayback(
              position: position,
            );
          },
        );

    _durationSubscription =
        _audioPlayerService
            .durationStream
            .listen(
              (duration) {
            _updatePlayback(
              duration:
              duration ?? Duration.zero,
            );
          },
        );

    _playerStateSubscription =
        _audioPlayerService
            .playerStateStream
            .listen(
              (state) {
            switch (
            state.processingState) {
              case ProcessingState.idle:
                _updatePlayback(
                  status:
                  PlaybackStatus.idle,
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

  // ===========================================================================
  // COMPLETED
  // ===========================================================================

  Future<void> _handleTrackCompleted() async {
    _updatePlayback(
      status:
      PlaybackStatus.completed,
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
        status:
        PlaybackStatus.error,
        isPlaying: false,
      );
    }
  }

  // ===========================================================================
  // PLAYBACK STATE
  // ===========================================================================

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

  // ===========================================================================
  // SEARCH
  // ===========================================================================

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
    } catch (error) {
      _searchResults = [];
      _errorMessage =
          error.toString();
    } finally {
      _isSearching = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // CLEAR SEARCH
  // ===========================================================================

  void clearSearch() {
    _searchResults = [];
    _errorMessage = null;

    notifyListeners();
  }

  // ===========================================================================
  // DEDUPLICATE
  // ===========================================================================

  List<Song> _deduplicate(
      List<Song> songs,
      ) {
    final result = <Song>[];

    final ids = <String>{};

    for (final song in songs) {
      final id =
      song.id.trim();

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

  // ===========================================================================
  // RESOLVE STREAM
  // ===========================================================================

  Future<Song> resolveSong(
      Song song,
      ) async {
    final streamUrl =
    await _youtubeService
        .getAudioStreamUrl(
      song.id,
    );

    return song.copyWith(
      streamUrl: streamUrl,
    );
  }

  // ===========================================================================
  // PLAY SONG
  // ===========================================================================

  Future<void> playSong(
      Song song, {
        List<Song>? sourceQueue,
      }) async {
    _errorMessage = null;

    _updatePlayback(
      currentSong: song,
      status:
      PlaybackStatus.loading,
      position: Duration.zero,
      isPlaying: false,
    );

    try {
      // -----------------------------------------------------------------------
      // QUEUE
      // -----------------------------------------------------------------------

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
          index >= 0 ? index : 0,
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

      // -----------------------------------------------------------------------
      // RESOLVE FRESH STREAM
      // -----------------------------------------------------------------------

      final resolvedSong =
      await resolveSong(song);

      // -----------------------------------------------------------------------
      // UPDATE QUEUE
      // -----------------------------------------------------------------------

      _queueService.replaceCurrent(
        resolvedSong,
      );

      _updatePlayback(
        currentSong:
        resolvedSong,
        status:
        PlaybackStatus.loading,
      );

      // -----------------------------------------------------------------------
      // PLAY
      // -----------------------------------------------------------------------

      await _audioPlayerService
          .playSong(
        resolvedSong,
      );

      // -----------------------------------------------------------------------
      // RECENTLY PLAYED
      // -----------------------------------------------------------------------

      await _libraryService
          .addToRecentlyPlayed(
        resolvedSong,
      );

      // -----------------------------------------------------------------------
      // FINAL STATE
      // -----------------------------------------------------------------------

      _updatePlayback(
        currentSong:
        resolvedSong,
        status:
        PlaybackStatus.playing,
        isPlaying: true,
      );
    } catch (error) {
      _errorMessage =
          error.toString();

      _updatePlayback(
        status:
        PlaybackStatus.error,
        isPlaying: false,
      );

      rethrow;
    }
  }

  // ===========================================================================
  // PLAY
  // ===========================================================================

  Future<void> play() async {
    await _audioPlayerService.play();
  }

  // ===========================================================================
  // PAUSE
  // ===========================================================================

  Future<void> pause() async {
    await _audioPlayerService.pause();
  }

  // ===========================================================================
  // TOGGLE
  // ===========================================================================

  Future<void> togglePlayPause() async {
    if (_playbackState.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  // ===========================================================================
  // SEEK
  // ===========================================================================

  Future<void> seek(
      Duration position,
      ) async {
    await _audioPlayerService.seek(
      position,
    );
  }

  // ===========================================================================
  // NEXT
  // ===========================================================================

  Future<void> next() async {
    final song =
    _queueService.next();

    if (song == null) {
      return;
    }

    await playSong(song);
  }

  // ===========================================================================
  // PREVIOUS
  // ===========================================================================

  Future<void> previous() async {
    final song =
    _queueService.previous();

    if (song == null) {
      await seek(
        Duration.zero,
      );

      return;
    }

    await playSong(song);
  }

  // ===========================================================================
  // SET QUEUE
  // ===========================================================================

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

  // ===========================================================================
  // ADD QUEUE
  // ===========================================================================

  void addToQueue(
      Song song,
      ) {
    _queueService.add(
      song,
    );

    notifyListeners();
  }

  // ===========================================================================
  // ADD ALL TO QUEUE
  // ===========================================================================

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

  // ===========================================================================
  // REMOVE FROM QUEUE
  // ===========================================================================

  void removeFromQueue(
      int index,
      ) {
    _queueService.removeAt(
      index,
    );

    notifyListeners();
  }

  // ===========================================================================
  // CLEAR QUEUE
  // ===========================================================================

  void clearQueue() {
    _queueService.clear();

    notifyListeners();
  }

  // ===========================================================================
  // FAVORITES
  // ===========================================================================

  Future<void> toggleFavorite(
      Song song,
      ) async {
    await _libraryService
        .toggleFavorite(
      song,
    );

    notifyListeners();
  }

  // ===========================================================================
  // PLAYLIST CREATE
  // ===========================================================================

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

    // Reload playlists only.
    await _playlistService.initialize();

    Playlist? createdPlaylist;

    for (final playlist
    in _playlistService.playlists.reversed) {
      if (playlist.name == trimmed) {
        createdPlaylist = playlist;
        break;
      }
    }

    notifyListeners();

    return createdPlaylist;
  }

  // ===========================================================================
  // PLAYLIST DELETE
  // ===========================================================================

  Future<void> deletePlaylist(
      String playlistId,
      ) async {
    await _playlistService
        .deletePlaylist(
      playlistId,
    );

    notifyListeners();
  }

  // ===========================================================================
  // PLAYLIST RENAME
  // ===========================================================================

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

  // ===========================================================================
  // ADD SONG TO PLAYLIST
  // ===========================================================================

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

  // ===========================================================================
  // REMOVE SONG FROM PLAYLIST
  // ===========================================================================

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

  // ===========================================================================
  // GET PLAYLIST
  // ===========================================================================

  Playlist? getPlaylist(
      String playlistId,
      ) {
    return _playlistService
        .getPlaylist(
      playlistId,
    );
  }

  // ===========================================================================
  // STOP
  // ===========================================================================

  Future<void> stop() async {
    await _audioPlayerService.stop();

    _updatePlayback(
      status:
      PlaybackStatus.idle,
      isPlaying: false,
      position: Duration.zero,
    );
  }

  // ===========================================================================
  // CLEAR ERROR
  // ===========================================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ===========================================================================
  // DISPOSE CONTROLLER
  // ===========================================================================

  Future<void> disposeController() async {
    await _playingSubscription?.cancel();

    await _positionSubscription?.cancel();

    await _durationSubscription?.cancel();

    await _playerStateSubscription?.cancel();

    await _audioPlayerService.dispose();

    _youtubeService.dispose();

    super.dispose();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _playingSubscription?.cancel();

    _positionSubscription?.cancel();

    _durationSubscription?.cancel();

    _playerStateSubscription?.cancel();

    _youtubeService.dispose();

    super.dispose();
  }
}