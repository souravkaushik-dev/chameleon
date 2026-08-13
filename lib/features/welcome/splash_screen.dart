import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hicons/flutter_hicons.dart' show Hicons;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/audio_player_service.dart';
import '../../data/services/settings_service.dart';
import '../../navigation/bottom_nav.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final SettingsService settings;
  final AudioPlayerService audioPlayerService;

  const SplashScreen({
    super.key,
    required this.settings,
    required this.audioPlayerService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _onboardingCompletedKey =
      'chameleon_onboarding_completed';

  late final AnimationController _introController;
  late final AnimationController _exitController;

  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _markBlur;

  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleOffset;

  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineOffset;

  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  bool _onboardingCompleted = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    _markOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .24,
          .48,
          curve: Curves.easeOut,
        ),
      ),
    );

    _markScale = Tween<double>(
      begin: .94,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .24,
          .56,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _markBlur = Tween<double>(
      begin: 9,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .24,
          .52,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _titleOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .48,
          .68,
          curve: Curves.easeOut,
        ),
      ),
    );

    _titleOffset = Tween<double>(
      begin: 5,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .48,
          .70,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _taglineOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .66,
          .88,
          curve: Curves.easeOut,
        ),
      ),
    );

    _taglineOffset = Tween<double>(
      begin: 4,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          .66,
          .90,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitOpacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _exitScale = Tween<double>(
      begin: 1,
      end: 1.008,
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _loadAndStart();
  }

  Future<void> _loadAndStart() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _onboardingCompleted =
          preferences.getBool(_onboardingCompletedKey) ?? false;
    });

    await _introController.forward();

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted) {
      return;
    }

    await _leave();
  }

  Future<void> _leave() async {
    if (_isLeaving) {
      return;
    }

    _isLeaving = true;

    await _exitController.forward();

    if (!mounted) {
      return;
    }

    final Widget destination;

    if (_onboardingCompleted) {
      destination = BottomNav(
        settings: widget.settings,
        audioPlayerService: widget.audioPlayerService,
      );
    } else {
      destination = OnboardingScreen(
        settings: widget.settings,
        audioPlayerService: widget.audioPlayerService,
      );
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 650,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) {
          return destination;
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
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _introController,
          _exitController,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CinematicBackground(
                    color: colors.primary,
                  ),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _markOpacity.value,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _markBlur.value,
                              sigmaY: _markBlur.value,
                            ),
                            child: Transform.scale(
                              scale: _markScale.value,
                              child: Icon(
                                Hicons.musicnoteLightOutline,
                                size: 48,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Opacity(
                          opacity: _titleOpacity.value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              _titleOffset.value,
                            ),
                            child: Text(
                              'CHAMELEON',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 5.5,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              _taglineOffset.value,
                            ),
                            child: Text(
                              'LESS INTERFACE. MORE MUSIC.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.2,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: .58,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CinematicBackground extends StatelessWidget {
  final Color color;

  const _CinematicBackground({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 100,
            sigmaY: 100,
          ),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(
                alpha: .018,
              ),
            ),
          ),
        ),
      ),
    );
  }
}