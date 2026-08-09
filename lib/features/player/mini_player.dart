import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../data/models/song.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';
import 'now_playing_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({
    super.key,
  });

  @override
  State<MiniPlayer> createState() =>
      _MiniPlayerState();
}

class _MiniPlayerState
    extends State<MiniPlayer> {
  final MusicController controller =
      MusicControllerProvider.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final Song? song =
            controller.currentSong;

        if (song == null) {
          return const SizedBox.shrink();
        }

        return _MiniPlayerContent(
          controller: controller,
          song: song,
        );
      },
    );
  }
}

class _MiniPlayerContent
    extends StatelessWidget {
  final MusicController controller;
  final Song song;

  const _MiniPlayerContent({
    required this.controller,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        10.w,
        0,
        10.w,
        7.h,
      ),
      child: GestureDetector(
        behavior:
        HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder<void>(
              transitionDuration:
              const Duration(
                milliseconds: 450,
              ),
              reverseTransitionDuration:
              const Duration(
                milliseconds: 350,
              ),
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
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve:
                    Curves.easeOutCubic,
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.97,
                      end: 1,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve:
                        Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: Container(
              height: 68.h,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white
                    .withValues(
                  alpha: 0.075,
                )
                    : Colors.white
                    .withValues(
                  alpha: 0.88,
                ),
                borderRadius:
                BorderRadius.circular(
                  24.r,
                ),
              ),
              child: Row(
                children: [
                  // ==========================================================
                  // ARTWORK
                  // ==========================================================

                  Padding(
                    padding:
                    EdgeInsets.all(5.w),
                    child:
                    _MiniArtwork(
                      key:
                      ValueKey(
                        song.id,
                      ),
                      url:
                      song.thumbnailUrl,
                    ),
                  ),

                  SizedBox(
                    width: 10.w,
                  ),

                  // ==========================================================
                  // SONG INFORMATION
                  // ==========================================================

                  Expanded(
                    child:
                    _MiniSongInfo(
                      song: song,
                      isDark:
                      isDark,
                    ),
                  ),

                  // ==========================================================
                  // PLAY / PAUSE
                  // ==========================================================

                  _MiniButton(
                    icon: controller
                        .playbackState
                        .isPlaying
                        ? Icons
                        .pause_rounded
                        : Icons
                        .play_arrow_rounded,
                    onTap:
                        () async {
                      await controller
                          .togglePlayPause();
                    },
                    size: 24.sp,
                  ),

                  // ==========================================================
                  // NEXT
                  // ==========================================================

                  _MiniButton(
                    icon:
                    Icons.skip_next_rounded,
                    enabled:
                    controller.hasNext,
                    onTap:
                        () async {
                      if (!controller
                          .hasNext) {
                        return;
                      }

                      await controller
                          .next();
                    },
                    size: 24.sp,
                  ),

                  SizedBox(
                    width: 5.w,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
      duration: 300.ms,
      curve:
      Curves.easeOutCubic,
    )
        .slideY(
      begin: 0.20,
      end: 0,
      duration: 400.ms,
      curve:
      Curves.easeOutCubic,
    )
        .scale(
      begin:
      const Offset(
        0.98,
        0.98,
      ),
      end:
      const Offset(
        1,
        1,
      ),
      duration: 400.ms,
      curve:
      Curves.easeOutCubic,
    );
  }
}

// =============================================================================
// ARTWORK
// =============================================================================

class _MiniArtwork
    extends StatelessWidget {
  final String? url;

  const _MiniArtwork({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        18.r,
      ),
      child: SizedBox(
        width: 58.w,
        height: 58.w,
        child: AnimatedSwitcher(
          duration:
          const Duration(
            milliseconds: 350,
          ),
          child:
          url == null ||
              url!.isEmpty
              ? Container(
            key: const ValueKey(
              'empty-art',
            ),
            color: Colors.black12,
            alignment:
            Alignment.center,
            child: Icon(
              Icons
                  .music_note_rounded,
              size: 24.sp,
            ),
          )
              : Image.network(
            url!,
            key: ValueKey(
              url,
            ),
            width: 58.w,
            height: 58.w,
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
                color:
                Colors.black12,
                alignment:
                Alignment.center,
                child: Icon(
                  Icons
                      .music_note_rounded,
                  size:
                  24.sp,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SONG INFO
// =============================================================================

class _MiniSongInfo
    extends StatelessWidget {
  final Song song;
  final bool isDark;

  const _MiniSongInfo({
    required this.song,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary =
    isDark
        ? Colors.white
        : Colors.black;

    final secondary =
    isDark
        ? Colors.white
        .withValues(
      alpha: 0.55,
    )
        : Colors.black
        .withValues(
      alpha: 0.55,
    );

    return Column(
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
          style: TextStyle(
            color: primary,
            fontSize: 13.sp,
            fontWeight:
            FontWeight.w700,
            letterSpacing:
            -0.2,
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
          style: TextStyle(
            color: secondary,
            fontSize: 11.sp,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// MINI BUTTON
// =============================================================================

class _MiniButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  final bool enabled;
  final double size;

  const _MiniButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.size = 24,
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
        height: 58.h,
        child: Center(
          child: AnimatedOpacity(
            duration:
            const Duration(
              milliseconds: 180,
            ),
            opacity:
            enabled ? 1 : 0.25,
            child: Icon(
              icon,
              size: size,
              color:
              Theme.of(context)
                  .colorScheme
                  .onSurface,
            ),
          ),
        ),
      ),
    );
  }
}