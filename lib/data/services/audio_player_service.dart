import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';

class AudioPlayerService {
  // ===========================================================================
  // PLAYER
  // ===========================================================================

  final AudioPlayer _player = AudioPlayer(
    userAgent:
    'Mozilla/5.0 (Linux; Android 10; K) '
        'AppleWebKit/537.36 '
        '(KHTML, like Gecko) '
        'Chrome/131.0.0.0 Mobile Safari/537.36',
    useLazyPreparation: true,
    useProxyForRequestHeaders: false,
  );

  AudioPlayer get player => _player;

  // ===========================================================================
  // CURRENT SOURCE
  // ===========================================================================

  String? _loadedSongId;
  String? _loadedStreamUrl;

  // ===========================================================================
  // REQUEST CONTROL
  // ===========================================================================

  int _requestId = 0;

  // ===========================================================================
  // PREPARATION
  // ===========================================================================

  bool _isPreparing = false;
  int _preparingRequestId = 0;

  // ===========================================================================
  // STREAMS
  // ===========================================================================

  Stream<bool> get playingStream =>
      _player.playingStream;

  Stream<Duration> get positionStream =>
      _player.positionStream;

  Stream<Duration?> get durationStream =>
      _player.durationStream;

  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream;

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool get isPlaying =>
      _player.playing;

  bool get isPreparing =>
      _isPreparing;

  bool get hasLoadedSource =>
      _loadedSongId != null &&
          _loadedStreamUrl != null;

  String? get loadedSongId =>
      _loadedSongId;

  // ===========================================================================
  // PLAY SONG
  // ===========================================================================

  Future<void> playSong(
      Song song,
      ) async {
    final streamUrl =
    song.streamUrl?.trim();

    if (streamUrl == null ||
        streamUrl.isEmpty) {
      throw Exception(
        'Song does not have a playable stream.',
      );
    }

    final requestId =
    ++_requestId;

    // ========================================================================
    // SAME SOURCE = FASTEST PATH
    // ========================================================================

    if (_loadedSongId == song.id &&
        _loadedStreamUrl == streamUrl) {
      _startPlayback(requestId);
      return;
    }

    // ========================================================================
    // NEW SOURCE
    // ========================================================================

    await _loadSourceAndStart(
      song: song,
      streamUrl: streamUrl,
      requestId: requestId,
    );
  }

  // ===========================================================================
  // LOAD SOURCE + START
  // ===========================================================================

  Future<void> _loadSourceAndStart({
    required Song song,
    required String streamUrl,
    required int requestId,
  }) async {
    if (!_isCurrentRequest(requestId)) {
      return;
    }

    _isPreparing = true;
    _preparingRequestId = requestId;

    try {
      final source =
      _createSource(
        song,
        streamUrl,
      );

      // Do not wait for full network preparation before handing the source to
      // the player. play() starts loading as soon as possible.
      await _player.setAudioSource(
        source,
        preload: false,
        initialPosition:
        Duration.zero,
      );

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _loadedSongId = song.id;
      _loadedStreamUrl = streamUrl;
      _isPreparing = false;

      _startPlayback(requestId);
    } on PlayerInterruptedException {
      if (_isCurrentRequest(requestId)) {
        rethrow;
      }
    } finally {
      if (_preparingRequestId ==
          requestId) {
        _isPreparing = false;
      }
    }
  }

  // ===========================================================================
  // MEDIA ITEM
  // ===========================================================================

  MediaItem _mediaItemFor(
      Song song,
      ) {
    final thumbnail =
    song.thumbnailUrl?.trim();

    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: 'Chameleon',
      duration: song.duration,
      artUri: thumbnail != null &&
          thumbnail.isNotEmpty
          ? Uri.tryParse(thumbnail)
          : null,
      playable: true,
    );
  }

  // ===========================================================================
  // AUDIO SOURCE
  // ===========================================================================

  AudioSource _createSource(
      Song song,
      String streamUrl,
      ) {
    return AudioSource.uri(
      Uri.parse(streamUrl),
      headers: const {
        'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; K) '
            'AppleWebKit/537.36 '
            '(KHTML, like Gecko) '
            'Chrome/131.0.0.0 Mobile Safari/537.36',
        'Referer':
        'https://www.youtube.com/',
        'Origin':
        'https://www.youtube.com',
      },

      // This MediaItem is what just_audio_background uses for the
      // notification, lock screen and system media controls.
      tag: _mediaItemFor(song),
    );
  }

  // ===========================================================================
  // START PLAYBACK
  // ===========================================================================

  void _startPlayback(
      int requestId,
      ) {
    if (!_isCurrentRequest(requestId)) {
      return;
    }

    // IMPORTANT:
    // Do not await this Future. The Future represents the lifetime of
    // playback, not merely the moment playback begins.
    unawaited(
      _player.play().catchError(
            (_) {},
      ),
    );
  }

  // ===========================================================================
  // REQUEST CHECK
  // ===========================================================================

  bool _isCurrentRequest(
      int requestId,
      ) {
    return requestId ==
        _requestId;
  }

  // ===========================================================================
  // PREPARE SONG
  // ===========================================================================

  Future<void> prepareSong(
      Song song,
      ) async {
    final streamUrl =
    song.streamUrl?.trim();

    if (streamUrl == null ||
        streamUrl.isEmpty) {
      throw Exception(
        'Song does not have a playable stream.',
      );
    }

    if (_loadedSongId == song.id &&
        _loadedStreamUrl == streamUrl) {
      return;
    }

    final requestId =
    ++_requestId;

    _isPreparing = true;
    _preparingRequestId = requestId;

    try {
      final source =
      _createSource(
        song,
        streamUrl,
      );

      await _player.setAudioSource(
        source,
        preload: true,
        initialPosition:
        Duration.zero,
      );

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _loadedSongId = song.id;
      _loadedStreamUrl = streamUrl;
    } on PlayerInterruptedException {
      if (_isCurrentRequest(requestId)) {
        rethrow;
      }
    } finally {
      if (_preparingRequestId ==
          requestId) {
        _isPreparing = false;
      }
    }
  }

  // ===========================================================================
  // PLAY
  // ===========================================================================

  void play() {
    _startPlayback(_requestId);
  }

  // ===========================================================================
  // PAUSE
  // ===========================================================================

  Future<void> pause() async {
    await _player.pause();
  }

  // ===========================================================================
  // TOGGLE
  // ===========================================================================

  void togglePlayPause() {
    if (_player.playing) {
      unawaited(_player.pause());
    } else {
      play();
    }
  }

  // ===========================================================================
  // STOP
  // ===========================================================================

  Future<void> stop() async {
    _requestId++;

    await _player.stop();

    _loadedSongId = null;
    _loadedStreamUrl = null;
    _isPreparing = false;
  }

  // ===========================================================================
  // SEEK
  // ===========================================================================

  Future<void> seek(
      Duration position,
      ) async {
    await _player.seek(position);
  }

  // ===========================================================================
  // VOLUME
  // ===========================================================================

  Future<void> setVolume(
      double volume,
      ) async {
    await _player.setVolume(
      volume.clamp(0.0, 1.0),
    );
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  Future<void> clearSource() async {
    _requestId++;

    await _player.stop();

    _loadedSongId = null;
    _loadedStreamUrl = null;
    _isPreparing = false;
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  Future<void> dispose() async {
    _requestId++;

    _loadedSongId = null;
    _loadedStreamUrl = null;
    _isPreparing = false;

    await _player.dispose();
  }
}
