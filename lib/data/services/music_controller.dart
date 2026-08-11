import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/playback_state.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'Jio/jiosaavn_service.dart';
import 'audio_player_service.dart';
import 'library_service.dart';
import 'playlist_service.dart';
import 'queue_service.dart';
import 'settings_service.dart';
import 'youtube_service.dart';

enum PlaybackProvider {
  youtube,
  jioSaavn,
}

class MusicController extends ChangeNotifier {
  final YoutubeService _youtubeService;
  final JioSaavnService _jioSaavnService;
  late final AudioPlayerService _audioPlayerService;
  final QueueService _queueService;
  final LibraryService _libraryService;
  final PlaylistService _playlistService;
  late final SettingsService _settingsService;

  MusicController({
    YoutubeService? youtubeService,
    JioSaavnService? jioSaavnService,
    AudioPlayerService? audioPlayerService,
    QueueService? queueService,
    LibraryService? libraryService,
    PlaylistService? playlistService,
    SettingsService? settingsService,
  })  : _youtubeService =
      youtubeService ?? YoutubeService(),
        _jioSaavnService =
            jioSaavnService ?? JioSaavnService(),
        _queueService =
            queueService ?? QueueService(),
        _libraryService =
            libraryService ?? LibraryService(),
        _playlistService =
            playlistService ?? PlaylistService() {
    _settingsService =
        settingsService ?? SettingsService();

    _audioPlayerService =
        audioPlayerService ??
            AudioPlayerService(
              settingsService: _settingsService,
            );

    _settingsService.addListener(
      _onSettingsChanged,
    );

    _bindPlayerStreams();
  }

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

  PlaybackProvider? _lastPlaybackProvider;

  final Map<String, _CachedStream> _resolvedSongs =
  {};

  final Map<String, Future<Song>> _preloadTasks =
  {};

  static const Duration _streamCacheDuration =
  Duration(minutes: 5);

  static const int _defaultPreloadCount = 3;

  StreamSubscription<bool>? _playingSubscription;

  StreamSubscription<Duration>? _positionSubscription;

  StreamSubscription<Duration?>?
  _durationSubscription;

  StreamSubscription<PlayerState>?
  _playerStateSubscription;

  StreamSubscription<int?>?
  _playerIndexSubscription;

  bool _sleepTimerStopping = false;

  bool _handlingTrackCompletion = false;
  int _completionRequestId = 0;

  PlaybackState get playbackState {
    return _playbackState;
  }

