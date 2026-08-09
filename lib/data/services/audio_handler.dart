import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'audio_player_service.dart';
import 'queue_service.dart';

class ChameleonAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayerService playerService;
  final QueueService queueService;

  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;

  ChameleonAudioHandler({
    required this.playerService,
    required this.queueService,
  }) {
    _bindPlayer();
  }

  // ===========================================================================
  // PLAYER STREAMS
  // ===========================================================================

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  void _bindPlayer() {
    _playingSubscription =
        playerService.playingStream.listen((playing) {
          _broadcastState(
            playing: playing,
          );
        });

    _positionSubscription =
        playerService.positionStream.listen((position) {
          _broadcastState(
            position: position,
          );
        });

    _durationSubscription =
        playerService.durationStream.listen((duration) {
          _broadcastState(
            duration: duration,
          );
        });

    _stateSubscription =
        playerService.playerStateStream.listen((state) {
          _broadcastProcessingState(state);
        });
  }

  // ===========================================================================
  // MEDIA ITEM
  // ===========================================================================

  void updateSong(
      Song song,
      ) {
    final item = _toMediaItem(song);

    mediaItem.add(item);

    _syncQueue();
  }

  MediaItem _toMediaItem(
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
  // QUEUE
  // ===========================================================================

  void _syncQueue() {
    final songs =
        queueService.queue;

    final mediaItems = songs
        .map(_toMediaItem)
        .toList();

    queue.add(mediaItems);

    final current =
        queueService.currentSong;

    if (current != null) {
      mediaItem.add(
        _toMediaItem(current),
      );
    }
  }

  // ===========================================================================
  // PLAY
  // ===========================================================================

  @override
  Future<void> play() async {
    playerService.play();
  }

  // ===========================================================================
  // PAUSE
  // ===========================================================================

  @override
  Future<void> pause() async {
    await playerService.pause();
  }

  // ===========================================================================
  // STOP
  // ===========================================================================

  @override
  Future<void> stop() async {
    await playerService.stop();

    await super.stop();
  }

  // ===========================================================================
  // SEEK
  // ===========================================================================

  @override
  Future<void> seek(
      Duration position,
      ) async {
    await playerService.seek(
      position,
    );
  }

  // ===========================================================================
  // NEXT
  // ===========================================================================

  @override
  Future<void> skipToNext() async {
    final callback = onNext;

    if (callback != null) {
      await callback();
      return;
    }

    final song =
    queueService.next();

    if (song == null) {
      return;
    }

    _syncQueue();
  }

  // ===========================================================================
  // PREVIOUS
  // ===========================================================================

  @override
  Future<void> skipToPrevious() async {
    final callback = onPrevious;

    if (callback != null) {
      await callback();
      return;
    }

    final song =
    queueService.previous();

    if (song == null) {
      await playerService.seek(
        Duration.zero,
      );
      return;
    }

    _syncQueue();
  }

  // ===========================================================================
  // QUEUE ITEM
  // ===========================================================================

  @override
  Future<void> skipToQueueItem(
      int index,
      ) async {
    final songs =
        queueService.queue;

    if (index < 0 ||
        index >= songs.length) {
      return;
    }

    final song =
    songs[index];

    final currentIndex =
        queueService.currentIndex;

    if (index == currentIndex) {
      await playerService.seek(
        Duration.zero,
      );
      return;
    }

    if (index > currentIndex) {
      for (
      var i = currentIndex;
      i < index;
      i++
      ) {
        queueService.next();
      }
    } else {
      for (
      var i = currentIndex;
      i > index;
      i--
      ) {
        queueService.previous();
      }
    }

    final callback = onNext;

    if (callback != null) {
      await callback();
    }

    _syncQueue();
  }

  // ===========================================================================
  // PROCESSING STATE
  // ===========================================================================

  void _broadcastProcessingState(
      PlayerState state,
      ) {
    final processingState =
    switch (state.processingState) {
      ProcessingState.idle =>
      AudioProcessingState.idle,

      ProcessingState.loading =>
      AudioProcessingState.loading,

      ProcessingState.buffering =>
      AudioProcessingState.buffering,

      ProcessingState.ready =>
      AudioProcessingState.ready,

      ProcessingState.completed =>
      AudioProcessingState.completed,
    };

    _broadcastState(
      processingState:
      processingState,
      playing:
      state.playing,
    );
  }

  // ===========================================================================
  // PLAYBACK STATE
  // ===========================================================================

  void _broadcastState({
    bool? playing,
    Duration? position,
    Duration? duration,
    AudioProcessingState? processingState,
  }) {
    final current =
        playbackState.value;

    final controls = <MediaControl>[
      MediaControl.skipToPrevious,

      playing == true
          ? MediaControl.pause
          : MediaControl.play,

      MediaControl.skipToNext,
    ];

    playbackState.add(
      current.copyWith(
        controls: controls,

        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },

        androidCompactActionIndices: const [
          0,
          1,
          2,
        ],

        processingState:
        processingState ??
            current.processingState,

        playing:
        playing ??
            current.playing,

        updatePosition:
        position ??
            current.position,

        bufferedPosition:
        playerService
            .player
            .bufferedPosition,

        speed:
        playerService
            .player
            .speed,
      ),
    );
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  Future<void> disposeHandler() async {
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _stateSubscription?.cancel();
  }
}