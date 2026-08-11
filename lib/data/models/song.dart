class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? youtubeUrl;
  final String? streamUrl;
  final int? releaseYear;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnailUrl,
    this.duration,
    this.youtubeUrl,
    this.streamUrl,
    this.releaseYear,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    Duration? duration,
    String? youtubeUrl,
    String? streamUrl,
    int? releaseYear,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl:
      thumbnailUrl ?? this.thumbnailUrl,
      duration:
      duration ?? this.duration,
      youtubeUrl:
      youtubeUrl ?? this.youtubeUrl,
      streamUrl:
      streamUrl ?? this.streamUrl,
      releaseYear:
      releaseYear ?? this.releaseYear,
    );
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist)';
  }
}