  AudioPlayerService get audioPlayerService {
    return _audioPlayerService;
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

  PlaybackProvider? get lastPlaybackProvider {
    return _lastPlaybackProvider;
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
SettingsService get settingsService => _settingsService;

  bool get autoplayEnabled => _settingsService.autoplay;
  bool get crossfadeEnabled => _settingsService.crossfade;
  bool get gaplessEnabled => _settingsService.gapless;
  bool get highQualityEnabled => _settingsService.highQuality;
  bool get normalizeEnabled => _settingsService.normalize;
  bool get miniPlayerEnabled => _settingsService.miniPlayer;
  bool get animatedArtworkEnabled =>
      _settingsService.animatedArtwork;
  bool get keepScreenAwakeEnabled =>
      _settingsService.keepScreenAwake;
  bool get notificationsEnabled =>
      _settingsService.notifications;
  bool get wifiOnlyEnabled => _settingsService.wifiOnly;
  bool get saveSearchesEnabled =>
      _settingsService.saveSearches;
  bool get shouldShowMiniPlayer =>
      _settingsService.miniPlayer && currentSong != null;

  String get downloadQuality =>
      _settingsService.downloadQuality;
  int get recentLimit => _settingsService.recentLimit;
  bool get shouldSaveSearchHistory =>
      _settingsService.saveSearches;
  bool get shouldShowNotifications =>
      _settingsService.notifications;
  bool get wifiOnlyPlayback =>
      _settingsService.wifiOnly;

  Future<void> setAutoplay(bool value) async {
    await _settingsService.setAutoplay(value);
  }

  Future<void> setCrossfade(bool value) async {
    await _settingsService.setCrossfade(value);
  }

  Future<void> setGapless(bool value) async {
    await _settingsService.setGapless(value);
  }

  Future<void> setHighQuality(bool value) async {
    await _settingsService.setHighQuality(value);
    await _applyAudioSettings();
  }

  Future<void> setNormalize(bool value) async {
    await _settingsService.setNormalize(value);
    await _applyAudioSettings();
  }

  Future<void> setMiniPlayer(bool value) async {
    await _settingsService.setMiniPlayer(value);
  }

  Future<void> setAnimatedArtwork(bool value) async {
    await _settingsService.setAnimatedArtwork(value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    await _settingsService.setKeepScreenAwake(value);
  }

  Future<void> setNotifications(bool value) async {
    await _settingsService.setNotifications(value);
  }

  Future<void> setWifiOnly(bool value) async {
    await _settingsService.setWifiOnly(value);
  }

  Future<void> setSaveSearches(bool value) async {
    await _settingsService.setSaveSearches(value);
  }

  Future<void> setDownloadQuality(String value) async {
    await _settingsService.setDownloadQuality(value);
  }

  Future<void> setRecentLimit(int value) async {
    await _settingsService.setRecentLimit(value);
  }


  void _onSettingsChanged() {
    unawaited(_applyAudioSettings());
    notifyListeners();
  }
  Future<void> _applyAudioSettings() async {
    try {
      if (_settingsService.normalize) {
        await _audioPlayerService.setVolume(1.0);
      }
    } catch (_) {
    }
  }
bool get sleepTimerActive {
    return _settingsService.sleepTimerActive;
  }

  bool get sleepTimerEndOfSong {
    return _settingsService.sleepTimerEndOfSong;
  }

  Duration? get sleepTimerRemaining {
    return _settingsService.sleepTimerRemaining;
  }

  Duration? get sleepTimerDuration {
    return _settingsService.sleepTimerDuration;
  }

  Future<void> setSleepTimer(
      Duration duration,
      ) async {
    _sleepTimerStopping = false;

    await _settingsService.setSleepTimer(
      duration,
    );

    notifyListeners();
  }

  Future<void> setSleepTimerEndOfSong() async {
    _sleepTimerStopping = false;

    await _settingsService
        .setSleepTimerEndOfSong();

    notifyListeners();
  }

  Future<void> clearSleepTimer() async {
    _sleepTimerStopping = false;

    await _settingsService.clearSleepTimer();

    notifyListeners();
  }

  Future<void> _checkSleepTimer() async {
    if (_sleepTimerStopping) {
      return;
    }

    if (!_settingsService.sleepTimerActive) {
      return;
    }

    if (_settingsService.sleepTimerEndOfSong) {
      return;
    }

    final remaining =
        _settingsService.sleepTimerRemaining;

    if (remaining == null) {
      return;
    }

    if (remaining > Duration.zero) {
      return;
    }

    _sleepTimerStopping = true;

    try {
      await _settingsService.clearSleepTimer();

      await _audioPlayerService.pause();

      _updatePlayback(
        status: PlaybackStatus.paused,
        isPlaying: false,
      );
    } catch (error) {
      _errorMessage =
      'Unable to stop playback after sleep timer.';

      _sleepTimerStopping = false;

      notifyListeners();
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
        _settingsService.initialize(),
        _libraryService.initialize(),
        _playlistService.initialize(),
      ]);

      await _applyAudioSettings();

      await refreshHome();

      _isInitialized = true;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isInitializing = false;

      notifyListeners();
    }
  }
List<Song> _recentHomeSongs(
      List<Song> songs,
      ) {
    final currentYear =
        DateTime.now().year;

    final recent = <Song>[];
    final unknown = <Song>[];

    for (final song in songs) {
      final year = song.releaseYear;

      if (year == null) {
        unknown.add(song);
        continue;
      }

      if (year >= currentYear - 1) {
        recent.add(song);
      }
    }

    return [
      ...recent,
      ...unknown,
    ];
  }

  String _normalizeHomeTitle(
      String value,
      ) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'\b(official|lyrics?|audio|video|visualizer|remastered)\b',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'[^\p{L}\p{N}\s]+',
        unicode: true,
      ),
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
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
      final batches =
      <List<Song>>[];

