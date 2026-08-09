import '../models/song.dart';

class QueueService {
  // ===========================================================================
  // QUEUE
  // ===========================================================================

  final List<Song> _queue = [];

  int _currentIndex = -1;

  // ===========================================================================
  // FULL QUEUE
  // ===========================================================================

  List<Song> get queue {
    return List.unmodifiable(
      _queue,
    );
  }

  // ===========================================================================
  // UPCOMING QUEUE
  // ===========================================================================
  //
  // Returns ONLY songs after the currently playing song.
  //
  // Example:
  //
  // A → B → C → D
  //         ↑
  //       CURRENT
  //
  // upcoming = C? No:
  //
  // D only.
  //
  // Previous songs are never included.
  //

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

  // ===========================================================================
  // CURRENT INDEX
  // ===========================================================================

  int get currentIndex {
    return _currentIndex;
  }

  // ===========================================================================
  // CURRENT SONG
  // ===========================================================================

  Song? get currentSong {
    if (_currentIndex < 0 ||
        _currentIndex >= _queue.length) {
      return null;
    }

    return _queue[_currentIndex];
  }

  // ===========================================================================
  // HAS NEXT
  // ===========================================================================

  bool get hasNext {
    return _currentIndex >= 0 &&
        _currentIndex < _queue.length - 1;
  }

  // ===========================================================================
  // HAS PREVIOUS
  // ===========================================================================

  bool get hasPrevious {
    return _currentIndex > 0;
  }

  // ===========================================================================
  // SET QUEUE
  // ===========================================================================

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

  // ===========================================================================
  // ADD SONG
  // ===========================================================================

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

  // ===========================================================================
  // ADD MULTIPLE
  // ===========================================================================

  void addAll(
      List<Song> songs,
      ) {
    for (final song in songs) {
      add(song);
    }
  }

  // ===========================================================================
  // NEXT
  // ===========================================================================

  Song? next() {
    if (!hasNext) {
      return null;
    }

    _currentIndex++;

    return currentSong;
  }

  // ===========================================================================
  // PREVIOUS
  // ===========================================================================

  Song? previous() {
    if (!hasPrevious) {
      return null;
    }

    _currentIndex--;

    return currentSong;
  }

  // ===========================================================================
  // REPLACE CURRENT
  // ===========================================================================

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

  // ===========================================================================
  // REMOVE
  // ===========================================================================

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

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  void clear() {
    _queue.clear();

    _currentIndex = -1;
  }
}