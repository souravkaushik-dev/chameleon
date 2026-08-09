import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer(
    userAgent:
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 '
        '(KHTML, like Gecko) '
        'Version/17.0 Mobile/15E148 Safari/604.1',
    useLazyPreparation: true,
    useProxyForRequestHeaders: false,
  );

  AudioPlayerService() {
    _listenToPlayerErrors();
    _listenToPlaybackEvents();
    _listenToDuration();
  }

  AudioPlayer get player => _player;
  String? _loadedSongId;
  String? _loadedStreamUrl;
  int _requestId = 0;
  bool _isPreparing = false;
  int _preparingRequestId = 0;
  Object? _lastError;

  Object? get lastError => _lastError;
  Stream<bool> get playingStream {
    return _player.playingStream;
  }

  Stream<Duration> get positionStream {
    return _player.positionStream;
  }

  Stream<Duration?> get durationStream {
    return _player.durationStream;
  }

  Stream<PlayerState> get playerStateStream {
    return _player.playerStateStream;
  }

  Stream<ProcessingState> get processingStateStream {
    return _player.processingStateStream;
  }

  Stream<int?> get currentIndexStream {
    return _player.currentIndexStream;
  }
  bool get isPlaying {
    return _player.playing;
  }

  bool get isPreparing {
    return _isPreparing;
  }

  bool get hasLoadedSource {
    return _loadedSongId != null &&
        _loadedStreamUrl != null;
  }

  String? get loadedSongId {
    return _loadedSongId;
  }

  Duration get position {
    return _player.position;
  }

  Duration? get duration {
    return _player.duration;
  }

  ProcessingState get processingState {
    return _player.processingState;
  }
  void _listenToPlayerErrors() {
    _player.errorStream.listen(
          (Object error) {
        _lastError = error;

        debugPrint(
          '🔴 CHAMELEON AUDIO ERROR: $error',
        );
      },
    );
  }

  void _listenToDuration() {
    _player.durationStream.listen(
          (duration) {
        debugPrint(
          '🎵 REAL AUDIO DURATION: $duration',
        );

        debugPrint(
          '🎵 REAL AUDIO POSITION: ${_player.position}',
        );
      },
    );
  }
  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen(
          (PlaybackEvent event) {
        debugPrint(
          '🎵 CHAMELEON AUDIO: '
              'state=${_player.processingState} '
              'playing=${_player.playing} '
              'position=${event.updatePosition} '
              'buffered=${event.bufferedPosition}',
        );
      },
      onError: (
          Object error,
          StackTrace stackTrace,
          ) {
        _lastError = error;

        debugPrint(
          '🔴 CHAMELEON PLAYBACK STREAM ERROR: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      },
    );
  }
  Future<void> playSong(
      Song song,
      ) async {
    final streamUrl = song.streamUrl?.trim();

    if (streamUrl == null || streamUrl.isEmpty) {
      throw Exception(
        'Song does not have a playable stream.',
      );
    }

    // Every tap gets a new request.
    // The newest request always wins.
    final requestId = ++_requestId;

    _lastError = null;
    //
    // If the requested song is already loaded, don't recreate the source.
    // This is the fastest possible path.
    //

    if (_loadedSongId == song.id &&
        _loadedStreamUrl == streamUrl) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      await play();

      return;
    }
    await _loadSourceAndStart(
      song: song,
      streamUrl: streamUrl,
      requestId: requestId,
    );
  }
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
      final source = _createSource(
        song,
        streamUrl,
      );

      // -----------------------------------------------------------------------
      // Stop the previous source first.
      // -----------------------------------------------------------------------

      if (_player.audioSource != null) {
        try {
          await _player.stop();
        } catch (_) {
          // Ignore stop errors while replacing a source.
        }
      }

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      // -----------------------------------------------------------------------
      // Load source.
      //
      // preload: false means don't block the tap waiting for the entire
      // network source to buffer.
      // -----------------------------------------------------------------------

      await _player.setAudioSource(
        source,
        preload: false,
        initialPosition: Duration.zero,
      );

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _loadedSongId = song.id;
      _loadedStreamUrl = streamUrl;
      _isPreparing = false;

      // -----------------------------------------------------------------------
      // Start immediately.
      // -----------------------------------------------------------------------

      await play();
    } on PlayerInterruptedException {
      if (_isCurrentRequest(requestId)) {
        rethrow;
      }
    } catch (error, stackTrace) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _lastError = error;

      debugPrint(
        '🔴 CHAMELEON LOAD ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      if (_preparingRequestId == requestId) {
        _isPreparing = false;
      }
    }
  }

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

      // IMPORTANT:
      // Do not use Song.duration here.
      //
      // just_audio will determine the real duration
      // from the actual audio stream.

      artUri: thumbnail != null &&
          thumbnail.isNotEmpty
          ? Uri.tryParse(thumbnail)
          : null,

      playable: true,
    );
  }
  AudioSource _createSource(
      Song song,
      String streamUrl,
      ) {
    final uri = Uri.parse(
      streamUrl,
    );
    //
    // Do NOT force YouTube Referer / Origin headers here.
    //
    // This is intentionally kept simple for iOS compatibility.
    //
    // If your resolver absolutely requires custom headers, we can add them
    // back after confirming that basic iOS playback works.
    //

    return AudioSource.uri(
      uri,
      tag: _mediaItemFor(song),
    );
  }
  Future<void> play() async {
    try {
      await _player.play();
    } catch (error, stackTrace) {
      _lastError = error;

      debugPrint(
        '🔴 CHAMELEON PLAY FAILED: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (error, stackTrace) {
      _lastError = error;

      debugPrint(
        '🔴 CHAMELEON PAUSE FAILED: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }
  Future<void> stop() async {
    _requestId++;

    try {
      await _player.stop();
    } finally {
      _loadedSongId = null;
      _loadedStreamUrl = null;
      _isPreparing = false;
      _lastError = null;
    }
  }
  Future<void> seek(
      Duration position,
      ) async {
    await _player.seek(
      position,
    );
  }
  Future<void> setVolume(
      double volume,
      ) async {
    await _player.setVolume(
      volume.clamp(
        0.0,
        1.0,
      ),
    );
  }
  Future<void> prepareSong(
      Song song,
      ) async {
    final streamUrl = song.streamUrl?.trim();

    if (streamUrl == null || streamUrl.isEmpty) {
      throw Exception(
        'Song does not have a playable stream.',
      );
    }

    // Already loaded.
    if (_loadedSongId == song.id &&
        _loadedStreamUrl == streamUrl) {
      return;
    }

    final requestId = ++_requestId;

    _isPreparing = true;
    _preparingRequestId = requestId;

    try {
      final source = _createSource(
        song,
        streamUrl,
      );

      await _player.setAudioSource(
        source,
        preload: true,
        initialPosition: Duration.zero,
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
    } catch (error, stackTrace) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _lastError = error;

      debugPrint(
        '🔴 CHAMELEON PREPARE ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      if (_preparingRequestId == requestId) {
        _isPreparing = false;
      }
    }
  }
  Future<void> clearSource() async {
    _requestId++;

    try {
      await _player.stop();
    } finally {
      _loadedSongId = null;
      _loadedStreamUrl = null;
      _isPreparing = false;
      _lastError = null;
    }
  }
  bool _isCurrentRequest(
      int requestId,
      ) {
    return requestId == _requestId;
  }
  Future<void> dispose() async {
    _requestId++;

    _loadedSongId = null;
    _loadedStreamUrl = null;
    _isPreparing = false;
    _lastError = null;

    await _player.dispose();
  }
}