      try {
        final jioSongs =
        await _jioSaavnService.discover(
          limit: 60,
        );

        if (jioSongs.isNotEmpty) {
          batches.add(jioSongs);
        }
      } catch (_) {}

      if (batches.isEmpty) {
        final currentYear =
            DateTime.now().year;

        const fallbackQueries = <String>[
          'new songs',
          'latest music',
        ];

        for (final query
        in fallbackQueries) {
          try {
            final results =
            await _youtubeService.search(
              '$query $currentYear',
              limit: 30,
            );

            if (results.isNotEmpty) {
              batches.add(results);
            }
          } catch (_) {}
        }
      }

      final songs = <Song>[];
      final seenIds =
      <String>{};
      final seenTitles =
      <String>{};

      for (final batch in batches) {
        for (final song in batch) {
          final id =
          song.id.trim();

          if (id.isEmpty) {
            continue;
          }

          if (!seenIds.add(id)) {
            continue;
          }

          final titleKey =
          _normalizeHomeTitle(
            song.title,
          );

          if (titleKey.isNotEmpty &&
              !seenTitles.add(
                titleKey,
              )) {
            continue;
          }

          songs.add(song);

          if (songs.length >= 40) {
            break;
          }
        }

        if (songs.length >= 40) {
          break;
        }
      }

      if (songs.isEmpty) {
        _errorMessage =
        'Unable to load music right now. Please try again.';
        return;
      }

      final currentYear =
          DateTime.now().year;

      songs.sort(
            (a, b) {
          final yearA =
              a.releaseYear ??
                  currentYear;

          final yearB =
              b.releaseYear ??
                  currentYear;

          return yearB.compareTo(
            yearA,
          );
        },
      );

      _trendingSongs =
          songs.take(40).toList();

      final artists = <String>[];
      final seenArtists =
      <String>{};

