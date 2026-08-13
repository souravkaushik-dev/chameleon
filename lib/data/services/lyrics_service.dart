import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/song.dart';

class LyricsResult {
  final String? plainLyrics;
  final String? syncedLyrics;
  final bool instrumental;
  final String source;

  const LyricsResult({
    this.plainLyrics,
    this.syncedLyrics,
    this.instrumental = false,
    this.source = 'unknown',
  });

  bool get hasSyncedLyrics =>
      syncedLyrics != null && syncedLyrics!.trim().isNotEmpty;

  bool get hasPlainLyrics =>
      plainLyrics != null && plainLyrics!.trim().isNotEmpty;

  bool get isEmpty => !hasSyncedLyrics && !hasPlainLyrics;
}

class LyricsService {
  // Primary source.
  static const String _lrclibHost = 'lrclib.net';

  // JioSaavn's public web API is unofficial and can change without notice.
  // We use it only as a fallback when LRCLIB has no usable lyrics.
  static const String _jioSaavnHost = 'www.jiosaavn.com';

  static const Duration _timeout = Duration(seconds: 8);

  final http.Client _client;

  final Map<String, Future<LyricsResult?>> _requests = {};
  final Map<String, LyricsResult?> _cache = {};

  LyricsService({http.Client? client})
      : _client = client ?? http.Client();

