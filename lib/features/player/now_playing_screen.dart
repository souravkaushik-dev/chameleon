import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';
import 'lyrics_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final MusicController controller = MusicControllerProvider.instance;

  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;

  double _lyricsDragDistance = 0;

  void _openLyrics(BuildContext context, Song song) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, __) => LyricsScreen(song: song),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleLyricsDragUpdate(DragUpdateDetails details) {
    _lyricsDragDistance += details.primaryDelta ?? 0;
  }

  void _handleLyricsDragEnd(BuildContext context, Song song) {
    if (_lyricsDragDistance < -55) {
      _openLyrics(context, song);
    }
    _lyricsDragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final Song? song = controller.currentSong;

        if (song == null) {
          return _EmptyPlayer(
            onClose: () {
              Navigator.of(context).pop();
            },
          );
        }

        final playback = controller.playbackState;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CinematicArtwork(
                  key: ValueKey(song.id),
                  url: song.thumbnailUrl,
                ),
                const _CinematicGradient(),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _GlassFloatingButton(
                            icon: Hicons.down2LightOutline,
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          ),

                          _GlassFloatingButton(
                            icon: Icons.more_horiz_rounded,
                            onTap: () {
                              _showSongOptions(context, song);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: _handleLyricsDragUpdate,
                      onVerticalDragEnd: (_) {
                        _handleLyricsDragEnd(context, song);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                            child: _BottomControls(
                              song: song,
                              isPlaying: playback.isPlaying,
                              position: playback.position,
                              duration: playback.duration,
                              isFavorite: controller.isFavorite(song),
                              shuffleEnabled: _shuffleEnabled,
                              repeatEnabled: _repeatEnabled,
                              hasPrevious: controller.hasPrevious,
                              hasNext: controller.hasNext,
                              onFavorite: () async {
                                await controller.toggleFavorite(song);
                              },
                              onShuffle: () {
                                setState(() {
                                  _shuffleEnabled = !_shuffleEnabled;
                                });
                              },
                              onRepeat: () {
                                setState(() {
                                  _repeatEnabled = !_repeatEnabled;
                                });
                              },
                              onPrevious: () async {
                                await controller.previous();
                              },
                              onPlayPause: () async {
                                await controller.togglePlayPause();
                              },
                              onNext: () async {
                                await controller.next();
                              },
                              onQueue: () {
                                _showQueue(context);
                              },
                              onSeek: (position) async {
                                await controller.seek(position);
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
                            child: _LyricsPeekPanel(
                              onTap: () => _openLyrics(context, song),
                            ),
                          ),
                        ],
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
  }

  void _showSongOptions(BuildContext context, Song song) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),

              SizedBox(height: 18.h),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13.r),
                    child: SizedBox(
                      width: 56.w,
                      height: 56.w,
                      child: Image.network(
                        song.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color:
                            theme.colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Icon(
                              Hicons.musicnoteLightOutline,
                              size: 25.sp,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(width: 13.w),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4.h),
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

              SizedBox(height: 18.h),
              _OptionTile(
                icon: Hicons.musicFilterBold,
                title: 'Add to queue',
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  controller.addToQueue(song);

                  _showMessage(context, 'Added to queue');
                },
              ),
              _OptionTile(
                icon: Icons.playlist_add_rounded,
                title: 'Add to playlist',
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  _showPlaylistPicker(context, song);
                },
              ),
              _OptionTile(
                icon: controller.isFavorite(song)
                    ? Hicons.heart1Bold
                    : Hicons.heart1LightOutline,
                title: controller.isFavorite(song)
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onTap: () async {
                  Navigator.of(sheetContext).pop();

                  await controller.toggleFavorite(song);
                },
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 220.ms)
            .slideY(
          begin: 0.04,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
      },
    );
  }
  void _showPlaylistPicker(BuildContext context, Song song) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final theme = Theme.of(context);

            final playlists = controller.playlists;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.78,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32.r),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),

                  const _SheetHandle(),

                  Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 18.h, 16.w, 14.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Add to playlist',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.of(sheetContext).pop();

                            _showCreatePlaylistForSong(context, song);
                          },
                          child: Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Hicons.addLightOutline,
                              size: 23.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (playlists.isEmpty)
                    Expanded(
                      child: _EmptyPlaylistState(
                        onCreate: () {
                          Navigator.of(sheetContext).pop();

                          _showCreatePlaylistForSong(context, song);
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 28.h),
                        physics: const BouncingScrollPhysics(),
                        itemCount: playlists.length,
                        separatorBuilder: (_, __) => SizedBox(height: 7.h),
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];

                          final alreadyAdded = playlist.songs.any(
                                (item) => item.id == song.id,
                          );

                          return _PlaylistPickerTile(
                            playlist: playlist,
                            alreadyAdded: alreadyAdded,
                            onTap: alreadyAdded
                                ? null
                                : () async {
                              await controller.addToPlaylist(
                                playlist.id,
                                song,
                              );

                              if (!sheetContext.mounted) {
                                return;
                              }

                              Navigator.of(sheetContext).pop();

                              _showMessage(
                                context,
                                'Added to ${playlist.name}',
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .slideY(
              begin: 0.04,
              end: 0,
              duration: 330.ms,
              curve: Curves.easeOutCubic,
            );
          },
        );
      },
    );
  }
  void _showCreatePlaylistForSong(BuildContext context, Song song) {
    final nameController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 22.h),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                  ),
                ),

                SizedBox(height: 22.h),

                Text(
                  'New playlist',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  'Create a playlist and add this song.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                SizedBox(height: 20.h),

                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Playlist name',
                    prefixIcon: const Icon(Hicons.musicFilterBold),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: 14.h),

                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        return;
                      }

                      final playlist = await controller.createPlaylist(
                        name: name,
                      );

                      if (playlist == null) {
                        return;
                      }

                      await controller.addToPlaylist(playlist.id, song);

                      if (!sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(sheetContext).pop();

                      _showMessage(context, 'Created ${playlist.name}');
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
        )
            .animate()
            .fadeIn(duration: 220.ms)
            .slideY(
          begin: 0.04,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
      },
    ).whenComplete(nameController.dispose);
  }
  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final theme = Theme.of(context);

            final queue = controller.upcomingQueue;

            final current = controller.currentSong;

            return Container(
              height: MediaQuery.sizeOf(context).height * 0.82,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32.r),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),

                  const _SheetHandle(),

                  Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 18.h, 16.w, 12.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Queue',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  fontSize: 25.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '${queue.length} ${queue.length == 1 ? 'song' : 'songs'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (queue.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              controller.clearQueue();
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: queue.isEmpty
                        ? const _EmptyQueueState()
                        : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        18.w,
                        4.h,
                        18.w,
                        28.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: queue.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: 6.h),
                      itemBuilder: (context, index) {
                        final queueSong = queue[index];

                        final isCurrent = current?.id == queueSong.id;

                        return _QueueSongTile(
                          song: queueSong,
                          isCurrent: isCurrent,
                          index: index,
                          onTap: () async {
                            await controller.playSong(
                              queueSong,
                              sourceQueue: queue,
                            );

                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          onRemove: isCurrent
                              ? null
                              : () {
                            controller.removeFromQueue(index);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .slideY(
              begin: 0.04,
              end: 0,
              duration: 330.ms,
              curve: Curves.easeOutCubic,
            );
          },
        );
      },
    );
  }
  void _showMessage(BuildContext context, String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}

