import 'package:chameleon/features/library/playlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final MusicController controller =
      MusicControllerProvider.instance;

  @override
  void initState() {
    super.initState();

    controller.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.refreshLibrary();
    });
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshLibrary() async {
    await controller.refreshLibrary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final playlists = controller.playlists;
    final favorites = controller.favorites;
    final recentlyPlayed = controller.recentlyPlayed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshLibrary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  22.w,
                  20.h,
                  22.w,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _LibraryHeader(
                    playlistCount: playlists.length,
                    likedCount: favorites.length,
                  ),
                ),
              ),

              // =============================================================
              // PLAYLISTS
              // =============================================================

              if (playlists.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22.w,
                    30.h,
                    22.w,
                    0,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Playlists',
                      subtitle: 'Your music, your way.',
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.only(
                    top: 14.h,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _PlaylistHorizontalList(
                      playlists: playlists,
                    ),
                  ),
                ),
              ],

              // =============================================================
              // CREATE PLAYLIST
              // =============================================================

              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  22.w,
                  playlists.isEmpty ? 30.h : 20.h,
                  22.w,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CreatePlaylistButton(
                    onTap: () {
                      _showCreatePlaylistDialog(context);
                    },
                  ),
                ),
              ),

              // =============================================================
              // LIKED SONGS
              // =============================================================

              if (favorites.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22.w,
                    32.h,
                    22.w,
                    0,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Liked Songs',
                      subtitle: 'Songs you saved.',
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22.w,
                    12.h,
                    22.w,
                    0,
                  ),
                  sliver: SliverList.builder(
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final song = favorites[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 8.h,
                        ),
                        child: _SongTile(
                          song: song,
                          index: index,
                          favorite: true,
                          onTap: () async {
                            await controller.playSong(
                              song,
                              sourceQueue: favorites,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],

              // =============================================================
              // RECENTLY PLAYED
              // =============================================================

              if (recentlyPlayed.isNotEmpty) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22.w,
                    32.h,
                    22.w,
                    0,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Recently Played',
                      subtitle: 'Pick up where you left off.',
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    22.w,
                    12.h,
                    22.w,
                    0,
                  ),
                  sliver: SliverList.builder(
                    itemCount: recentlyPlayed.length,
                    itemBuilder: (context, index) {
                      final song = recentlyPlayed[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 8.h,
                        ),
                        child: _SongTile(
                          song: song,
                          index: index,
                          onTap: () async {
                            await controller.playSong(
                              song,
                              sourceQueue: recentlyPlayed,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],

              // =============================================================
              // EMPTY STATE
              // =============================================================

              if (playlists.isEmpty &&
                  favorites.isEmpty &&
                  recentlyPlayed.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyLibrary(
                    onCreatePlaylist: () {
                      _showCreatePlaylistDialog(context);
                    },
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130.h,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(
      BuildContext context,
      ) async {
    final controller = MusicControllerProvider.instance;

    final nameController = TextEditingController();

    try {
      final name = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (sheetContext) {
          final theme = Theme.of(sheetContext);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext)
                  .viewInsets
                  .bottom,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                22.w,
                10.h,
                22.w,
                22.h,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: theme
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .12),
                        borderRadius:
                        BorderRadius.circular(99.r),
                      ),
                    ),
                  ),

                  SizedBox(height: 22.h),

                  Text(
                    'Create playlist',
                    style: theme
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Text(
                    'Give your playlist a name.',
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization:
                    TextCapitalization.sentences,
                    textInputAction:
                    TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Playlist name',
                      filled: true,
                      fillColor:
                      theme.scaffoldBackgroundColor,
                      prefixIcon: const Icon(
                        Icons.queue_music_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(18.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) {
                      final trimmed = value.trim();

                      if (trimmed.isEmpty) {
                        return;
                      }

                      Navigator.of(sheetContext).pop(
                        trimmed,
                      );
                    },
                  ),

                  SizedBox(height: 14.h),

                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: FilledButton(
                      onPressed: () {
                        final trimmed =
                        nameController.text.trim();

                        if (trimmed.isEmpty) {
                          return;
                        }

                        Navigator.of(sheetContext).pop(
                          trimmed,
                        );
                      },
                      child: Text(
                        'Create playlist',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (name == null || name.trim().isEmpty) {
        return;
      }

      final playlistName = name.trim();

      // Create the playlist first.
      await controller.createPlaylist(
        name: playlistName,
      );

      // Reload persisted data.
      await controller.refreshLibrary();

      if (!mounted) {
        return;
      }

      // Find the actual newly-created playlist.
      Playlist? createdPlaylist;

      for (final playlist
      in controller.playlists.reversed) {
        if (playlist.name == playlistName) {
          createdPlaylist = playlist;
          break;
        }
      }

      if (createdPlaylist == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
            Text('Playlist was not created.'),
          ),
        );
        return;
      }

      // Rebuild first, then navigate on the next frame.
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          if (!mounted) {
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistScreen(
                playlistId:
                createdPlaylist!.id,
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not create playlist: $error',
          ),
        ),
      );
    } finally {
      nameController.dispose();
    }
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _LibraryHeader extends StatelessWidget {
  final int playlistCount;
  final int likedCount;

  const _LibraryHeader({
    required this.playlistCount,
    required this.likedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR LIBRARY',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 2.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Your music.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          '$playlistCount playlists  •  $likedCount liked',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
      begin: .04,
      end: 0,
      duration: 350.ms,
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 21.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 3.h),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// CREATE PLAYLIST
// =============================================================================

class _CreatePlaylistButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreatePlaylistButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 17.w,
            vertical: 14.h,
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Hicons.addLightOutline,
                  color: theme.colorScheme.surface,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  'Create playlist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: .03, end: 0);
  }
}

// =============================================================================
// PLAYLIST HORIZONTAL LIST
// =============================================================================

class _PlaylistHorizontalList extends StatelessWidget {
  final List<Playlist> playlists;

  const _PlaylistHorizontalList({
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 215.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: 22.w,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: playlists.length,
        separatorBuilder: (_, __) {
          return SizedBox(width: 12.w);
        },
        itemBuilder: (context, index) {
          return _PlaylistCard(
            playlist: playlists[index],
            index: index,
          );
        },
      ),
    );
  }
}

// =============================================================================
// PLAYLIST CARD
// =============================================================================

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int index;

  const _PlaylistCard({
    required this.playlist,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final songs = playlist.songs;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) {
              return PlaylistScreen(
                playlistId: playlist.id,
              );
            },
          ),
        );
      },
      child: SizedBox(
        width: 170.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(23.r),
              child: SizedBox(
                width: 170.w,
                height: 150.w,
                child: _PlaylistArtwork(
                  songs: songs,
                ),
              ),
            ),
            SizedBox(height: 9.h),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${songs.length} '
                  '${songs.length == 1 ? 'song' : 'songs'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.sp,
                color:
                theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (index * 40).ms,
      duration: 350.ms,
    )
        .slideX(
      begin: .04,
      end: 0,
      delay: (index * 40).ms,
      duration: 350.ms,
    );
  }
}

