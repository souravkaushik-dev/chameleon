import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';
import '../player/now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicController controller =
      MusicControllerProvider.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {
    await controller.refreshHome();
  }

  void _openSearch({
    String initialQuery = '',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(
        alpha: 0.35,
      ),
      builder: (_) {
        return _SearchSheet(
          initialQuery: initialQuery,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor:
          theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: theme.colorScheme.onSurface,
              backgroundColor:
              theme.colorScheme.surface,
              displacement: 28.h,
              child: CustomScrollView(
                physics:
                const BouncingScrollPhysics(
                  parent:
                  AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      22.w,
                      18.h,
                      22.w,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _Header(
                        onSearch: _openSearch,
                      )
                          .animate()
                          .fadeIn(
                        duration: 400.ms,
                      )
                          .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 400.ms,
                        curve:
                        Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  if (controller.isHomeLoading)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        12.h,
                        22.w,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child:
                        _LoadingIndicator(),
                      ),
                    ),
                  if (controller.errorMessage !=
                      null &&
                      !controller.isHomeLoading)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        12.h,
                        22.w,
                        0,
                      ),
                      sliver:
                      SliverToBoxAdapter(
                        child: _ErrorPill(
                          message: controller
                              .errorMessage!,
                        ),
                      ),
                    ),
                  if (controller.recentlyPlayed.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        22.h,
                        0,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Recently played',
                          subtitle:
                          'Pick up where you left off',
                        ),
                      ),
                    ),

                  if (controller.recentlyPlayed.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 12.h,
                        ),
                        child: _RecentlyPlayedList(
                          songs:
                          controller.recentlyPlayed,
                        ),
                      ),
                    ),
                  if (controller
                      .trendingSongs.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        28.h,
                        0,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child: _SectionTitle(
                          title: 'Trending now',
                          subtitle:
                          'Fresh from YouTube',
                        ),
                      ),
                    ),

                  if (controller
                      .trendingSongs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 10.h,
                        ),
                        child: _TrendingList(
                          songs:
                          controller.trendingSongs,
                        ),
                      ),
                    ),
                  if (controller
                      .trendingArtists.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        24.h,
                        0,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child: _SectionTitle(
                          title:
                          'Trending ',
                          subtitle:
                          'From your current feed',
                        ),
                      ),
                    ),

                  if (controller
                      .trendingArtists.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 9.h,
                        ),
                        child: _ArtistList(
                          artists: controller
                              .trendingArtists,
                          onArtistTap: (artist) {
                            _openSearch(
                              initialQuery: artist,
                            );
                          },
                        ),
                      ),
                    ),
                  if (controller
                      .suggestedSongs.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        26.h,
                        22.w,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child: _SectionTitle(
                          title:
                          'Suggested for you',
                          subtitle:
                          'More music to explore',
                        ),
                      ),
                    ),

                  if (controller
                      .suggestedSongs.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        10.h,
                        22.w,
                        0,
                      ),
                      sliver: SliverList.builder(
                        itemCount: controller
                            .suggestedSongs.length,
                        itemBuilder:
                            (context, index) {
                          final song = controller
                              .suggestedSongs[index];

                          return Padding(
                            padding:
                            EdgeInsets.only(
                              bottom: 7.h,
                            ),
                            child: _SongTile(
                              song: song,
                              index: index,
                            ),
                          );
                        },
                      ),
                    ),
                  if (controller
                      .playlists.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        26.h,
                        0,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child: _SectionTitle(
                          title:
                          'Your playlists',
                        ),
                      ),
                    ),

                  if (controller
                      .playlists.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 10.h,
                        ),
                        child: _PlaylistList(
                          playlists:
                          controller.playlists,
                        ),
                      ),
                    ),
                  if (controller
                      .favorites.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        26.h,
                        22.w,
                        0,
                      ),
                      sliver:
                      const SliverToBoxAdapter(
                        child: _SectionTitle(
                          title:
                          'Your favorites',
                        ),
                      ),
                    ),

                  if (controller
                      .favorites.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        22.w,
                        10.h,
                        22.w,
                        0,
                      ),
                      sliver: SliverList.builder(
                        itemCount:
                        controller.favorites.length,
                        itemBuilder:
                            (context, index) {
                          return Padding(
                            padding:
                            EdgeInsets.only(
                              bottom: 7.h,
                            ),
                            child: _SongTile(
                              song: controller
                                  .favorites[index],
                              index: index,
                              favorite: true,
                            ),
                          );
                        },
                      ),
                    ),
                  if (!controller.isHomeLoading &&
                      controller
                          .trendingSongs.isEmpty &&
                      controller
                          .suggestedSongs.isEmpty &&
                      controller
                          .recentlyPlayed.isEmpty &&
                      controller.favorites.isEmpty &&
                      controller.playlists.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHome(),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 150.h,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
Future<void> _playAndOpenNowPlaying(
    BuildContext context, {
      required Song song,
      List<Song>? sourceQueue,
      bool closeCurrentRoute = false,
    }) async {
  final controller =
      MusicControllerProvider.instance;

  await controller.playSong(
    song,
    sourceQueue: sourceQueue,
  );

  if (!context.mounted) {
    return;
  }

  final navigator = Navigator.of(
    context,
    rootNavigator: true,
  );

  if (closeCurrentRoute) {
    navigator.pop();

    await Future<void>.delayed(
      const Duration(milliseconds: 80),
    );

    if (!context.mounted) {
      return;
    }
  }

  navigator.push(
    PageRouteBuilder<void>(
      transitionDuration:
      const Duration(milliseconds: 420),
      reverseTransitionDuration:
      const Duration(milliseconds: 320),
      pageBuilder: (
          context,
          animation,
          secondaryAnimation,
          ) {
        return const NowPlayingScreen();
      },
      transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(
                0,
                0.035,
              ),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
Future<void> _showSongOptions(
    BuildContext context,
    Song song, {
      List<Song>? queue,
    }) async {
  final controller = MusicControllerProvider.instance;
  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final isFavorite = controller.isFavorite(song);

      return SafeArea(
        child: Container(
          margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 12.h),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13.r),
                      child: SizedBox(
                        width: 52.w,
                        height: 52.w,
                        child: _Artwork(
                          url: song.thumbnailUrl,
                          cropBlackBars: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _OptionTile(
                icon: isFavorite
                    ? Hicons.heart1Bold
                    : Hicons.heart1LightOutline,
                title: isFavorite ? 'Unlike' : 'Like',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await controller.toggleFavorite(song);
                  _showHomeMessage(
                    context,
                    isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites',
                  );
                },
              ),
              _OptionTile(
                  icon: Hicons.musicFilterBold,
                title: 'Add to queue',
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.addToQueue(song);
                  _showHomeMessage(context, 'Added to queue');
                },
              ),
              _OptionTile(
                icon: Hicons.folder1LightOutline,
                title: 'Add to playlist',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _showHomePlaylistPicker(context, song);
                },
              ),
              _OptionTile(
                icon: Hicons.playLightOutline,
                title: 'Play now',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _playAndOpenNowPlaying(
                    context,
                    song: song,
                    sourceQueue: queue,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showHomePlaylistPicker(
    BuildContext context,
    Song song,
    ) async {
  final controller = MusicControllerProvider.instance;
  final playlists = controller.playlists;

  if (playlists.isEmpty) {
    await _showHomeCreatePlaylistForSong(context, song);
    return;
  }

  if (!context.mounted) return;

  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.72.sh),
          margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
          padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to playlist',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showHomeCreatePlaylistForSong(context, song);
                      },
                      icon: const Icon(Hicons.addLightOutline),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];

                    return _PlaylistOption(
                      playlist: playlist,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await controller.addToPlaylist(
                          playlist.id,
                          song,
                        );
                        if (context.mounted) {
                          _showHomeMessage(
                            context,
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

Future<void> _showHomeCreatePlaylistForSong(
    BuildContext context,
    Song song,
    ) async {
  final controller = MusicControllerProvider.instance;
  final nameController = TextEditingController();

  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        title: const Text('New playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = nameController.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );

  nameController.dispose();

  if (name == null || name.trim().isEmpty) return;

  await controller.createPlaylist(name: name.trim());

  final playlists = controller.playlists;
  if (playlists.isEmpty) return;

  final created = playlists.last;

  await controller.addToPlaylist(created.id, song);

  if (context.mounted) {
    _showHomeMessage(context, 'Created ${created.name}');
  }
}

void _showHomeMessage(BuildContext context, String message) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
    );
}

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
      contentPadding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 2.h,
      ),
      leading: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 21.sp),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlaylistOption extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistOption({
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final songs = playlist.songs;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 18.w,
        vertical: 3.h,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 52.w,
          height: 52.w,
          child: _PlaylistArtwork(songs: songs),
        ),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
class _Header extends StatelessWidget {
  final VoidCallback onSearch;

  const _Header({
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'CHAMELEON',
                style: theme
                    .textTheme.bodySmall
                    ?.copyWith(
                  letterSpacing: 3.2,
                  fontWeight:
                  FontWeight.w700,
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                'Good music,\nno noise.',
                style: theme.textTheme
                    .displayLarge
                    ?.copyWith(
                  fontSize: 42.sp,
                  height: 0.98,
                  fontWeight:
                  FontWeight.w700,
                  letterSpacing: -1.8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          behavior:
          HitTestBehavior.opaque,
          onTap: onSearch,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color:
              theme.colorScheme.surface,
              borderRadius:
              BorderRadius.circular(
                22.r,
              ),
            ),
            child: Icon(
              Hicons.search1LightOutline,
              size: 26.sp,
              color:
              theme.colorScheme.onSurface,
            ),
          ),
        )
            .animate()
            .fadeIn(
          delay: 120.ms,
          duration: 350.ms,
        )
            .scale(
          begin:
          const Offset(0.9, 0.9),
          end:
          const Offset(1, 1),
          delay: 120.ms,
          duration: 350.ms,
          curve:
          Curves.easeOutBack,
        ),
      ],
    );
  }
}
class _SectionTitle
    extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme
              .titleLarge
              ?.copyWith(
            fontSize: 21.sp,
            fontWeight:
            FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding:
            EdgeInsets.only(
              top: 2.h,
            ),
            child: Text(
              subtitle!,
              style: theme.textTheme
                  .bodySmall
                  ?.copyWith(
                fontSize: 11.sp,
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
class _RecentlyPlayedList extends StatelessWidget {
  final List<Song> songs;

  const _RecentlyPlayedList({
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSongs = songs.take(10).toList();

    return SizedBox(
      height: 286.h,
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 22.w,
          right: 22.w,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visibleSongs.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: 14.w),
        itemBuilder: (context, index) {
          return _RecentlyPlayedCard(
            song: visibleSongs[index],
            index: index,
            songs: visibleSongs,
          );
        },
      ),
    );
  }
}
class _RecentlyPlayedCard extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songs;

  const _RecentlyPlayedCard({
    required this.song,
    required this.index,
    required this.songs,
  });

  Future<void> _play(BuildContext context) async {
    await _playAndOpenNowPlaying(
      context,
      song: song,
      sourceQueue: songs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _play(context),
      onLongPress: () => _showSongOptions(
        context,
        song,
        queue: songs,
      ),
      child: SizedBox(
        width: 236.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: SizedBox(
                width: 236.w,
                height: 236.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Artwork(
                      url: song.thumbnailUrl,
                      cropBlackBars: true,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.55, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.38),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14.w,
                      right: 14.w,
                      child: GestureDetector(
                        onTap: () => _showSongOptions(
                          context,
                          song,
                          queue: songs,
                        ),
                        child: Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Hicons.menuHamburger1LightOutline,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14.w,
                      bottom: 14.w,
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Hicons.playLightOutline,
                          color: Colors.black,
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 11.h),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (45 * index).ms,
      duration: 450.ms,
    )
        .slideX(
      begin: 0.07,
      end: 0,
      delay: (45 * index).ms,
      duration: 450.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
class _TrendingList
    extends StatelessWidget {
  final List<Song> songs;

  const _TrendingList({
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205.h,
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 22.w,
          right: 22.w,
        ),
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount: songs.length,
        separatorBuilder:
            (context, index) =>
            SizedBox(
              width: 11.w,
            ),
        itemBuilder:
            (context, index) {
          return _TrendingCard(
            song: songs[index],
            index: index,
          );
        },
      ),
    );
  }
}
class _TrendingCard
    extends StatelessWidget {
  final Song song;
  final int index;

  const _TrendingCard({
    required this.song,
    required this.index,
  });

  Future<void> _play(
      BuildContext context,
      ) async {
    await _playAndOpenNowPlaying(
      context,
      song: song,
      sourceQueue:
      MusicControllerProvider
          .instance
          .trendingSongs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: () => _play(context),
      onLongPress: () => _showSongOptions(
        context,
        song,
        queue: MusicControllerProvider.instance.trendingSongs,
      ),
      child: SizedBox(
        width: 158.w,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                25.r,
              ),
              child: SizedBox(
                width: 158.w,
                height: 158.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Artwork(
                      url: song.thumbnailUrl,
                      cropBlackBars: true,
                    ),
                    Positioned(
                      top: 10.w,
                      right: 10.w,
                      child: GestureDetector(
                        onTap: () => _showSongOptions(
                          context,
                          song,
                          queue: MusicControllerProvider.instance.trendingSongs,
                        ),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                            size: 21.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              song.title,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme.textTheme
                  .titleMedium
                  ?.copyWith(
                fontSize: 14.sp,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              song.artist,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme.textTheme
                  .bodySmall
                  ?.copyWith(
                fontSize: 11.sp,
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (35 * index).ms,
      duration: 400.ms,
    )
        .slideX(
      begin: 0.05,
      end: 0,
      delay: (35 * index).ms,
      duration: 400.ms,
      curve:
      Curves.easeOutCubic,
    );
  }
}
class _ArtistList
    extends StatelessWidget {
  final List<String> artists;
  final ValueChanged<String>
  onArtistTap;

  const _ArtistList({
    required this.artists,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 22.w,
          right: 22.w,
        ),
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount: artists.length,
        separatorBuilder:
            (context, index) =>
            SizedBox(
              width: 7.w,
            ),
        itemBuilder:
            (context, index) {
          return _ArtistChip(
            name: artists[index],
            index: index,
            onTap: () =>
                onArtistTap(
                  artists[index],
                ),
          );
        },
      ),
    );
  }
}

class _ArtistChip
    extends StatelessWidget {
  final String name;
  final int index;
  final VoidCallback onTap;

  const _ArtistChip({
    required this.name,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints:
        BoxConstraints(
          minWidth: 70.w,
        ),
        padding:
        EdgeInsets.symmetric(
          horizontal: 15.w,
        ),
        decoration:
        BoxDecoration(
          color: theme
              .colorScheme.surface,
          borderRadius:
          BorderRadius.circular(
            18.r,
          ),
        ),
        alignment:
        Alignment.center,
        child: Text(
          name,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style: theme.textTheme
              .bodyMedium
              ?.copyWith(
            fontSize: 12.sp,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (25 * index).ms,
      duration: 320.ms,
    )
        .slideX(
      begin: 0.04,
      end: 0,
      delay: (25 * index).ms,
      duration: 320.ms,
    );
  }
}
class _SongTile
    extends StatelessWidget {
  final Song song;
  final int index;
  final bool favorite;

  const _SongTile({
    required this.song,
    required this.index,
    this.favorite = false,
  });

  String _durationText() {
    final duration =
        song.duration;

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
    final theme =
    Theme.of(context);

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: () async {
        await _playAndOpenNowPlaying(
          context,
          song: song,
        );
      },
      onLongPress: () => _showSongOptions(context, song),
      child: Container(
        padding:
        EdgeInsets.all(8.w),
        decoration:
        BoxDecoration(
          color:
          theme.colorScheme.surface,
          borderRadius:
          BorderRadius.circular(
            22.r,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                16.r,
              ),
              child: SizedBox(
                width: 58.w,
                height: 58.w,
                child: _Artwork(
                  url:
                  song.thumbnailUrl,
                  cropBlackBars: true,
                ),
              ),
            ),
            SizedBox(width: 12.w),
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
                    TextOverflow.ellipsis,
                    style: theme.textTheme
                        .titleMedium
                        ?.copyWith(
                      fontSize: 14.sp,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
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
                      ),
                      if (_durationText()
                          .isNotEmpty) ...[
                        SizedBox(
                          width: 7.w,
                        ),
                        Text(
                          '•',
                          style:
                          TextStyle(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        SizedBox(
                          width: 7.w,
                        ),
                        Text(
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
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              favorite
                  ? Hicons
                  .heart1LightOutline
                  : Icons
                  .more_horiz_rounded,
              size: favorite
                  ? 18.sp
                  : 21.sp,
              color: favorite
                  ? theme
                  .colorScheme
                  .onSurface
                  : theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (20 * index).ms,
      duration: 330.ms,
    )
        .slideY(
      begin: 0.025,
      end: 0,
      delay: (20 * index).ms,
      duration: 330.ms,
      curve:
      Curves.easeOutCubic,
    );
  }
}
class _PlaylistList
    extends StatelessWidget {
  final List<Playlist> playlists;

  const _PlaylistList({
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205.h,
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 22.w,
          right: 22.w,
        ),
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount: playlists.length,
        separatorBuilder:
            (context, index) =>
            SizedBox(
              width: 11.w,
            ),
        itemBuilder:
            (context, index) {
          return _PlaylistCard(
            playlist:
            playlists[index],
            index: index,
          );
        },
      ),
    );
  }
}

class _PlaylistCard
    extends StatelessWidget {
  final Playlist playlist;
  final int index;

  const _PlaylistCard({
    required this.playlist,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final songs =
        playlist.songs;
    final theme =
    Theme.of(context);

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: songs.isEmpty
          ? null
          : () async {
        await _playAndOpenNowPlaying(
          context,
          song: songs.first,
          sourceQueue: songs,
        );
      },
      child: SizedBox(
        width: 170.w,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                24.r,
              ),
              child: SizedBox(
                width: 170.w,
                height: 150.w,
                child:
                _PlaylistArtwork(
                  songs: songs,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              playlist.name,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme.textTheme
                  .titleMedium
                  ?.copyWith(
                fontSize: 14.sp,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
              style: theme.textTheme
                  .bodySmall
                  ?.copyWith(
                fontSize: 11.sp,
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (30 * index).ms,
      duration: 350.ms,
    )
        .slideX(
      begin: 0.04,
      end: 0,
      delay: (30 * index).ms,
      duration: 350.ms,
    );
  }
}
class _PlaylistArtwork
    extends StatelessWidget {
  final List<Song> songs;

  const _PlaylistArtwork({
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const _EmptyArtwork();
    }

    if (songs.length == 1) {
      return _Artwork(
        url: songs.first.thumbnailUrl,
        cropBlackBars: true,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _Artwork(
          url: songs.first.thumbnailUrl,
          cropBlackBars: true,
        ),
        Positioned(
          right: -16.w,
          bottom: -16.w,
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(
              20.r,
            ),
            child: SizedBox(
              width: 105.w,
              height: 105.w,
              child: _Artwork(
                url:
                songs[1].thumbnailUrl,
                cropBlackBars: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _Artwork
    extends StatelessWidget {
  final String? url;
  final bool cropBlackBars;

  const _Artwork({
    required this.url,
    this.cropBlackBars = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    if (url == null ||
        url!.trim().isEmpty) {
      return const _EmptyArtwork();
    }

    Widget image({
      double scale = 1,
    }) {
      return Transform.scale(
        scale: scale,
        child: Image.network(
          url!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment:
          Alignment.center,
          filterQuality:
          FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return const _EmptyArtwork();
          },
          loadingBuilder: (
              context,
              child,
              progress,
              ) {
            if (progress == null) {
              return child;
            }

            return Container(
              color: theme
                  .colorScheme
                  .surface,
              alignment:
              Alignment.center,
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child:
                CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      );
    }

    return ClipRect(
      child: cropBlackBars
          ? image(scale: 1.42)
          : image(),
    );
  }
}
class _EmptyArtwork
    extends StatelessWidget {
  const _EmptyArtwork();

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Container(
      color:
      theme.colorScheme.surface,
      alignment:
      Alignment.center,
      child: Icon(
        Hicons.musicnoteLightOutline,
        size: 34.sp,
        color: theme.colorScheme
            .onSurfaceVariant,
      ),
    );
  }
}
class _LoadingIndicator
    extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 14.w,
          height: 14.w,
          child:
          CircularProgressIndicator(
            strokeWidth: 1.6,
            color:
            theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 9.w),
        Text(
          'Refreshing music',
          style: theme.textTheme
              .bodySmall
              ?.copyWith(
            color: theme.colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(
      duration: 250.ms,
    );
  }
}
class _ErrorPill
    extends StatelessWidget {
  final String message;

  const _ErrorPill({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Container(
      padding:
      EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 10.h,
      ),
      decoration:
      BoxDecoration(
        color:
        theme.colorScheme.surface,
        borderRadius:
        BorderRadius.circular(
          17.r,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Hicons.informationCircleBold,
            size: 17.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Music could not be refreshed.',
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme.textTheme
                  .bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyHome
    extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Center(
      child: Padding(
        padding:
        EdgeInsets.symmetric(
          horizontal: 42.w,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration:
              BoxDecoration(
                color: theme
                    .colorScheme
                    .surface,
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                Hicons.musicnoteLightOutline,
                size: 30.sp,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Nothing here yet.',
              textAlign:
              TextAlign.center,
              style: theme.textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Pull down to discover fresh music.',
              textAlign:
              TextAlign.center,
              style: theme.textTheme
                  .bodyMedium
                  ?.copyWith(
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SearchSheet
    extends StatefulWidget {
  final String initialQuery;

  const _SearchSheet({
    this.initialQuery = '',
  });

  @override
  State<_SearchSheet> createState() =>
      _SearchSheetState();
}

class _SearchSheetState
    extends State<_SearchSheet> {
  late final TextEditingController
  _searchController;

  late final FocusNode _focusNode;

  Timer? _debounce;

  final controller =
      MusicControllerProvider.instance;

  @override
  void initState() {
    super.initState();

    _searchController =
        TextEditingController(
          text: widget.initialQuery,
        );

    _focusNode = FocusNode();

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        if (!mounted) {
          return;
        }

        _focusNode.requestFocus();

        if (widget.initialQuery
            .trim()
            .isNotEmpty) {
          controller.search(
            widget.initialQuery,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(
      String value,
      ) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      controller.clearSearch();
      return;
    }

    _debounce = Timer(
      const Duration(
        milliseconds: 350,
      ),
          () {
        controller.search(query);
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

    await controller.search(query);

    if (mounted) {
      FocusScope.of(context)
          .unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.62,
          maxChildSize: 0.96,
          expand: false,
          snap: true,
          snapSizes: const [
            0.86,
            0.96,
          ],
          builder:
              (context, scrollController) {
            return Container(
              decoration:
              BoxDecoration(
                color: theme
                    .scaffoldBackgroundColor,
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(
                    34.r,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding:
                    EdgeInsets.only(
                      top: 10.h,
                      bottom: 6.h,
                    ),
                    child: Container(
                      width: 36.w,
                      height: 4.h,
                      decoration:
                      BoxDecoration(
                        color: theme
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          99.r,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(
                      18.w,
                      7.h,
                      18.w,
                      10.h,
                    ),
                    child: Container(
                      height: 56.h,
                      decoration:
                      BoxDecoration(
                        color: theme
                            .colorScheme
                            .surface,
                        borderRadius:
                        BorderRadius
                            .circular(
                          21.r,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 17.w,
                          ),
                          Icon(
                            Hicons
                                .search1LightOutline,
                            size: 23.sp,
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          SizedBox(
                            width: 10.w,
                          ),
                          Expanded(
                            child:
                            TextField(
                              controller:
                              _searchController,
                              focusNode:
                              _focusNode,
                              textInputAction:
                              TextInputAction
                                  .search,
                              onChanged:
                              _onSearchChanged,
                              onSubmitted:
                              _submit,
                              style: theme
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontSize:
                                15.sp,
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                              decoration:
                              InputDecoration(
                                hintText:
                                'Search songs, artists...',
                                hintStyle:
                                theme
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: theme
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                border:
                                InputBorder
                                    .none,
                                enabledBorder:
                                InputBorder
                                    .none,
                                focusedBorder:
                                InputBorder
                                    .none,
                                contentPadding:
                                EdgeInsets
                                    .zero,
                              ),
                            ),
                          ),
                          if (_searchController
                              .text
                              .isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController
                                    .clear();
                                controller
                                    .clearSearch();
                                _focusNode
                                    .requestFocus();
                                setState(() {});
                              },
                              child:
                              Container(
                                width: 32.w,
                                height: 32.w,
                                margin:
                                EdgeInsets
                                    .only(
                                  right: 10.w,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: theme
                                      .scaffoldBackgroundColor,
                                  shape:
                                  BoxShape
                                      .circle,
                                ),
                                child:
                                Icon(
                                  Hicons
                                      .closeLightOutline,
                                  size: 17.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                    _SearchResults(
                      scrollController:
                      scrollController,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
              duration: 250.ms,
            )
                .slideY(
              begin: 0.035,
              end: 0,
              duration: 350.ms,
              curve:
              Curves.easeOutCubic,
            );
          },
        );
      },
    );
  }
}
class _SearchResults
    extends StatelessWidget {
  final ScrollController
  scrollController;

  const _SearchResults({
    required this.scrollController,
  });

  String _durationText(
      Song song,
      ) {
    final duration =
        song.duration;

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
    final theme =
    Theme.of(context);

    final controller =
        MusicControllerProvider
            .instance;

    if (controller.isSearching) {
      return const Center(
        child:
        CircularProgressIndicator(
          strokeWidth: 1.8,
        ),
      )
          .animate()
          .fadeIn(
        duration: 200.ms,
      );
    }

    final results =
        controller.searchResults;

    if (results.isEmpty) {
      return SingleChildScrollView(
        controller:
        scrollController,
        physics:
        const BouncingScrollPhysics(),
        child: SizedBox(
          height: 450.h,
          child: Center(
            child: Padding(
              padding:
              EdgeInsets.symmetric(
                horizontal: 35.w,
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70.w,
                    height: 70.w,
                    decoration:
                    BoxDecoration(
                      color: theme
                          .colorScheme
                          .surface,
                      shape:
                      BoxShape.circle,
                    ),
                    child: Icon(
                      Hicons
                          .musicnoteLightOutline,
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  Text(
                    'Find your next song.',
                    textAlign:
                    TextAlign.center,
                    style: theme
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    height: 6.h,
                  ),
                  Text(
                    'Search for a song or artist to explore YouTube.',
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
          ),
        ),
      );
    }

    return ListView.builder(
      controller:
      scrollController,
      padding: EdgeInsets.fromLTRB(
        18.w,
        4.h,
        18.w,
        35.h,
      ),
      physics:
      const BouncingScrollPhysics(),
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior
          .onDrag,
      itemCount: results.length,
      itemBuilder:
          (context, index) {
        final song =
        results[index];

        return Padding(
          padding:
          EdgeInsets.only(
            bottom: 7.h,
          ),
          child: _SearchResultTile(
            song: song,
            index: index,
            durationText:
            _durationText(song),
          ),
        );
      },
    );
  }
}
class _SearchResultTile
    extends StatelessWidget {
  final Song song;
  final int index;
  final String durationText;

  const _SearchResultTile({
    required this.song,
    required this.index,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: () async {
        await _playAndOpenNowPlaying(
          context,
          song: song,
          closeCurrentRoute: true,
        );
      },
      child: Container(
        padding:
        EdgeInsets.all(8.w),
        decoration:
        BoxDecoration(
          color:
          theme.colorScheme.surface,
          borderRadius:
          BorderRadius.circular(
            21.r,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(
                15.r,
              ),
              child: SizedBox(
                width: 62.w,
                height: 62.w,
                child: _Artwork(
                  url:
                  song.thumbnailUrl,
                  cropBlackBars: true,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: theme.textTheme
                        .titleMedium
                        ?.copyWith(
                      fontSize: 13.5.sp,
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
                    style: theme.textTheme
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
            if (durationText.isNotEmpty)
              Padding(
                padding:
                EdgeInsets.only(
                  left: 7.w,
                  right: 4.w,
                ),
                child: Text(
                  durationText,
                  style: theme.textTheme
                      .bodySmall
                      ?.copyWith(
                    fontSize: 10.sp,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
      delay: (index * 25).ms,
      duration: 300.ms,
    )
        .slideX(
      begin: 0.04,
      end: 0,
      delay: (index * 25).ms,
      duration: 300.ms,
      curve:
      Curves.easeOutCubic,
    );
  }
}

