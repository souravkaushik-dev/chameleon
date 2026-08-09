import 'song.dart';

enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

class PlaybackState {
  final Song? currentSong;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  const PlaybackState({
    this.currentSong,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
  });

  PlaybackState copyWith({
    Song? currentSong,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
  }) {
    return PlaybackState(
      currentSong: currentSong ?? this.currentSong,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}