// =============================================================================
// PLAYLIST ARTWORK
// =============================================================================

class _PlaylistArtwork extends StatelessWidget {
  final List<Song> songs;

  const _PlaylistArtwork({
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return _ArtworkPlaceholder(
        icon: Icons.queue_music_rounded,
      );
    }

    final artwork = songs
        .map((song) => song.thumbnailUrl)
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .take(4)
        .toList();

    if (artwork.isEmpty) {
      return _ArtworkPlaceholder(
        icon: Icons.queue_music_rounded,
      );
    }

    if (artwork.length == 1) {
      return _Artwork(
        url: artwork.first,
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: artwork.length > 4
          ? 4
          : artwork.length,
      itemBuilder: (context, index) {
        return _Artwork(
          url: artwork[index],
        );
      },
    );
  }
}

// =============================================================================
// SONG TILE
// =============================================================================

class _SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final bool favorite;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.index,
    required this.onTap,
    this.favorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(13.r),
                child: SizedBox(
                  width: 55.w,
                  height: 55.w,
                  child: _Artwork(
                    url: song.thumbnailUrl,
                  ),
                ),
              ),
              SizedBox(width: 13.w),
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
                          .titleMedium
                          ?.copyWith(
                        fontSize: 14.sp,
                        fontWeight:
                        FontWeight.w600,
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
              SizedBox(width: 8.w),
              Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.more_horiz_rounded,
                size: favorite ? 19.sp : 22.sp,
                color: favorite
                    ? theme.colorScheme.primary
                    : theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (index * 25).ms,
      duration: 300.ms,
    )
        .slideY(
      begin: .025,
      end: 0,
      delay: (index * 25).ms,
      duration: 300.ms,
    );
  }
}

// =============================================================================
// ARTWORK
// =============================================================================

class _Artwork extends StatelessWidget {
  final String? url;

  const _Artwork({
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (url == null || url!.trim().isEmpty) {
      return _ArtworkPlaceholder(
        icon: Hicons.musicnoteLightOutline,
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return _ArtworkPlaceholder(
          icon: Hicons.musicnoteLightOutline,
        );
      },
      loadingBuilder: (
          context,
          child,
          loadingProgress,
          ) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// ARTWORK PLACEHOLDER
// =============================================================================

class _ArtworkPlaceholder extends StatelessWidget {
  final IconData icon;

  const _ArtworkPlaceholder({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          size: 34.sp,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY
// =============================================================================

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onCreatePlaylist;

  const _EmptyLibrary({
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 35.w,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                BorderRadius.circular(26.r),
              ),
              child: Icon(
                Icons.library_music_rounded,
                size: 35.sp,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Your library is empty',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              'Create a playlist or like a song '
                  'and it will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create playlist'),
            ),
          ],
        ),
      ),
    );
  }
}