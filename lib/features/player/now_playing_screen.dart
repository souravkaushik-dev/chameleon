import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({
    super.key,
  });

  @override
  State<NowPlayingScreen> createState() =>
      _NowPlayingScreenState();
}

class _NowPlayingScreenState
    extends State<NowPlayingScreen> {
  final MusicController controller =
      MusicControllerProvider.instance;

  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final Song? song =
            controller.currentSong;

        if (song == null) {
          return _EmptyPlayer(
            onClose: () {
              Navigator.of(context).pop();
            },
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ===========================================================
                // FULLSCREEN ARTWORK
                // ===========================================================

                _CinematicArtwork(
                  key: ValueKey(song.id),
                  url: song.thumbnailUrl,
                ),

                // ===========================================================
                // CINEMATIC GRADIENT
                // ===========================================================

                const _CinematicGradient(),

                // ===========================================================
                // TOP CONTROLS
                // ===========================================================

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16.w,
                        10.h,
                        16.w,
                        0,
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          _FloatingButton(
                            icon: Icons
                                .keyboard_arrow_down_rounded,
                            onTap: () {
                              Navigator.of(context)
                                  .pop();
                            },
                          ),
                          _FloatingButton(
                            icon:
                            Icons.more_horiz_rounded,
                            onTap: () {
                              _showSongOptions(
                                context,
                                song,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ===========================================================
                // BOTTOM PLAYER
                // ===========================================================

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        0,
                        20.w,
                        12.h,
                      ),
                      child: _BottomControls(
                        song: song,
                        isPlaying: controller
                            .playbackState
                            .isPlaying,
                        position: controller
                            .playbackState
                            .position,
                        duration: controller
                            .playbackState
                            .duration,
                        isFavorite:
                        controller.isFavorite(
                          song,
                        ),
                        shuffleEnabled:
                        _shuffleEnabled,
                        repeatEnabled:
                        _repeatEnabled,
                        hasPrevious:
                        controller.hasPrevious,
                        hasNext:
                        controller.hasNext,
                        onFavorite: () async {
                          await controller
                              .toggleFavorite(song);
                        },
                        onShuffle: () {
                          setState(() {
                            _shuffleEnabled =
                            !_shuffleEnabled;
                          });
                        },
                        onRepeat: () {
                          setState(() {
                            _repeatEnabled =
                            !_repeatEnabled;
                          });
                        },
                        onPrevious: () async {
                          await controller.previous();
                        },
                        onPlayPause: () async {
                          await controller
                              .togglePlayPause();
                        },
                        onNext: () async {
                          await controller.next();
                        },
                        onQueue: () {
                          _showQueue(context);
                        },
                        onSeek: (position) async {
                          await controller.seek(
                            position,
                          );
                        },
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

  // ===========================================================================
  // SONG OPTIONS
  // ===========================================================================

  void _showSongOptions(
      BuildContext context,
      Song song,
      ) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20.w,
            10.h,
            20.w,
            24.h,
          ),
          decoration: BoxDecoration(
            color:
            theme.scaffoldBackgroundColor,
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(32.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),

              SizedBox(height: 18.h),

              Text(
                song.title,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                song.artist,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                theme.textTheme.bodySmall
                    ?.copyWith(
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              ),

              SizedBox(height: 16.h),

              _OptionTile(
                icon:
                Icons.queue_music_rounded,
                title: 'Add to queue',
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  controller.addToQueue(
                    song,
                  );
                },
              ),

              _OptionTile(
                icon:
                Icons.playlist_add_rounded,
                title: 'Add to playlist',
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                },
              ),

              _OptionTile(
                icon: controller
                    .isFavorite(song)
                    ? Icons.favorite_rounded
                    : Icons
                    .favorite_border_rounded,
                title: controller
                    .isFavorite(song)
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onTap: () async {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  await controller
                      .toggleFavorite(song);
                },
              ),
            ],
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
  // QUEUE
  // ===========================================================================

  void _showQueue(
      BuildContext context,
      ) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final queue =
                controller.queue;

            final current =
                controller.currentSong;

            return Container(
              height:
              MediaQuery.sizeOf(context)
                  .height *
                  0.80,
              decoration: BoxDecoration(
                color: theme
                    .scaffoldBackgroundColor,
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(32.r),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10.h),

                  const _SheetHandle(),

                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(
                      22.w,
                      18.h,
                      22.w,
                      12.h,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Queue',
                          style: theme
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontSize: 25.sp,
                            fontWeight:
                            FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${queue.length} songs',
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

                  Expanded(
                    child: queue.isEmpty
                        ? Center(
                      child: Text(
                        'Queue is empty',
                        style: theme
                            .textTheme
                            .bodyMedium,
                      ),
                    )
                        : ListView.separated(
                      padding:
                      EdgeInsets.fromLTRB(
                        18.w,
                        4.h,
                        18.w,
                        28.h,
                      ),
                      physics:
                      const BouncingScrollPhysics(),
                      itemCount:
                      queue.length,
                      separatorBuilder:
                          (_, _) =>
                          SizedBox(
                            height: 6.h,
                          ),
                      itemBuilder:
                          (context, index) {
                        final queueSong =
                        queue[index];

                        final isCurrent =
                            current?.id ==
                                queueSong.id;

                        return _QueueSongTile(
                          song: queueSong,
                          isCurrent:
                          isCurrent,
                          index: index,
                          onTap:
                              () async {
                            await controller
                                .playSong(
                              queueSong,
                              sourceQueue:
                              queue,
                            );

                            if (sheetContext
                                .mounted) {
                              Navigator.of(
                                sheetContext,
                              ).pop();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
              duration: 220.ms,
            )
                .slideY(
              begin: 0.04,
              end: 0,
              duration: 330.ms,
              curve:
              Curves.easeOutCubic,
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// FULLSCREEN CINEMATIC ARTWORK
// =============================================================================

class _CinematicArtwork
    extends StatelessWidget {
  final String? url;

  const _CinematicArtwork({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null ||
        url!.trim().isEmpty) {
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
        duration:
        const Duration(milliseconds: 650),
        switchInCurve:
        Curves.easeOutCubic,
        switchOutCurve:
        Curves.easeInCubic,
        child: Image.network(
          url!,
          key: ValueKey(url),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality:
          FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder:
              (context, error, stackTrace) {
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
          },
          loadingBuilder:
              (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return const ColoredBox(
              color: Colors.black,
              child: Center(
                child:
                CircularProgressIndicator(
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
        .fadeIn(
      duration: 500.ms,
    )
        .scale(
      begin:
      const Offset(1.025, 1.025),
      end:
      const Offset(1, 1),
      duration: 700.ms,
      curve:
      Curves.easeOutCubic,
    );
  }
}

// =============================================================================
// CINEMATIC GRADIENT
// =============================================================================

class _CinematicGradient
    extends StatelessWidget {
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
              stops: const [
                0.00,
                0.32,
                0.55,
                0.70,
                0.84,
                1.00,
              ],
              colors: [
                Colors.black.withValues(
                  alpha: 0.32,
                ),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(
                  alpha: 0.16,
                ),
                Colors.black.withValues(
                  alpha: 0.68,
                ),
                Colors.black.withValues(
                  alpha: 0.98,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM CONTROLS
// =============================================================================

class _BottomControls
    extends StatelessWidget {
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
        // =====================================================================
        // SONG INFO
        // =====================================================================

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21.sp,
                      height: 1.05,
                      fontWeight:
                      FontWeight.w700,
                      letterSpacing: -0.55,
                      shadows: const [
                        Shadow(
                          blurRadius: 12,
                          color:
                          Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white
                          .withValues(
                        alpha: 0.68,
                      ),
                      fontSize: 13.sp,
                      fontWeight:
                      FontWeight.w500,
                      shadows: const [
                        Shadow(
                          blurRadius: 10,
                          color:
                          Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 14.w),

            _BottomIcon(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons
                  .favorite_border_rounded,
              active: isFavorite,
              size: 27.sp,
              onTap: onFavorite,
            ),
          ],
        )
            .animate()
            .fadeIn(
          delay: 100.ms,
          duration: 400.ms,
        )
            .slideY(
          begin: 0.04,
          end: 0,
          delay: 100.ms,
          duration: 400.ms,
          curve:
          Curves.easeOutCubic,
        ),

        SizedBox(height: 12.h),

        // =====================================================================
        // PROGRESS
        // =====================================================================

        _CinematicProgress(
          position: position,
          duration: duration,
          onSeek: onSeek,
        ),

        SizedBox(height: 4.h),

        // =====================================================================
        // MAIN CONTROLS
        // =====================================================================

        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            _BottomIcon(
              icon:
              Icons.shuffle_rounded,
              active: shuffleEnabled,
              onTap: onShuffle,
            ),

            _BottomIcon(
              icon:
              Icons.skip_previous_rounded,
              size: 34.sp,
              enabled: hasPrevious,
              onTap: onPrevious,
            ),

            GestureDetector(
              behavior:
              HitTestBehavior.opaque,
              onTap: onPlayPause,
              child: Container(
                width: 64.w,
                height: 64.w,
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment:
                Alignment.center,
                child: AnimatedSwitcher(
                  duration:
                  const Duration(
                    milliseconds: 180,
                  ),
                  transitionBuilder:
                      (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons
                        .play_arrow_rounded,
                    key: ValueKey(
                      isPlaying,
                    ),
                    color: Colors.black,
                    size: 34.sp,
                  ),
                ),
              ),
            ),

            _BottomIcon(
              icon:
              Icons.skip_next_rounded,
              size: 34.sp,
              enabled: hasNext,
              onTap: onNext,
            ),

            _BottomIcon(
              icon:
              Icons.repeat_rounded,
              active: repeatEnabled,
              onTap: onRepeat,
            ),
          ],
        )
            .animate()
            .fadeIn(
          delay: 160.ms,
          duration: 450.ms,
        )
            .slideY(
          begin: 0.05,
          end: 0,
          delay: 160.ms,
          duration: 450.ms,
          curve:
          Curves.easeOutCubic,
        ),

        SizedBox(height: 3.h),

        // =====================================================================
        // QUEUE
        // =====================================================================

        GestureDetector(
          behavior:
          HitTestBehavior.opaque,
          onTap: onQueue,
          child: Padding(
            padding:
            EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 5.h,
            ),
            child: Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  Icons
                      .queue_music_rounded,
                  color: Colors.white
                      .withValues(
                    alpha: 0.55,
                  ),
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Queue',
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 11.sp,
                    fontWeight:
                    FontWeight.w600,
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

// =============================================================================
// PROGRESS
// =============================================================================

class _CinematicProgress
    extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _CinematicProgress({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  String _format(Duration value) {
    final minutes =
        value.inMinutes;

    final seconds =
        value.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final durationMs =
        duration.inMilliseconds;

    final safeMax =
    durationMs > 0 ? durationMs : 1;

    final currentMs =
    position.inMilliseconds.clamp(
      0,
      safeMax,
    );

    return Column(
      children: [
        SliderTheme(
          data:
          SliderTheme.of(context)
              .copyWith(
            trackHeight: 3.h,
            activeTrackColor:
            Colors.white,
            inactiveTrackColor:
            Colors.white.withValues(
              alpha: 0.28,
            ),
            thumbColor: Colors.white,
            overlayColor:
            Colors.white12,
            thumbShape:
            RoundSliderThumbShape(
              enabledThumbRadius: 5.r,
            ),
            overlayShape:
            RoundSliderOverlayShape(
              overlayRadius: 15.r,
            ),
          ),
          child: Slider(
            value:
            currentMs.toDouble(),
            min: 0,
            max:
            safeMax.toDouble(),
            onChanged: (value) {
              onSeek(
                Duration(
                  milliseconds:
                  value.round(),
                ),
              );
            },
          ),
        ),

        Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal: 3.w,
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              Text(
                _format(position),
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.48,
                  ),
                  fontSize: 10.sp,
                ),
              ),
              Text(
                _format(duration),
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.48,
                  ),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PLAYER ICON
// =============================================================================

class _BottomIcon
    extends StatelessWidget {
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
      behavior:
      HitTestBehavior.opaque,
      onTap:
      enabled ? onTap : null,
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
              : Colors.white
              .withValues(
            alpha: 0.72,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TOP FLOATING BUTTON
// =============================================================================

class _FloatingButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration:
        BoxDecoration(
          color: Colors.black
              .withValues(
            alpha: 0.28,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }
}

// =============================================================================
// QUEUE TILE
// =============================================================================

class _QueueSongTile
    extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final int index;
  final VoidCallback onTap;

  const _QueueSongTile({
    required this.song,
    required this.isCurrent,
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
        padding:
        EdgeInsets.all(8.w),
        decoration:
        BoxDecoration(
          color: isCurrent
              ? theme
              .colorScheme
              .surface
              : theme
              .colorScheme
              .surface
              .withValues(
            alpha: 0.68,
          ),
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
                width: 58.w,
                height: 58.w,
                child: Image.network(
                  song.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, _, _) {
                    return Container(
                      color: theme
                          .colorScheme
                          .surface,
                      alignment:
                      Alignment.center,
                      child: Icon(
                        Icons
                            .music_note_rounded,
                        size: 24.sp,
                      ),
                    );
                  },
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

            if (isCurrent)
              Icon(
                Icons
                    .graphic_eq_rounded,
                size: 21.sp,
                color: theme
                    .colorScheme
                    .onSurface,
              )
                  .animate(
                onPlay:
                    (animation) =>
                    animation
                        .repeat(),
              )
                  .scale(
                begin:
                const Offset(
                  0.85,
                  0.85,
                ),
                end:
                const Offset(
                  1.08,
                  1.08,
                ),
                duration:
                500.ms,
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
    );
  }
}

// =============================================================================
// SHEET HANDLE
// =============================================================================

class _SheetHandle
    extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 4.h,
      decoration:
      BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(
          alpha: 0.12,
        ),
        borderRadius:
        BorderRadius.circular(99.r),
      ),
    );
  }
}

// =============================================================================
// OPTION TILE
// =============================================================================

class _OptionTile
    extends StatelessWidget {
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
    final theme =
    Theme.of(context);

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding:
        EdgeInsets.symmetric(
          vertical: 13.h,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
            SizedBox(width: 15.w),
            Text(
              title,
              style: theme
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                fontSize: 14.sp,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY PLAYER
// =============================================================================

class _EmptyPlayer
    extends StatelessWidget {
  final VoidCallback onClose;

  const _EmptyPlayer({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.music_off_rounded,
                color: Colors.white38,
                size: 55.sp,
              ),
              SizedBox(height: 15.h),
              Text(
                'Nothing is playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      18.r,
                    ),
                  ),
                  child: Text(
                    'Go back',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight:
                      FontWeight.w600,
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