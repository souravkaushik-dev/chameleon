import 'package:advanced_salomon_bottom_bar/advanced_salomon_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/library/library_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({
    super.key,
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

    _screens = const [
      HomeScreen(),
   //   SearchScreen(),
 //     LibraryScreen(),
//      SettingsScreen(),
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

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,

          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating bottom navigation.
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
            ),
            child: _ChameleonBottomBar(
              currentIndex: _currentIndex,
              onChanged: (index) {
                if (index == _currentIndex) {
                  return;
                }

                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// FLOATING BOTTOM BAR
// =============================================================================

class _ChameleonBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _ChameleonBottomBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28.r),

          // Floating shadow.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark
                    ? 0.30
                    : 0.12,
              ),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(
                0,
                10,
              ),
            ),
          ],

          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark
                  ? 0.06
                  : 0.04,
            ),
            width: 0.8,
          ),
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: AdvancedSalomonBottomBar(
            currentIndex: currentIndex,
            onTap: onChanged,

            backgroundColor: Colors.transparent,

            margin: EdgeInsets.symmetric(
              horizontal: 5.w,
              vertical: 5.h,
            ),

            selectedColorOpacity: 0.10,

            itemShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21.r),
            ),

            items: [
              // ===============================================================
              // HOME
              // ===============================================================

              AdvancedSalomonBottomBarItem(
                icon: Icon(
                  Icons.home_outlined,
                  size: 22.sp,
                ),
                activeIcon: Icon(
                  Icons.home_rounded,
                  size: 22.sp,
                ),
                title: Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor:
                theme.colorScheme.onSurface,
                unselectedColor:
                theme.colorScheme.onSurfaceVariant,
              ),

              // ===============================================================
              // SEARCH
              // ===============================================================

              AdvancedSalomonBottomBarItem(
                icon: Icon(
                  Icons.search_outlined,
                  size: 22.sp,
                ),
                activeIcon: Icon(
                  Icons.search_rounded,
                  size: 22.sp,
                ),
                title: Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor:
                theme.colorScheme.onSurface,
                unselectedColor:
                theme.colorScheme.onSurfaceVariant,
              ),

              // ===============================================================
              // LIBRARY
              // ===============================================================

              AdvancedSalomonBottomBarItem(
                icon: Icon(
                  Icons.library_music_outlined,
                  size: 22.sp,
                ),
                activeIcon: Icon(
                  Icons.library_music_rounded,
                  size: 22.sp,
                ),
                title: Text(
                  'Library',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor:
                theme.colorScheme.onSurface,
                unselectedColor:
                theme.colorScheme.onSurfaceVariant,
              ),

              // ===============================================================
              // SETTINGS
              // ===============================================================

              AdvancedSalomonBottomBarItem(
                icon: Icon(
                  Icons.settings_outlined,
                  size: 22.sp,
                ),
                activeIcon: Icon(
                  Icons.settings_rounded,
                  size: 22.sp,
                ),
                title: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor:
                theme.colorScheme.onSurface,
                unselectedColor:
                theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}