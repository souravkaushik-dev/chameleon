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
    this.version = '1.0.3+4',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsService get settings => widget.settings;

  @override
  void initState() {
    super.initState();
    settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _openEqualizer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EqualizerScreen(audioService: widget.audioPlayerService),
      ),
    );
  }

  Future<void> _showThemePicker() async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ChoiceSheet<ThemeMode>(
        title: 'Appearance',
        subtitle: 'Choose how Chameleon should look',
        selected: settings.themeMode,
        items: const [
          _ChoiceItem(
            ThemeMode.system,
            'System',
            'Follow your device appearance',
            Icons.brightness_auto_rounded,
          ),
          _ChoiceItem(
            ThemeMode.light,
            'Light',
            'Always use light mode',
            Icons.light_mode_rounded,
          ),
          _ChoiceItem(
            ThemeMode.dark,
            'Dark',
            'Always use dark mode',
            Icons.dark_mode_rounded,
          ),
        ],
      ),
    );
    if (selected != null) await settings.setThemeMode(selected);
  }

  Future<void> _showRecentLimit() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ChoiceSheet<int>(
        title: 'Recently played',
        subtitle: 'Choose how many songs to remember',
        selected: settings.recentLimit,
        items: const [
          _ChoiceItem(
            25,
            '25 songs',
            'Keep a smaller history',
            Icons.history_rounded,
          ),
          _ChoiceItem(50, '50 songs', 'Recommended', Icons.history_rounded),
          _ChoiceItem(
            100,
            '100 songs',
            'Keep more listening history',
            Icons.history_rounded,
          ),
        ],
      ),
    );
    if (selected != null) await settings.setRecentLimit(selected);
  }

  Future<void> _showDownloadQuality() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ChoiceSheet<String>(
        title: 'Download quality',
        subtitle: 'Choose the preferred quality',
        selected: settings.downloadQuality,
        items: const [
          _ChoiceItem(
            'Low',
            'Low',
            'Smaller files',
            Icons.data_saver_on_outlined,
          ),
          _ChoiceItem(
            'Medium',
            'Medium',
            'Balanced quality and storage',
            Icons.graphic_eq_rounded,
          ),
          _ChoiceItem(
            'High',
            'High',
            'Best available quality',
            Icons.high_quality_outlined,
          ),
        ],
      ),
    );
    if (selected != null) await settings.setDownloadQuality(selected);
  }

  Future<void> _showSleepTimer() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _SleepTimerSheet(
        settings: settings,
        onCustom: () async {
          Navigator.pop(context);
          await Future<void>.delayed(const Duration(milliseconds: 120));
          if (mounted) await _showCustomSleepTimer();
        },
      ),
    );
  }

  Future<void> _showCustomSleepTimer() async {
    int hours = settings.sleepTimerDuration?.inHours ?? 0;
    int minutes = (settings.sleepTimerDuration?.inMinutes ?? 30).remainder(60);

    final duration = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
          child: _GlassSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                SizedBox(height: 14.h),
                Text(
                  'Custom sleep timer',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Choose any duration manually.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NumberPicker(
                      label: 'Hours',
                      value: hours,
                      max: 23,
                      onChanged: (v) => setModalState(() => hours = v),
                    ),
                    SizedBox(width: 18.w),
                    _NumberPicker(
                      label: 'Minutes',
                      value: minutes,
                      max: 59,
                      onChanged: (v) => setModalState(() => minutes = v),
                    ),
                  ],
                ),
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: hours == 0 && minutes == 0
                        ? null
                        : () => Navigator.pop(
                            context,
                            Duration(hours: hours, minutes: minutes),
                          ),
                    child: const Text('Start timer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (duration != null) await settings.setSleepTimer(duration);
  }

  String _sleepTimerSubtitle() {
    if (settings.sleepTimerEndOfSong) return 'Stops after the current song';
    if (!settings.sleepTimerActive) return 'Off';
    final r = settings.sleepTimerRemaining;
    if (r == null) return 'Timer active';
    final h = r.inHours;
    final m = r.inMinutes.remainder(60);
    final s = r.inSeconds.remainder(60);
    if (h > 0)
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} remaining';
    return '$m:${s.toString().padLeft(2, '0')} remaining';
  }

  String _themeName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System default',
  };

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text(
          'Your settings will be restored to their defaults. Playlists, liked songs, and recently played songs will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await settings.reset();
    if (mounted) _showMessage('Settings restored');
  }

  void _showMessage(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) =>
          _AboutSheet(version: widget.version, onGithub: widget.onOpenGithub),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20.w,
            toolbarHeight: 64.h,
            title: Text(
              'Settings',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 22.h),
              child: _SettingsHero(color: color, version: widget.version)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(
                    begin: .04,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              children: [
                _SettingsTile(
                  icon: Hicons.colorPickerLightOutline,
                  title: 'Theme',
                  subtitle: _themeName(settings.themeMode),
                  onTap: _showThemePicker,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Player',
              icon: Hicons.musicnoteLightOutline,
              children: [
                _AnimatedSwitchTile(
                  icon: Hicons.up2LightOutline,
                  title: 'Mini player',
                  subtitle: 'Show the current song above the navigation bar',
                  value: settings.miniPlayer,
                  onChanged: settings.setMiniPlayer,
                ),
                _SettingsTile(
                  icon: Icons.timer_outlined,
                  title: 'Sleep timer',
                  subtitle: _sleepTimerSubtitle(),
                  onTap: _showSleepTimer,
                ),
                _AnimatedSwitchTile(
                  icon: Icons.play_arrow_rounded,
                  title: 'Autoplay',
                  subtitle: 'Continue with the next available song',
                  value: settings.autoplay,
                  onChanged: settings.setAutoplay,
                ),
          /*      _AnimatedSwitchTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Crossfade',
                  subtitle: 'Blend the end of one song into the next',
                  value: settings.crossfade,
                  onChanged: settings.setCrossfade,
                ),
                _AnimatedSwitchTile(
                  icon: Icons.high_quality_outlined,
                  title: 'High quality',
                  subtitle: 'Prefer the best available streaming quality',
                  value: settings.highQuality,
                  onChanged: settings.setHighQuality,
                ),
                _AnimatedSwitchTile(
                  icon: Icons.equalizer_rounded,
                  title: 'Normalize volume',
                  subtitle: 'Reduce sudden volume differences between songs',
                  value: settings.normalize,
                  onChanged: settings.setNormalize,
                ),*/

                _SettingsTile(
                  icon: Hicons.filter4LightOutline,
                  title: 'Equalizer',
                  subtitle: 'Adjust bass, vocals and other frequencies',
                  onTap: _openEqualizer,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Search',
              icon: Hicons.search1LightOutline,
              children: [
                _AnimatedSwitchTile(
                  icon: Hicons.rotateLeftLightOutline,
                  title: 'Search history',
                  subtitle: 'Save recent searches for quick access',
                  value: settings.saveSearches,
                  onChanged: settings.setSaveSearches,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Library',
              icon: Hicons.folder2LightOutline,
              children: [
                _SettingsTile(
                  icon: Hicons.rotateLeftLightOutline,
                  title: 'Recently played',
                  subtitle: '${settings.recentLimit} songs',
                  onTap: _showRecentLimit,
                ),
              ],
            ),
          ),
          /*      SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Data & storage',
              icon: Icons.storage_outlined,
              children: [
                _AnimatedSwitchTile(
                  icon: Icons.wifi_rounded,
                  title: 'Wi-Fi only',
                  subtitle: 'Prefer Wi-Fi for data-heavy operations',
                  value: settings.wifiOnly,
                  onChanged: settings.setWifiOnly,
                ),
                _SettingsTile(
                  icon: Icons.download_rounded,
                  title: 'Download quality',
                  subtitle: settings.downloadQuality,
                  onTap: _showDownloadQuality,
                ),
              ],
            ),
          ),*/
          /*   SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Data & storage',
              icon: Icons.storage_outlined,
              children: [
                _AnimatedSwitchTile(
                  icon: Icons.wifi_rounded,
                  title: 'Wi-Fi only',
                  subtitle: 'Prefer Wi-Fi for data-heavy operations',
                  value: settings.wifiOnly,
                  onChanged: settings.setWifiOnly,
                ),
              ],
            ),
          ),
    SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Display',
              icon: Hicons.imageLightOutline,
              children: [
                _AnimatedSwitchTile(
                  icon: Hicons.imageLightOutline,
                  title: 'Animated artwork',
                  subtitle: 'Allow animated artwork where available',
                  value: settings.animatedArtwork,
                  onChanged: settings.setAnimatedArtwork,
                ),
              ],
            ),
          ),*/
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'About',
              icon: Hicons.informationSquareLightOutline,
              children: [
                _SettingsTile(
                  icon: Hicons.dangerTriangleLightOutline,
                  title: 'About Chameleon',
                  subtitle: 'Version ${widget.version}',
                  onTap: _showAbout,
                ),
                _SettingsTile(
                  icon: Hicons.linkLightOutline,
                  title: 'GitHub',
                  subtitle: 'View the Chameleon project',
                  onTap: widget.onOpenGithub,
                  trailing: widget.onOpenGithub == null
                      ? const _UnavailableBadge()
                      : null,
                ),
                _SettingsTile(
                  icon: Hicons.documentAlignCenter2LightOutline,
                  title: 'Open-source licenses',
                  subtitle: 'Libraries used by Chameleon',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Chameleon',
                    applicationVersion: widget.version,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 10.h),
              child: _ResetTile(color: color, onTap: _resetSettings),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 120.h),
              child: Column(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Hicons.musicnoteLightOutline,
                      size: 23.sp,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Made for music.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Chameleon • Music player',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: .55,
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

class _SettingsHero extends StatelessWidget {
  final Color color;
  final String version;

  const _SettingsHero({required this.color, required this.version});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withValues(alpha: .78)],
      ),
      borderRadius: BorderRadius.circular(28.r),
    ),
    child: Row(
      children: [
        Container(
          width: 58.w,
          height: 58.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Hicons.musicnoteLightOutline,
            color: Colors.white,
            size: 28,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chameleon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Customize your listening experience.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Version $version',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .55),
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 8.h),
            child: Row(
              children: [
                Icon(icon, size: 16.sp, color: color),
                SizedBox(width: 7.w),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.05,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const _SoftDivider(),
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

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 68.w, right: 14.w),
    child: Container(
      height: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .045),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              _SettingsIcon(icon: icon),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        height: 1.25,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: trailing!,
                ),
              if (onTap != null)
                Icon(
                  Hicons.right2LightOutline,
                  size: 20.sp,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: .42,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSwitchTile extends StatefulWidget {
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
  State<_AnimatedSwitchTile> createState() => _AnimatedSwitchTileState();
}

class _AnimatedSwitchTileState extends State<_AnimatedSwitchTile> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void toggle() => widget.onChanged(!widget.value);
    return GestureDetector(
      onTap: toggle,
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? .985 : 1,
        duration: const Duration(milliseconds: 110),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            children: [
              _SettingsIcon(icon: widget.icon, active: widget.value),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        height: 1.25,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              LiquidGlassToggle(
                value: widget.value,
                activeColor: theme.colorScheme.primary,
                onChanged: (_) => toggle(),
                style: LiquidGlassStyle(
                  shape: LiquidGlassShape.squircle(
                    cornerRadius: 20,
                    borderType: OpticalBorder(
                      borderSaturation: 1.2,
                      ambientIntensity: 1,
                    ),
                  ),
                  refraction: const LiquidGlassRefraction(
                    distortion: .10,
                    distortionWidth: 20,
                    magnification: 1.04,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _SettingsIcon({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: .11)
            : theme.colorScheme.onSurface.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(
        icon,
        size: 20.sp,
        color: active ? color : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(99.r),
    ),
    child: Text(
      'SET UP',
      style: TextStyle(
        fontSize: 8.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _ChoiceItem<T> {
  final T value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ChoiceItem(this.value, this.title, this.subtitle, this.icon);
}

class _ChoiceSheet<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
      child: _GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 15.h),
            for (final item in items)
              _ChoiceRow(
                item: item,
                selected: item.value == selected,
                color: color,
                onTap: () => Navigator.pop(context, item.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? color.withValues(alpha: .08) : Colors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: .055),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 21.sp,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Hicons.tickLightOutline
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: .18),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  final SettingsService settings;
  final VoidCallback onCustom;

  const _SleepTimerSheet({required this.settings, required this.onCustom});

  String _subtitle() {
    if (settings.sleepTimerEndOfSong) return 'Stops after the current song';
    if (!settings.sleepTimerActive) return 'Off';
    final r = settings.sleepTimerRemaining;
    if (r == null) return 'Timer active';
    final h = r.inHours;
    final m = r.inMinutes.remainder(60);
    final s = r.inSeconds.remainder(60);
    if (h > 0)
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} remaining';
    return '$m:${s.toString().padLeft(2, '0')} remaining';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
      child: _GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            SizedBox(height: 12.h),
            Icon(Icons.nightlight_round, size: 28.sp, color: color),
            SizedBox(height: 7.h),
            Text(
              'Sleep Timer',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4.h),
            Text(
              _subtitle(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 15.h),
            _TimerOption(
              title: 'Off',
              subtitle: 'Keep playing normally',
              selected: !settings.sleepTimerActive,
              onTap: () async {
                await settings.clearSleepTimer();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _TimerOption(
              title: '15 minutes',
              subtitle: 'Stop playback in 15 minutes',
              selected:
                  settings.sleepTimerDuration == const Duration(minutes: 15),
              onTap: () async {
                await settings.setSleepTimer(const Duration(minutes: 15));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _TimerOption(
              title: '30 minutes',
              subtitle: 'Stop playback in 30 minutes',
              selected:
                  settings.sleepTimerDuration == const Duration(minutes: 30),
              onTap: () async {
                await settings.setSleepTimer(const Duration(minutes: 30));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _TimerOption(
              title: '45 minutes',
              subtitle: 'Stop playback in 45 minutes',
              selected:
                  settings.sleepTimerDuration == const Duration(minutes: 45),
              onTap: () async {
                await settings.setSleepTimer(const Duration(minutes: 45));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _TimerOption(
              title: '60 minutes',
              subtitle: 'Stop playback in one hour',
              selected: settings.sleepTimerDuration == const Duration(hours: 1),
              onTap: () async {
                await settings.setSleepTimer(const Duration(hours: 1));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _TimerOption(
              title: 'End of song',
              subtitle: 'Stop after the current song',
              selected: settings.sleepTimerEndOfSong,
              onTap: () async {
                await settings.setSleepTimerEndOfSong();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _TimerOption(
              title: 'Custom time',
              subtitle: 'Choose any duration manually',
              selected: false,
              onTap: onCustom,
            ),
            if (settings.sleepTimerActive)
              TextButton(
                onPressed: () async {
                  await settings.clearSleepTimer();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Cancel timer'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimerOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TimerOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Material(
      color: selected ? color.withValues(alpha: .08) : Colors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: .055),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_outlined,
                  size: 21.sp,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Hicons.tickLightOutline
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: .18),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 104.w,
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value <= 0 ? null : () => onChanged(value - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: value >= max ? null : () => onChanged(value + 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GlassSheet extends StatelessWidget {
  final Widget child;

  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 14.h),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(30.r),
    ),
    child: child,
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Container(
    width: 38.w,
    height: 4.h,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99.r),
    ),
  );
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
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        10.w,
        0,
        10.w,
        10.h,
      ),
      child: _GlassSheet(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .86,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),

                SizedBox(height: 20.h),

                Container(
                  width: 76.w,
                  height: 76.w,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(
                      alpha: .11,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Hicons.musicnoteLightOutline,
                    color: colors.primary,
                    size: 38.sp,
                  ),
                ),

                SizedBox(height: 14.h),

                Text(
                  'Chameleon',
                  style: TextStyle(
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5.h),

                Text(
                  'Music player',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  'Version $version',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.onSurfaceVariant.withValues(
                      alpha: .65,
                    ),
                  ),
                ),

                SizedBox(height: 22.h),

                // Current features

                const _AboutSectionTitle(
                  title: 'Current features',
                ),

                SizedBox(height: 10.h),

                const _AboutInfoRow(
                  icon: Icons.play_arrow_rounded,
                  title: 'Real music playback',
                  subtitle:
                  'Smooth music playback with queue and player controls.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.queue_music_rounded,
                  title: 'Smart queue',
                  subtitle:
                  'Queue songs, navigate next and previous, and manage playback order.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.search_rounded,
                  title: 'YouTube music discovery',
                  subtitle:
                  'Search and discover music with artwork and playback support.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.favorite_border_rounded,
                  title: 'Favorites & playlists',
                  subtitle:
                  'Save favorite songs and organize music into playlists.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.history_rounded,
                  title: 'Recently played',
                  subtitle:
                  'Keep track of recently played songs with a configurable history limit.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.timer_outlined,
                  title: 'Sleep timer',
                  subtitle:
                  'Stop playback automatically with a timer or at the end of a song.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.equalizer_rounded,
                  title: 'Built-in equalizer',
                  subtitle:
                  'Fine-tune bass, vocals, treble and individual frequencies.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.music_note_rounded,
                  title: 'Queue playback',
                  subtitle:
                  'Manage consecutive songs and continue through the playback queue.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Autoplay',
                  subtitle:
                  'Automatically continue to the next queued song when enabled.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.picture_in_picture_alt_outlined,
                  title: 'Global mini player',
                  subtitle:
                  'Control your current song from anywhere in the app.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Search history',
                  subtitle:
                  'Save, revisit and clear previous searches with an on/off setting.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.image_outlined,
                  title: 'Animated artwork',
                  subtitle:
                  'Optional artwork animation throughout the player experience.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.water_drop_outlined,
                  title: 'Liquid Glass interface',
                  subtitle:
                  'A refined interface with smooth animations and glass controls.',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.tune_rounded,
                  title: 'Playback settings',
                  subtitle:
                  'Control autoplay, gapless playback, mini player and other player preferences.',
                ),

                // In development

                SizedBox(height: 22.h),

                const _AboutSectionTitle(
                  title: 'In development',
                ),

                SizedBox(height: 10.h),

                const _AboutInfoRow(
                  icon: Icons.swap_horiz_rounded,
                  title: 'True crossfade',
                  subtitle:
                  'Overlapping transitions between consecutive songs.',
                  status: 'Working on it',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Audio normalization',
                  subtitle:
                  'More consistent perceived volume between different songs.',
                  status: 'Working on it',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.high_quality_rounded,
                  title: 'High-quality streaming',
                  subtitle:
                  'Use the highest available audio stream when enabled.',
                  status: 'Working on it',
                ),

                SizedBox(height: 8.h),

                const _AboutInfoRow(
                  icon: Icons.wifi_rounded,
                  title: 'Wi-Fi only',
                  subtitle:
                  'Restrict network and download operations to Wi-Fi.',
                  status: 'Working on it',
                ),

                if (onGithub != null) ...[
                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onGithub!();
                      },
                      icon: const Icon(
                        Icons.link_rounded,
                      ),
                      label: const Text(
                        'View on GitHub',
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 12.h),

                Text(
                  'Made for music lovers.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: colors.onSurfaceVariant.withValues(
                      alpha: .6,
                    ),
                  ),
                ),

                SizedBox(height: 6.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSectionTitle extends StatelessWidget {
  final String title;

  const _AboutSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;

  const _AboutInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(icon, size: 20.sp, color: theme.colorScheme.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    height: 1.25,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (status != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    status!,
                    style: TextStyle(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .35,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetTile extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ResetTile({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Hicons.refresh1LightOutline, color: color),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset settings',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Restore settings to their defaults',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Hicons.right2LightOutline,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: .42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
