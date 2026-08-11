import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'settings_service.dart';

class AudioPlayerService {
  final AndroidEqualizer _equalizer = AndroidEqualizer();

  final SettingsService _settingsService;

  late final AudioPlayer _player;
  String? _loadedSongId;
  String? _loadedStreamUrl;

  int _requestId = 0;

  bool _isPreparing = false;
  int _preparingRequestId = 0;

  Object? _lastError;
  bool _equalizerEnabled = false;

  List<double> _equalizerGains = [];

  double _userVolume = 1.0;
  bool _normalizationApplied = false;
  AudioPlayerService({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService() {
    _settingsService.addListener(_onSettingsChanged);

    _player = AudioPlayer(
      userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 '
          '(KHTML, like Gecko) '
          'Version/17.0 Mobile/15E148 Safari/604.1',
      useLazyPreparation: true,
      useProxyForRequestHeaders: false,
      audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]),
    );

    _listenToPlayerErrors();
    _listenToPlaybackEvents();
    _listenToDuration();

    unawaited(initializeEqualizer());
  }

  SettingsService get settingsService => _settingsService;

  bool get highQualityEnabled => _settingsService.highQuality;

  bool get normalizeEnabled => _settingsService.normalize;

  bool get crossfadeEnabled => _settingsService.crossfade;

  bool get gaplessEnabled => _settingsService.gapless;

  bool get autoplayEnabled => _settingsService.autoplay;

  bool get shouldUseGaplessQueue =>
      _settingsService.gapless;

  void _onSettingsChanged() {
    unawaited(applySettings());
  }

  Future<void> applySettings() async {
    try {
      if (_settingsService.normalize) {
        _normalizationApplied = true;
        await _player.setVolume(1.0);
      } else if (_normalizationApplied) {
        _normalizationApplied = false;
        await _player.setVolume(_userVolume);
      }
    } catch (_) {
    }
  }
  AudioPlayer get player => _player;
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
    return _loadedSongId != null && _loadedStreamUrl != null;
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

  MediaItem? get currentMediaItem {
    final tag = _player.sequenceState?.currentSource?.tag;

    if (tag is MediaItem) {
      return tag;
    }

    return null;
  }
  AndroidEqualizer get equalizer {
    return _equalizer;
  }

  bool get equalizerEnabled {
    return _equalizerEnabled;
  }