  Future<LyricsResult?> getLyrics(
      Song song, {
        bool forceRefresh = false,
      }) async {
    final key = _cacheKey(song);

    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key];
    }

    final existing = _requests[key];
    if (existing != null) {
      return existing;
    }

    final request = _fetchWithFallback(song);
    _requests[key] = request;

    try {
      final result = await request;
      _cache[key] = result;
      return result;
    } finally {
      if (identical(_requests[key], request)) {
        _requests.remove(key);
      }
    }
  }

  /// Source order:
  ///
  /// 1. LRCLIB — preferred because it can provide synchronized LRC lyrics.
  /// 2. JioSaavn — fallback, especially useful for Indian/regional songs.
  Future<LyricsResult?> _fetchWithFallback(Song song) async {
    LyricsResult? result;

    try {
      result = await _fetchFromLrclib(song);
    } catch (_) {
      result = null;
    }

    if (result != null && !result.isEmpty && !result.instrumental) {
      return result;
    }

    // If LRCLIB returned no lyrics or marked the track instrumental, give
    // JioSaavn a chance before showing "lyrics unavailable".
    try {
      final jioResult = await _fetchFromJioSaavn(song);

      if (jioResult != null && !jioResult.isEmpty) {
        return jioResult;
      }
    } catch (_) {
      // Keep the UI silent. If both sources fail, the lyrics screen displays
      // its existing unavailable state.
    }

    // Preserve a genuine LRCLIB instrumental result if JioSaavn also fails.
    return result;
  }

  // ---------------------------------------------------------------------------
  // LRCLIB
  // ---------------------------------------------------------------------------

  Future<LyricsResult?> _fetchFromLrclib(Song song) async {
    final title = song.title.trim();
    final artist = song.artist.trim();

    if (title.isEmpty || artist.isEmpty) {
      return null;
    }

    final query = <String, String>{
      'track_name': title,
      'artist_name': artist,
    };

    final duration = song.duration;

    if (duration != null && duration > Duration.zero) {
      query['duration'] =
          (duration.inMilliseconds / 1000).toStringAsFixed(3);
    }

    final uri = Uri.https(
      _lrclibHost,
      '/api/get',
      query,
    );

    final response = await _client
        .get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent':
        'Chameleon/1.0 (https://github.com/souravkaushik-dev/chameleon)',
      },
    )
        .timeout(_timeout);

    if (response.statusCode == 404 || response.statusCode == 429) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final result = LyricsResult(
      plainLyrics: _clean(decoded['plainLyrics']),
      syncedLyrics: _clean(decoded['syncedLyrics']),
      instrumental: decoded['instrumental'] == true,
      source: 'LRCLIB',
    );

    return result.isEmpty && !result.instrumental ? null : result;
  }

  // ---------------------------------------------------------------------------
  // JioSaavn fallback
  // ---------------------------------------------------------------------------

  Future<LyricsResult?> _fetchFromJioSaavn(Song song) async {
    final title = song.title.trim();
    final artist = song.artist.trim();

    if (title.isEmpty || artist.isEmpty) {
      return null;
    }

    // Search JioSaavn by title + artist. We deliberately do not use the
    // YouTube ID because JioSaavn has its own song IDs.
    final search = await _jioSaavnSearch(
      '$title $artist',
    );

    if (search.isEmpty) {
      return null;
    }

    final candidate = _chooseBestJioSaavnSong(
      search,
      song,
    );

    if (candidate == null) {
      return null;
    }

    final songId = _stringValue(
      candidate['id'] ??
          candidate['songid'] ??
          candidate['songId'],
    );

    if (songId == null || songId.isEmpty) {
      return null;
    }

    // Fetch complete song metadata. This commonly contains lyrics_id and
    // has_lyrics, depending on the current JioSaavn response shape.
    final details = await _jioSaavnSongDetails(songId);

    final merged = <String, dynamic>{
      ...candidate,
      ...?details,
    };

    final hasLyrics = _boolValue(
      merged['has_lyrics'] ??
          merged['hasLyrics'] ??
          merged['hasLyricsAvailable'],
    );

    final lyricsId = _stringValue(
      merged['lyrics_id'] ??
          merged['lyricsId'],
    );

    // Some JioSaavn responses can already include lyrics.
    final inlineLyrics = _extractJioLyrics(merged);

    if (inlineLyrics != null && inlineLyrics.trim().isNotEmpty) {
      return LyricsResult(
        plainLyrics: inlineLyrics,
        source: 'JioSaavn',
      );
    }

    if (hasLyrics != true && (lyricsId == null || lyricsId.isEmpty)) {
      return null;
    }

    if (lyricsId == null || lyricsId.isEmpty) {
      return null;
    }

    final lyricsResponse = await _jioSaavnLyrics(lyricsId);

    final lyrics = _extractJioLyrics(
      lyricsResponse,
    );

    if (lyrics == null || lyrics.trim().isEmpty) {
      return null;
    }

    return LyricsResult(
      plainLyrics: lyrics,
      source: 'JioSaavn',
    );
  }

  Future<List<Map<String, dynamic>>> _jioSaavnSearch(
      String query,
      ) async {
    final uri = Uri.https(
      _jioSaavnHost,
      '/api.php',
      {
        '__call': 'search.getResults',
        '_format': 'json',
        '_marker': '0',
        'ctx': 'web6dot0',
        'q': query,
      },
    );

    final response = await _client
        .get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        'Referer': 'https://www.jiosaavn.com/',
      },
    )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }

    final decoded = _decodeJson(response.body);

    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final songs = decoded['songs'];

    if (songs is Map<String, dynamic>) {
      final data = songs['data'];

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList();
      }
    }

    // A few versions/wrappers return the data array directly.
    final data = decoded['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    return const [];
  }

  Future<Map<String, dynamic>?> _jioSaavnSongDetails(
      String songId,
      ) async {
    final uri = Uri.https(
      _jioSaavnHost,
      '/api.php',
      {
        '__call': 'song.getDetails',
        'cc': 'in',
        '_marker': '0',
        '_format': 'json',
        'pids': songId,
      },
    );

    final response = await _client
        .get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        'Referer': 'https://www.jiosaavn.com/',
      },
    )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = _decodeJson(response.body);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final direct = decoded[songId];

    if (direct is Map) {
      return Map<String, dynamic>.from(direct);
    }

    // Some wrappers return a single song object.
    if (decoded.containsKey('song')) {
      final songData = decoded['song'];

      if (songData is Map) {
        return Map<String, dynamic>.from(songData);
      }
    }

    return decoded;
  }

  Future<Map<String, dynamic>?> _jioSaavnLyrics(
      String lyricsId,
      ) async {
    final uri = Uri.https(
      _jioSaavnHost,
      '/api.php',
      {
        '__call': 'lyrics.getLyrics',
        'lyrics_id': lyricsId,
        'ctx': 'web6dot0',
        'api_version': '4',
        '_format': 'json',
        '_marker': '0',
      },
    );

    final response = await _client
        .get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        'Referer': 'https://www.jiosaavn.com/',
      },
    )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = _decodeJson(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  Map<String, dynamic>? _chooseBestJioSaavnSong(
      List<Map<String, dynamic>> results,
      Song target,
      ) {
    if (results.isEmpty) {
      return null;
    }

    final targetTitle = _normalise(target.title);
    final targetArtist = _normalise(target.artist);
    final targetDuration = target.duration?.inSeconds ?? 0;

    Map<String, dynamic>? best;
    var bestScore = double.negativeInfinity;

    for (final candidate in results.take(10)) {
      final title = _stringValue(
        candidate['title'] ??
            candidate['song'] ??
            candidate['song_name'] ??
            candidate['songName'],
      ) ??
          '';

      final artist = _stringValue(
        candidate['singers'] ??
            candidate['primary_artists'] ??
            candidate['primaryArtists'] ??
            candidate['artist'],
      ) ??
          '';

      final duration = _parseDurationSeconds(
        candidate['duration'],
      );

      final titleScore = _similarity(
        targetTitle,
        _normalise(title),
      );

      final artistScore = _similarity(
        targetArtist,
        _normalise(artist),
      );

      var score = (titleScore * 0.62) + (artistScore * 0.28);

      if (targetDuration > 0 && duration > 0) {
        final difference = (targetDuration - duration).abs();

        if (difference <= 2) {
          score += 0.15;
        } else if (difference <= 5) {
          score += 0.08;
        } else if (difference <= 15) {
          score += 0.02;
        } else {
          score -= math.min(difference / 180.0, 0.15);
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    // Do not accept a wildly unrelated JioSaavn result.
    if (bestScore < 0.35) {
      return null;
    }

    return best;
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _extractJioLyrics(
      Map<String, dynamic>? data,
      ) {
    if (data == null) {
      return null;
    }

    final direct = _clean(
      data['lyrics'] ??
          data['lyrics_text'] ??
          data['lyricsText'] ??
          data['plainLyrics'] ??
          data['plain_lyrics'],
    );

    if (direct != null) {
      return _cleanLyricsMarkup(direct);
    }

    // Some wrappers nest the response under "data".
    final nested = data['data'];

    if (nested is Map) {
      return _extractJioLyrics(
        Map<String, dynamic>.from(nested),
      );
    }

    return null;
  }

  String _cleanLyricsMarkup(String lyrics) {
    var text = lyrics;

    // JioSaavn lyrics responses can contain HTML line breaks/tags.
    text = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');

    text = _decodeHtmlEntities(text);

    // Normalise excessive blank lines without destroying lyric formatting.
    text = text.replaceAll('\r\n', '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  String? _clean(dynamic value) {
    if (value is! String) {
      return null;
    }

    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value.trim();
    }

    return value.toString().trim();
  }

  bool? _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' || normalized == '1') {
        return true;
      }

      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    if (value is num) {
      return value != 0;
    }

    return null;
  }

  int _parseDurationSeconds(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.round();
    }

    final string = value.toString().trim();

    final direct = int.tryParse(string);
    if (direct != null) {
      return direct;
    }

    final parts = string.split(':');

    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = double.tryParse(parts[1]) ?? 0;

      return (minutes * 60 + seconds).round();
    }

    return 0;
  }

  String _normalise(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\u0900-\u097F]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) {
      return 0;
    }

    if (a == b) {
      return 1;
    }

    final aTokens = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final bTokens = b.split(' ').where((e) => e.isNotEmpty).toSet();

    if (aTokens.isEmpty || bTokens.isEmpty) {
      return 0;
    }

    final intersection = aTokens.intersection(bTokens).length;
    final union = aTokens.union(bTokens).length;

    return union == 0 ? 0 : intersection / union;
  }

  String _cacheKey(Song song) {
    return [
      song.id,
      song.title.trim().toLowerCase(),
      song.artist.trim().toLowerCase(),
      song.duration?.inSeconds ?? 0,
    ].join('|');
  }

  void clear() {
    _requests.clear();
    _cache.clear();
  }

  void dispose() {
    clear();
    _client.close();
  }
}
