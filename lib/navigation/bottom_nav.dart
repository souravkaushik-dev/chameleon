import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../data/models/song.dart';
import '../../data/services/music_controller_provider.dart';
import '../../data/services/settings_service.dart';

import '../data/services/music_controller.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/library/library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/player/now_playing_screen.dart';

class BottomNav extends StatefulWidget {
  final SettingsService settings;

  const BottomNav({
    super.key,
    required this.settings,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  final MusicController controller =
      MusicControllerProvider.instance;

  @override
  void initState() {
    super.initState();

    _screens = [
      const HomeScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      SettingsScreen(
        settings: widget.settings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final theme = Theme.of(context);

            final appColor =
                theme.colorScheme.primary;

            final onSurface =
                theme.colorScheme.onSurface;

            final hasSong =
                controller.currentSong != null;

            return LiquidGlassScaffold(
              backgroundColor:
              theme.scaffoldBackgroundColor,

              // =============================================================
              // CONTENT + MINI PLAYER
              // =============================================================

              body: Stack(
                children: [
                  // ---------------------------------------------------------
                  // APP SCREENS
                  // ---------------------------------------------------------

                  Positioned.fill(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _screens,
                    ),
                  ),

                  // ---------------------------------------------------------
                  // GLOBAL MINI PLAYER
                  // ---------------------------------------------------------

                  if (hasSong)
                    Positioned(
                      left: 0,
                      right: 0,

                      // Navigation occupies approximately
                      // 70px + bottom margin.
                      //
                      // Mini player is deliberately
                      // positioned higher to create
                      // a visible gap.
                      bottom: 104.h,

                      child:
                      const _GlobalMiniPlayer(),
                    ),
                ],
              ),

              // =============================================================
              // LIQUID GLASS NAVIGATION
              // =============================================================

              bottomNavigationBar:
              LiquidGlassBottomNavBar(
                width: 358.w,
                height: 70.h,

                margin: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  bottom: 10.h,
                ),

                alignment:
                Alignment.bottomCenter,

                itemPadding: 5,

                items: const [
                  // =========================================================
                  // HOME
                  // =========================================================

                  LiquidGlassTabBarItem(
                    icon:
                    Hicons.home2LightOutline,
                    selectedIcon:
                    Hicons.home2Bold,
                    label: 'Home',
                  ),

                  // =========================================================
                  // SEARCH
                  // =========================================================

                  LiquidGlassTabBarItem(
                    icon:
                    Hicons.search1LightOutline,
                    selectedIcon:
                    Hicons.search1Bold,
                    label: 'Search',
                  ),

                  // =========================================================
                  // LIBRARY
                  // =========================================================

                  LiquidGlassTabBarItem(
                    icon:
                    Hicons.musicnoteLightOutline,
                    selectedIcon:
                    Hicons.musicnoteBold,
                    label: 'Library',
                  ),

                  // =========================================================
                  // SETTINGS
                  // =========================================================

                  LiquidGlassTabBarItem(
                    icon:
                    Hicons.settingLightOutline,
                    selectedIcon:
                    Hicons.settingBold,
                    label: 'Settings',
                  ),
                ],

                selectedIndex:
                _currentIndex,

                onChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },

                // =============================================================
                // NAV ITEM STYLE
                // =============================================================

                itemStyle:
                LiquidGlassNavItemStyle(
                  selectedColor:
                  appColor,

                  unselectedColor:
                  onSurface.withValues(
                    alpha: 0.62,
                  ),

                  iconSize: 23,

                  labelFontSize: 11,

                  iconLabelGap: 2,

                  selectedFontWeight:
                  FontWeight.w700,

                  unselectedFontWeight:
                  FontWeight.w600,
                ),

                // =============================================================
                // LIQUID MORPH PILL
                // =============================================================

                pillStyle:
                LiquidGlassNavPillStyle(
                  mode:
                  LiquidGlassPillMode.both,

                  animated: true,

                  animationDuration:
                  const Duration(
                    milliseconds: 360,
                  ),

                  animationCurve:
                  Curves.easeOutCubic,

                  color:
                  appColor.withValues(
                    alpha: 0.10,
                  ),

                  // Magnification
                  magnification: 1.18,

                  // Refraction
                  distortion: 0.075,

                  distortionWidth: 18,

                  // Pill growth
                  growHeight: 10,

                  enableInnerRadiusTransparent:
                  true,

                  // Spring movement
                  travelStiffness: 300,

                  travelDamping: 30,

                  // Jelly movement
                  jelly:
                  const LiquidGlassJellyConfig(
                    style:
                    LiquidGlassJellyStyle
                        .squashStretch,

                    stiffness: 260,

                    damping: 13,

                    maxVelocity: 6,

                    velocityClamp: 60,

                    stretchWidth: 17.1,

                    squashHeight: 9.8,

                    anchorBias: -1.0,

                    recoilScale: 3.0,

                    recoilAnchor: 1.0,

                    directionTau: 0.42,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// GLOBAL MINI PLAYER
// =============================================================================
//
// A separate, floating glass mini-player.
// It intentionally sits above the liquid-glass navigation and does not
// participate in the navigation bar itself.
//

class _GlobalMiniPlayer extends StatefulWidget {
  const _GlobalMiniPlayer();

  @override
  State<_GlobalMiniPlayer> createState() =>
      _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState
    extends State<_GlobalMiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPulse(bool isPlaying) {
    if (isPlaying) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.animateTo(
        0,
        duration: const Duration(
          milliseconds: 220,
        ),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        MusicControllerProvider.instance;

    final song = controller.currentSong;

    if (song == null) {
      _syncPulse(false);
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final playback = controller.playbackState;
    final isPlaying = playback.isPlaying;

    _syncPulse(isPlaying);

    final durationMs =
        playback.duration.inMilliseconds;

    final positionMs =
        playback.position.inMilliseconds;

    final progress = durationMs <= 0
        ? 0.0
        : (positionMs / durationMs)
        .clamp(0.0, 1.0);

    // Never show the loading spinner while audio is already playing.
    // The audio player's `playing` state is the source of truth for the
    // mini-player button. Loading/buffering can briefly overlap with a
    // playing state during stream transitions.
    final isLoading =
        !isPlaying &&
            (playback.status.name == 'loading' ||
                playback.status.name == 'buffering');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse =
              _pulseController.value;

          return Transform.scale(
            scale: isPlaying
                ? 1.0 + (pulse * 0.006)
                : 1.0,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(26.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 22,
              sigmaY: 22,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                BorderRadius.circular(26.r),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                      const NowPlayingScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 82.h,
                  padding: EdgeInsets.fromLTRB(
                    8.w,
                    8.w,
                    10.w,
                    8.w,
                  ),
                  decoration: BoxDecoration(
                    color:
                    colors.surface.withValues(
                      alpha:
                      theme.brightness ==
                          Brightness.dark
                          ? 0.42
                          : 0.50,
                    ),
                    borderRadius:
                    BorderRadius.circular(26.r),
                    border: Border.all(
                      color:
                      colors.onSurface.withValues(
                        alpha: 0.10,
                      ),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        colors.onSurface.withValues(
                          alpha: 0.06,
                        ),
                        blurRadius: 24,
                        spreadRadius: -8,
                        offset:
                        const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // =================================================
                          // ARTWORK
                          // =================================================

                          AnimatedScale(
                            scale: isPlaying
                                ? 1.0
                                : 0.97,
                            duration:
                            const Duration(
                              milliseconds: 280,
                            ),
                            curve:
                            Curves.easeOutCubic,
                            child: _MiniArtwork(
                              song: song,
                              isPlaying:
                              isPlaying,
                            ),
                          ),

                          SizedBox(
                            width: 11.w,
                          ),

                          // =================================================
                          // SONG INFORMATION
                          // =================================================

                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration:
                                  const Duration(
                                    milliseconds: 260,
                                  ),
                                  switchInCurve:
                                  Curves.easeOut,
                                  switchOutCurve:
                                  Curves.easeIn,
                                  transitionBuilder:
                                      (
                                      child,
                                      animation,
                                      ) {
                                    return FadeTransition(
                                      opacity:
                                      animation,
                                      child:
                                      SlideTransition(
                                        position:
                                        Tween<Offset>(
                                          begin:
                                          const Offset(
                                            0,
                                            0.15,
                                          ),
                                          end:
                                          Offset.zero,
                                        ).animate(
                                          animation,
                                        ),
                                        child:
                                        child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    song.title,
                                    key: ValueKey(
                                      song.id,
                                    ),
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style:
                                    TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight:
                                      FontWeight.w700,
                                      color:
                                      colors.onSurface,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: 3.h,
                                ),

                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight:
                                    FontWeight.w500,
                                    color: colors
                                        .onSurfaceVariant,
                                  ),
                                ),

                                SizedBox(
                                  height: 5.h,
                                ),

                                // =================================================
                                // PROGRESS
                                // =================================================

                                SizedBox(
                                  height: 3.h,
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10.r,
                                    ),
                                    child:
                                    Stack(
                                      children: [
                                        Positioned.fill(
                                          child:
                                          Container(
                                            color: colors
                                                .onSurface
                                                .withValues(
                                              alpha: 0.10,
                                            ),
                                          ),
                                        ),
                                        AnimatedFractionallySizedBox(
                                          duration:
                                          const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve:
                                          Curves.linear,
                                          alignment:
                                          Alignment
                                              .centerLeft,
                                          widthFactor:
                                          progress,
                                          child:
                                          Container(
                                            decoration:
                                            BoxDecoration(
                                              color: colors
                                                  .primary,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                10.r,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            width: 8.w,
                          ),

                          // =================================================
                          // PLAY / PAUSE
                          // =================================================

                          _MiniPlayButton(
                            controller:
                            controller,
                            isPlaying:
                            isPlaying,
                            isLoading:
                            isLoading,
                          ),
                        ],
                      ),

                      // =====================================================
                      // SUBTLE GLASS SHINE
                      // =====================================================

                      IgnorePointer(
                        child: Align(
                          alignment:
                          Alignment.topCenter,
                          child: Container(
                            height: 1.h,
                            margin:
                            EdgeInsets.symmetric(
                              horizontal: 24.w,
                            ),
                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10.r,
                              ),
                              color: Colors.white
                                  .withValues(
                                alpha:
                                theme.brightness ==
                                    Brightness.dark
                                    ? 0.12
                                    : 0.22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MINI ARTWORK
// =============================================================================

class _MiniArtwork extends StatelessWidget {
  final Song song;
  final bool isPlaying;

  const _MiniArtwork({
    required this.song,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final artwork = song.thumbnailUrl;

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: 64.w,
      height: 64.w,
      padding: EdgeInsets.all(
        isPlaying ? 1.5.w : 0,
      ),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(20.r),
        boxShadow: isPlaying
            ? [
          BoxShadow(
            color:
            colors.primary.withValues(
              alpha: 0.16,
            ),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ]
            : null,
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(18.r),
        child: artwork != null &&
            artwork.isNotEmpty
            ? Image.network(
          artwork,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
              _ArtworkFallback(
                colors: colors,
              ),
        )
            : _ArtworkFallback(
          colors: colors,
        ),
      ),
    );
  }
}

// =============================================================================
// ARTWORK FALLBACK
// =============================================================================

class _ArtworkFallback extends StatelessWidget {
  final ColorScheme colors;

  const _ArtworkFallback({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
      colors.surfaceContainerHighest,
      child: Icon(
        Hicons.musicnoteLightOutline,
        size: 26.sp,
        color:
        colors.onSurfaceVariant,
      ),
    );
  }
}

// =============================================================================
// MINI PLAY BUTTON
// =============================================================================

class _MiniPlayButton extends StatelessWidget {
  final MusicController controller;
  final bool isPlaying;
  final bool isLoading;

  const _MiniPlayButton({
    required this.controller,
    required this.isPlaying,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: colors.primary.withValues(
          alpha: isPlaying ? 0.12 : 0.08,
        ),
        borderRadius:
        BorderRadius.circular(19.r),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.10,
          ),
          width: 0.7,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(19.r),
          onTap: isLoading
              ? null
              : () async {
            await controller
                .togglePlayPause();
          },
          child: Center(
            child: AnimatedSwitcher(
              duration:
              const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: isLoading
                  ? SizedBox(
                key: const ValueKey(
                  'loading',
                ),
                width: 19.w,
                height: 19.w,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  colors.primary,
                ),
              )
                  : Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(
                  isPlaying,
                ),
                size: 27.sp,
                color:
                colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