  List<double> get equalizerGains {
    return List.unmodifiable(_equalizerGains);
  }
  Future<void> initializeEqualizer() async {
    try {
      final parameters = await _equalizer.parameters;

      _equalizerGains = List<double>.filled(parameters.bands.length, 0.0);

      _equalizerEnabled = false;

      await _equalizer.setEnabled(false);
    } catch (_) {
      _equalizerGains = [];
      _equalizerEnabled = false;
    }
  }
  Future<AndroidEqualizerParameters?> getEqualizerParameters() async {
    try {
      return await _equalizer.parameters;
    } catch (_) {
      return null;
    }
  }
  Future<void> setEqualizerEnabled(bool enabled) async {
    try {
      await _equalizer.setEnabled(enabled);

      _equalizerEnabled = enabled;
    } catch (_) {
      _equalizerEnabled = false;
    }
  }
  Future<void> setEqualizerBandGain(int index, double gain) async {
    try {
      final parameters = await _equalizer.parameters;

      if (index < 0 || index >= parameters.bands.length) {
        return;
      }

      final band = parameters.bands[index];

      final clampedGain = gain.clamp(
        parameters.minDecibels,
        parameters.maxDecibels,
      );

      await band.setGain(clampedGain);

      if (index >= _equalizerGains.length) {
        _equalizerGains = List<double>.filled(parameters.bands.length, 0.0);
      }

      _equalizerGains[index] = clampedGain;
    } catch (_) {
    }
  }
  Future<void> setEqualizerGains(List<double> gains) async {
    try {
      final parameters = await _equalizer.parameters;

      final count = gains.length < parameters.bands.length
          ? gains.length
          : parameters.bands.length;

      for (int i = 0; i < count; i++) {
        final gain = gains[i].clamp(
          parameters.minDecibels,
          parameters.maxDecibels,
        );

        await parameters.bands[i].setGain(gain);
      }

      _equalizerGains = List<double>.generate(parameters.bands.length, (index) {
        if (index < gains.length) {
          return gains[index].clamp(
            parameters.minDecibels,
            parameters.maxDecibels,
          );
        }

        return 0.0;
      });
    } catch (_) {
    }
  }
  Future<void> resetEqualizer() async {
    try {
      final parameters = await _equalizer.parameters;

      for (final band in parameters.bands) {
        await band.setGain(0.0);
      }

      _equalizerGains = List<double>.filled(parameters.bands.length, 0.0);
    } catch (_) {
    }
  }
  Future<void> applyEqualizerPreset(List<double> gains) async {
    await setEqualizerGains(gains);
  }
  void _listenToPlayerErrors() {
    _player.errorStream.listen((Object error) {
      _lastError = error;
    });
  }
  void _listenToDuration() {
    _player.durationStream.listen((_) {});
  }
  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen(
          (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _lastError = error;
      },
    );
  }
  Future<void> playSong(Song song) async {
    await applySettings();

    final streamUrl = song.streamUrl?.trim();

    if (streamUrl == null || streamUrl.isEmpty) {
      throw Exception('Song does not have a playable stream.');
    }

    final requestId = ++_requestId;

    _lastError = null;
if (_loadedSongId == song.id && _loadedStreamUrl == streamUrl) {
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
      final source = _createSource(song, streamUrl);
if (_player.audioSource != null) {
        try {
          await _player.stop();
        } catch (_) {
        }
      }

      if (!_isCurrentRequest(requestId)) {
        return;
      }
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
await play();
    } on PlayerInterruptedException {
      if (_isCurrentRequest(requestId)) {
        rethrow;
      }
    } catch (error) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _lastError = error;

      rethrow;
    } finally {
      if (_preparingRequestId == requestId) {
        _isPreparing = false;
      }
    }
  }
  MediaItem _mediaItemFor(Song song) {
    final thumbnail = song.thumbnailUrl?.trim();

    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: 'Chameleon',
      artUri: thumbnail != null && thumbnail.isNotEmpty
          ? Uri.tryParse(thumbnail)
          : null,

      playable: true,
    );
  }
  AudioSource _createSource(Song song, String streamUrl) {
    final uri = Uri.parse(streamUrl);

    return AudioSource.uri(uri, tag: _mediaItemFor(song));
  }

  Future<void> loadGaplessQueue(
      List<Song> songs, {
        int initialIndex = 0,
        bool startPlaying = true,
      }) async {
    final validSongs = songs
        .where(
          (song) =>
      song.streamUrl != null &&
          song.streamUrl!.trim().isNotEmpty,
    )
        .toList();

    if (validSongs.isEmpty) {
      throw Exception('Queue does not contain playable streams.');
    }

    final safeIndex = initialIndex.clamp(
      0,
      validSongs.length - 1,
    );

    final requestId = ++_requestId;
    _isPreparing = true;
    _preparingRequestId = requestId;

    try {
      final children = validSongs
          .map(
            (song) => _createSource(
          song,
          song.streamUrl!.trim(),
        ),
      )
          .toList();

      final playlist = ConcatenatingAudioSource(
        children: children,
        useLazyPreparation: true,
      );

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      try {
        await _player.stop();
      } catch (_) {
      }

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      await _player.setAudioSource(
        playlist,
        initialIndex: safeIndex,
        initialPosition: Duration.zero,
        preload: true,
      );

      if (!_isCurrentRequest(requestId)) {
        return;
      }

      final current = validSongs[safeIndex];

      _loadedSongId = current.id;
      _loadedStreamUrl = current.streamUrl!.trim();
      _isPreparing = false;

      if (startPlaying) {
        await play();
      }
    } on PlayerInterruptedException {
      if (_isCurrentRequest(requestId)) {
        rethrow;
      }
    } catch (error) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _lastError = error;
      rethrow;
    } finally {
      if (_preparingRequestId == requestId) {
        _isPreparing = false;
      }
    }
  }
  Future<bool> appendGaplessSong(Song song) async {
    final streamUrl = song.streamUrl?.trim();

    if (streamUrl == null || streamUrl.isEmpty) {
      return false;
    }

    final source = _player.audioSource;

    if (source is! ConcatenatingAudioSource) {
      return false;
    }

    await source.add(
      _createSource(song, streamUrl),
    );

    return true;
  }

  bool get hasGaplessQueue =>
      _player.audioSource is ConcatenatingAudioSource;

  int? get gaplessCurrentIndex => _player.currentIndex;

  int get gaplessQueueLength {
    final source = _player.audioSource;

    if (source is ConcatenatingAudioSource) {
      return source.length;
    }

    return 0;
  }

  Future<void> clearGaplessQueue() async {
    if (!hasGaplessQueue) {
      return;
    }

    await clearSource();
  }

  Future<void> skipToGaplessIndex(int index) async {
    final source = _player.audioSource;

    if (source is! ConcatenatingAudioSource) {
      return;
    }

    if (index < 0 || index >= source.length) {
      return;
    }

    await _player.seek(
      Duration.zero,
      index: index,
    );
  }
  Future<void> play() async {
    await applySettings();

    try {
      await _player.play();
    } catch (error) {
      _lastError = error;

      rethrow;
    }
  }
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (error) {
      _lastError = error;

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

      if (_settingsService.normalize) {
        await _player.setVolume(1.0);
      } else {
        await _player.setVolume(_userVolume);
      }
    }
  }
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  Future<void> setVolume(double volume) async {
    final safeVolume =
    volume.clamp(0.0, 1.0).toDouble();

    _userVolume = safeVolume;

    if (_settingsService.normalize) {
      _normalizationApplied = true;
      await _player.setVolume(1.0);
      return;
    }

    _normalizationApplied = false;
    await _player.setVolume(safeVolume);
  }

  double get volume => _userVolume;
  Future<void> prepareSong(Song song) async {
    final streamUrl = song.streamUrl?.trim();

    if (streamUrl == null || streamUrl.isEmpty) {
      throw Exception('Song does not have a playable stream.');
    }
if (_loadedSongId == song.id && _loadedStreamUrl == streamUrl) {
      return;
    }

    final requestId = ++_requestId;

    _isPreparing = true;
    _preparingRequestId = requestId;

    try {
      final source = _createSource(song, streamUrl);

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
    } catch (error) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _lastError = error;

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

      if (_settingsService.normalize) {
        await _player.setVolume(1.0);
      } else {
        await _player.setVolume(_userVolume);
      }
    }
  }
  bool _isCurrentRequest(int requestId) {
    return requestId == _requestId;
  }
  Future<void> dispose() async {
    _requestId++;

    _settingsService.removeListener(_onSettingsChanged);

    _loadedSongId = null;
    _loadedStreamUrl = null;
    _isPreparing = false;
    _lastError = null;
    _userVolume = 1.0;
    _normalizationApplied = false;

    try {
      await _equalizer.setEnabled(false);
    } catch (_) {}

    await _player.dispose();
  }
}