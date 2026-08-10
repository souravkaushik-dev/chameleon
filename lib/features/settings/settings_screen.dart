import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hicons/flutter_hicons.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/settings_service.dart';
import 'equalizer.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;

  final AudioPlayerService audioPlayerService;

  final VoidCallback? onOpenGithub;

  final String version;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.audioPlayerService,
    this.onOpenGithub,
    this.version = '1.0.2+3',
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsService get settings => widget.settings;

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

  void _openEqualizer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EqualizerScreen(
          audioService: widget.audioPlayerService,
        ),
      ),
    );
  }


  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // -------------------------------------------------------------------------
  // APPEARANCE
  // -------------------------------------------------------------------------

  Future<void> _showThemePicker() async {
    final selected =
    await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return _ChoiceSheet<ThemeMode>(
          title: 'Appearance',
          subtitle: 'Choose how Chameleon should look',
          selected: settings.themeMode,
          items: const [
            _ChoiceItem(
              value: ThemeMode.system,
              title: 'System',
              subtitle: 'Follow your device appearance',
              icon: Hicons.colorPickerLightOutline,
            ),
            _ChoiceItem(
              value: ThemeMode.light,
              title: 'Light',
              subtitle: 'Always use light mode',
              icon: Hicons.sun2LightOutline,
            ),
            _ChoiceItem(
              value: ThemeMode.dark,
              title: 'Dark',
              subtitle: 'Always use dark mode',
              icon: Hicons.moonLightOutline,
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await settings.setThemeMode(selected);
    }
  }

  // -------------------------------------------------------------------------
  // RECENTLY PLAYED
  // -------------------------------------------------------------------------

  Future<void> _showRecentLimit() async {
    final selected =
    await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return _ChoiceSheet<int>(
          title: 'Recently played',
          subtitle: 'Choose how many songs to remember',
          selected: settings.recentLimit,
          items: const [
            _ChoiceItem(
              value: 25,
              title: '25 songs',
              subtitle: 'Keep a smaller history',
              icon: Hicons.rotateLeftLightOutline,
            ),
            _ChoiceItem(
              value: 50,
              title: '50 songs',
              subtitle: 'Recommended',
              icon: Hicons.rotateLeftLightOutline,
            ),
            _ChoiceItem(
              value: 100,
              title: '100 songs',
              subtitle: 'Keep more listening history',
              icon: Hicons.rotateLeftLightOutline,
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await settings.setRecentLimit(selected);
    }
  }

  // -------------------------------------------------------------------------
  // RESET
  // -------------------------------------------------------------------------

  Future<void> _resetSettings() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor:
          theme.colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: const Text(
            'Reset settings?',
          ),
          content: const Text(
            'Your settings will be restored to their defaults. '
                'Your playlists, liked songs, and recently played songs '
                'will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Reset',
              ),
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

  // -------------------------------------------------------------------------
  // ABOUT
  // -------------------------------------------------------------------------

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return _AboutSheet(
          version: widget.version,
          onGithub: widget.onOpenGithub,
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // MESSAGE
  // -------------------------------------------------------------------------

  void _showMessage(
      String message,
      ) {
    final theme = Theme.of(context);

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
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18.r),
          ),
        ),
      );
  }

  // -------------------------------------------------------------------------
  // THEME NAME
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics:
        const BouncingScrollPhysics(),
        slivers: [
          // -----------------------------------------------------------------
          // APP BAR
          // -----------------------------------------------------------------

          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor:
            theme.scaffoldBackgroundColor,
            surfaceTintColor:
            Colors.transparent,
            titleSpacing: 20.w,
            toolbarHeight: 64.h,
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

          // -----------------------------------------------------------------
          // HERO
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                8.h,
                20.w,
                22.h,
              ),
              child: _SettingsHero(
                color: color,
                version: widget.version,
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

          // -----------------------------------------------------------------
          // APPEARANCE
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Appearance',
              icon: Hicons.paletteLightOutline,
              children: [
                _SettingsTile(
                  icon:
                  Hicons.colorPickerLightOutline,
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

          // -----------------------------------------------------------------
          // PLAYER
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Player',
              icon:
              Hicons.musicnoteLightOutline,
              children: [
                _AnimatedSwitchTile(
                  icon:
                  Hicons.up2LightOutline,
                  title: 'Mini player',
                  subtitle:
                  'Show the current song above the navigation bar',
                  value:
                  settings.miniPlayer,
                  onChanged:
                  settings.setMiniPlayer,
                ),

                _SettingsTile(
                  icon: Hicons.filter4LightOutline,
                  title: 'Equalizer',
                  subtitle: 'Adjust bass, vocals and other frequencies',
                  onTap: _openEqualizer,
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // SEARCH
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Search',
              icon: Hicons.search1LightOutline,
              children: [
                _AnimatedSwitchTile(
                  icon:
                  Hicons.rotateLeftLightOutline,
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

          // -----------------------------------------------------------------
          // LIBRARY
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Library',
              icon:
              Hicons.folder2LightOutline,
              children: [
                _SettingsTile(
                  icon:
                  Hicons.rotateLeftLightOutline,
                  title: 'Recently played',
                  subtitle:
                  '${settings.recentLimit} songs',
                  onTap:
                  _showRecentLimit,
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // ABOUT
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'About',
              icon: Hicons.informationSquareLightOutline,
              children: [
                _SettingsTile(
                  icon:
                  Hicons.dangerTriangleLightOutline,
                  title: 'About Chameleon',
                  subtitle:
                  'Version ${widget.version}',
                  onTap:
                  _showAbout,
                ),

                _SettingsTile(
                  icon:
                  Hicons.linkLightOutline,
                  title: 'GitHub',
                  subtitle:
                  'View the Chameleon project',
                  onTap:
                  widget.onOpenGithub,
                  trailing:
                  widget.onOpenGithub == null
                      ? const _UnavailableBadge()
                      : null,
                ),

                _SettingsTile(
                  icon:
                  Hicons.documentAlignCenter2LightOutline,
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
                      widget.version,
                    );
                  },
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // RESET
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                2.h,
                20.w,
                10.h,
              ),
              child: _ResetTile(
                color: color,
                onTap:
                _resetSettings,
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // FOOTER
          // -----------------------------------------------------------------

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                18.h,
                20.w,
                120.h,
              ),
              child: Column(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration:
                    BoxDecoration(
                      color: color.withValues(
                        alpha: 0.10,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child: Icon(
                      Hicons
                          .musicnoteLightOutline,
                      size: 23.sp,
                      color: color,
                    ),
                  ),

                  SizedBox(
                    height: 10.h,
                  ),

                  Text(
                    'Made for music.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight:
                      FontWeight.w700,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  SizedBox(
                    height: 4.h,
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
// SETTINGS HERO
class _SettingsHero
    extends StatelessWidget {
  final Color color;
  final String version;

  const _SettingsHero({
    required this.color,
    required this.version,
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
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            color,
            color.withValues(
              alpha: 0.78,
            ),
          ],
        ),
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
              color:
              Colors.white.withValues(
                alpha: 0.14,
              ),
              shape:
              BoxShape.circle,
            ),
            child: const Icon(
              Hicons
                  .musicnoteLightOutline,
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
                    color:
                    Colors.white,
                    fontSize: 19.sp,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing:
                    -0.3,
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

                SizedBox(
                  height: 8.h,
                ),

                Text(
                  'Version $version',
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 9.5.sp,
                    fontWeight:
                    FontWeight.w600,
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
// SETTINGS SECTION
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

    final color =
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
                  color: color,
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
                    letterSpacing:
                    1.05,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

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
// DIVIDER
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
// SETTINGS TILE
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
        splashColor: theme
            .colorScheme
            .primary
            .withValues(
          alpha: 0.06,
        ),
        highlightColor: theme
            .colorScheme
            .primary
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
                      TextOverflow
                          .ellipsis,
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
                      TextOverflow
                          .ellipsis,
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
                  Hicons
                      .right2LightOutline,
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
// SWITCH TILE
class _AnimatedSwitchTile
    extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>
  onChanged;

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
                  CrossAxisAlignment
                      .start,
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
                      TextOverflow
                          .ellipsis,
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
                onTap: _toggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// LIQUID GLASS SWITCH
class _AnimatedSwitch
    extends StatelessWidget {
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
    final theme =
    Theme.of(context);

    return LiquidGlassToggle(
      value: value,
      activeColor:
      theme.colorScheme.primary,
      onChanged: (_) {
        onTap();
      },
      style:
      LiquidGlassStyle(
        shape:
        LiquidGlassShape.squircle(
          cornerRadius: 20,
          borderType:
          OpticalBorder(
            borderSaturation:
            1.2,
            ambientIntensity:
            1.0,
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
// SETTINGS ICON
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

    final color =
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
            ? color.withValues(
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
      child:
      AnimatedSwitcher(
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
              ? color
              : theme
              .colorScheme
              .onSurfaceVariant,
        ),
      ),
    );
  }
}
// UNAVAILABLE BADGE
class _UnavailableBadge
    extends StatelessWidget {
  const _UnavailableBadge();

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Container(
      padding:
      EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 5.h,
      ),
      decoration:
      BoxDecoration(
        color: theme
            .colorScheme
            .onSurface
            .withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          99.r,
        ),
      ),
      child: Text(
        'SET UP',
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight:
          FontWeight.w800,
          letterSpacing: 0.7,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
      ),
    );
  }
}
// CHOICE ITEM
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
// CHOICE SHEET
class _ChoiceSheet<T>
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final T selected;
  final List<_ChoiceItem<T>>
  items;

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

    final color =
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
          color: theme
              .scaffoldBackgroundColor,
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

            for (final item
            in items)
              _ChoiceRow<T>(
                item: item,
                selected:
                item.value ==
                    selected,
                color: color,
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
// CHOICE ROW
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
                  CrossAxisAlignment
                      .start,
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
                  Hicons
                      .tickLightOutline,
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
// SHEET HANDLE
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

class _AboutSheet extends StatelessWidget {
  final String version;
  final VoidCallback? onGithub;

  const _AboutSheet({
    required this.version,
    required this.onGithub,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final primary = colors.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        10.w,
        0,
        10.w,
        10.h,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20.w,
          14.h,
          20.w,
          20.h,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),

            SizedBox(height: 20.h),
            // APP ICON
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                color: primary.withValues(
                  alpha: 0.11,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Hicons.musicnoteLightOutline,
                color: primary,
                size: 38.sp,
              ),
            ),

            SizedBox(height: 14.h),
            // APP NAME
            Text(
              'Chameleon',
              style: TextStyle(
                fontSize: 25.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),

            SizedBox(height: 5.h),

            Text(
              'Music player',
              style: TextStyle(
                fontSize: 11.sp,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 6.h),

            Text(
              'Version $version',
              style: TextStyle(
                fontSize: 10.sp,
                color: colors.onSurfaceVariant.withValues(
                  alpha: 0.65,
                ),
              ),
            ),

            SizedBox(height: 22.h),
            // FEATURES
            _AboutInfoRow(
              icon: Hicons.playLightOutline,
              title: 'Real music playback',
              subtitle:
              'Smooth playback with background audio controls.',
            ),

            SizedBox(height: 8.h),

            _AboutInfoRow(
              icon: Hicons.search1LightOutline,
              title: 'YouTube music discovery',
              subtitle:
              'Search and discover music with high-quality artwork.',
            ),

            SizedBox(height: 8.h),

            _AboutInfoRow(
              icon: Hicons.filter4LightOutline,
              title: 'Built-in equalizer',
              subtitle:
              'Fine-tune bass, vocals, treble and individual frequencies.',
            ),

            SizedBox(height: 8.h),

            _AboutInfoRow(
              icon: Hicons.voiceLightOutline,
              title: 'Sound presets',
              subtitle:
              'Quickly switch between Flat, Bass, Treble, Vocal, Pop, Rock and more.',
            ),

            SizedBox(height: 8.h),

            _AboutInfoRow(
              icon: Hicons.imageLightOutline,
              title: 'High-resolution artwork',
              subtitle:
              'Beautiful album and song artwork throughout the player.',
            ),

            SizedBox(height: 8.h),

            _AboutInfoRow(
              icon: Hicons.dropLightOutline,
              title: 'Liquid Glass interface',
              subtitle:
              'A refined interface with smooth animations and glass controls.',
            ),

            SizedBox(height: 18.h),
            // GITHUB
            if (onGithub != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);

                    onGithub!();
                  },
                  icon: const Icon(
                    Hicons.linkLightOutline,
                  ),
                  label: const Text(
                    'View on GitHub',
                  ),
                ),
              ),

              SizedBox(height: 8.h),
            ],
            // FOOTER
            Text(
              'Made for music lovers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: colors.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 6.h),
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
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
// ABOUT INFO
class _AboutInfoRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AboutInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Container(
      padding:
      EdgeInsets.all(13.w),
      decoration:
      BoxDecoration(
        color: theme
            .colorScheme
            .surfaceContainerLow,
        borderRadius:
        BorderRadius.circular(
          18.r,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration:
            BoxDecoration(
              color: theme
                  .colorScheme
                  .primary
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                13.r,
              ),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: theme
                  .colorScheme
                  .primary,
            ),
          ),

          SizedBox(
            width: 12.w,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
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
                    fontSize: 10.sp,
                    height: 1.25,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
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
// RESET TILE
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
                  Hicons
                      .refresh1LightOutline,
                  color: color,
                ),
              ),

              SizedBox(
                width: 13.w,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
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
                Hicons
                    .right2LightOutline,
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