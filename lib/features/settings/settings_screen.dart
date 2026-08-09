import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../data/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;

  const SettingsScreen({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  SettingsService get settings =>
      widget.settings;

  @override
  void initState() {
    super.initState();
    settings.addListener(
      _onSettingsChanged,
    );
  }

  @override
  void dispose() {
    settings.removeListener(
      _onSettingsChanged,
    );
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _showThemePicker() async {
    final selected =
    await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      builder: (context) {
        return _ChoiceSheet<ThemeMode>(
          title: 'Appearance',
          subtitle:
          'Choose how Chameleon should look',
          selected: settings.themeMode,
          items: const [
            _ChoiceItem(
              value: ThemeMode.system,
              title: 'System',
              subtitle:
              'Follow your device appearance',
              icon:
              Icons.brightness_auto_rounded,
            ),
            _ChoiceItem(
              value: ThemeMode.light,
              title: 'Light',
              subtitle:
              'Always use light mode',
              icon:
              Icons.light_mode_rounded,
            ),
            _ChoiceItem(
              value: ThemeMode.dark,
              title: 'Dark',
              subtitle:
              'Always use dark mode',
              icon:
              Icons.dark_mode_rounded,
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await settings.setThemeMode(
        selected,
      );
    }
  }
  Future<void> _showRecentLimit() async {
    final selected =
    await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      builder: (context) {
        return _ChoiceSheet<int>(
          title: 'Recently played',
          subtitle:
          'Choose how many songs to remember',
          selected:
          settings.recentLimit,
          items: const [
            _ChoiceItem(
              value: 25,
              title: '25 songs',
              subtitle:
              'Keep a smaller history',
              icon:
              Icons.history_rounded,
            ),
            _ChoiceItem(
              value: 50,
              title: '50 songs',
              subtitle: 'Recommended',
              icon:
              Icons.history_rounded,
            ),
            _ChoiceItem(
              value: 100,
              title: '100 songs',
              subtitle:
              'Keep more listening history',
              icon:
              Icons.history_rounded,
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await settings.setRecentLimit(
        selected,
      );
    }
  }
  Future<void> _resetSettings() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme =
        Theme.of(context);

        return AlertDialog(
          backgroundColor:
          theme.scaffoldBackgroundColor,
          elevation: 0,
          title: const Text(
            'Reset settings?',
          ),
          content: const Text(
            'Your settings will be restored to their defaults. Your playlists, liked songs, and recently played songs will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor:
                theme.colorScheme.primary,
              ),
              child:
              const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await settings.reset();

    if (!mounted) {
      return;
    }

    _showMessage(
      'Settings restored',
    );
  }
  void _showMessage(
      String message,
      ) {
    final theme =
    Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          theme.colorScheme.primary,
          behavior:
          SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            18.w,
            0,
            18.w,
            20.h,
          ),
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18.r,
            ),
          ),
        ),
      );
  }
  String _themeName(
      ThemeMode mode,
      ) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';

      case ThemeMode.dark:
        return 'Dark';

      case ThemeMode.system:
        return 'System default';
    }
  }
  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final appColor =
        theme.colorScheme.primary;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,

      body: CustomScrollView(
        physics:
        const BouncingScrollPhysics(),

        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor:
            theme.scaffoldBackgroundColor,
            surfaceTintColor:
            Colors.transparent,
            titleSpacing: 20.w,

            title: Text(
              'Settings',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight:
                FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.fromLTRB(
                20.w,
                8.h,
                20.w,
                22.h,
              ),
              child: _SettingsHero(
                color: appColor,
              )
                  .animate()
                  .fadeIn(
                duration: 350.ms,
              )
                  .slideY(
                begin: 0.04,
                end: 0,
                duration: 400.ms,
                curve:
                Curves.easeOutCubic,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Appearance',
              icon:
              Icons.palette_rounded,
              children: [
                _SettingsTile(
                  icon:
                  Icons.brightness_6_rounded,
                  title: 'Theme',
                  subtitle:
                  _themeName(
                    settings.themeMode,
                  ),
                  onTap:
                  _showThemePicker,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Player',
              icon:
              Icons.music_note_rounded,
              children: [
                _AnimatedSwitchTile(
                  icon:
                  Icons
                      .keyboard_arrow_up_rounded,
                  title: 'Mini player',
                  subtitle:
                  'Show the current song above the navigation bar',
                  value:
                  settings.miniPlayer,
                  onChanged:
                  settings.setMiniPlayer,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Search',
              icon:
              Icons.search_rounded,
              children: [
                _AnimatedSwitchTile(
                  icon:
                  Icons.history_rounded,
                  title: 'Search history',
                  subtitle:
                  'Save recent searches for quick access',
                  value:
                  settings.saveSearches,
                  onChanged:
                  settings.setSaveSearches,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Library',
              icon:
              Icons.library_music_rounded,
              children: [
                _SettingsTile(
                  icon:
                  Icons.history_rounded,
                  title:
                  'Recently played',
                  subtitle:
                  '${settings.recentLimit} songs',
                  onTap:
                  _showRecentLimit,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'About',
              icon:
              Icons.info_rounded,
              children: [
                _SettingsTile(
                  icon:
                  Icons.music_note_rounded,
                  title: 'Chameleon',
                  subtitle:
                  'Version 1.0.0',
                  showChevron: false,
                ),

                _SettingsTile(
                  icon:
                  Icons.code_rounded,
                  title: 'GitHub',
                  subtitle:
                  'Open-source project',
                  onTap: () {
                    _showMessage(
                      'GitHub link coming soon',
                    );
                  },
                ),

                _SettingsTile(
                  icon:
                  Icons.description_rounded,
                  title:
                  'Open-source licenses',
                  subtitle:
                  'Libraries used by Chameleon',
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName:
                      'Chameleon',
                      applicationVersion:
                      '1.0.0',
                    );
                  },
                ),

                _SettingsTile(
                  icon:
                  Icons.storefront_rounded,
                  title:
                  'Google Play',
                  subtitle:
                  'Chameleon is coming soon',
                  trailing:
                  _ComingSoonBadge(
                    color: appColor,
                  ),
                  showChevron: false,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.fromLTRB(
                20.w,
                2.h,
                20.w,
                10.h,
              ),
              child: _ResetTile(
                color: appColor,
                onTap:
                _resetSettings,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.fromLTRB(
                20.w,
                15.h,
                20.w,
                125.h,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons
                        .music_note_rounded,
                    size: 24.sp,
                    color: appColor,
                  ),

                  SizedBox(
                    height: 8.h,
                  ),

                  Text(
                    'Made for music.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight:
                      FontWeight.w600,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  SizedBox(
                    height: 3.h,
                  ),

                  Text(
                    'Chameleon • Music player',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SettingsHero
    extends StatelessWidget {
  final Color color;

  const _SettingsHero({
    required this.color,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      EdgeInsets.all(20.w),

      decoration:
      BoxDecoration(
        color: color,
        borderRadius:
        BorderRadius.circular(
          28.r,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 58.w,
            height: 58.w,

            decoration:
            BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons
                  .music_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          SizedBox(
            width: 15.w,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  'Chameleon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(
                  height: 4.h,
                ),

                Text(
                  'Customize your listening experience.',
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 11.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SettingsSection
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final appColor =
        theme.colorScheme.primary;

    return Padding(
      padding:
      EdgeInsets.fromLTRB(
        20.w,
        4.h,
        20.w,
        15.h,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Padding(
            padding:
            EdgeInsets.fromLTRB(
              4.w,
              3.h,
              4.w,
              8.h,
            ),

            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: appColor,
                ),

                SizedBox(
                  width: 7.w,
                ),

                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing: 1.05,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Flat.
          // No border.
          // No shadow.

          Container(
            decoration:
            BoxDecoration(
              color: theme
                  .colorScheme
                  .surfaceContainerLow,
              borderRadius:
              BorderRadius.circular(
                24.r,
              ),
            ),

            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(
                24.r,
              ),

              child: Column(
                children: [
                  for (
                  int i = 0;
                  i < children.length;
                  i++
                  ) ...[
                    children[i],

                    if (i <
                        children.length - 1)
                      const _SoftDivider(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SoftDivider
    extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Padding(
      padding:
      EdgeInsets.only(
        left: 68.w,
        right: 14.w,
      ),

      child: Container(
        height: 1,
        color: theme
            .colorScheme
            .onSurface
            .withValues(
          alpha: 0.045,
        ),
      ),
    );
  }
}
class _SettingsTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        splashColor:
        theme.colorScheme.primary
            .withValues(
          alpha: 0.06,
        ),

        highlightColor:
        theme.colorScheme.primary
            .withValues(
          alpha: 0.035,
        ),

        child: Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 12.h,
          ),

          child: Row(
            children: [
              _SettingsIcon(
                icon: icon,
              ),

              SizedBox(
                width: 13.w,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    SizedBox(
                      height: 3.h,
                    ),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        height: 1.25,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null)
                Padding(
                  padding:
                  EdgeInsets.only(
                    left: 8.w,
                  ),
                  child: trailing!,
                ),

              if (onTap != null &&
                  showChevron)
                Icon(
                  Icons
                      .chevron_right_rounded,
                  size: 20.sp,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.42,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
class _AnimatedSwitchTile
    extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimatedSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_AnimatedSwitchTile>
  createState() =>
      _AnimatedSwitchTileState();
}

class _AnimatedSwitchTileState
    extends State<_AnimatedSwitchTile> {
  bool _pressed = false;

  void _toggle() {
    widget.onChanged(
      !widget.value,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return GestureDetector(
      onTap: _toggle,

      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },

      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },

      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });
      },

      child: AnimatedScale(
        scale:
        _pressed ? 0.985 : 1,

        duration:
        const Duration(
          milliseconds: 110,
        ),

        child: Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 10.h,
          ),

          child: Row(
            children: [
              _SettingsIcon(
                icon: widget.icon,
                active:
                widget.value,
              ),

              SizedBox(
                width: 13.w,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    SizedBox(
                      height: 3.h,
                    ),

                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        height: 1.25,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 8.w,
              ),

              _AnimatedSwitch(
                value:
                widget.value,
                onTap:
                _toggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _AnimatedSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;

  const _AnimatedSwitch({
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return LiquidGlassToggle(
      value: value,

      activeColor: accent,

      onChanged: (_) {
        onTap();
      },

      style: LiquidGlassStyle(
        shape: LiquidGlassShape.squircle(
          cornerRadius: 20,
          borderType: OpticalBorder(
            borderSaturation: 1.2,
            ambientIntensity: 1.0,
          ),
        ),

        refraction:
        const LiquidGlassRefraction(
          distortion: 0.10,
          distortionWidth: 20,
          magnification: 1.04,
        ),
      ),
    );
  }
}
class _SettingsIcon
    extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _SettingsIcon({
    required this.icon,
    this.active = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final appColor =
        theme.colorScheme.primary;

    return AnimatedContainer(
      duration:
      const Duration(
        milliseconds: 220,
      ),

      width: 42.w,
      height: 42.w,

      decoration:
      BoxDecoration(
        color: active
            ? appColor.withValues(
          alpha: 0.11,
        )
            : theme
            .colorScheme
            .onSurface
            .withValues(
          alpha: 0.055,
        ),

        borderRadius:
        BorderRadius.circular(
          14.r,
        ),
      ),

      child: AnimatedSwitcher(
        duration:
        const Duration(
          milliseconds: 180,
        ),

        child: Icon(
          icon,

          key: ValueKey(
            '${icon.codePoint}_$active',
          ),

          size: 20.sp,

          color: active
              ? appColor
              : theme
              .colorScheme
              .onSurfaceVariant,
        ),
      ),
    );
  }
}
class _ChoiceItem<T> {
  final T value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ChoiceItem({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
class _ChoiceSheet<T>
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final T selected;
  final List<_ChoiceItem<T>> items;

  const _ChoiceSheet({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.items,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final appColor =
        theme.colorScheme.primary;

    return Padding(
      padding:
      EdgeInsets.fromLTRB(
        10.w,
        0,
        10.w,
        10.h,
      ),

      child: Container(
        padding:
        EdgeInsets.fromLTRB(
          12.w,
          12.h,
          12.w,
          14.h,
        ),

        decoration:
        BoxDecoration(
          color:
          theme.scaffoldBackgroundColor,
          borderRadius:
          BorderRadius.circular(
            30.r,
          ),
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            const _SheetHandle(),

            SizedBox(
              height: 8.h,
            ),

            Text(
              title,
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            SizedBox(
              height: 4.h,
            ),

            Text(
              subtitle,
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            SizedBox(
              height: 15.h,
            ),

            for (final item in items)
              _ChoiceRow<T>(
                item: item,
                selected:
                item.value ==
                    selected,
                color: appColor,
                onTap: () {
                  Navigator.pop(
                    context,
                    item.value,
                  );
                },
              ),
          ],
        ),
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
  }
}
class _ChoiceRow<T>
    extends StatelessWidget {
  final _ChoiceItem<T> item;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.item,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Material(
      color: selected
          ? color.withValues(
        alpha: 0.08,
      )
          : Colors.transparent,

      borderRadius:
      BorderRadius.circular(
        18.r,
      ),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          18.r,
        ),

        onTap: onTap,

        child: Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 8.h,
          ),

          child: Row(
            children: [
              Container(
                width: 45.w,
                height: 45.w,

                decoration:
                BoxDecoration(
                  color: theme
                      .colorScheme
                      .onSurface
                      .withValues(
                    alpha: 0.055,
                  ),
                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  item.icon,
                  size: 21.sp,
                  color: selected
                      ? color
                      : theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              SizedBox(
                width: 13.w,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    SizedBox(
                      height: 3.h,
                    ),

                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds: 180,
                ),

                child: selected
                    ? Icon(
                  Icons
                      .check_circle_rounded,
                  key:
                  const ValueKey(
                    'selected',
                  ),
                  color: color,
                  size: 22.sp,
                )
                    : Icon(
                  Icons
                      .radio_button_unchecked_rounded,
                  key:
                  const ValueKey(
                    'unselected',
                  ),
                  color: theme
                      .colorScheme
                      .onSurface
                      .withValues(
                    alpha: 0.18,
                  ),
                  size: 22.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SheetHandle
    extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Container(
      width: 38.w,
      height: 4.h,

      decoration:
      BoxDecoration(
        color: theme
            .colorScheme
            .onSurface
            .withValues(
          alpha: 0.12,
        ),
        borderRadius:
        BorderRadius.circular(
          99.r,
        ),
      ),
    );
  }
}
class _ComingSoonBadge
    extends StatelessWidget {
  final Color color;

  const _ComingSoonBadge({
    required this.color,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      EdgeInsets.symmetric(
        horizontal: 9.w,
        vertical: 5.h,
      ),

      decoration:
      BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
        BorderRadius.circular(
          99.r,
        ),
      ),

      child: Text(
        'SOON',
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight:
          FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
class _ResetTile
    extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ResetTile({
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Material(
      color: theme
          .colorScheme
          .surfaceContainerLow,

      borderRadius:
      BorderRadius.circular(
        22.r,
      ),

      child: InkWell(
        onTap: onTap,

        borderRadius:
        BorderRadius.circular(
          22.r,
        ),

        splashColor:
        color.withValues(
          alpha: 0.06,
        ),

        child: Padding(
          padding:
          EdgeInsets.all(14.w),

          child: Row(
            children: [
              Container(
                width: 45.w,
                height: 45.w,

                decoration:
                BoxDecoration(
                  color:
                  color.withValues(
                    alpha: 0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  Icons
                      .restart_alt_rounded,
                  color: color,
                ),
              ),

              SizedBox(
                width: 13.w,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Reset settings',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    SizedBox(
                      height: 3.h,
                    ),

                    Text(
                      'Restore settings to their defaults',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .chevron_right_rounded,
                color: theme
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}