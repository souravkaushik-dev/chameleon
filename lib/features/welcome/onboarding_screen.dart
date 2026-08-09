import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../navigation/bottom_nav.dart';
import '../../../data/services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  final SettingsService settings;

  const OnboardingScreen({
    super.key,
    required this.settings,
  });

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // STORAGE
  // ===========================================================================

  static const String _onboardingCompletedKey =
      'chameleon_onboarding_completed';

  static const String _userNameKey =
      'chameleon_user_name';

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final AnimationController _buttonController;
  late final AnimationController _fieldController;

  bool _isSaving = false;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController();

    _nameFocus =
        FocusNode();

    _entranceController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 1300,
          ),
        );

    _ambientController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            seconds: 14,
          ),
        );

    _buttonController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 180,
          ),
        );

    _fieldController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 280,
          ),
        );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _ambientController.repeat();

    await Future<void>.delayed(
      const Duration(
        milliseconds: 100,
      ),
    );

    if (!mounted) {
      return;
    }

    await _entranceController.forward();

    if (!mounted) {
      return;
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();

    _entranceController.dispose();
    _ambientController.dispose();
    _buttonController.dispose();
    _fieldController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // CONTINUE
  // ===========================================================================

  Future<void> _continue() async {
    if (_isSaving) {
      return;
    }

    final name =
    _nameController.text.trim();

    if (name.isEmpty) {
      _nameFocus.requestFocus();
      _fieldController.forward();
      return;
    }

    if (name.length > 30) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    await _buttonController.forward();

    try {
      final preferences =
      await SharedPreferences.getInstance();

      await preferences.setString(
        _userNameKey,
        name,
      );

      await preferences.setBool(
        _onboardingCompletedKey,
        true,
      );

      if (!mounted) {
        return;
      }

      await _buttonController.reverse();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration:
          const Duration(
            milliseconds: 850,
          ),
          reverseTransitionDuration:
          const Duration(
            milliseconds: 500,
          ),
          pageBuilder: (
              context,
              animation,
              secondaryAnimation,
              ) {
            return BottomNav(
              settings: widget.settings,
            );
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
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.025,
                  end: 1.0,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      await _buttonController.reverse();
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final appColor =
        colors.primary;

    return ScreenUtilPlusInit(
      designSize:
      const Size(
        390,
        844,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (
          context,
          child,
          ) {
        return Scaffold(
          backgroundColor:
          theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true,
          body: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _ambientController,
              _buttonController,
              _fieldController,
            ]),
            builder: (
                context,
                child,
                ) {
              final entrance =
              CurvedAnimation(
                parent:
                _entranceController,
                curve:
                Curves.easeOutCubic,
              );

              final entranceValue =
                  entrance.value;

              final ambientValue =
                  _ambientController.value;

              final buttonValue =
                  _buttonController.value;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // ==========================================================
                  // BACKGROUND
                  // ==========================================================

                  Container(
                    color:
                    theme.scaffoldBackgroundColor,
                  ),

                  _CinematicBackground(
                    color: appColor,
                    animation:
                    ambientValue,
                  ),

                  // ==========================================================
                  // CONTENT
                  // ==========================================================

                  SafeArea(
                    child: LayoutBuilder(
                      builder: (
                          context,
                          constraints,
                          ) {
                        final keyboardHeight =
                            MediaQuery.viewInsetsOf(
                              context,
                            ).bottom;

                        final keyboardOpen =
                            keyboardHeight > 0;

                        return AnimatedPadding(
                          duration:
                          const Duration(
                            milliseconds: 280,
                          ),
                          curve:
                          Curves.easeOutCubic,
                          padding:
                          EdgeInsets.only(
                            bottom:
                            keyboardOpen
                                ? keyboardHeight
                                : 0,
                          ),
                          child:
                          SingleChildScrollView(
                            physics:
                            const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints:
                              BoxConstraints(
                                minHeight:
                                constraints.maxHeight,
                              ),
                              child:
                              Padding(
                                padding:
                                EdgeInsets.symmetric(
                                  horizontal:
                                  24.w,
                                ),
                                child:
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    // ========================================
                                    // TOP BRAND
                                    // ========================================

                                    SizedBox(
                                      height:
                                      26.h,
                                    ),

                                    _AnimatedEntrance(
                                      opacity:
                                      entranceValue,
                                      offset:
                                      Offset(
                                        -18.w *
                                            (1 -
                                                entranceValue),
                                        0,
                                      ),
                                      child:
                                      _BrandMark(
                                        color:
                                        appColor,
                                      ),
                                    ),

                                    // ========================================
                                    // HERO
                                    // ========================================

                                    SizedBox(
                                      height:
                                      112.h,
                                    ),

                                    _AnimatedEntrance(
                                      opacity:
                                      entranceValue,
                                      offset:
                                      Offset(
                                        0,
                                        30.h *
                                            (1 -
                                                entranceValue),
                                      ),
                                      child:
                                      _HeroSection(
                                        colors:
                                        colors,
                                        animation:
                                        entranceValue,
                                      ),
                                    ),

                                    // ========================================
                                    // LARGE SPACING
                                    // ========================================

                                    SizedBox(
                                      height:
                                      105.h,
                                    ),

                                    // ========================================
                                    // NAME AREA
                                    // ========================================

                                    _AnimatedEntrance(
                                      opacity:
                                      entranceValue,
                                      offset:
                                      Offset(
                                        0,
                                        28.h *
                                            (1 -
                                                entranceValue),
                                      ),
                                      child:
                                      _NameSection(
                                        controller:
                                        _nameController,
                                        focusNode:
                                        _nameFocus,
                                        colors:
                                        colors,
                                        accent:
                                        appColor,
                                        fieldAnimation:
                                        _fieldController,
                                        onSubmitted:
                                            (_) =>
                                            _continue(),
                                      ),
                                    ),

                                    // ========================================
                                    // BUTTON
                                    // ========================================

                                    SizedBox(
                                      height:
                                      26.h,
                                    ),

                                    _AnimatedEntrance(
                                      opacity:
                                      entranceValue,
                                      offset:
                                      Offset(
                                        0,
                                        22.h *
                                            (1 -
                                                entranceValue),
                                      ),
                                      child:
                                      _ContinueButton(
                                        color:
                                        appColor,
                                        colors:
                                        colors,
                                        isSaving:
                                        _isSaving,
                                        animation:
                                        buttonValue,
                                        onTap:
                                        _continue,
                                      ),
                                    ),

                                    // ========================================
                                    // FOOTER
                                    // ========================================

                                    SizedBox(
                                      height:
                                      18.h,
                                    ),

                                    Center(
                                      child:
                                      AnimatedOpacity(
                                        duration:
                                        const Duration(
                                          milliseconds:
                                          500,
                                        ),
                                        opacity:
                                        entranceValue *
                                            0.34,
                                        child:
                                        Text(
                                          'YOUR MUSIC. YOUR MOOD.',
                                          textAlign:
                                          TextAlign
                                              .center,
                                          style:
                                          TextStyle(
                                            fontSize:
                                            8.sp,
                                            letterSpacing:
                                            1.6,
                                            fontWeight:
                                            FontWeight
                                                .w700,
                                            color:
                                            colors
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      height:
                                      18.h,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// ANIMATED ENTRANCE
// =============================================================================

class _AnimatedEntrance
    extends StatelessWidget {
  final double opacity;
  final Offset offset;
  final Widget child;

  const _AnimatedEntrance({
    required this.opacity,
    required this.offset,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Opacity(
      opacity:
      opacity.clamp(
        0.0,
        1.0,
      ),
      child:
      Transform.translate(
        offset: offset,
        child: child,
      ),
    );
  }
}

// =============================================================================
// BRAND
// =============================================================================

class _BrandMark
    extends StatelessWidget {
  final Color color;

  const _BrandMark({
    required this.color,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,
            color:
            color.withValues(
              alpha: 0.09,
            ),
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: color,
            size: 18.sp,
          ),
        ),
        SizedBox(
          width: 9.w,
        ),
        Text(
          'CHAMELEON',
          style:
          TextStyle(
            fontSize: 9.sp,
            letterSpacing: 2.4,
            fontWeight:
            FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// HERO
// =============================================================================

class _HeroSection
    extends StatelessWidget {
  final ColorScheme colors;
  final double animation;

  const _HeroSection({
    required this.colors,
    required this.animation,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final scale =
        0.96 +
            (animation * 0.04);

    return Transform.scale(
      alignment:
      Alignment.centerLeft,
      scale: scale,
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome',
            style:
            TextStyle(
              fontSize: 16.sp,
              fontWeight:
              FontWeight.w500,
              letterSpacing:
              -0.2,
              color:
              colors.onSurfaceVariant,
            ),
          ),

          SizedBox(
            height: 5.h,
          ),

          Text(
            'Chameleon',
            style:
            TextStyle(
              fontSize: 45.sp,
              height: 0.98,
              letterSpacing:
              -2.4,
              fontWeight:
              FontWeight.w800,
              color:
              colors.onSurface,
            ),
          ),

          SizedBox(
            height: 16.h,
          ),

          ConstrainedBox(
            constraints:
            BoxConstraints(
              maxWidth: 270.w,
            ),
            child:
            Text(
              'Music that feels like you.',
              style:
              TextStyle(
                fontSize: 15.sp,
                height: 1.45,
                fontWeight:
                FontWeight.w500,
                letterSpacing:
                -0.15,
                color:
                colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// NAME SECTION
// =============================================================================

class _NameSection
    extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ColorScheme colors;
  final Color accent;
  final AnimationController fieldAnimation;
  final ValueChanged<String> onSubmitted;

  const _NameSection({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.accent,
    required this.fieldAnimation,
    required this.onSubmitted,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'What should we call you?',
          style:
          TextStyle(
            fontSize: 13.sp,
            fontWeight:
            FontWeight.w700,
            letterSpacing:
            -0.1,
            color:
            colors.onSurface,
          ),
        ),

        SizedBox(
          height: 12.h,
        ),

        _MinimalNameField(
          controller:
          controller,
          focusNode:
          focusNode,
          colors:
          colors,
          accent:
          accent,
          fieldAnimation:
          fieldAnimation,
          onSubmitted:
          onSubmitted,
        ),

        SizedBox(
          height: 9.h,
        ),

        Text(
          'You can change this later in Settings.',
          style:
          TextStyle(
            fontSize: 10.sp,
            fontWeight:
            FontWeight.w500,
            color:
            colors.onSurfaceVariant
                .withValues(
              alpha: 0.65,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// NAME FIELD
// =============================================================================

class _MinimalNameField
    extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ColorScheme colors;
  final Color accent;
  final AnimationController fieldAnimation;
  final ValueChanged<String> onSubmitted;

  const _MinimalNameField({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.accent,
    required this.fieldAnimation,
    required this.onSubmitted,
  });

  @override
  State<_MinimalNameField>
  createState() =>
      _MinimalNameFieldState();
}

class _MinimalNameFieldState
    extends State<_MinimalNameField> {
  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(
      _focusChanged,
    );
  }

  void _focusChanged() {
    if (widget.focusNode.hasFocus) {
      widget.fieldAnimation.forward();
    } else {
      widget.fieldAnimation.reverse();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(
      _focusChanged,
    );

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final focused =
        widget.focusNode.hasFocus;

    return Column(
      children: [
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 220,
          ),
          curve:
          Curves.easeOutCubic,
          height: 58.h,
          decoration:
          BoxDecoration(
            color: focused
                ? widget.accent
                .withValues(
              alpha: 0.045,
            )
                : widget.colors
                .surface
                .withValues(
              alpha: 0.018,
            ),
            borderRadius:
            BorderRadius.circular(
              16.r,
            ),
          ),
          child:
          TextField(
            controller:
            widget.controller,
            focusNode:
            widget.focusNode,
            textCapitalization:
            TextCapitalization.words,
            textInputAction:
            TextInputAction.done,
            keyboardType:
            TextInputType.name,
            maxLength:
            30,
            onSubmitted:
            widget.onSubmitted,
            style:
            TextStyle(
              fontSize: 17.sp,
              fontWeight:
              FontWeight.w600,
              letterSpacing:
              -0.25,
              color:
              widget.colors
                  .onSurface,
            ),
            cursorColor:
            widget.accent,
            decoration:
            InputDecoration(
              counterText:
              '',
              border:
              InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 17.h,
              ),
              hintText:
              'Enter your name',
              hintStyle:
              TextStyle(
                fontSize: 16.sp,
                fontWeight:
                FontWeight.w500,
                color: widget
                    .colors
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.58,
                ),
              ),
            ),
          ),
        ),

        SizedBox(
          height: 2.h,
        ),

        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 260,
          ),
          curve:
          Curves.easeOutCubic,
          height: 2.h,
          width: double.infinity,
          decoration:
          BoxDecoration(
            color: focused
                ? widget.accent
                : widget.colors
                .onSurface
                .withValues(
              alpha: 0.10,
            ),
            borderRadius:
            BorderRadius.circular(
              10.r,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CONTINUE BUTTON
// =============================================================================

class _ContinueButton
    extends StatelessWidget {
  final Color color;
  final ColorScheme colors;
  final bool isSaving;
  final double animation;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.color,
    required this.colors,
    required this.isSaving,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final scale =
        1.0 -
            (animation * 0.035);

    return Transform.scale(
      scale: scale,
      child:
      SizedBox(
        width:
        double.infinity,
        height: 58.h,
        child:
        Material(
          color:
          Colors.transparent,
          child:
          InkWell(
            borderRadius:
            BorderRadius.circular(
              18.r,
            ),
            onTap:
            isSaving
                ? null
                : onTap,
            child:
            AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 220,
              ),
              curve:
              Curves.easeOutCubic,
              decoration:
              BoxDecoration(
                color:
                color,
                borderRadius:
                BorderRadius.circular(
                  18.r,
                ),
              ),
              child:
              Center(
                child:
                AnimatedSwitcher(
                  duration:
                  const Duration(
                    milliseconds:
                    180,
                  ),
                  child:
                  isSaving
                      ? SizedBox(
                    key:
                    const ValueKey(
                      'loading',
                    ),
                    width:
                    20.w,
                    height:
                    20.w,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      colors.onPrimary,
                    ),
                  )
                      : Row(
                    key:
                    const ValueKey(
                      'continue',
                    ),
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style:
                        TextStyle(
                          fontSize:
                          15.sp,
                          fontWeight:
                          FontWeight.w700,
                          letterSpacing:
                          -0.1,
                          color:
                          colors.onPrimary,
                        ),
                      ),
                      SizedBox(
                        width:
                        8.w,
                      ),
                      Icon(
                        Icons
                            .arrow_forward_rounded,
                        size:
                        19.sp,
                        color:
                        colors.onPrimary,
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
// CINEMATIC BACKGROUND
// =============================================================================

class _CinematicBackground
    extends StatelessWidget {
  final Color color;
  final double animation;

  const _CinematicBackground({
    required this.color,
    required this.animation,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final size =
    MediaQuery.sizeOf(
      context,
    );

    final wave =
    Curves.easeInOut.transform(
      animation,
    );

    final x1 =
        size.width *
            (0.02 +
                wave * 0.18);

    final y1 =
        size.height *
            (0.04 -
                wave * 0.035);

    final x2 =
        size.width *
            (0.68 -
                wave * 0.15);

    final y2 =
        size.height *
            (0.70 +
                wave * 0.08);

    return IgnorePointer(
      child:
      Stack(
        fit:
        StackFit.expand,
        children: [
          // ================================================================
          // TOP LIGHT
          // ================================================================

          Positioned(
            left:
            x1,
            top:
            y1,
            child:
            ImageFiltered(
              imageFilter:
              ImageFilter.blur(
                sigmaX:
                90,
                sigmaY:
                90,
              ),
              child:
              Container(
                width:
                size.width *
                    0.62,
                height:
                size.width *
                    0.62,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
                  color:
                  color.withValues(
                    alpha:
                    0.045,
                  ),
                ),
              ),
            ),
          ),

          // ================================================================
          // LOWER LIGHT
          // ================================================================

          Positioned(
            left:
            x2,
            top:
            y2,
            child:
            ImageFiltered(
              imageFilter:
              ImageFilter.blur(
                sigmaX:
                105,
                sigmaY:
                105,
              ),
              child:
              Container(
                width:
                size.width *
                    0.52,
                height:
                size.width *
                    0.52,
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
            ),
          ),

          // ================================================================
          // SUBTLE CENTER GLOW
          // ================================================================

          Positioned.fill(
            child:
            DecoratedBox(
              decoration:
              BoxDecoration(
                gradient:
                RadialGradient(
                  center:
                  Alignment(
                    wave *
                        0.10,
                    -0.10 +
                        wave *
                            0.08,
                  ),
                  radius:
                  0.85,
                  colors: [
                    color.withValues(
                      alpha:
                      0.015,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}