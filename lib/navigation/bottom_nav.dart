import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../data/services/settings_service.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/library/library_screen.dart';
import '../features/settings/settings_screen.dart';

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
        final theme = Theme.of(context);

        final appColor =
            theme.colorScheme.primary;

        final onSurface =
            theme.colorScheme.onSurface;

        return LiquidGlassScaffold(
          backgroundColor:
          theme.scaffoldBackgroundColor,

          // =================================================================
          // MAIN CONTENT
          // =================================================================

          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // =================================================================
          // FLOATING LIQUID GLASS NAVIGATION
          // =================================================================

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
              // =============================================================
              // HOME
              // =============================================================

              LiquidGlassTabBarItem(
                icon:
                Icons.home_outlined,
                selectedIcon:
                Icons.home_rounded,
                label: 'Home',
              ),

              // =============================================================
              // SEARCH
              // =============================================================

              LiquidGlassTabBarItem(
                icon:
                Icons.search_outlined,
                selectedIcon:
                Icons.search_rounded,
                label: 'Search',
              ),

              // =============================================================
              // LIBRARY
              // =============================================================

              LiquidGlassTabBarItem(
                icon:
                Icons.library_music_outlined,
                selectedIcon:
                Icons.library_music_rounded,
                label: 'Library',
              ),

              // =============================================================
              // SETTINGS
              // =============================================================

              LiquidGlassTabBarItem(
                icon:
                Icons.settings_outlined,
                selectedIcon:
                Icons.settings_rounded,
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

            // =================================================================
            // ITEM STYLE
            // =================================================================

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

            // =================================================================
            // LIQUID MORPHING PILL
            // =================================================================

            pillStyle:
            LiquidGlassNavPillStyle(
              // Full glass-refracting pill
              // on both Impeller and Skia.
              mode:
              LiquidGlassPillMode.both,

              // Animate the pill between tabs.
              animated: true,

              animationDuration:
              const Duration(
                milliseconds: 360,
              ),

              animationCurve:
              Curves.easeOutCubic,

              // -------------------------------------------------------------
              // Selected pill tint
              // -------------------------------------------------------------

              color:
              appColor.withValues(
                alpha: 0.10,
              ),

              // -------------------------------------------------------------
              // THIS IS THE MAGNIFICATION
              // -------------------------------------------------------------

              magnification: 1.18,

              // -------------------------------------------------------------
              // Refraction
              // -------------------------------------------------------------

              distortion: 0.075,

              distortionWidth: 18,

              // -------------------------------------------------------------
              // Pill grows slightly while travelling
              // -------------------------------------------------------------

              growHeight: 10,

              // -------------------------------------------------------------
              // Keep inner glass transparent
              // so the content beneath participates
              // in the liquid-glass effect.
              // -------------------------------------------------------------

              enableInnerRadiusTransparent:
              true,

              // -------------------------------------------------------------
              // Spring travel
              // -------------------------------------------------------------

              travelStiffness: 300,

              travelDamping: 30,

              // -------------------------------------------------------------
              // Jelly movement
              // -------------------------------------------------------------

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
  }
}