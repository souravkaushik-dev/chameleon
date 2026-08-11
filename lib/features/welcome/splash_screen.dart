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
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _onboardingCompletedKey =
      'chameleon_onboarding_completed';

  static const String _userNameKey =
      'chameleon_user_name';
  late final AnimationController _mainController;
  late final AnimationController _ambientController;
  late final AnimationController _welcomeController;
  late final AnimationController _exitController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoBlur;

  late final Animation<double> _welcomeOpacity;
  late final Animation<double> _welcomeOffset;

  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;
  String? _userName;

  bool _onboardingCompleted = false;

  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1300,
      ),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeOut,
        ),
      ),
    );

    _logoScale = Tween<double>(
      begin: 0.86,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoBlur = Tween<double>(
      begin: 18.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.0,
          0.70,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 5200,
      ),
    );
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 850,
      ),
    );

    _welcomeOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeOut,
      ),
    );

    _welcomeOffset = Tween<double>(
      begin: 18.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.easeOutCubic,
      ),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 600,
      ),
    );

    _exitOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _exitScale = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    _loadUserAndStart();
  }
  Future<void> _loadUserAndStart() async {
    final preferences =
    await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _onboardingCompleted =
          preferences.getBool(
            _onboardingCompletedKey,
          ) ??
              false;

      _userName =
          preferences.getString(
            _userNameKey,
          );
    });

    _startAnimation();
  }
  Future<void> _startAnimation() async {
    _ambientController.repeat(
      reverse: true,
    );
await _mainController.forward();

    if (!mounted) {
      return;
    }
await Future<void>.delayed(
      const Duration(
        milliseconds: 120,
      ),
    );

    if (!mounted) {
      return;
    }

    await _welcomeController.forward();

    if (!mounted) {
      return;
    }
await Future<void>.delayed(
      const Duration(
        milliseconds: 1300,
      ),
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
        transitionDuration:
        const Duration(
          milliseconds: 700,
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
          return destination;
        },
        transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
          final curved =
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }
  @override
  void dispose() {
    _mainController.dispose();
    _ambientController.dispose();
    _welcomeController.dispose();
    _exitController.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final appColor =
        colors.primary;

    final background =
        theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor:
      background,

      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _ambientController,
          _welcomeController,
          _exitController,
        ]),
        builder: (
            context,
            child,
            ) {
          return Opacity(
            opacity:
            _exitOpacity.value,
            child: Transform.scale(
              scale:
              _exitScale.value,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color:
                    background,
                  ),
                  _MinimalAmbientLight(
                    color:
                    appColor,
                    animation:
                    _ambientController,
                  ),
                  Center(
                    child: Opacity(
                      opacity:
                      _logoOpacity.value,
                      child:
                      ImageFiltered(
                        imageFilter:
                        ImageFilter.blur(
                          sigmaX:
                          _logoBlur.value,
                          sigmaY:
                          _logoBlur.value,
                        ),
                        child:
                        Transform.scale(
                          scale:
                          _logoScale.value,
                          child:
                          _ChameleonMark(
                            color:
                            appColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 54,
                    child: Opacity(
                      opacity:
                      _welcomeOpacity.value,
                      child:
                      Transform.translate(
                        offset: Offset(
                          0,
                          _welcomeOffset.value,
                        ),
                        child:
                        _WelcomeMessage(
                          userName:
                          _userName,
                          isReturningUser:
                          _onboardingCompleted,
                          colors:
                          colors,
                          appColor:
                          appColor,
                        ),
                      ),
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
class _MinimalAmbientLight
    extends StatelessWidget {
  final Color color;

  final Animation<double>
  animation;

  const _MinimalAmbientLight({
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final size =
    MediaQuery.sizeOf(context);

    final value =
        animation.value;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left:
            size.width * 0.15 +
                (value * 24),
            top:
            size.height * 0.25 -
                (value * 16),
            child:
            _SoftOrb(
              color:
              color,
              size:
              size.width * 0.72,
              opacity:
              0.035,
              blur:
              90,
            ),
          ),
          Positioned(
            right:
            -size.width * 0.22 +
                (value * 18),
            bottom:
            size.height * 0.22 +
                (value * 20),
            child:
            _SoftOrb(
              color:
              color,
              size:
              size.width * 0.55,
              opacity:
              0.025,
              blur:
              100,
            ),
          ),
          Center(
            child:
            _SoftOrb(
              color:
              color,
              size:
              size.width * 0.34,
              opacity:
              0.018,
              blur:
              75,
            ),
          ),
        ],
      ),
    );
  }
}
class _SoftOrb
    extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  final double blur;

  const _SoftOrb({
    required this.color,
    required this.size,
    required this.opacity,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter:
      ImageFilter.blur(
        sigmaX:
        blur,
        sigmaY:
        blur,
      ),
      child:
      Container(
        width:
        size,
        height:
        size,
        decoration:
        BoxDecoration(
          shape:
          BoxShape.circle,
          color:
          color.withValues(
            alpha:
            opacity,
          ),
        ),
      ),
    );
  }
}
class _ChameleonMark
    extends StatelessWidget {
  final Color color;

  const _ChameleonMark({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment:
        Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color:
              color.withValues(
                alpha:
                0.025,
              ),
            ),
          ),
          ClipOval(
            child:
            BackdropFilter(
              filter:
              ImageFilter.blur(
                sigmaX:
                14,
                sigmaY:
                14,
              ),
              child:
              Container(
                width:
                82,
                height:
                82,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
                  color:
                  color.withValues(
                    alpha:
                    0.055,
                  ),
                ),
                child:
                Icon(
                  Hicons
                      .musicnoteLightOutline,
                  size:
                  39,
                  color:
                  color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _WelcomeMessage
    extends StatelessWidget {
  final String? userName;

  final bool isReturningUser;

  final ColorScheme colors;

  final Color appColor;

  const _WelcomeMessage({
    required this.userName,
    required this.isReturningUser,
    required this.colors,
    required this.appColor,
  });

  @override
  Widget build(BuildContext context) {
    final name =
    userName?.trim();

    final hasName =
        name != null &&
            name.isNotEmpty;

    return Column(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Text(
          hasName
              ? 'Welcome back'
              : 'Welcome to',
          textAlign:
          TextAlign.center,
          style:
          TextStyle(
            fontSize:
            13,
            fontWeight:
            FontWeight.w500,
            letterSpacing:
            0.1,
            color:
            colors
                .onSurfaceVariant
                .withValues(
              alpha:
              0.72,
            ),
          ),
        ),

        const SizedBox(
          height:
          5,
        ),

        Text(
          hasName
              ? name!
              : 'Chameleon',
          textAlign:
          TextAlign.center,
          maxLines:
          1,
          overflow:
          TextOverflow.ellipsis,
          style:
          TextStyle(
            fontSize:
            21,
            fontWeight:
            FontWeight.w700,
            letterSpacing:
            -0.5,
            color:
            colors
                .onSurface,
          ),
        ),

        const SizedBox(
          height:
          7,
        ),

        Container(
          width:
          24,
          height:
          2,
          decoration:
          BoxDecoration(
            color:
            appColor
                .withValues(
              alpha:
              0.65,
            ),
            borderRadius:
            BorderRadius
                .circular(
              2,
            ),
          ),
        ),
      ],
    );
  }
}