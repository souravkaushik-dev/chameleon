import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer(
    userAgent:
    'Mozilla/5.0 (Linux; Android 10; K) '
        'AppleWebKit/537.36 '
        '(KHTML, like Gecko) '
        'Chrome/131.0.0.0 Mobile Safari/537.36',
  );

  AudioPlayer get player => _player;

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

  Future<void> playSong(Song song) async {
    final streamUrl = song.streamUrl;

    if (streamUrl == null || streamUrl.isEmpty) {
      throw Exception(
        'Song does not have a playable stream.',
      );
    }

    final uri = Uri.parse(streamUrl);

    final source = AudioSource.uri(
      uri,
      headers: {
        'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; K) '
            'AppleWebKit/537.36 '
            '(KHTML, like Gecko) '
            'Chrome/131.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://www.youtube.com/',
        'Origin': 'https://www.youtube.com',
      },
      tag: song.id,
    );

    await _player.setAudioSource(source);

    await _player.play();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(
      volume.clamp(0.0, 1.0),
    );
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}