import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';
import '../player/now_playing_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MusicController controller =
      MusicControllerProvider.instance;

  final TextEditingController _searchController =
  TextEditingController();

  final FocusNode _focusNode = FocusNode();

  final ScrollController _scrollController =
  ScrollController();

  static const String _historyKey =
      'chameleon_search_history';

  Timer? _debounce;

  List<String> _searchHistory = [];

  bool _hasSubmittedSearch = false;

  @override
  void initState() {
    super.initState();

    _loadSearchHistory();

    _searchController.addListener(
      _onTextChanged,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.removeListener(
      _onTextChanged,
    );

    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // SEARCH HISTORY
  // ===========================================================================

  Future<void> _loadSearchHistory() async {
    final preferences = SharedPreferencesAsync();

    final stored = await preferences.getStringList(
      _historyKey,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _searchHistory = stored ?? <String>[];
    });
  }

  Future<void> _saveSearchHistory(
      String query,
      ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return;
    }

    final updated = <String>[
      cleanQuery,
      ..._searchHistory.where(
            (item) =>
        item.toLowerCase() !=
            cleanQuery.toLowerCase(),
      ),
    ].take(8).toList();

    setState(() {
      _searchHistory = updated;
    });

    final preferences = SharedPreferencesAsync();

    await preferences.setStringList(
      _historyKey,
      updated,
    );
  }

  Future<void> _removeHistoryItem(
      String query,
      ) async {
    final updated = _searchHistory
        .where(
          (item) => item != query,
    )
        .toList();

    setState(() {
      _searchHistory = updated;
    });

    final preferences = SharedPreferencesAsync();

    await preferences.setStringList(
      _historyKey,
      updated,
    );
  }

  Future<void> _clearHistory() async {
    setState(() {
      _searchHistory.clear();
    });

    final preferences = SharedPreferencesAsync();

    await preferences.remove(
      _historyKey,
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }

    _debounce?.cancel();

    final query = _searchController.text.trim();

    if (query.isEmpty) {
      controller.clearSearch();

      if (mounted) {
        setState(() {
          _hasSubmittedSearch = false;
        });
      }

      return;
    }

    _debounce = Timer(
      const Duration(
        milliseconds: 450,
      ),
          () {
        _performSearch(
          query,
          saveHistory: false,
        );
      },
    );
  }

  Future<void> _submit(
      String value,
      ) async {
    final query = value.trim();

    if (query.isEmpty) {
      return;
    }

    await _performSearch(
      query,
      saveHistory: true,
    );

    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _performSearch(
      String query, {
        required bool saveHistory,
      }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _hasSubmittedSearch = true;
      });
    }

    if (saveHistory) {
      await _saveSearchHistory(
        cleanQuery,
      );
    }

    await controller.search(
      cleanQuery,
    );
  }

  Future<void> _searchFromHistory(
      String query,
      ) async {
    _searchController.text = query;

    _searchController.selection =
        TextSelection.fromPosition(
          TextPosition(
            offset: query.length,
          ),
        );

    await _performSearch(
      query,
      saveHistory: true,
    );
  }

  void _clearSearch() {
    _searchController.clear();

    controller.clearSearch();

    setState(() {
      _hasSubmittedSearch = false;
    });

    _focusNode.requestFocus();
  }

  // ===========================================================================
  // PLAY
  // ===========================================================================

  Future<void> _playSong(
      Song song,
      List<Song> queue,
      ) async {
    try {
      await controller.playSong(
        song,
        sourceQueue: queue,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
          const NowPlayingScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to play this song.',
      );
    }
  }

  // ===========================================================================
  // SONG OPTIONS
  // ===========================================================================

  Future<void> _showSongOptions(
      Song song,
      List<Song> queue,
      ) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isFavorite =
        controller.isFavorite(song);

        return SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              10.w,
              0,
              10.w,
              10.h,
            ),
            padding: EdgeInsets.fromLTRB(
              8.w,
              8.h,
              8.w,
              8.h,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
              BorderRadius.circular(30.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(
                    bottom: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      99.r,
                    ),
                  ),
                ),

                // Song header.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    10.w,
                    4.h,
                    10.w,
                    12.h,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(
                          13.r,
                        ),
                        child: SizedBox(
                          width: 52.w,
                          height: 52.w,
                          child:
                          _Artwork(
                            url:
                            song.thumbnailUrl,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 12.w,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: theme
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                            SizedBox(
                              height: 3.h,
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Like.
                _OptionTile(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  title: isFavorite
                      ? 'Unlike'
                      : 'Like',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await controller
                        .toggleFavorite(song);

                    if (mounted) {
                      setState(() {});
                      _showMessage(
                        isFavorite
                            ? 'Removed from favorites'
                            : 'Added to favorites',
                      );
                    }
                  },
                ),

                // Add to queue.
                _OptionTile(
                  icon: Icons.queue_music_rounded,
                  title: 'Add to queue',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    controller.addToQueue(song);

                    _showMessage(
                      'Added to queue',
                    );
                  },
                ),

                // Add to playlist.
                _OptionTile(
                  icon: Icons.playlist_add_rounded,
                  title: 'Add to playlist',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _showPlaylistPicker(
                      song,
                    );
                  },
                ),

                // Play now.
                _OptionTile(
                  icon: Icons.play_arrow_rounded,
                  title: 'Play now',
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _playSong(
                      song,
                      queue,
                    );
                  },
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(
          duration: 220.ms,
        )
            .slideY(
          begin: 0.04,
          end: 0,
          duration: 300.ms,
          curve:
          Curves.easeOutCubic,
        );
      },
    );
  }

  // ===========================================================================
  // PLAYLIST PICKER
  // ===========================================================================

  Future<void> _showPlaylistPicker(
      Song song,
      ) async {
    final playlists = controller.playlists;

    if (playlists.isEmpty) {
      await _showCreatePlaylistForSong(
        song,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 0.72.sh,
            ),
            margin: EdgeInsets.fromLTRB(
              10.w,
              0,
              10.w,
              10.h,
            ),
            padding: EdgeInsets.only(
              top: 8.h,
              bottom: 8.h,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
              BorderRadius.circular(30.r),
            ),
            child: Column(
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(
                    bottom: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      99.r,
                    ),
                  ),
                ),
                Padding(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 20.w,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add to playlist',
                          style: theme
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontSize: 20.sp,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );
                          _showCreatePlaylistForSong(
                            song,
                          );
                        },
                        icon: const Icon(
                          Icons.add_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 4.h,
                ),
                Expanded(
                  child: ListView.builder(
                    physics:
                    const BouncingScrollPhysics(),
                    itemCount:
                    playlists.length,
                    itemBuilder:
                        (
                        context,
                        index,
                        ) {
                      final playlist =
                      playlists[index];

                      return _PlaylistOption(
                        playlist:
                        playlist,
                        onTap: () async {
                          Navigator.pop(
                            sheetContext,
                          );

                          await controller
                              .addToPlaylist(
                            playlist.id,
                            song,
                          );

                          if (mounted) {
                            _showMessage(
                              'Added to ${playlist.name}',
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreatePlaylistForSong(
      Song song,
      ) async {
    final nameController =
    TextEditingController();

    final name =
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme =
        Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor:
          theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              28.r,
            ),
          ),
          title: const Text(
            'New playlist',
          ),
          content: TextField(
            controller:
            nameController,
            autofocus: true,
            textInputAction:
            TextInputAction.done,
            decoration:
            const InputDecoration(
              hintText:
              'Playlist name',
              border:
              InputBorder.none,
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  value.trim(),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                  ),
              child:
              const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                nameController
                    .text
                    .trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child:
              const Text('Create'),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (name == null ||
        name.trim().isEmpty) {
      return;
    }

    await controller.createPlaylist(
      name: name.trim(),
    );

    final playlists =
        controller.playlists;

    if (playlists.isEmpty) {
      return;
    }

    final created =
        playlists.last;

    await controller.addToPlaylist(
      created.id,
      song,
    );

    if (mounted) {
      _showMessage(
        'Created ${created.name}',
      );
    }
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            18.w,
            0,
            18.w,
            90.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18.r,
            ),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme =
        Theme.of(context);

        final hasQuery =
            _searchController.text
                .trim()
                .isNotEmpty;

        final results =
            controller.searchResults;

        final currentSong =
            controller.currentSong;

        return Scaffold(
          backgroundColor:
          theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                CustomScrollView(
                  controller:
                  _scrollController,
                  physics:
                  const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
                  slivers: [
                    // =========================================================
                    // HEADER
                    // =========================================================

                    SliverPadding(
                      padding:
                      EdgeInsets.fromLTRB(
                        22.w,
                        22.h,
                        22.w,
                        0,
                      ),
                      sliver:
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Search',
                              style: theme
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                fontSize:
                                38.sp,
                                fontWeight:
                                FontWeight.w700,
                                letterSpacing:
                                -1.4,
                              ),
                            ),
                            SizedBox(
                              height: 5.h,
                            ),
                            Text(
                              'Find something worth listening to.',
                              style: theme
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // =========================================================
                    // SEARCH FIELD
                    // =========================================================

                    SliverPadding(
                      padding:
                      EdgeInsets.fromLTRB(
                        18.w,
                        20.h,
                        18.w,
                        0,
                      ),
                      sliver:
                      SliverToBoxAdapter(
                        child:
                        _SearchField(
                          controller:
                          _searchController,
                          focusNode:
                          _focusNode,
                          hasText:
                          hasQuery,
                          onSubmitted:
                          _submit,
                          onClear:
                          _clearSearch,
                        ),
                      ),
                    ),

                    // =========================================================
                    // SEARCHING
                    // =========================================================

                    if (controller.isSearching)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          22.w,
                          24.h,
                          22.w,
                          0,
                        ),
                        sliver:
                        const SliverToBoxAdapter(
                          child:
                          _SearchingIndicator(),
                        ),
                      ),

                    // =========================================================
                    // RESULTS HEADER
                    // =========================================================

                    if (!controller.isSearching &&
                        hasQuery &&
                        results.isNotEmpty)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          22.w,
                          25.h,
                          22.w,
                          0,
                        ),
                        sliver:
                        SliverToBoxAdapter(
                          child:
                          _SectionHeader(
                            title: 'Results',
                            count:
                            results.length,
                          ),
                        ),
                      ),

                    // =========================================================
                    // RESULTS
                    // =========================================================

                    if (!controller.isSearching &&
                        hasQuery &&
                        results.isNotEmpty)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          18.w,
                          10.h,
                          18.w,
                          0,
                        ),
                        sliver:
                        SliverList.builder(
                          itemCount:
                          results.length,
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final song =
                            results[index];

                            return _ResultTile(
                              song: song,
                              index: index,
                              onPlay: () =>
                                  _playSong(
                                    song,
                                    results,
                                  ),
                              onMore: () =>
                                  _showSongOptions(
                                    song,
                                    results,
                                  ),
                            );
                          },
                        ),
                      ),

                    // =========================================================
                    // NO RESULTS
                    // =========================================================

                    if (!controller.isSearching &&
                        hasQuery &&
                        _hasSubmittedSearch &&
                        results.isEmpty)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          22.w,
                          65.h,
                          22.w,
                          0,
                        ),
                        sliver:
                        const SliverToBoxAdapter(
                          child:
                          _NoResults(),
                        ),
                      ),

                    // =========================================================
                    // RECENT SEARCHES
                    // =========================================================

                    if (!hasQuery &&
                        _searchHistory.isNotEmpty)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          22.w,
                          30.h,
                          22.w,
                          0,
                        ),
                        sliver:
                        SliverToBoxAdapter(
                          child:
                          _RecentSearchHeader(
                            onClear:
                            _clearHistory,
                          ),
                        ),
                      ),

                    if (!hasQuery &&
                        _searchHistory.isNotEmpty)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          18.w,
                          10.h,
                          18.w,
                          0,
                        ),
                        sliver:
                        SliverList.builder(
                          itemCount:
                          _searchHistory.length,
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final query =
                            _searchHistory[
                            index];

                            return _HistoryTile(
                              query: query,
                              index: index,
                              onTap: () =>
                                  _searchFromHistory(
                                    query,
                                  ),
                              onRemove: () =>
                                  _removeHistoryItem(
                                    query,
                                  ),
                            );
                          },
                        ),
                      ),

                    // =========================================================
                    // RECENTLY PLAYED
                    // =========================================================

                    if (!hasQuery &&
                        controller
                            .recentlyPlayed
                            .isNotEmpty)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          22.w,
                          _searchHistory
                              .isNotEmpty
                              ? 30.h
                              : 26.h,
                          0,
                          0,
                        ),
                        sliver:
                        const SliverToBoxAdapter(
                          child:
                          _SectionHeader(
                            title:
                            'Recently played',
                          ),
                        ),
                      ),

                    if (!hasQuery &&
                        controller
                            .recentlyPlayed
                            .isNotEmpty)
                      SliverToBoxAdapter(
                        child:
                        Padding(
                          padding:
                          EdgeInsets.only(
                            top: 12.h,
                          ),
                          child:
                          _RecentlyPlayedList(
                            songs: controller
                                .recentlyPlayed,
                            onPlay:
                            _playSong,
                            onMore:
                            _showSongOptions,
                          ),
                        ),
                      ),

                    // =========================================================
                    // QUICK SEARCH
                    // =========================================================

                    if (!hasQuery)
                      SliverPadding(
                        padding:
                        EdgeInsets.fromLTRB(
                          22.w,
                          30.h,
                          22.w,
                          0,
                        ),
                        sliver:
                        SliverToBoxAdapter(
                          child:
                          _QuickSearch(
                            onTap:
                            _searchFromHistory,
                          ),
                        ),
                      ),

                    // Space for mini player.
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: currentSong !=
                            null
                            ? 180.h
                            : 110.h,
                      ),
                    ),
                  ],
                ),

                // =============================================================
                // MINI PLAYER
                // =============================================================

                if (currentSong != null)
                  Positioned(
                    left: 12.w,
                    right: 12.w,
                    bottom: 10.h,
                    child: _MiniPlayer(
                      song: currentSong,
                      isPlaying: controller
                          .playbackState
                          .isPlaying,
                      position: controller
                          .playbackState
                          .position,
                      duration: controller
                          .playbackState
                          .duration,
                      onPlayPause:
                      controller
                          .togglePlayPause,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder: (_) =>
                            const NowPlayingScreen(),
                          ),
                        );
                      },
                      onMore: () =>
                          _showSongOptions(
                            currentSong,
                            controller.queue,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SEARCH FIELD
// =============================================================================

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
        BorderRadius.circular(22.r),
      ),
      child: Row(
        children: [
          SizedBox(width: 18.w),
          Icon(
            Icons.search_rounded,
            size: 24.sp,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction:
              TextInputAction.search,
              onSubmitted: onSubmitted,
              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration:
              InputDecoration(
                hintText:
                'Songs, artists...',
                hintStyle: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder:
                InputBorder.none,
                focusedBorder:
                InputBorder.none,
                contentPadding:
                EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 34.w,
                height: 34.w,
                margin:
                EdgeInsets.only(
                  right: 10.w,
                ),
                decoration:
                BoxDecoration(
                  color: theme
                      .scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18.sp,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(
      duration: 350.ms,
    )
        .slideY(
      begin: 0.04,
      end: 0,
      duration: 350.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// =============================================================================
// RESULT TILE
// =============================================================================

class _ResultTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onMore;

  const _ResultTile({
    required this.song,
    required this.index,
    required this.onPlay,
    required this.onMore,
  });

  String _durationText() {
    final duration = song.duration;

    if (duration == null) {
      return '';
    }

    final minutes =
        duration.inMinutes;

    final seconds =
        duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPlay,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
        EdgeInsets.symmetric(
          vertical: 6.h,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(16.r),
              child: SizedBox(
                width: 62.w,
                height: 62.w,
                child: _Artwork(
                  url: song.thumbnailUrl,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: theme
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontSize: 11.sp,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_durationText().isNotEmpty)
              Padding(
                padding:
                EdgeInsets.only(
                  right: 2.w,
                ),
                child: Text(
                  _durationText(),
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontSize: 10.sp,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            SizedBox(width: 2.w),
            IconButton(
              tooltip: 'More',
              onPressed: onMore,
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (25 * index).ms,
      duration: 300.ms,
    )
        .slideX(
      begin: 0.025,
      end: 0,
      delay: (25 * index).ms,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// =============================================================================
// RECENTLY PLAYED
// =============================================================================

class _RecentlyPlayedList
    extends StatelessWidget {
  final List<Song> songs;

  final Future<void> Function(
      Song,
      List<Song>,
      ) onPlay;

  final Future<void> Function(
      Song,
      List<Song>,
      ) onMore;

  const _RecentlyPlayedList({
    required this.songs,
    required this.onPlay,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final visible =
    songs.take(8).toList();

    return SizedBox(
      height: 211.h,
      child: ListView.separated(
        padding:
        EdgeInsets.symmetric(
          horizontal: 22.w,
        ),
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount: visible.length,
        separatorBuilder:
            (context, index) =>
            SizedBox(width: 12.w),
        itemBuilder:
            (context, index) {
          final song = visible[index];

          return GestureDetector(
            onTap: () =>
                onPlay(song, visible),
            child: SizedBox(
              width: 154.w,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(
                          23.r,
                        ),
                        child: SizedBox(
                          width: 154.w,
                          height: 154.w,
                          child: _Artwork(
                            url: song
                                .thumbnailUrl,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8.w,
                        bottom: 8.w,
                        child:
                        GestureDetector(
                          onTap: () =>
                              onMore(
                                song,
                                visible,
                              ),
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration:
                            BoxDecoration(
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .surface
                                  .withValues(
                                alpha: 0.94,
                              ),
                              shape:
                              BoxShape.circle,
                            ),
                            child: Icon(
                              Icons
                                  .more_horiz_rounded,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                      fontSize: 13.sp,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontSize: 10.5.sp,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(
            delay: (45 * index).ms,
            duration: 350.ms,
          )
              .slideX(
            begin: 0.06,
            end: 0,
            delay: (45 * index).ms,
            duration: 350.ms,
          );
        },
      ),
    );
  }
}

// =============================================================================
// MINI PLAYER
// =============================================================================

class _MiniPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  final Future<void> Function()
  onPlayPause;

  final VoidCallback onTap;
  final VoidCallback onMore;

  const _MiniPlayer({
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double progress = 0;

    if (duration.inMilliseconds > 0) {
      progress =
          (position.inMilliseconds /
              duration.inMilliseconds)
              .clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
          BorderRadius.circular(23.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha:
                theme.brightness ==
                    Brightness.dark
                    ? 0.32
                    : 0.10,
              ),
              blurRadius: 28,
              offset:
              const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    18.r,
                  ),
                  child: Container(
                    width: 56.w,
                    height: 56.w,
                    margin:
                    EdgeInsets.only(
                      left: 6.w,
                    ),
                    child: _Artwork(
                      url:
                      song.thumbnailUrl,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 2.h,
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          fontSize: 10.sp,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 22.sp,
                  ),
                ),
                IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(
                    isPlaying
                        ? Icons
                        .pause_rounded
                        : Icons
                        .play_arrow_rounded,
                    size: 27.sp,
                  ),
                ),
                SizedBox(width: 3.w),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius:
                BorderRadius.vertical(
                  bottom:
                  Radius.circular(23.r),
                ),
                child: Align(
                  alignment:
                  Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 2.h,
                      color: theme
                          .colorScheme
                          .onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      duration: 250.ms,
    )
        .slideY(
      begin: 0.12,
      end: 0,
      duration: 350.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// =============================================================================
// OPTION TILE
// =============================================================================

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding:
      EdgeInsets.symmetric(
        horizontal: 8.w,
      ),
      leading: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: theme
              .scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 21.sp,
        ),
      ),
      title: Text(
        title,
        style: theme
            .textTheme
            .titleSmall
            ?.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// PLAYLIST OPTION
// =============================================================================

class _PlaylistOption
    extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistOption({
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding:
      EdgeInsets.symmetric(
        horizontal: 18.w,
        vertical: 3.h,
      ),
      leading: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: theme
              .scaffoldBackgroundColor,
          borderRadius:
          BorderRadius.circular(15.r),
        ),
        child: playlist.artworkUrl !=
            null &&
            playlist.artworkUrl!
                .isNotEmpty
            ? ClipRRect(
          borderRadius:
          BorderRadius.circular(
            15.r,
          ),
          child: Image.network(
            playlist.artworkUrl!,
            fit: BoxFit.cover,
            errorBuilder:
                (
                context,
                error,
                stackTrace,
                ) {
              return Icon(
                Icons
                    .queue_music_rounded,
                size: 21.sp,
              );
            },
          ),
        )
            : Icon(
          Icons.queue_music_rounded,
          size: 21.sp,
        ),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style: theme
            .textTheme
            .titleSmall
            ?.copyWith(
          fontWeight:
          FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${playlist.songs.length} songs',
        style: theme
            .textTheme
            .bodySmall
            ?.copyWith(
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.add_rounded,
        size: 21.sp,
      ),
    );
  }
}

// =============================================================================
// RECENT SEARCH
// =============================================================================

class _RecentSearchHeader
    extends StatelessWidget {
  final VoidCallback onClear;

  const _RecentSearchHeader({
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Recent searches',
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
              fontSize: 21.sp,
              fontWeight:
              FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        GestureDetector(
          onTap: onClear,
          child: Text(
            'Clear',
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              fontWeight:
              FontWeight.w600,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String query;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryTile({
    required this.query,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
      EdgeInsets.only(
        bottom: 4.h,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration:
              BoxDecoration(
                color: theme
                    .colorScheme
                    .surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 19.sp,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: theme
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontSize: 14.sp,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                size: 18.sp,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (index * 35).ms,
      duration: 280.ms,
    );
  }
}

// =============================================================================
// QUICK SEARCH
// =============================================================================

class _QuickSearch
    extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _QuickSearch({
    required this.onTap,
  });

  static const queries = [
    'Trending music',
    'Daft Punk',
    'The Weeknd',
    'Billie Eilish',
    'Chill music',
    'Electronic music',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Quick search',
          style: theme
              .textTheme
              .titleLarge
              ?.copyWith(
            fontSize: 21.sp,
            fontWeight:
            FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: queries.map(
                (query) {
              return GestureDetector(
                onTap: () => onTap(query),
                child: Container(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 10.h,
                  ),
                  decoration:
                  BoxDecoration(
                    color: theme
                        .colorScheme
                        .surface,
                    borderRadius:
                    BorderRadius
                        .circular(
                      18.r,
                    ),
                  ),
                  child: Text(
                    query,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontSize: 12.sp,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader
    extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({
    required this.title,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
              fontSize: 21.sp,
              fontWeight:
              FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (count != null)
          Text(
            '$count',
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// SEARCHING
// =============================================================================

class _SearchingIndicator
    extends StatelessWidget {
  const _SearchingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 18.w,
          height: 18.w,
          child:
          CircularProgressIndicator(
            strokeWidth: 1.8,
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          'Finding music...',
          style: theme
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// NO RESULTS
// =============================================================================

class _NoResults
    extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 68.w,
          height: 68.w,
          decoration: BoxDecoration(
            color: theme
                .colorScheme
                .surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search_off_rounded,
            size: 29.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Nothing found',
          style: theme
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Try another song, artist, or search term.',
          textAlign: TextAlign.center,
          style: theme
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ARTWORK
// =============================================================================

class _Artwork extends StatelessWidget {
  final String? url;

  const _Artwork({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: Theme.of(context)
            .colorScheme
            .surface,
        alignment: Alignment.center,
        child: Icon(
          Icons.music_note_rounded,
          size: 27.sp,
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      filterQuality:
      FilterQuality.high,
      errorBuilder:
          (
          context,
          error,
          stackTrace,
          ) {
        return Container(
          color: Theme.of(context)
              .colorScheme
              .surface,
          alignment:
          Alignment.center,
          child: Icon(
            Icons.music_note_rounded,
            size: 27.sp,
          ),
        );
      },
    );
  }
}