      for (final song
      in _trendingSongs) {
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

      _trendingArtists =
          artists;

      final suggestions =
      <Song>[];

      final suggestionIds =
      <String>{};

      final currentId =
          currentSong?.id;

      for (final song in songs) {
        if (song.id == currentId) {
          continue;
        }

        if (!suggestionIds.add(
          song.id,
        )) {
          continue;
        }

        suggestions.add(song);

        if (suggestions.length >= 30) {
          break;
        }
      }

      _suggestedSongs =
          _removeDuplicateTitles(
            suggestions,
          ).take(30).toList();

      _homeLastUpdated =
          DateTime.now();

      unawaited(
        preloadSongs(
          _trendingSongs,
          count:
          _defaultPreloadCount,
        ),
      );

      unawaited(
        preloadSongs(
          _suggestedSongs,
          count:
          _defaultPreloadCount,
        ),
      );
    } catch (_) {
      _errorMessage =
      'Unable to refresh Home right now.';
    } finally {
      _isHomeLoading = false;

      notifyListeners();
    }
  }

  List<Song> _removeDuplicateTitles(
      List<Song> songs,
      ) {
    final result = <Song>[];

    final seenTitles =
    <String>{};

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

  List<String> _extractArtists(
      List<Song> songs,
      ) {
    final artists = <String>[];

    final seen =
    <String>{};

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

    final suggestions =
    <Song>[];

    final seenIds =
    <String>{};

    final currentId =
        currentSong?.id;

    for (final song in trending) {
      if (song.id == currentId) {
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
              (
              isPlaying,
              ) {
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
              (
              position,
              ) {
            _updatePlayback(
              position: position,
            );

            unawaited(
              _checkSleepTimer(),
            );
          },
        );

    _durationSubscription =
        _audioPlayerService.durationStream.listen(
              (
              duration,
              ) {
            _updatePlayback(
              duration:
              duration ??
                  Duration.zero,
            );
          },
        );

    _playerIndexSubscription =
        _audioPlayerService.currentIndexStream.listen(
              (
              index,
              ) {
            if (index == null) {
              return;
            }

            unawaited(
              _handleAudioQueueIndexChanged(index),
            );
          },
        );

    _playerStateSubscription =
        _audioPlayerService.playerStateStream.listen(
              (
              state,
              ) {
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
                unawaited(
                  _handleTrackCompleted(),
                );
                break;
            }
          },
        );
  }

  Future<void> _handleAudioQueueIndexChanged(
      int index,
      ) async {
    if (!_audioPlayerService.hasGaplessQueue) {
      return;
    }

    final songs = _queueService.queue;

    if (index < 0 || index >= songs.length) {
      return;
    }

    final song = songs[index];
    _queueService.setQueue(
      songs,
      startIndex: index,
    );

    _updatePlayback(
      currentSong: song,
      position: Duration.zero,
    );
    if (_audioPlayerService.isPlaying) {
      unawaited(
        _libraryService.addToRecentlyPlayed(song),
      );
    }

    notifyListeners();
  }

  Future<bool> _tryStartGaplessQueue({
    required List<Song> sourceQueue,
    required int startIndex,
    required int requestId,
  }) async {
    if (!_settingsService.gapless) {
      return false;
    }

    if (sourceQueue.isEmpty ||
        startIndex < 0 ||
        startIndex >= sourceQueue.length) {
      return false;
    }

    if (requestId != _playRequestId) {
      return false;
    }

    try {
      final resolvedQueue = <Song>[];

      for (final queueSong in sourceQueue) {
        if (requestId != _playRequestId) {
          return false;
        }

        final resolved = await resolveSong(
          queueSong,
          allowFallback: true,
        );

        if (resolved.streamUrl == null ||
            resolved.streamUrl!.trim().isEmpty) {
          return false;
        }

        resolvedQueue.add(resolved);
      }

      if (requestId != _playRequestId) {
        return false;
      }

      _queueService.setQueue(
        resolvedQueue,
        startIndex: startIndex,
      );

      final current = resolvedQueue[startIndex];

      await _applyAudioSettings();

      await _audioPlayerService.loadGaplessQueue(
        resolvedQueue,
        initialIndex: startIndex,
        startPlaying: true,
      );

      if (requestId != _playRequestId) {
        return true;
      }

      _updatePlayback(
        currentSong: current,
        status: PlaybackStatus.playing,
        position: Duration.zero,
        isPlaying: true,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleTrackCompleted() async {
    if (_handlingTrackCompletion) {
      return;
    }

    _handlingTrackCompletion = true;
    final completionId = ++_completionRequestId;

    try {
      _updatePlayback(
        status: PlaybackStatus.completed,
        isPlaying: false,
      );
      if (_settingsService.sleepTimerEndOfSong) {
        await _settingsService.clearSleepTimer();

        _sleepTimerStopping = false;

        _updatePlayback(
          status: PlaybackStatus.paused,
          isPlaying: false,
        );

        return;
      }
      if (_audioPlayerService.hasGaplessQueue) {
        if (!_settingsService.autoplay) {
          await _audioPlayerService.pause();
          _updatePlayback(
            status: PlaybackStatus.paused,
            isPlaying: false,
          );
        }
        return;
      }
      if (!hasNext) {
        return;
      }
      if (!_settingsService.autoplay) {
        return;
      }

      if (_settingsService.crossfade) {
        await _playNextWithCrossfade(completionId);
      } else {
        await next();
      }
    } catch (error) {
      if (completionId != _completionRequestId) {
        return;
      }

      _errorMessage = error.toString();

      _updatePlayback(
        status: PlaybackStatus.error,
        isPlaying: false,
      );
    } finally {
      if (completionId == _completionRequestId) {
        _handlingTrackCompletion = false;
      }
    }
  }

  Future<void> _playNextWithCrossfade(
      int completionId,
      ) async {
    if (completionId != _completionRequestId) {
      return;
    }
    const fadeSteps = 8;
    const fadeStepDuration = Duration(milliseconds: 35);

    final currentVolume =
    _audioPlayerService.player.volume.clamp(0.0, 1.0);

    for (int i = fadeSteps; i >= 1; i--) {
      if (completionId != _completionRequestId) {
        return;
      }

      await _audioPlayerService.setVolume(
        currentVolume * (i / fadeSteps),
      );

      await Future<void>.delayed(
        fadeStepDuration,
      );
    }

    if (completionId != _completionRequestId) {
      return;
    }

    await next();

    if (completionId != _completionRequestId) {
      return;
    }

    for (int i = 1; i <= fadeSteps; i++) {
      if (completionId != _completionRequestId) {
        return;
      }

      await _audioPlayerService.setVolume(
        currentVolume * (i / fadeSteps),
      );

      await Future<void>.delayed(
        fadeStepDuration,
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
        limit: 100,
      );

      _searchResults =
          _deduplicate(results);
    } catch (_) {
      _searchResults = [];

      _errorMessage =
      'Unable to search right now. Please try again.';
    } finally {
      _isSearching = false;

      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];

    _errorMessage = null;

    _isSearching = false;

    notifyListeners();
  }

  List<Song> _deduplicate(
      List<Song> songs,
      ) {
    final result = <Song>[];

    final ids =
    <String>{};

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
Future<Song> resolveSong(
      Song song, {
        bool allowFallback = false,
      }) async {
    final existingUrl =
    song.streamUrl?.trim();

    if (existingUrl != null &&
        existingUrl.isNotEmpty) {
      return song;
    }

    final cached =
    _resolvedSongs[song.id];

    if (cached != null &&
        cached.isValid) {
      return song.copyWith(
        streamUrl: cached.url,
      );
    }

    if (cached != null) {
      _resolvedSongs.remove(
        song.id,
      );
    }

    final existingTask =
    _preloadTasks[song.id];

    if (existingTask != null) {
      return existingTask;
    }

    final task =
    _resolveFreshSong(
      song,
      allowFallback:
      allowFallback,
    );

    _preloadTasks[song.id] =
        task;

    try {
      final resolved =
      await task;

      final streamUrl =
      resolved.streamUrl?.trim();

      if (streamUrl == null ||
          streamUrl.isEmpty) {
        throw Exception(
          'Unable to resolve audio stream.',
        );
      }

      _resolvedSongs[song.id] =
          _CachedStream(
            url: streamUrl,
            createdAt: DateTime.now(),
          );

      return resolved;
    } finally {
      if (identical(
        _preloadTasks[song.id],
        task,
      )) {
        _preloadTasks.remove(
          song.id,
        );
      }
    }
  }

  Future<Song> _resolveFreshSong(
      Song song, {
        bool allowFallback = true,
      }) async {
    final isJioSaavnSong =
    song.id.startsWith(
      'saavn_',
    );
if (isJioSaavnSong) {
      try {
        final streamUrl =
        await _jioSaavnService
            .getAudioStreamUrl(
          song,
        )
            .timeout(
          const Duration(
            seconds: 4,
          ),
        );

        final trimmedUrl =
        streamUrl.trim();

        if (trimmedUrl.isEmpty) {
          throw Exception(
            'JioSaavn returned an empty stream URL.',
          );
        }

        _lastPlaybackProvider =
            PlaybackProvider.jioSaavn;

        return song.copyWith(
          streamUrl:
          trimmedUrl,
        );
      } catch (_) {
        throw Exception(
          'Unable to play "${song.title}" from JioSaavn.',
        );
      }
    }
try {
      final streamUrl =
      await _youtubeService
          .getAudioStreamUrl(
        song.id,
      )
          .timeout(
        const Duration(
          seconds: 4,
        ),
      );

      final trimmedUrl =
      streamUrl.trim();

      if (trimmedUrl.isEmpty) {
        throw Exception(
          'YouTube returned an empty audio stream URL.',
        );
      }

      _lastPlaybackProvider =
          PlaybackProvider.youtube;

      return song.copyWith(
        streamUrl:
        trimmedUrl,
      );
    } catch (_) {
      if (!allowFallback) {
        rethrow;
      }
try {
        final streamUrl =
        await _jioSaavnService
            .getAudioStreamUrl(
          song,
        )
            .timeout(
          const Duration(
            seconds: 4,
          ),
        );

        final trimmedUrl =
        streamUrl.trim();

        if (trimmedUrl.isEmpty) {
          throw Exception(
            'JioSaavn returned an empty stream URL.',
          );
        }

        _lastPlaybackProvider =
            PlaybackProvider.jioSaavn;

        return song.copyWith(
          streamUrl:
          trimmedUrl,
        );
      } catch (_) {
        throw Exception(
          'Unable to play "${song.title}". '
              'YouTube and JioSaavn both failed.',
        );
      }
    }
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
      final id =
      song.id.trim();

      if (id.isEmpty) {
        continue;
      }

      if (uniqueSongs
          .containsKey(id)) {
        continue;
      }

      uniqueSongs[id] =
          song;

      if (uniqueSongs.length >=
          count) {
        break;
      }
    }

    if (uniqueSongs.isEmpty) {
      return;
    }

    await Future.wait(
      uniqueSongs.values.map(
            (
            song,
            ) async {
          try {
            await resolveSong(
              song,
            );
          } catch (_) {}
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
      song.id ==
          current.id,
    );

    if (index < 0 ||
        index + 1 >=
            songs.length) {
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
      songId,
    );
  }
Future<void> playSong(
      Song song, {
        List<Song>? sourceQueue,
      }) async {
    final requestId =
    ++_playRequestId;

    _errorMessage = null;

    _sleepTimerStopping =
    false;

    _updatePlayback(
      currentSong: song,
      status:
      PlaybackStatus.loading,
      position:
      Duration.zero,
      isPlaying: false,
    );

    try {
if (sourceQueue != null &&
          sourceQueue.isNotEmpty) {
        final index =
        sourceQueue.indexWhere(
              (item) =>
          item.id ==
              song.id,
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
            current.id !=
                song.id) {
          _queueService.setQueue(
            [
              song,
            ],
            startIndex: 0,
          );
        }
      }

      if (requestId !=
          _playRequestId) {
        return;
      }

      if (sourceQueue != null &&
          sourceQueue.length > 1 &&
          _settingsService.gapless &&
          _settingsService.autoplay) {
        final startIndex =
            _queueService.currentIndex;

        final startedGapless =
        await _tryStartGaplessQueue(
          sourceQueue: sourceQueue,
          startIndex: startIndex,
          requestId: requestId,
        );

        if (startedGapless) {
          _preloadNextSong();
          return;
        }
      }
Song resolvedSong;

      try {
        resolvedSong =
        await resolveSong(
          song,
          allowFallback:
          song.id.startsWith(
            'saavn_',
          ),
        );
      } catch (_) {
        _invalidateStream(
          song.id,
        );

        if (requestId !=
            _playRequestId) {
          return;
        }

        resolvedSong =
        await resolveSong(
          song,
          allowFallback: true,
        );
      }

      if (requestId !=
          _playRequestId) {
        return;
      }
_queueService
          .replaceCurrent(
        resolvedSong,
      );

      _updatePlayback(
        currentSong:
        resolvedSong,
        status:
        PlaybackStatus.loading,
      );

      if (requestId !=
          _playRequestId) {
        return;
      }
await _applyAudioSettings();

      try {
        await _audioPlayerService
            .playSong(
          resolvedSong,
        );
      } catch (_) {
        if (requestId !=
            _playRequestId) {
          return;
        }

        _invalidateStream(
          resolvedSong.id,
        );

        final fallbackSong =
        await _resolveFreshSong(
          song,
          allowFallback: true,
        );

        if (requestId !=
            _playRequestId) {
          return;
        }

        final fallbackUrl =
        fallbackSong
            .streamUrl
            ?.trim();

        if (fallbackUrl ==
            null ||
            fallbackUrl.isEmpty) {
          throw Exception(
            'Fallback audio stream is unavailable.',
          );
        }

        _resolvedSongs[
        song.id] =
            _CachedStream(
              url: fallbackUrl,
              createdAt:
              DateTime.now(),
            );

        _queueService
            .replaceCurrent(
          fallbackSong,
        );

        _updatePlayback(
          currentSong:
          fallbackSong,
          status:
          PlaybackStatus.loading,
        );

        if (requestId !=
            _playRequestId) {
          return;
        }

        await _applyAudioSettings();

        await _audioPlayerService
            .playSong(
          fallbackSong,
        );

        resolvedSong =
            fallbackSong;
      }

      if (requestId !=
          _playRequestId) {
        return;
      }
unawaited(
        _libraryService
            .addToRecentlyPlayed(
          resolvedSong,
        ),
      );
_updatePlayback(
        currentSong:
        resolvedSong,
      );
_preloadNextSong();
    } catch (error) {
      if (requestId !=
          _playRequestId) {
        return;
      }

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
Future<void> play() async {
    await _audioPlayerService.play();
  }

  Future<void> pause() async {
    await _audioPlayerService.pause();
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayerService
        .isPlaying) {
      await _audioPlayerService
          .pause();
    } else {
      await _audioPlayerService
          .play();
    }
  }

  Future<void> seek(
      Duration position,
      ) async {
    await _audioPlayerService
        .seek(position);
  }
Future<void> next() async {
    _completionRequestId++;
    _handlingTrackCompletion = false;

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
    _completionRequestId++;
    _handlingTrackCompletion = false;

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
    _completionRequestId++;
    _handlingTrackCompletion = false;

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
      description:
      description,
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
    _completionRequestId++;
    _handlingTrackCompletion = false;

    _sleepTimerStopping =
    false;

    await _audioPlayerService
        .stop();

    _updatePlayback(
      status:
      PlaybackStatus.idle,
      isPlaying: false,
      position:
      Duration.zero,
    );
  }
void clearError() {
    _errorMessage = null;

    notifyListeners();
  }
Future<void> disposeController() async {
    await _playingSubscription
        ?.cancel();

    await _positionSubscription
        ?.cancel();

    await _durationSubscription
        ?.cancel();

    await _playerStateSubscription
        ?.cancel();

    await _playerIndexSubscription
        ?.cancel();

    _settingsService.removeListener(_onSettingsChanged);

    _resolvedSongs.clear();

    _preloadTasks.clear();

    await _audioPlayerService
        .dispose();

    _youtubeService.dispose();

    _jioSaavnService.dispose();

    super.dispose();
  }

  @override
  void dispose() {
    _playingSubscription
        ?.cancel();

    _positionSubscription
        ?.cancel();

    _durationSubscription
        ?.cancel();

    _playerStateSubscription
        ?.cancel();

    _playerIndexSubscription
        ?.cancel();

    _settingsService.removeListener(_onSettingsChanged);

    _resolvedSongs.clear();

    _preloadTasks.clear();

    _youtubeService.dispose();

    _jioSaavnService.dispose();

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
        .difference(
      createdAt,
    ) <
        const Duration(
          minutes: 5,
        );
  }
}