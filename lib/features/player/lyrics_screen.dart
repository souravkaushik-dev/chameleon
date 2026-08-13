import 'dart:ui' show ImageFilter;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../data/models/song.dart';
import '../../data/services/lyrics_service.dart';
import '../../data/services/music_controller.dart';
import '../../data/services/music_controller_provider.dart';

TextStyle _manrope({
  required double size,
  required FontWeight weight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class LyricsScreen extends StatefulWidget {
  final Song song;

  const LyricsScreen({super.key, required this.song});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final MusicController _controller = MusicControllerProvider.instance;
  final LyricsService _lyricsService = LyricsService();

  Timer? _syncTimer;

  LyricsResult? _result;
  List<_LyricLine> _lines = const [];

  bool _loading = true;
  int _activeLine = -1;

  @override
  void initState() {
    super.initState();
    _load();

    _syncTimer = Timer.periodic(
      const Duration(milliseconds: 180),
      (_) => _syncLyrics(),
    );
  }

  Future<void> _load() async {
    final result = await _lyricsService.getLyrics(widget.song);

    if (!mounted) {
      return;
    }

    final parsed = result?.hasSyncedLyrics == true
        ? _parseLrc(result!.syncedLyrics!)
        : <_LyricLine>[];

    setState(() {
      _result = result;
      _lines = parsed;
      _loading = false;
    });

    _syncLyrics();
  }

  void _syncLyrics() {
    if (!mounted || _lines.isEmpty) {
      return;
    }

    final position = _controller.playbackState.position;
    final milliseconds = position.inMilliseconds;

    var nextIndex = -1;

    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].time.inMilliseconds <= milliseconds) {
        nextIndex = i;
      } else {
        break;
      }
    }

    if (nextIndex != _activeLine) {
      setState(() {
        _activeLine = nextIndex;
      });
    }
  }

  List<_LyricLine> _parseLrc(String source) {
    final result = <_LyricLine>[];
    final pattern = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');

    for (final rawLine in source.split('\n')) {
      final matches = pattern.allMatches(rawLine).toList();
      if (matches.isEmpty) {
        continue;
      }

      final lyric = rawLine.replaceAll(pattern, '').trim();
      if (lyric.isEmpty) {
        continue;
      }

      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
        final fraction = match.group(3) ?? '0';

        final milliseconds = int.parse(
          fraction.padRight(3, '0').substring(0, 3),
        );

        result.add(
          _LyricLine(
            time: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            ),
            text: lyric,
          ),
        );
      }
    }

    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _lyricsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DefaultTextStyle(
        style: _manrope(
          size: 14.sp,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _LyricsArtwork(url: widget.song.thumbnailUrl),
            const _LyricsGradient(),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
                    child: Row(
                      children: [
                        _GlassButton(
                          icon: Hicons.down2LightOutline,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _GlassButton(
                          icon: Icons.more_horiz_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Column(
                      children: [
                        Text(
                          'LYRICS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .48),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          widget.song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .58),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildContent(),
                    ),
                  ),

                  SizedBox(height: 12.h),
                  _BottomProgress(controller: _controller),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const _LyricsLoading(key: ValueKey('loading'));
    }

    final result = _result;

    if (result == null || result.isEmpty) {
      return _LyricsUnavailable(
        key: const ValueKey('unavailable'),
        instrumental: result?.instrumental ?? false,
      );
    }

    if (_lines.isNotEmpty) {
      return _SyncedLyrics(
        key: const ValueKey('synced'),
        lines: _lines,
        activeIndex: _activeLine,
        onLineTap: (line) async {
          await _controller.seek(line.time);
        },
      );
    }

    if (result.hasPlainLyrics) {
      return _PlainLyrics(
        key: const ValueKey('plain'),
        text: result.plainLyrics!,
      );
    }

    return const _LyricsUnavailable(key: ValueKey('fallback-unavailable'));
  }
}

class _LyricLine {
  final Duration time;
  final String text;

  const _LyricLine({required this.time, required this.text});
}

class _SyncedLyrics extends StatefulWidget {
  final List<_LyricLine> lines;
  final int activeIndex;
  final Future<void> Function(_LyricLine line) onLineTap;

  const _SyncedLyrics({
    super.key,
    required this.lines,
    required this.activeIndex,
    required this.onLineTap,
  });

  @override
  State<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends State<_SyncedLyrics> {
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _lineKeys;

  int _lastAnimatedIndex = -1;

  @override
  void initState() {
    super.initState();
    _lineKeys = List.generate(widget.lines.length, (_) => GlobalKey());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateToActiveLine(initial: true);
    });
  }

  @override
  void didUpdateWidget(covariant _SyncedLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lines.length != widget.lines.length) {
      _lineKeys = List.generate(widget.lines.length, (_) => GlobalKey());
    }

    if (widget.activeIndex >= 0 &&
        widget.activeIndex != oldWidget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToActiveLine();
      });
    }
  }

  Future<void> _animateToActiveLine({bool initial = false}) async {
    final index = widget.activeIndex;

    if (!mounted ||
        index < 0 ||
        index >= _lineKeys.length ||
        !_scrollController.hasClients) {
      return;
    }

    if (!initial && index == _lastAnimatedIndex) {
      return;
    }

    _lastAnimatedIndex = index;

    final context = _lineKeys[index].currentContext;

    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      alignment: 0.43,
      duration: Duration(milliseconds: initial ? 420 : 520),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _tapLine(int index) async {
    if (index < 0 || index >= widget.lines.length) {
      return;
    }

    final line = widget.lines[index];

    // Seek first so playback and lyric highlighting move together.
    await widget.onLineTap(line);

    if (!mounted) {
      return;
    }

    // Immediately bring the tapped lyric into the cinematic focus position.
    final context = _lineKeys[index].currentContext;

    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        alignment: 0.43,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 36.h, 24.w, 110.h),
      itemCount: widget.lines.length,
      itemBuilder: (context, index) {
        final active = index == widget.activeIndex;
        final distance = widget.activeIndex < 0
            ? 99
            : (index - widget.activeIndex).abs();

        final opacity = widget.activeIndex < 0
            ? .72
            : active
            ? 1.0
            : distance == 1
            ? .62
            : distance == 2
            ? .40
            : .24;

        return KeyedSubtree(
              key: _lineKeys[index],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tapLine(index),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    opacity: opacity,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      scale: active ? 1.0 : .985,
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        style: _manrope(
                          size: active ? 25.sp : 20.sp,
                          weight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: .88),
                          height: active ? 1.20 : 1.28,
                          letterSpacing: active ? -.65 : -.38,
                        ),
                        child: Text(
                          widget.lines[index].text,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .animate(delay: Duration(milliseconds: (index.clamp(0, 8)) * 18))
            .fadeIn(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOut,
            )
            .slideY(
              begin: .025,
              end: 0,
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _PlainLyrics extends StatelessWidget {
  final String text;

  const _PlainLyrics({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(26.w, 30.h, 26.w, 90.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _manrope(
          size: 19.sp,
          weight: FontWeight.w600,
          color: Colors.white.withValues(alpha: .82),
          height: 1.7,
          letterSpacing: -.25,
        ),
      ),
    );
  }
}

class _LyricsUnavailable extends StatelessWidget {
  final bool instrumental;

  const _LyricsUnavailable({super.key, this.instrumental = false});

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 36.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Icon(
                    instrumental
                        ? Hicons.musicnoteLightOutline
                        : Hicons.voiceLightOutline,
                    color: Colors.white.withValues(alpha: .72),
                    size: 30.sp,
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  instrumental
                      ? 'Instrumental track'
                      : 'Lyrics aren’t available yet',
                  textAlign: TextAlign.center,
                  style: _manrope(
                    size: 20.sp,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -.45,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  instrumental
                      ? 'This song does not have lyrics.'
                      : 'Sorry, we’re currently working on lyrics for this song. '
                            'They’ll be available here soon.',
                  textAlign: TextAlign.center,
                  style: _manrope(
                    size: 13.sp,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: .58),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: 44.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: .04,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _LyricsLoading extends StatelessWidget {
  const _LyricsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 27,
            height: 27,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 15.h),
          Text(
            'Finding lyrics…',
            style: _manrope(
              size: 13.sp,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .58),
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsArtwork extends StatelessWidget {
  final String? url;

  const _LyricsArtwork({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const ColoredBox(color: Colors.black);
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Transform.scale(
        scale: 1.10,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
        ),
      ),
    );
  }
}

class _LyricsGradient extends StatelessWidget {
  const _LyricsGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .22, .58, 1],
            colors: [
              Colors.black.withValues(alpha: .54),
              Colors.black.withValues(alpha: .12),
              Colors.black.withValues(alpha: .22),
              Colors.black.withValues(alpha: .90),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.white.withValues(alpha: .12),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: Icon(icon, color: Colors.white, size: 21.sp),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomProgress extends StatelessWidget {
  final MusicController controller;

  const _BottomProgress({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final playback = controller.playbackState;
        final durationMs = playback.duration.inMilliseconds;
        final positionMs = playback.position.inMilliseconds;

        final progress = durationMs <= 0
            ? 0.0
            : (positionMs / durationMs).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 26.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: .14),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}
