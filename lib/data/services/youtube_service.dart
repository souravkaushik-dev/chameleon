import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song.dart';

const customAndroidVr = YoutubeApiClient(
  {
    'context': {
      'client': {
        'clientName': 'ANDROID_VR',
        'clientVersion': '1.65.10',
        'deviceModel': 'Quest 3',
        'osVersion': '12L',
        'osName': 'Android',
        'androidSdkVersion': '32',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
      'contextClientName': 28,
      'requireJsPlayer': false,
    },
  },
  'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
);

final customClients = [
  customAndroidVr,
];

class YoutubeService {
  final YoutubeExplode _youtube = YoutubeExplode();

  final Map<String, Future<String>> _streamRequests = {};

  String _thumbnailUrl(String videoId) {
    return 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
  }

  Future<List<Song>> search(
      String query, {
        int limit = 30,
      }) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final results = await _youtube.search.search(
      trimmedQuery,
    );

    final songs = <Song>[];
    final seenIds = <String>{};

    for (final video in results) {
      final id = video.id.value.trim();

      if (id.isEmpty) {
        continue;
      }

      if (!seenIds.add(id)) {
        continue;
      }

      songs.add(
        Song(
          id: id,
          title: video.title,
          artist: video.author,
          thumbnailUrl: _thumbnailUrl(id),
          duration: video.duration,
          youtubeUrl: 'https://www.youtube.com/watch?v=$id',
        ),
      );

      if (songs.length >= limit) {
        break;
      }
    }

    return songs;
  }

  Future<Song> getSong(
      String videoId,
      ) async {
    final trimmedId = videoId.trim();

    if (trimmedId.isEmpty) {
      throw Exception(
        'YouTube video ID is empty.',
      );
    }

    final video = await _youtube.videos.get(
      trimmedId,
    );

    final id = video.id.value;

    return Song(
      id: id,
      title: video.title,
      artist: video.author,
      thumbnailUrl: _thumbnailUrl(id),
      duration: video.duration,
      youtubeUrl: 'https://www.youtube.com/watch?v=$id',
    );
  }

  Future<String> getAudioStreamUrl(
      String videoId,
      ) async {
    final trimmedId = videoId.trim();

    if (trimmedId.isEmpty) {
      throw Exception(
        'YouTube video ID is empty.',
      );
    }

    final existingRequest =
    _streamRequests[trimmedId];

    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _resolveAudioStreamUrl(
      trimmedId,
    );

    _streamRequests[trimmedId] = request;

    try {
      return await request;
    } finally {
      if (identical(
        _streamRequests[trimmedId],
        request,
      )) {
        _streamRequests.remove(
          trimmedId,
        );
      }
    }
  }

  Future<String> _resolveAudioStreamUrl(
      String videoId,
      ) async {
    try {
      final manifest =
      await _youtube.videos.streams.getManifest(
        videoId,
        ytClients: customClients,
      );

      final audioStreams =
      manifest.audioOnly.toList();

      if (audioStreams.isEmpty) {
        throw Exception(
          'No audio-only stream found for $videoId.',
        );
      }

      final compatibleStreams =
      audioStreams.where(
            (stream) {
          final container =
          stream.container.name.toLowerCase();

          final codec =
          stream.audioCodec.toLowerCase();

          final isMp4 =
              container == 'mp4';

          final isAac =
              codec.contains('mp4a') ||
                  codec.contains('aac');

          return isMp4 && isAac;
        },
      ).toList();

      if (compatibleStreams.isEmpty) {
        throw Exception(
          'No MP4/AAC audio stream found for $videoId.',
        );
      }

      compatibleStreams.sort(
            (a, b) => b.bitrate.compareTo(
          a.bitrate,
        ),
      );

      final selected =
          compatibleStreams.first;

      final selectedUrl =
      selected.url.toString().trim();

      if (selectedUrl.isEmpty) {
        throw Exception(
          'YouTube returned an empty audio stream URL.',
        );
      }

      return selectedUrl;
    } on RequestLimitExceededException {
      rethrow;
    }
  }

  void clearStreamRequest(
      String videoId,
      ) {
    _streamRequests.remove(
      videoId.trim(),
    );
  }

  void clearStreamRequests() {
    _streamRequests.clear();
  }

  void dispose() {
    _streamRequests.clear();
    _youtube.close();
  }
}