import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';
import '../player/now_playing_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
  });

  @override
  State<PlaylistScreen> createState() =>
      _PlaylistScreenState();
}

class _PlaylistScreenState
    extends State<PlaylistScreen> {
  final MusicController controller =
      MusicControllerProvider.instance;
  Playlist? _findPlaylist() {
    for (final item in controller.playlists) {
      if (item.id == widget.playlistId) {
        return item;
      }
    }

    return null;
  }
  String? _getArtwork(
      Playlist playlist,
      ) {
    final playlistArtwork =
        playlist.artworkUrl;

    if (playlistArtwork != null &&
        playlistArtwork.trim().isNotEmpty) {
      return playlistArtwork;
    }

    for (final song in playlist.songs) {
      final url = song.thumbnailUrl;

      if (url != null &&
          url.trim().isNotEmpty) {
        return url;
      }
    }

    return null;
  }
  Future<void> _playSong(
      Song song,
      List<Song> songs,
      ) async {
    try {
      await controller.playSong(
        song,
        sourceQueue: List<Song>.from(songs),
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
          const NowPlayingScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to play this song.',
      );
    }
  }

  Future<void> _playAll(
      List<Song> songs,
      ) async {
    if (songs.isEmpty) {
      _showMessage(
        'This playlist is empty.',
      );
      return;
    }

    await _playSong(
      songs.first,
      songs,
    );
  }
  Future<void> _shuffle(
      List<Song> songs,
      ) async {
    if (songs.isEmpty) {
      _showMessage(
        'This playlist is empty.',
      );
      return;
    }

    final shuffled =
    List<Song>.from(songs)
      ..shuffle();

    await _playSong(
      shuffled.first,
      shuffled,
    );
  }
  Future<void> _toggleLike(
      Song song,
      ) async {
    await controller.toggleFavorite(
      song,
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }
  void _addToQueue(
      Song song,
      ) {
    controller.addToQueue(song);

    _showMessage(
      'Added to queue',
    );
  }
  Future<void> _removeSong(
      Playlist playlist,
      Song song,
      ) async {
    await controller.removeFromPlaylist(
      playlist.id,
      song.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      'Removed from playlist',
    );
  }
  Future<void> _showSongMenu(
      Song song,
      Playlist playlist,
      ) async {
    final theme =
    Theme.of(context);

    final liked =
    controller.isFavorite(song);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
      Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            10.w,
            0,
            10.w,
            10.h,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              10.w,
              10.h,
              10.w,
              14.h,
            ),
            decoration: BoxDecoration(
              color:
              theme.colorScheme.surface,
              borderRadius:
              BorderRadius.circular(
                30.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha: 0.22,
                  ),
                  blurRadius: 40,
                  offset:
                  const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const _SheetHandle(),

                // SONG HEADER
                Container(
                  padding:
                  EdgeInsets.all(8.w),
                  margin:
                  EdgeInsets.only(
                    bottom: 8.h,
                  ),
                  decoration:
                  BoxDecoration(
                    color: theme
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(
                      alpha: 0.45,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20.r,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(
                          14.r,
                        ),
                        child: SizedBox(
                          width: 58.w,
                          height: 58.w,
                          child: _Artwork(
                            url: song
                                .thumbnailUrl,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 12.w,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style: theme
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                            SizedBox(
                              height: 4.h,
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
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

                _MenuItem(
                  icon: liked
                      ? Hicons
                      .heart1Bold
                      : Hicons
                      .heart1LightOutline,
                  title: liked
                      ? 'Unlike'
                      : 'Like',
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _toggleLike(
                      song,
                    );
                  },
                ),

                _MenuItem(
                  icon: Hicons
                      .musicFilterBold,
                  title: 'Add to queue',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    _addToQueue(song);
                  },
                ),

                _MenuItem(
                  icon: Hicons
                      .playLightOutline,
                  title: 'Play now',
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _playSong(
                      song,
                      playlist.songs,
                    );
                  },
                ),

                _MenuItem(
                  icon: Hicons
                      .folderCross1LightOutline,
                  title:
                  'Remove from playlist',
                  destructive: true,
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _removeSong(
                      playlist,
                      song,
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
          begin: 0.05,
          end: 0,
          duration: 320.ms,
          curve:
          Curves.easeOutCubic,
        );
      },
    );
  }
  Future<void> _showPlaylistMenu(
      Playlist playlist,
      ) async {
    final theme =
    Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
      Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            10.w,
            0,
            10.w,
            10.h,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              10.w,
              10.h,
              10.w,
              14.h,
            ),
            decoration: BoxDecoration(
              color:
              theme.colorScheme.surface,
              borderRadius:
              BorderRadius.circular(
                30.r,
              ),
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const _SheetHandle(),

                _MenuItem(
                  icon: Hicons
                      .playLightOutline,
                  title: 'Play playlist',
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _playAll(
                      playlist.songs,
                    );
                  },
                ),

                _MenuItem(
                  icon:
                  Hicons.shuffle1LightOutline,
                  title: 'Shuffle',
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _shuffle(
                      playlist.songs,
                    );
                  },
                ),

                _MenuItem(
                  icon: Hicons
                      .delete1LightOutline,
                  title:
                  'Delete playlist',
                  destructive: true,
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await _confirmDelete(
                      playlist,
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
          begin: 0.05,
          end: 0,
          duration: 320.ms,
          curve:
          Curves.easeOutCubic,
        );
      },
    );
  }
  Future<void> _confirmDelete(
      Playlist playlist,
      ) async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme =
        Theme.of(dialogContext);

        return AlertDialog(
          backgroundColor:
          theme.colorScheme.surface,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              26.r,
            ),
          ),
          title: Text(
            'Delete playlist?',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          content: Text(
            '“${playlist.name}” will be permanently removed.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await controller.deletePlaylist(
      playlist.id,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }
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
          content: Text(
            message,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          behavior:
          SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            18.w,
            0,
            18.w,
            24.h,
          ),
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18.r,
            ),
          ),
        ),
      );
  }
  @override
  Widget build(
      BuildContext context,
      ) {
    final playlist =
    _findPlaylist();

    if (playlist == null) {
      return const _PlaylistNotFound();
    }

    // Create a stable snapshot.
    final songs =
    List<Song>.from(
      playlist.songs,
    );

    final artwork =
    _getArtwork(playlist);

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: CustomScrollView(
        key: PageStorageKey<String>(
          'playlist_${playlist.id}',
        ),
        physics:
        const BouncingScrollPhysics(
          parent:
          AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // HERO
          //
          // IMPORTANT:
          // Do NOT put .animate() on this sliver.
          _CinematicHero(
            key: ValueKey<String>(
              'hero_${playlist.id}',
            ),
            playlist: playlist,
            artwork: artwork,
            onBack: () {
              Navigator.pop(context);
            },
            onMore: () {
              _showPlaylistMenu(
                playlist,
              );
            },
          ),
          // ACTIONS
          //
          // IMPORTANT:
          // Animation is INSIDE SliverToBoxAdapter.
          SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.fromLTRB(
                22.w,
                18.h,
                22.w,
                15.h,
              ),
              child: _PlaylistActions(
                enabled:
                songs.isNotEmpty,
                onPlay: () {
                  _playAll(songs);
                },
                onShuffle: () {
                  _shuffle(songs);
                },
              )
                  .animate()
                  .fadeIn(
                delay: 150.ms,
                duration: 400.ms,
              )
                  .slideY(
                begin: 0.05,
                end: 0,
                delay: 150.ms,
                duration: 400.ms,
                curve:
                Curves.easeOutCubic,
              ),
            ),
          ),
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                EdgeInsets.fromLTRB(
                  22.w,
                  4.h,
                  22.w,
                  10.h,
                ),
                child: Row(
                  children: [
                    Text(
                      'Songs',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontSize: 19.sp,
                        fontWeight:
                        FontWeight.w700,
                        letterSpacing:
                        -0.4,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${songs.length}',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .onSurfaceVariant,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // SONG LIST
          //
          // SliverList itself is NOT animated.
          // Individual normal song tiles can be animated safely.
          if (songs.isNotEmpty)
            SliverPadding(
              padding:
              EdgeInsets.symmetric(
                horizontal: 17.w,
              ),
              sliver: SliverList(
                delegate:
                SliverChildBuilderDelegate(
                      (context, index) {
                    final song =
                    songs[index];

                    return KeyedSubtree(
                      key: ValueKey<String>(
                        'song_${playlist.id}_${song.id}',
                      ),
                      child:
                      _PlaylistSongTile(
                        song: song,
                        index: index,
                        favorite:
                        controller
                            .isFavorite(
                          song,
                        ),
                        onTap: () {
                          _playSong(
                            song,
                            songs,
                          );
                        },
                        onMore: () {
                          _showSongMenu(
                            song,
                            playlist,
                          );
                        },
                      ),
                    );
                  },
                  childCount:
                  songs.length,
                ),
              ),
            ),
          if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child:
              _EmptyPlaylist(),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120.h,
            ),
          ),
        ],
      ),
    );
  }
}
class _PlaylistActions
    extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  const _PlaylistActions({
    required this.enabled,
    required this.onPlay,
    required this.onShuffle,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed:
            enabled ? onPlay : null,
            icon: Icon(
              Hicons.playLightOutline,
              size: 23.sp,
            ),
            label: Text(
              'Play',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            style:
            FilledButton.styleFrom(
              minimumSize:
              Size(
                0,
                54.h,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  19.r,
                ),
              ),
            ),
          ),
        ),

        SizedBox(
          width: 10.w,
        ),

        Material(
          color: theme
              .colorScheme
              .surface,
          shape:
          const CircleBorder(),
          child: InkWell(
            customBorder:
            const CircleBorder(),
            onTap:
            enabled ? onShuffle : null,
            child: SizedBox(
              width: 54.w,
              height: 54.w,
              child: Icon(
                Hicons.shuffle1LightOutline,
                size: 21.sp,
                color: enabled
                    ? null
                    : theme
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.45,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _CinematicHero
    extends StatelessWidget {
  final Playlist playlist;
  final String? artwork;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _CinematicHero({
    super.key,
    required this.playlist,
    required this.artwork,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SliverAppBar(
      expandedHeight: 430.h,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.black,
      surfaceTintColor:
      Colors.transparent,

      leading: Padding(
        padding:
        EdgeInsets.only(left: 10.w),
        child: _GlassButton(
          icon:
          Hicons.left2LightOutline,
          onTap: onBack,
        ),
      ),

      actions: [
        Padding(
          padding:
          EdgeInsets.only(right: 10.w),
          child: _GlassButton(
            icon:
            Hicons.menuHamburger1LightOutline,
            onTap: onMore,
          ),
        ),
      ],

      flexibleSpace:
      FlexibleSpaceBar(
        collapseMode:
        CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // BACKGROUND
            if (artwork != null)
              Image.network(
                artwork!,
                fit: BoxFit.cover,
                filterQuality:
                FilterQuality.high,
                errorBuilder:
                    (_, __, ___) {
                  return const ColoredBox(
                    color: Colors.black,
                  );
                },
              ),

            // BLUR
            if (artwork != null)
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 28,
                  sigmaY: 28,
                ),
                child: Container(
                  color: Colors.black
                      .withValues(
                    alpha: 0.48,
                  ),
                ),
              ),

            // GRADIENT
            DecoratedBox(
              decoration:
              BoxDecoration(
                gradient:
                LinearGradient(
                  begin:
                  Alignment.topCenter,
                  end:
                  Alignment.bottomCenter,
                  colors: [
                    Colors.black
                        .withValues(
                      alpha: 0.16,
                    ),
                    Colors.black
                        .withValues(
                      alpha: 0.08,
                    ),
                    Colors.black
                        .withValues(
                      alpha: 0.30,
                    ),
                    Colors.black
                        .withValues(
                      alpha: 0.82,
                    ),
                    Colors.black,
                  ],
                  stops: const [
                    0.0,
                    0.25,
                    0.52,
                    0.80,
                    1.0,
                  ],
                ),
              ),
            ),

            // CONTENT
            SafeArea(
              child: Padding(
                padding:
                EdgeInsets.fromLTRB(
                  22.w,
                  82.h,
                  22.w,
                  27.h,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: [
                    // IMPORTANT:
                    // Animate the normal Container,
                    // NOT the SliverAppBar.
                    Hero(
                      tag:
                      'playlist_${playlist.id}',
                      child: Container(
                        width: 245.w,
                        height: 245.w,
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius
                              .circular(
                            30.r,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withValues(
                                alpha: 0.50,
                              ),
                              blurRadius:
                              42,
                              spreadRadius:
                              1,
                              offset:
                              const Offset(
                                0,
                                20,
                              ),
                            ),
                          ],
                        ),
                        clipBehavior:
                        Clip.antiAlias,
                        child: _Artwork(
                          url: artwork,
                        ),
                      )
                          .animate()
                          .fadeIn(
                        duration: 500.ms,
                      )
                          .scale(
                        begin:
                        const Offset(
                          0.94,
                          0.94,
                        ),
                        end:
                        const Offset(
                          1,
                          1,
                        ),
                        duration:
                        650.ms,
                        curve: Curves
                            .easeOutCubic,
                      ),
                    ),

                    SizedBox(
                      height: 19.h,
                    ),

                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27.sp,
                        height: 1.05,
                        fontWeight:
                        FontWeight.w800,
                        letterSpacing: -0.9,
                        shadows: const [
                          Shadow(
                            color:
                            Colors.black54,
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: 6.h,
                    ),

                    Text(
                      '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.60,
                        ),
                        fontSize: 12.sp,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _GlassButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Material(
          color: Colors.white
              .withValues(
            alpha: 0.14,
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: Icon(
                icon,
                color: Colors.white,
                size: 19.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _PlaylistSongTile
    extends StatelessWidget {
  final Song song;
  final int index;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _PlaylistSongTile({
    required this.song,
    required this.index,
    required this.favorite,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final tile = GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 5.h,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 7.h,
        ),
        decoration: BoxDecoration(
          color: theme
              .colorScheme
              .surface
              .withValues(
            alpha: 0.42,
          ),
          borderRadius:
          BorderRadius.circular(
            19.r,
          ),
        ),
        child: Row(
          children: [
            // ARTWORK
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                14.r,
              ),
              child: SizedBox(
                width: 60.w,
                height: 60.w,
                child: _Artwork(
                  url: song.thumbnailUrl,
                ),
              ),
            ),

            SizedBox(
              width: 13.w,
            ),

            // INFO
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
                  SizedBox(
                    height: 4.h,
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
                      fontSize: 11.sp,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // LIKE
            if (favorite)
              Padding(
                padding:
                EdgeInsets.only(
                  right: 2.w,
                ),
                child: Icon(
                  Hicons.heart1Bold,
                  size: 27.sp,
                  color: theme
                      .colorScheme
                      .primary,
                )
                    .animate()
                    .scale(
                  duration: 250.ms,
                  curve:
                  Curves.easeOutBack,
                ),
              ),

            // MENU
            IconButton(
              onPressed: onMore,
              splashRadius: 22.r,
              icon: Icon(
                Hicons.menuHamburger1LightOutline,
                size: 23.sp,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    // IMPORTANT:
    // This is a normal box widget inside SliverList.
    // Therefore flutter_animate is safe here.
    return tile
        .animate()
        .fadeIn(
      delay: (index * 20).ms,
      duration: 280.ms,
    )
        .slideX(
      begin: 0.035,
      end: 0,
      delay: (index * 20).ms,
      duration: 330.ms,
      curve:
      Curves.easeOutCubic,
    );
  }
}
class _MenuItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          18.r,
        ),
        onTap: onTap,
        child: Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal: 7.w,
            vertical: 5.h,
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration:
                BoxDecoration(
                  color: theme
                      .scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 21.sp,
                  color: color,
                ),
              ),

              SizedBox(
                width: 14.w,
              ),

              Expanded(
                child: Text(
                  title,
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontSize: 14.sp,
                    fontWeight:
                    FontWeight.w600,
                    color: color,
                  ),
                ),
              ),

              Icon(
                Hicons
                    .right2LightOutline,
                size: 20.sp,
                color: theme
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SheetHandle
    extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: 38.w,
      height: 4.h,
      margin:
      EdgeInsets.only(
        bottom: 10.h,
      ),
      decoration:
      BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(
          alpha: 0.13,
        ),
        borderRadius:
        BorderRadius.circular(
          99.r,
        ),
      ),
    );
  }
}
class _EmptyPlaylist
    extends StatelessWidget {
  const _EmptyPlaylist();

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Center(
      child: Padding(
        padding:
        EdgeInsets.all(35.w),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 92.w,
              height: 92.w,
              decoration:
              BoxDecoration(
                color: theme
                    .colorScheme
                    .surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Hicons
                    .musicFilterBold,
                size: 38.sp,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            )
                .animate()
                .fadeIn(
              duration: 400.ms,
            )
                .scale(
              begin:
              const Offset(
                0.85,
                0.85,
              ),
              end:
              const Offset(
                1,
                1,
              ),
              duration: 500.ms,
              curve:
              Curves.easeOutBack,
            ),

            SizedBox(
              height: 18.h,
            ),

            Text(
              'Your playlist is empty',
              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            SizedBox(
              height: 7.h,
            ),

            Text(
              'Add songs from Home or Search.',
              textAlign:
              TextAlign.center,
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
    );
  }
}
class _PlaylistNotFound
    extends StatelessWidget {
  const _PlaylistNotFound();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Hicons
                  .folderCross1LightOutline,
              size: 54.sp,
            ),

            SizedBox(
              height: 14.h,
            ),

            Text(
              'Playlist not found',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            SizedBox(
              height: 16.h,
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
              const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
class _Artwork
    extends StatelessWidget {
  final String? url;

  const _Artwork({
    required this.url,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    if (url == null ||
        url!.trim().isEmpty) {
      return Container(
        color: theme
            .colorScheme
            .surfaceContainerHighest,
        alignment:
        Alignment.center,
        child: Icon(
          Hicons.musicnoteLightOutline,
          size: 32.sp,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      url!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality:
      FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder:
          (_, __, ___) {
        return Container(
          color: theme
              .colorScheme
              .surfaceContainerHighest,
          alignment:
          Alignment.center,
          child: Icon(
            Hicons.musicnoteLightOutline,
            size: 32.sp,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        );
      },
      loadingBuilder:
          (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return Container(
          color: theme
              .colorScheme
              .surfaceContainerHighest,
          alignment:
          Alignment.center,
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child:
            CircularProgressIndicator(
              strokeWidth: 1.8,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}