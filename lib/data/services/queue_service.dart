import '../models/song.dart';

class QueueService {
  final List<Song> _queue = [];

  int _currentIndex = -1;
  List<Song> get queue {
    return List.unmodifiable(
      _queue,
    );
  }

  List<Song> get upcoming {
    if (_queue.isEmpty) {
      return const [];
    }

    if (_currentIndex < 0 ||
        _currentIndex >= _queue.length - 1) {
      return const [];
    }

    return List.unmodifiable(
      _queue.sublist(
        _currentIndex + 1,
      ),
    );
  }
  int get currentIndex {
    return _currentIndex;
  }
  Song? get currentSong {
    if (_currentIndex < 0 ||
        _currentIndex >= _queue.length) {
      return null;
    }

    return _queue[_currentIndex];
  }
  bool get hasNext {
    return _currentIndex >= 0 &&
        _currentIndex < _queue.length - 1;
  }
  bool get hasPrevious {
    return _currentIndex > 0;
  }
  void setQueue(
      List<Song> songs, {
        int startIndex = 0,
      }) {
    _queue
      ..clear()
      ..addAll(songs);

    if (_queue.isEmpty) {
      _currentIndex = -1;
      return;
    }

    _currentIndex = startIndex.clamp(
      0,
      _queue.length - 1,
    );
  }
  void add(
      Song song,
      ) {
    final alreadyExists =
    _queue.any(
          (item) =>
      item.id == song.id,
    );

    if (alreadyExists) {
      return;
    }

    _queue.add(song);

    if (_currentIndex == -1) {
      _currentIndex = 0;
    }
  }
  void addAll(
      List<Song> songs,
      ) {
    for (final song in songs) {
      add(song);
    }
  }
  Song? next() {
    if (!hasNext) {
      return null;
    }

    _currentIndex++;

    return currentSong;
  }
  Song? previous() {
    if (!hasPrevious) {
      return null;
    }

    _currentIndex--;

    return currentSong;
  }
  void replaceCurrent(
      Song song,
      ) {
    if (_currentIndex < 0 ||
        _currentIndex >= _queue.length) {
      return;
    }

    _queue[_currentIndex] =
        song;
  }
  void removeAt(
      int index,
      ) {
    if (index < 0 ||
        index >= _queue.length) {
      return;
    }

    _queue.removeAt(index);

    if (_queue.isEmpty) {
      _currentIndex = -1;
      return;
    }

    if (index < _currentIndex) {
      _currentIndex--;
    }

    if (_currentIndex >=
        _queue.length) {
      _currentIndex =
          _queue.length - 1;
    }
  }
  void clear() {
    _queue.clear();

    _currentIndex = -1;
  }
}