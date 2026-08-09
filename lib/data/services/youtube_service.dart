import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song.dart';

class YoutubeService {
  final YoutubeExplode _youtube = YoutubeExplode();

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

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
      final id = video.id.value;

      // Only accept actual videos.
      if (id.isEmpty) {
        continue;
      }

      // Prevent duplicate YouTube videos.
      if (!seenIds.add(id)) {
        continue;
      }

      songs.add(
        Song(
          id: id,
          title: video.title,
          artist: video.author,
          thumbnailUrl:
          'https://i.ytimg.com/vi/${video.id.value}/maxresdefault.jpg',
          duration: video.duration,
          youtubeUrl:
          'https://www.youtube.com/watch?v=$id',
        ),
      );

      if (songs.length >= limit) {
        break;
      }
    }

    return songs;
  }

  // ---------------------------------------------------------------------------
  // GET SONG
  // ---------------------------------------------------------------------------

  Future<Song> getSong(
      String videoId,
      ) async {
    final video = await _youtube.videos.get(
      videoId,
    );

    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      duration: video.duration,
      youtubeUrl:
      'https://www.youtube.com/watch?v=${video.id.value}',
    );
  }

  // ---------------------------------------------------------------------------
  // AUDIO STREAM
  // ---------------------------------------------------------------------------

  Future<String> getAudioStreamUrl(
      String videoId,
      ) async {
    final manifest =
    await _youtube.videos.streams.getManifest(
      videoId,
      ytClients: [
        YoutubeApiClient.androidVr,
        YoutubeApiClient.ios,
      ],
    );

    final audioStreams =
    manifest.audioOnly.toList();

    if (audioStreams.isEmpty) {
      throw Exception(
        'No audio-only stream found for $videoId.',
      );
    }

    audioStreams.sort(
          (a, b) => b.bitrate.compareTo(
        a.bitrate,
      ),
    );

    return audioStreams.first.url.toString();
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  void dispose() {
    _youtube.close();
  }
}