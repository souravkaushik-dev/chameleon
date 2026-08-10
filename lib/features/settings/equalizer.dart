import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../data/services/audio_player_service.dart';

class EqualizerScreen extends StatefulWidget {
  final AudioPlayerService audioService;

  const EqualizerScreen({
    super.key,
    required this.audioService,
  });

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  AndroidEqualizerParameters? _parameters;

  List<double> _gains = [];

  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;

  String? _error;

  Timer? _gainDebounce;

  int _presetGeneration = 0;

  @override
  void initState() {
    super.initState();

    _loadEqualizer();
  }

  @override
  void dispose() {
    _gainDebounce?.cancel();
    super.dispose();
  }
  // LOAD
  Future<void> _loadEqualizer() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      AndroidEqualizerParameters? parameters;

      // The native effect can need a short amount of time after playback
      // starts before its parameters become available.
      for (int attempt = 0; attempt < 8; attempt++) {
        parameters =
        await widget.audioService.getEqualizerParameters();

        if (parameters != null &&
            parameters.bands.isNotEmpty) {
          break;
        }

        if (attempt < 7) {
          await Future<void>.delayed(
            const Duration(milliseconds: 150),
          );
        }
      }

      if (!mounted) {
        return;
      }

      if (parameters == null ||
          parameters.bands.isEmpty) {
        setState(() {
          _parameters = null;
          _gains = [];
          _enabled = false;
          _loading = false;
        });

        return;
      }

      final savedGains =
          widget.audioService.equalizerGains;

      final gains = List<double>.generate(
        parameters.bands.length,
            (index) {
          final saved =
          index < savedGains.length
              ? savedGains[index]
              : 0.0;

          return saved
              .clamp(
            parameters!.minDecibels,
            parameters.maxDecibels,
          )
              .toDouble();
        },
      );

