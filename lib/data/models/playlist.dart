import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? artworkUrl;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUrl,
    this.songs = const [],
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUrl,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      songs: songs ?? this.songs,
    );
  }
}