class _LyricsPeekPanel extends StatelessWidget {
  final VoidCallback onTap;

  const _LyricsPeekPanel({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 76.h,
        width: double.infinity,
        child: LiquidGlassLens(
          style: LiquidGlassStyle(
            shape: LiquidGlassShape.continuousRoundedRectangle(
              cornerRadius: 27,
              borderWidth: 0,
              borderColor: Colors.transparent,
              lightIntensity: 0,
              borderType: const OpticalBorder(
                borderSolidity: 0,
                ambientIntensity: 0,
              ),
            ),
            appearance: LiquidGlassAppearance(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.13),
              blur: const LiquidGlassBlur(
                sigmaX: 3,
                sigmaY: 3,
              ),
              saturation: 1.02,
            ),
            refraction: const LiquidGlassRefraction(
              distortion: 0.035,
              distortionWidth: 22,
              magnification: 1.0,
              chromaticAberration: 0.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 10.h, 10.w, 10.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lyrics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                _LyricsPeekAction(
                  icon: Icons.ios_share_rounded,
                  onTap: onTap,
                ),
                SizedBox(width: 7.w),
                _LyricsPeekAction(
                  icon: Icons.open_in_full_rounded,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 220.ms, duration: 420.ms)
        .slideY(
      begin: 0.08,
      end: 0,
      delay: 220.ms,
      duration: 480.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

class _LyricsPeekAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _LyricsPeekAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 42.w,
        height: 42.w,
        child: LiquidGlassLens(
          style: LiquidGlassStyle(
            shape: LiquidGlassShape.continuousRoundedRectangle(
              cornerRadius: 21,
              borderWidth: 0,
              borderColor: Colors.transparent,
              lightIntensity: 0,
              borderType: const OpticalBorder(
                borderSolidity: 0,
                ambientIntensity: 0,
              ),
            ),
            appearance: LiquidGlassAppearance(
              color: Colors.white.withValues(alpha: 0.10),
              blur: const LiquidGlassBlur(
                sigmaX: 2,
                sigmaY: 2,
              ),
            ),
            refraction: const LiquidGlassRefraction(
              distortion: 0.025,
              distortionWidth: 18,
              magnification: 1.0,
              chromaticAberration: 0.0,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.86),
            size: 18.sp,
          ),
        ),
      ),
    );
  }
}

class _CinematicArtwork extends StatelessWidget {
  final String? url;

  const _CinematicArtwork({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            color: Colors.white24,
            size: 70,
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Image.network(
          url!,
          key: ValueKey(url),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Icon(
                  Hicons.musicnoteLightOutline,
                  color: Colors.white24,
                  size: 70,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 1.5,
                ),
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
      begin: const Offset(1.025, 1.025),
      end: const Offset(1, 1),
      duration: 700.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
class _CinematicGradient extends StatelessWidget {
  const _CinematicGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.00, 0.32, 0.55, 0.70, 0.84, 1.00],
              colors: [
                Colors.black.withValues(alpha: 0.32),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
                Colors.black.withValues(alpha: 0.68),
                Colors.black.withValues(alpha: 0.98),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _BottomControls extends StatelessWidget {
  final Song song;

  final bool isPlaying;
  final Duration position;
  final Duration duration;

  final bool isFavorite;
  final bool shuffleEnabled;
  final bool repeatEnabled;

  final bool hasPrevious;
  final bool hasNext;

  final VoidCallback onFavorite;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onQueue;

  final ValueChanged<Duration> onSeek;

  const _BottomControls({
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.isFavorite,
    required this.shuffleEnabled,
    required this.repeatEnabled,
    required this.hasPrevious,
    required this.hasNext,
    required this.onFavorite,
    required this.onShuffle,
    required this.onRepeat,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onQueue,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21.sp,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.55,
                      shadows: const [
                        Shadow(blurRadius: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 14.w),

            _BottomIcon(
              icon: isFavorite
                  ? Hicons.heart1Bold
                  : Hicons.heart1LightOutline,
              active: isFavorite,
              size: 27.sp,
              onTap: onFavorite,
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(
          begin: 0.04,
          end: 0,
          delay: 100.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        ),

        SizedBox(height: 12.h),
        _CinematicProgress(
          position: position,
          duration: duration,
          onSeek: onSeek,
        ),

        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BottomIcon(
              icon: Hicons.shuffle1LightOutline,
              active: shuffleEnabled,
              onTap: onShuffle,
            ),

            _BottomIcon(
              icon: Hicons.previousLightOutline,
              size: 34.sp,
              enabled: hasPrevious,
              onTap: onPrevious,
            ),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPlayPause,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 20,
                    sigmaY: 20,
                  ),
                  child: Container(
                    width: 68.w,
                    height: 68.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      // True translucent glass
                      color: Colors.white.withValues(alpha: 0.18),

                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        isPlaying
                            ? Hicons.pauseLightOutline
                            : Hicons.playLightOutline,
                        key: ValueKey(isPlaying),
                        color: Colors.white,
                        size: 34.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            _BottomIcon(
              icon: Hicons.nextLightOutline,
              size: 34.sp,
              enabled: hasNext,
              onTap: onNext,
            ),

            _BottomIcon(
              icon: Hicons.repeate1LightOutline,
              active: repeatEnabled,
              onTap: onRepeat,
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 160.ms, duration: 450.ms)
            .slideY(
          begin: 0.05,
          end: 0,
          delay: 160.ms,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        ),

        SizedBox(height: 3.h),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onQueue,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Hicons.musicFilterBold,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Queue',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
class _CinematicProgress extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _CinematicProgress({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  String _format(Duration value) {
    if (value.isNegative) {
      value = Duration.zero;
    }

    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final durationMs =
        duration.inMilliseconds;

    final safeDurationMs =
    durationMs > 0
        ? durationMs
        : 1;

    final positionMs =
    position.inMilliseconds.clamp(
      0,
      safeDurationMs,
    );

    final progress =
    (positionMs / safeDurationMs)
        .clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: LiquidGlassSlider(
            value: progress,
            onChanged: (value) {
              final safeValue =
              value.clamp(0.0, 1.0);

              final seekPosition =
              Duration(
                milliseconds:
                (safeValue *
                    safeDurationMs)
                    .round(),
              );

              onSeek(seekPosition);
            },
          ),
        ),

        SizedBox(
          height: 1.h,
        ),

        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(position),
              style: TextStyle(
                color:
                Colors.white.withValues(
                  alpha: 0.48,
                ),
                fontSize: 10.sp,
                fontWeight:
                FontWeight.w500,
              ),
            ),
            Text(
              _format(duration),
              style: TextStyle(
                color:
                Colors.white.withValues(
                  alpha: 0.48,
                ),
                fontSize: 10.sp,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  final bool enabled;
  final bool active;
  final double? size;

  const _BottomIcon({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.active = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 44.w,
        height: 44.w,
        child: Icon(
          icon,
          size: size ?? 21.sp,
          color: !enabled
              ? Colors.white24
              : active
              ? Colors.white
              : Colors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24.sp),
      ),
    );
  }
}
class _QueueSongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _QueueSongTile({
    required this.song,
    required this.isCurrent,
    required this.index,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.surface
              : theme.colorScheme.surface.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(21.r),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child: SizedBox(
                width: 58.w,
                height: 58.w,
                child: Image.network(
                  song.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: theme.colorScheme.surface,
                      alignment: Alignment.center,
                      child: Icon(Hicons.musicnoteLightOutline, size: 24.sp),
                    );
                  },
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            if (isCurrent)
              Icon(
                Hicons.voiceLightOutline,
                size: 21.sp,
                color: theme.colorScheme.onSurface,
              )
            else if (onRemove != null)
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: Icon(
                  Hicons.closeLightOutline,
                  size: 20.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 25).ms, duration: 300.ms)
        .slideX(begin: 0.04, end: 0, delay: (index * 25).ms, duration: 300.ms);
  }
}
class _PlaylistPickerTile extends StatelessWidget {
  final Playlist playlist;
  final bool alreadyAdded;
  final VoidCallback? onTap;

  const _PlaylistPickerTile({
    required this.playlist,
    required this.alreadyAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(9.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: SizedBox(
                width: 58.w,
                height: 58.w,
                child:
                playlist.artworkUrl != null &&
                    playlist.artworkUrl!.isNotEmpty
                    ? Image.network(
                  playlist.artworkUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _playlistIcon(theme);
                  },
                )
                    : _playlistIcon(theme),
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              alreadyAdded
                  ? Hicons.ticket1LightOutline
                  : Hicons.right2LightOutline,
              color: alreadyAdded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 22.sp,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.03, end: 0, duration: 280.ms);
  }

  Widget _playlistIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Hicons.musicFilterBold, size: 26.sp),
    );
  }
}
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99.r),
      ),
    );
  }
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: theme.colorScheme.onSurface),
            SizedBox(width: 15.w),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _EmptyPlaylistState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPlaylistState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 52.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),

            SizedBox(height: 14.h),

            Text(
              'No playlists yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 6.h),

            Text(
              'Create a playlist to save this song.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 18.h),

            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Hicons.addLightOutline),
              label: const Text('Create playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
class _EmptyQueueState extends StatelessWidget {
  const _EmptyQueueState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Hicons.musicFilterBold,
            size: 54.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'Queue is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Add songs from the menu.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyPlayer extends StatelessWidget {
  final VoidCallback onClose;

  const _EmptyPlayer({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_off_rounded, color: Colors.white38, size: 55.sp),

              SizedBox(height: 15.h),

              Text(
                'Nothing is playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 18.h),

              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Text(
                    'Go back',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _GlassFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassFloatingButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 21.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