      setState(() {
        _parameters = parameters;
        _gains = gains;
        _enabled =
            widget.audioService.equalizerEnabled;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _parameters = null;
        _gains = [];
        _enabled = false;
        _loading = false;
        _error = error.toString();
      });
    }
  }
  // ENABLE / DISABLE
  Future<void> _setEnabled(bool value) async {
    final parameters = _parameters;

    if (parameters == null || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.audioService
          .setEqualizerEnabled(value);

      if (!mounted) {
        return;
      }

      setState(() {
        _enabled = value;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to change equalizer.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
  // BAND
  void _onGainChanged(
      int index,
      double value,
      ) {
    final parameters = _parameters;

    if (parameters == null ||
        !_enabled ||
        index < 0 ||
        index >= _gains.length ||
        index >= parameters.bands.length) {
      return;
    }

    final safeValue = value
        .clamp(
      parameters.minDecibels,
      parameters.maxDecibels,
    )
        .toDouble();

    setState(() {
      _gains[index] = safeValue;
    });

    _gainDebounce?.cancel();

    _gainDebounce = Timer(
      const Duration(milliseconds: 45),
          () {
        _applyGain(
          index,
          safeValue,
        );
      },
    );
  }

  Future<void> _applyGain(
      int index,
      double value,
      ) async {
    try {
      await widget.audioService
          .setEqualizerBandGain(
        index,
        value,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update equalizer band.',
      );
    }
  }
  // RESET
  Future<void> _reset() async {
    final parameters = _parameters;

    if (parameters == null) {
      return;
    }

    try {
      await widget.audioService
          .resetEqualizer();

      if (!mounted) {
        return;
      }

      setState(() {
        _gains = List<double>.filled(
          parameters.bands.length,
          0.0,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to reset equalizer.',
      );
    }
  }
  // PRESETS
  Future<void> _applyPreset(
      EqualizerPreset preset,
      ) async {
    final parameters = _parameters;

    if (parameters == null ||
        !_enabled ||
        _saving) {
      return;
    }

    final generation = ++_presetGeneration;

    final values = _buildPresetValues(
      preset,
      parameters.bands.length,
    );

    final updated = List<double>.from(
      _gains,
    );

    for (
    int index = 0;
    index < values.length;
    index++
    ) {
      final value = values[index]
          .clamp(
        parameters.minDecibels,
        parameters.maxDecibels,
      )
          .toDouble();

      updated[index] = value;

      try {
        await widget.audioService
            .setEqualizerBandGain(
          index,
          value,
        );
      } catch (_) {
        // Continue applying remaining bands.
      }
    }

    if (!mounted ||
        generation != _presetGeneration) {
      return;
    }

    setState(() {
      _gains = updated;
    });
  }

  List<double> _buildPresetValues(
      EqualizerPreset preset,
      int bandCount,
      ) {
    if (bandCount <= 0) {
      return [];
    }

    switch (preset) {
      case EqualizerPreset.flat:
        return List<double>.filled(
          bandCount,
          0.0,
        );

      case EqualizerPreset.bass:
        return _interpolatePreset(
          const [
            7.0,
            6.0,
            4.0,
            2.0,
            1.0,
            0.0,
          ],
          bandCount,
        );

      case EqualizerPreset.treble:
        return _interpolatePreset(
          const [
            0.0,
            0.0,
            1.0,
            3.0,
            5.0,
            7.0,
          ],
          bandCount,
        );

      case EqualizerPreset.vocal:
        return _interpolatePreset(
          const [
            -2.0,
            0.0,
            4.0,
            5.0,
            3.0,
            -1.0,
          ],
          bandCount,
        );

      case EqualizerPreset.pop:
        return _interpolatePreset(
          const [
            3.0,
            2.0,
            -1.0,
            2.0,
            4.0,
            5.0,
          ],
          bandCount,
        );

      case EqualizerPreset.rock:
        return _interpolatePreset(
          const [
            5.0,
            3.0,
            -1.0,
            2.0,
            4.0,
            5.0,
          ],
          bandCount,
        );

      case EqualizerPreset.classical:
        return _interpolatePreset(
          const [
            4.0,
            2.0,
            -1.0,
            -1.0,
            2.0,
            4.0,
          ],
          bandCount,
        );

      case EqualizerPreset.dance:
        return _interpolatePreset(
          const [
            6.0,
            4.0,
            1.0,
            2.0,
            5.0,
            4.0,
          ],
          bandCount,
        );
    }
  }

  List<double> _interpolatePreset(
      List<double> source,
      int count,
      ) {
    if (count == 1) {
      return [source.first];
    }

    if (count == source.length) {
      return List<double>.from(source);
    }

    return List<double>.generate(
      count,
          (index) {
        final position =
            index *
                (source.length - 1) /
                (count - 1);

        final lower = position.floor();
        final upper = position.ceil();

        if (lower == upper) {
          return source[lower];
        }

        final fraction =
            position - lower;

        return source[lower] +
            (source[upper] -
                source[lower]) *
                fraction;
      },
    );
  }
  // FREQUENCY
  String _frequencyLabel(int index) {
    final parameters = _parameters;

    if (parameters == null ||
        index < 0 ||
        index >= parameters.bands.length) {
      return '--';
    }

    final frequency =
        parameters
            .bands[index]
            .centerFrequency;

    if (frequency >= 1000) {
      final value =
          frequency / 1000.0;

      return '${value.toStringAsFixed(
        value >= 10 ? 0 : 1,
      )} kHz';
    }

    return '${frequency.round()} Hz';
  }

  String _gainLabel(double value) {
    if (value > 0) {
      return '+${value.toStringAsFixed(1)}';
    }

    return value.toStringAsFixed(1);
  }
  // MESSAGE
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }
  // BUILD
  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.colorScheme.surface,

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,

        elevation: 0,

        centerTitle: false,

        title: const Text(
          'Equalizer',
          style: TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Reset equalizer',
            onPressed:
            _loading ||
                _parameters == null
                ? null
                : _reset,
            icon: const Icon(
              Icons.restart_alt_rounded,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: _buildBody(),
    );
  }
  // BODY
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_parameters == null ||
        _parameters!.bands.isEmpty ||
        _gains.isEmpty) {
      return _buildUnavailable();
    }

    return RefreshIndicator(
      onRefresh: _loadEqualizer,

      child:
      ScrollConfiguration(
        behavior:
        const MaterialScrollBehavior()
            .copyWith(
          overscroll: false,
        ),

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(
            parent:
            BouncingScrollPhysics(),
          ),

          padding:
          const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            40,
          ),

          children: [
            _buildHeader(),

            const SizedBox(height: 14),

            _buildBands(),

            const SizedBox(height: 14),

            _buildPresets(),

            const SizedBox(height: 18),

            _buildHint(),
          ],
        ),
      ),
    );
  }
  // HEADER
  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.equalizer_rounded,
              size: 28,
              color: colors.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Equalizer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration:
                  const Duration(milliseconds: 180),
                  child: Text(
                    _enabled
                        ? 'Sound enhancement is active'
                        : 'Sound enhancement is disabled',
                    key: ValueKey(_enabled),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          LiquidGlassToggle(
            value: _enabled,
            activeColor: colors.primary,
            onChanged: (bool value) {
              if (_saving) {
                return;
              }

              _setEnabled(value);
            },
            style: LiquidGlassStyle(
              shape: LiquidGlassShape.squircle(
                cornerRadius: 20,
                borderType: OpticalBorder(
                  borderSaturation: 1.2,
                  ambientIntensity: 1.0,
                ),
              ),
              refraction: const LiquidGlassRefraction(
                distortion: 0.10,
                distortionWidth: 20,
                magnification: 1.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // BANDS
  Widget _buildBands() {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final parameters =
    _parameters!;

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        18,
        12,
        16,
      ),

      decoration:
      BoxDecoration(
        color:
        colors.surfaceContainerLow,

        borderRadius:
        BorderRadius.circular(28),
      ),

      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 4,
            ),

            child: Row(
              children: [
                Text(
                  'Frequency Bands',
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const Spacer(),

                Text(
                  '${parameters.minDecibels.toStringAsFixed(0)} '
                      'to '
                      '${parameters.maxDecibels.toStringAsFixed(0)} dB',

                  style: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    color: colors
                        .onSurfaceVariant,

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Fixed height is intentional.
          // It gives every Expanded band a finite height.
          SizedBox(
            height: 310,

            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,

              children: [
                for (
                int index = 0;
                index <
                    parameters
                        .bands.length;
                index++
                )
                  Expanded(
                    child:
                    _EqualizerBand(
                      frequency:
                      _frequencyLabel(
                        index,
                      ),

                      gain:
                      _gains[index],

                      min:
                      parameters
                          .minDecibels,

                      max:
                      parameters
                          .maxDecibels,

                      enabled:
                      _enabled,

                      primary:
                      colors.primary,

                      onChanged:
                          (value) {
                        _onGainChanged(
                          index,
                          value,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [
              _ScaleLabel(
                '${parameters.minDecibels.toStringAsFixed(0)} dB',
              ),

              const _ScaleLabel(
                '0 dB',
              ),

              _ScaleLabel(
                '+${parameters.maxDecibels.toStringAsFixed(0)} dB',
              ),
            ],
          ),
        ],
      ),
    );
  }
  // PRESETS
  Widget _buildPresets() {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Container(
      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(
        color:
        colors.surfaceContainerLow,

        borderRadius:
        BorderRadius.circular(26),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            'Presets',
            style: theme
                .textTheme
                .titleSmall
                ?.copyWith(
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Quickly tune your sound profile.',
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color:
              colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: [
              _PresetButton(
                label: 'Flat',
                icon:
                Icons.horizontal_rule_rounded,
                enabled: _parameters != null,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.flat,
                ),
              ),

              _PresetButton(
                label: 'Bass',
                icon:
                Icons.graphic_eq_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.bass,
                ),
              ),

              _PresetButton(
                label: 'Treble',
                icon:
                Icons.multiline_chart_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.treble,
                ),
              ),

              _PresetButton(
                label: 'Vocal',
                icon:
                Icons.record_voice_over_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.vocal,
                ),
              ),

              _PresetButton(
                label: 'Pop',
                icon:
                Icons.music_note_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.pop,
                ),
              ),

              _PresetButton(
                label: 'Rock',
                icon:
                Icons.library_music_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.rock,
                ),
              ),

              _PresetButton(
                label: 'Classical',
                icon:
                Icons.piano_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.classical,
                ),
              ),

              _PresetButton(
                label: 'Dance',
                icon:
                Icons.nightlife_rounded,
                enabled: _enabled,
                onPressed:
                    () => _applyPreset(
                  EqualizerPreset.dance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // HINT
  Widget _buildHint() {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color:
          colors.onSurfaceVariant,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            'Changes affect the current audio playback on this device.',
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color:
              colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
  // ERROR
  Widget _buildError() {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return _CenteredState(
      icon:
      Icons.tune_rounded,

      title:
      'Couldn’t load equalizer',

      message:
      'The audio effect could not be initialized. Try again.',

      action:
      FilledButton.icon(
        onPressed:
        _loadEqualizer,

        icon:
        const Icon(
          Icons.refresh_rounded,
        ),

        label:
        const Text(
          'Try again',
        ),
      ),

      color:
      colors.onSurfaceVariant,
    );
  }
  // UNAVAILABLE
  Widget _buildUnavailable() {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return _CenteredState(
      icon:
      Icons.equalizer_rounded,

      title:
      'Equalizer unavailable',

      message:
      'The native equalizer is not available yet. Start playback and try again.',

      action:
      FilledButton.icon(
        onPressed:
        _loadEqualizer,

        icon:
        const Icon(
          Icons.refresh_rounded,
        ),

        label:
        const Text(
          'Check again',
        ),
      ),

      color:
      colors.onSurfaceVariant,
    );
  }
}
// EQUALIZER BAND
class _EqualizerBand extends StatelessWidget {
  final String frequency;
  final double gain;
  final double min;
  final double max;
  final bool enabled;
  final Color primary;
  final ValueChanged<double> onChanged;

  const _EqualizerBand({
    required this.frequency,
    required this.gain,
    required this.min,
    required this.max,
    required this.enabled,
    required this.primary,
    required this.onChanged,
  });

  String _formatGain(
      double value,
      ) {
    if (value > 0) {
      return '+${value.toStringAsFixed(1)}';
    }

    return value.toStringAsFixed(1);
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final safeValue =
    gain.clamp(
      min,
      max,
    ).toDouble();

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 2.5,
      ),

      child: Column(
        children: [
          SizedBox(
            height: 22,

            child: FittedBox(
              fit:
              BoxFit.scaleDown,

              child: Text(
                _formatGain(
                  safeValue,
                ),

                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w800,

                  color: enabled
                      ? primary
                      : colors
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child:
            RotatedBox(
              quarterTurns: 3,

              child:
              SliderTheme(
                data:
                SliderTheme.of(
                  context,
                ).copyWith(
                  trackHeight: 4,

                  activeTrackColor:
                  enabled
                      ? primary
                      : colors
                      .surfaceContainerHighest,

                  inactiveTrackColor:
                  colors
                      .surfaceContainerHighest,

                  thumbColor:
                  enabled
                      ? primary
                      : colors.outline,

                  overlayColor:
                  primary.withValues(
                    alpha: 0.10,
                  ),

                  thumbShape:
                  const RoundSliderThumbShape(
                    enabledThumbRadius:
                    8,

                    disabledThumbRadius:
                    7,
                  ),

                  overlayShape:
                  const RoundSliderOverlayShape(
                    overlayRadius:
                    18,
                  ),
                ),

                child: Slider(
                  value:
                  safeValue,

                  min: min,

                  max: max,

                  divisions: 48,

                  onChanged:
                  enabled
                      ? onChanged
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          SizedBox(
            height: 24,

            child: FittedBox(
              fit:
              BoxFit.scaleDown,

              child: Text(
                frequency,

                maxLines: 1,

                textAlign:
                TextAlign.center,

                style: TextStyle(
                  fontSize: 9,

                  fontWeight:
                  FontWeight.w700,

                  color:
                  colors
                      .onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// PRESET BUTTON
class _PresetButton
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Material(
      color: enabled
          ? colors
          .surfaceContainerHighest
          : colors
          .surfaceContainerLow,

      borderRadius:
      BorderRadius.circular(16),

      child: InkWell(
        onTap:
        enabled
            ? onPressed
            : null,

        borderRadius:
        BorderRadius.circular(16),

        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),

          child: Row(
            mainAxisSize:
            MainAxisSize.min,

            children: [
              Icon(
                icon,
                size: 18,

                color: enabled
                    ? colors.primary
                    : colors
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.35,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                label,

                style: TextStyle(
                  fontSize: 12,

                  fontWeight:
                  FontWeight.w700,

                  color: enabled
                      ? colors.onSurface
                      : colors
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.4,
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
// SCALE LABEL
class _ScaleLabel
    extends StatelessWidget {
  final String text;

  const _ScaleLabel(
      this.text,
      );

  @override
  Widget build(
      BuildContext context,
      ) {
    return Text(
      text,

      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,

        fontWeight:
        FontWeight.w600,
      ),
    );
  }
}
// CENTERED STATE
class _CenteredState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget action;
  final Color color;

  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(32),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Icon(
              icon,
              size: 58,
              color: color.withValues(
                alpha: 0.65,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              title,

              textAlign:
              TextAlign.center,

              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              message,

              textAlign:
              TextAlign.center,

              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: color,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            action,
          ],
        ),
      ),
    );
  }
}
// PRESET TYPES
enum EqualizerPreset {
  flat,
  bass,
  treble,
  vocal,
  pop,
  rock,
  classical,
  dance,
}