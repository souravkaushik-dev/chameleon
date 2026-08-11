import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/song.dart';

class JioSaavnService {
  static const String _baseUrl =
      'https://saavn.sumit.co';

  static const Duration _requestTimeout =
  Duration(seconds: 4);

  final http.Client _client;

  JioSaavnService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Song>> search(
      String query, {
        int limit = 30,
      }) async {
    final trimmedQuery =
    query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '$_baseUrl/api/search/songs',
    ).replace(
      queryParameters: {
        'query': trimmedQuery,
        'page': '1',
        'limit': limit.toString(),
      },
    );

    final response = await _client
        .get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'JioSaavn returned HTTP '
            '${response.statusCode}.',
      );
    }

    final decoded =
    jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid JioSaavn response.',
      );
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      return [];
    }

    final results = data['results'];

    if (results is! List) {
      return [];
    }

    final songs = <Song>[];
    final seenIds = <String>{};

    for (final item in results) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final song =
      _mapSong(item);

      if (song == null) {
        continue;
      }

      if (!seenIds.add(song.id)) {
        continue;
      }

      songs.add(song);

      if (songs.length >= limit) {
        break;
      }
    }

    return songs;
  }

  Future<List<Song>> discover({
    int limit = 40,
  }) async {
    final currentYear =
        DateTime.now().year;

    final queries = <String>[
      '$currentYear new songs',
      '$currentYear latest songs',
      '$currentYear new music',
      'latest Hindi songs $currentYear',
      'latest Bollywood songs $currentYear',
      'latest English songs $currentYear',
    ];

    final songs = <Song>[];
    final seenIds = <String>{};
    final seenTitles = <String>{};

    for (final query in queries) {
      if (songs.length >= limit) {
        break;
      }

      try {
        final results = await search(
          query,
          limit: 20,
        );

        for (final song in results) {
          if (songs.length >= limit) {
            break;
          }

          if (!seenIds.add(song.id)) {
            continue;
          }

          final titleKey =
          _normalizeTitle(song.title);

          if (titleKey.isNotEmpty &&
              !seenTitles.add(titleKey)) {
            continue;
          }

          songs.add(song);
        }
      } catch (_) {
        continue;
      }
    }

    songs.sort(
          (a, b) {
        final yearA =
            a.releaseYear ?? 0;

        final yearB =
            b.releaseYear ?? 0;

        return yearB.compareTo(yearA);
      },
    );

    return songs.take(limit).toList();
  }

  Future<String> getAudioStreamUrl(
      Song song,
      ) async {
    final query =
    '${song.title} ${song.artist}'
        .trim();

    if (query.isEmpty) {
      throw Exception(
        'Unable to search JioSaavn.',
      );
    }

    final results =
    await search(
      query,
      limit: 10,
    );

    if (results.isEmpty) {
      throw Exception(
        'No matching JioSaavn song found.',
      );
    }

    final match =
    _findBestMatch(
      results,
      song,
    );

    if (match == null) {
      throw Exception(
        'No suitable JioSaavn match found.',
      );
    }

    final jioSaavnId =
    match.id.replaceFirst(
      'saavn_',
      '',
    );

    return _getDownloadUrl(
      jioSaavnId,
    );
  }

  Future<String> _getDownloadUrl(
      String songId,
      ) async {
    final uri = Uri.parse(
      '$_baseUrl/api/songs/$songId',
    );

    final response = await _client
        .get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to load JioSaavn song.',
      );
    }

    final decoded =
    jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid JioSaavn song response.',
      );
    }

    final data = decoded['data'];

    final songData =
    data is List &&
        data.isNotEmpty
        ? data.first
        : data;

    if (songData
    is! Map<String, dynamic>) {
      throw Exception(
        'Invalid JioSaavn song data.',
      );
    }

    final downloads =
    songData['downloadUrl'];

    if (downloads is! List) {
      throw Exception(
        'No JioSaavn download URL.',
      );
    }

    final candidates =
    <Map<String, dynamic>>[];

    for (final item in downloads) {
      if (item
      is! Map<String, dynamic>) {
        continue;
      }

      final url =
      item['url']
          ?.toString()
          .trim();

      if (url == null ||
          url.isEmpty) {
        continue;
      }

      candidates.add(item);
    }

    if (candidates.isEmpty) {
      throw Exception(
        'No playable JioSaavn URL.',
      );
    }

    const qualities = [
      '320kbps',
      '160kbps',
      '96kbps',
      '48kbps',
    ];

    for (final quality in qualities) {
      for (final candidate
      in candidates) {
        final candidateQuality =
        candidate['quality']
            ?.toString()
            .toLowerCase();

        if (candidateQuality ==
            quality.toLowerCase()) {
          return candidate['url']
              .toString()
              .trim();
        }
      }
    }

    return candidates.last['url']
        .toString()
        .trim();
  }

  Song? _mapSong(
      Map<String, dynamic> item,
      ) {
    final id =
        item['id']
            ?.toString()
            .trim() ??
            '';

    final title =
        item['name']
            ?.toString()
            .trim() ??
            '';

    if (id.isEmpty ||
        title.isEmpty) {
      return null;
    }

    final artist =
    _artistName(item);

    final album =
    _albumName(item);

    final thumbnailUrl =
    _imageUrl(item);

    final durationSeconds =
    int.tryParse(
      item['duration']
          ?.toString() ??
          '',
    );

    final releaseYear =
    _getReleaseYear(item);

    return Song(
      id: 'saavn_$id',
      title: title,
      artist: artist.isEmpty
          ? 'Unknown artist'
          : artist,
      album: album,
      thumbnailUrl:
      thumbnailUrl,
      duration:
      durationSeconds != null
          ? Duration(
        seconds:
        durationSeconds,
      )
          : null,
      youtubeUrl: null,
      streamUrl: null,
      releaseYear:
      releaseYear,
    );
  }

  String _artistName(
      Map<String, dynamic> item,
      ) {
    final primaryArtists =
    item['primaryArtists']
        ?.toString()
        .trim();

    if (primaryArtists != null &&
        primaryArtists.isNotEmpty) {
      return primaryArtists;
    }

    final artists =
    item['artists'];

    if (artists
    is Map<String, dynamic>) {
      final primary =
      artists['primary'];

      if (primary is List) {
        return primary
            .map(
              (artist) {
            if (artist
            is Map<String, dynamic>) {
              return artist['name']
                  ?.toString()
                  .trim() ??
                  '';
            }

            return artist
                .toString()
                .trim();
          },
        )
            .where(
              (name) =>
          name.isNotEmpty,
        )
            .join(', ');
      }
    }

    return '';
  }

  String? _albumName(
      Map<String, dynamic> item,
      ) {
    final album =
    item['album'];

    if (album
    is Map<String, dynamic>) {
      final name =
      album['name']
          ?.toString()
          .trim();

      if (name != null &&
          name.isNotEmpty) {
        return name;
      }
    }

    final albumName =
    item['albumName']
        ?.toString()
        .trim();

    if (albumName != null &&
        albumName.isNotEmpty) {
      return albumName;
    }

    return null;
  }

  String? _imageUrl(
      Map<String, dynamic> item,
      ) {
    final image =
    item['image'];

    if (image is List &&
        image.isNotEmpty) {
      for (final value
      in image.reversed) {
        if (value
        is Map<String, dynamic>) {
          final url =
          value['url']
              ?.toString()
              .trim();

          if (url != null &&
              url.isNotEmpty) {
            return url;
          }
        }

        final url =
        value.toString().trim();

        if (url.isNotEmpty &&
            url != 'null') {
          return url;
        }
      }
    }

    if (image is String &&
        image.trim().isNotEmpty) {
      return image.trim();
    }

    return null;
  }

  int? _getReleaseYear(
      Map<String, dynamic> item,
      ) {
    final possibleValues = <dynamic>[
      item['year'],
      item['releaseYear'],
      item['release_date'],
      item['releaseDate'],
    ];

    final album = item['album'];

    if (album is Map<String, dynamic>) {
      possibleValues.add(
        album['year'],
      );

      possibleValues.add(
        album['releaseDate'],
      );
    }

    for (final value in possibleValues) {
      if (value == null) {
        continue;
      }

      final text =
      value.toString().trim();

      if (text.isEmpty) {
        continue;
      }

      final directYear =
      int.tryParse(text);

      if (directYear != null &&
          directYear >= 1900 &&
          directYear <= 2100) {
        return directYear;
      }

      final match = RegExp(
        r'\b(19|20)\d{2}\b',
      ).firstMatch(text);

      if (match != null) {
        return int.tryParse(
          match.group(0)!,
        );
      }
    }

    return null;
  }

  Song? _findBestMatch(
      List<Song> songs,
      Song target,
      ) {
    Song? bestMatch;
    double bestScore = 0;

    final targetTitle =
    _normalizeTitle(
      target.title,
    );

    final targetArtist =
    _normalizeArtist(
      target.artist,
    );

    for (final song in songs) {
      final resultTitle =
      _normalizeTitle(
        song.title,
      );

      final resultArtist =
      _normalizeArtist(
        song.artist,
      );

      if (resultTitle.isEmpty) {
        continue;
      }

      final titleScore =
      _similarity(
        targetTitle,
        resultTitle,
      );

      final artistScore =
      _similarity(
        targetArtist,
        resultArtist,
      );

      double score =
          titleScore * 0.75 +
              artistScore * 0.25;

      if (_sameWords(
        targetTitle,
        resultTitle,
      )) {
        score += 0.10;
      }

      if (targetArtist.isNotEmpty &&
          resultArtist.isNotEmpty &&
          _sameWords(
            targetArtist,
            resultArtist,
          )) {
        score += 0.05;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = song;
      }
    }

    if (bestScore < 0.50) {
      return null;
    }

    return bestMatch;
  }

  String _normalizeTitle(
      String value,
      ) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'\((official|official video|official audio|lyrics?|audio|video|visualizer|remastered).*?\)',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'\[(official|official video|official audio|lyrics?|audio|video|visualizer|remastered).*?\]',
        caseSensitive: false,
      ),
      '',
    )
        .replaceAll(
      RegExp(
        r'\b(official|lyrics?|audio|video|visualizer)\b',
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

  String _normalizeArtist(
      String value,
      ) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'\b(feat\.?|ft\.?|featuring)\b',
        caseSensitive: false,
      ),
      ' ',
    )
        .replaceAll(
      '&',
      ' ',
    )
        .replaceAll(
      ',',
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  bool _sameWords(
      String first,
      String second,
      ) {
    final firstWords =
    first
        .split(' ')
        .where(
          (word) =>
      word.isNotEmpty,
    )
        .toSet();

    final secondWords =
    second
        .split(' ')
        .where(
          (word) =>
      word.isNotEmpty,
    )
        .toSet();

    if (firstWords.isEmpty ||
        secondWords.isEmpty) {
      return false;
    }

    final intersection =
    firstWords.intersection(
      secondWords,
    );

    final smaller =
    firstWords.length <
        secondWords.length
        ? firstWords.length
        : secondWords.length;

    return intersection.length /
        smaller >=
        0.75;
  }

  double _similarity(
      String a,
      String b,
      ) {
    if (a.isEmpty ||
        b.isEmpty) {
      return 0;
    }

    if (a == b) {
      return 1;
    }

    if (a.contains(b) ||
        b.contains(a)) {
      return 0.85;
    }

    final aWords =
    a.split(' ').toSet();

    final bWords =
    b.split(' ').toSet();

    final intersection =
    aWords.intersection(
      bWords,
    );

    final union =
    aWords.union(
      bWords,
    );

    if (union.isEmpty) {
      return 0;
    }

    return intersection.length /
        union.length;
  }

  void dispose() {
    _client.close();
  }
}