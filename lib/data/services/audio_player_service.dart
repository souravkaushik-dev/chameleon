import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerService {
  // REAL ANDROID EQUALIZER
  //
  // This is a native Android audio effect.
  //
  // On Android:
  //   AndroidEqualizer -> AudioPipeline -> AudioPlayer
  //
  // On iOS/macOS/web:
  //   just_audio does not provide this Android equalizer.
  //
  // The same service can still be used on those platforms; the equalizer
  // simply won't modify the audio there.
  final AndroidEqualizer _equalizer =
  AndroidEqualizer();

  late final AudioPlayer _player;
  // STATE
  String? _loadedSongId;
  String? _loadedStreamUrl;

  int _requestId = 0;

  bool _isPreparing = false;
  int _preparingRequestId = 0;

  Object? _lastError;
  // EQUALIZER STATE
  bool _equalizerEnabled = false;

  List<double> _equalizerGains = [];
  // CONSTRUCTOR
  AudioPlayerService() {
    _player = AudioPlayer(
      userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 '
          '(KHTML, like Gecko) '
          'Version/17.0 Mobile/15E148 Safari/604.1',
      useLazyPreparation: true,
      useProxyForRequestHeaders: false,
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _equalizer,
        ],
      ),
    );

    _listenToPlayerErrors();
    _listenToPlaybackEvents();
    _listenToDuration();
  }
  // PLAYER
  AudioPlayer get player => _player;
  // BASIC STATE
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
  // EQUALIZER GETTERS
  AndroidEqualizer get equalizer {
    return _equalizer;
  }

  bool get equalizerEnabled {
    return _equalizerEnabled;
  }

  List<double> get equalizerGains {
    return List.unmodifiable(
      _equalizerGains,
    );
  }
  // INITIALIZE EQUALIZER
  Future<void> initializeEqualizer() async {
    try {
      final parameters = await _equalizer.parameters;

      _equalizerGains = List<double>.filled(
        parameters.bands.length,
        0.0,
      );

      _equalizerEnabled = false;

      await _equalizer.setEnabled(false);
    } catch (_) {
      _equalizerGains = [];
      _equalizerEnabled = false;
    }
  }
  // EQUALIZER PARAMETERS
  Future<AndroidEqualizerParameters?>
  getEqualizerParameters() async {
    try {
      return await _equalizer.parameters;
    } catch (_) {
      return null;
    }
  }
  // EQUALIZER ENABLE / DISABLE
  Future<void> setEqualizerEnabled(
      bool enabled,
      ) async {
    try {
      await _equalizer.setEnabled(
        enabled,
      );

      _equalizerEnabled = enabled;
    } catch (_) {
      _equalizerEnabled = false;
    }
  }
  // SET SINGLE BAND GAIN
  Future<void> setEqualizerBandGain(
      int index,
      double gain,
      ) async {
    try {
      final parameters =
      await _equalizer.parameters;

      if (index < 0 ||
          index >= parameters.bands.length) {
        return;
      }

      final band =
      parameters.bands[index];

      final clampedGain =
      gain.clamp(
        parameters.minDecibels,
        parameters.maxDecibels,
      );

      await band.setGain(
        clampedGain,
      );

      if (index >=
          _equalizerGains.length) {
        _equalizerGains =
        List<double>.filled(
          parameters.bands.length,
          0.0,
        );
      }

      _equalizerGains[index] =
          clampedGain;
    } catch (_) {
      // Unsupported platform or unavailable
      // native equalizer.
    }
  }
  // SET ALL BAND GAINS
  Future<void> setEqualizerGains(
      List<double> gains,
      ) async {
    try {
      final parameters =
      await _equalizer.parameters;

      final count = gains.length <
          parameters.bands.length
          ? gains.length
          : parameters.bands.length;

      for (int i = 0; i < count; i++) {
        final gain = gains[i].clamp(
          parameters.minDecibels,
          parameters.maxDecibels,
        );

        await parameters.bands[i]
            .setGain(gain);
      }

      _equalizerGains =
      List<double>.generate(
        parameters.bands.length,
            (index) {
          if (index < gains.length) {
            return gains[index].clamp(
              parameters.minDecibels,
              parameters.maxDecibels,
            );
          }

          return 0.0;
        },
      );
    } catch (_) {
      // Unsupported platform.
    }
  }
  // RESET EQUALIZER
  Future<void> resetEqualizer() async {
    try {
      final parameters =
      await _equalizer.parameters;

      for (final band
      in parameters.bands) {
        await band.setGain(0.0);
      }

      _equalizerGains =
      List<double>.filled(
        parameters.bands.length,
        0.0,
      );
    } catch (_) {
      // Unsupported platform.
    }
  }
  // PRESET
  Future<void> applyEqualizerPreset(
      List<double> gains,
      ) async {
    await setEqualizerGains(
      gains,
    );
  }
  // PLAYER ERROR
  void _listenToPlayerErrors() {
    _player.errorStream.listen(
          (Object error) {
        _lastError = error;
      },
    );
  }
  // DURATION
  void _listenToDuration() {
    _player.durationStream.listen(
          (_) {},
    );
  }
  // PLAYBACK EVENTS
  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen(
          (_) {},
      onError: (
          Object error,
          StackTrace stackTrace,
          ) {
        _lastError = error;
      },
    );
  }
  // PLAY SONG
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

    _lastError = null;

    // -------------------------------------------------------------------------
    // SAME SOURCE
    // -------------------------------------------------------------------------

    if (_loadedSongId == song.id &&
        _loadedStreamUrl == streamUrl) {
      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      await play();

      return;
    }

    // -------------------------------------------------------------------------
    // NEW SOURCE
    // -------------------------------------------------------------------------

    await _loadSourceAndStart(
      song: song,
      streamUrl: streamUrl,
      requestId: requestId,
    );
  }
  // LOAD SOURCE + START
  Future<void> _loadSourceAndStart({
    required Song song,
    required String streamUrl,
    required int requestId,
  }) async {
    if (!_isCurrentRequest(
      requestId,
    )) {
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
      // STOP PREVIOUS SOURCE
      // -----------------------------------------------------------------------

      if (_player.audioSource != null) {
        try {
          await _player.stop();
        } catch (_) {
          // Ignore replacement errors.
        }
      }

      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      // -----------------------------------------------------------------------
      // LOAD
      // -----------------------------------------------------------------------

      await _player.setAudioSource(
        source,
        preload: false,
        initialPosition:
        Duration.zero,
      );

      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      _loadedSongId = song.id;
      _loadedStreamUrl = streamUrl;
      _isPreparing = false;

      // -----------------------------------------------------------------------
      // PLAY
      // -----------------------------------------------------------------------

      await play();
    } on PlayerInterruptedException {
      if (_isCurrentRequest(
        requestId,
      )) {
        rethrow;
      }
    } catch (error) {
      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      _lastError = error;

      rethrow;
    } finally {
      if (_preparingRequestId ==
          requestId) {
        _isPreparing = false;
      }
    }
  }
  // MEDIA ITEM
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

      // -----------------------------------------------------------------------
      // IMPORTANT
      //
      // Do not pass Song.duration here.
      //
      // just_audio determines duration from
      // the actual audio stream.
      // -----------------------------------------------------------------------

      artUri: thumbnail != null &&
          thumbnail.isNotEmpty
          ? Uri.tryParse(
        thumbnail,
      )
          : null,

      playable: true,
    );
  }
  // AUDIO SOURCE
  AudioSource _createSource(
      Song song,
      String streamUrl,
      ) {
    final uri =
    Uri.parse(streamUrl);

    return AudioSource.uri(
      uri,
      tag: _mediaItemFor(song),
    );
  }
  // PLAY
  Future<void> play() async {
    try {
      await _player.play();
    } catch (error) {
      _lastError = error;

      rethrow;
    }
  }
  // PAUSE
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (error) {
      _lastError = error;

      rethrow;
    }
  }
  // TOGGLE
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }
  // STOP
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
  // SEEK
  Future<void> seek(
      Duration position,
      ) async {
    await _player.seek(
      position,
    );
  }
  // VOLUME
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
  // PREPARE SONG
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

    // -------------------------------------------------------------------------
    // ALREADY LOADED
    // -------------------------------------------------------------------------

    if (_loadedSongId == song.id &&
        _loadedStreamUrl == streamUrl) {
      return;
    }

    final requestId =
    ++_requestId;

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
        initialPosition:
        Duration.zero,
      );

      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      _loadedSongId = song.id;
      _loadedStreamUrl = streamUrl;
    } on PlayerInterruptedException {
      if (_isCurrentRequest(
        requestId,
      )) {
        rethrow;
      }
    } catch (error) {
      if (!_isCurrentRequest(
        requestId,
      )) {
        return;
      }

      _lastError = error;

      rethrow;
    } finally {
      if (_preparingRequestId ==
          requestId) {
        _isPreparing = false;
      }
    }
  }
  // CLEAR SOURCE
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
  // REQUEST VALIDATION
  bool _isCurrentRequest(
      int requestId,
      ) {
    return requestId == _requestId;
  }
  // DISPOSE
  Future<void> dispose() async {
    _requestId++;

    _loadedSongId = null;
    _loadedStreamUrl = null;
    _isPreparing = false;
    _lastError = null;

    try {
      await _equalizer.setEnabled(
        false,
      );
    } catch (_) {}

    await _player.dispose();
  }
}