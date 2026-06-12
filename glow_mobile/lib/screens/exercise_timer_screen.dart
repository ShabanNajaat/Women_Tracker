import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/animated_glass_card.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';
import '../widgets/glowie_mascot.dart';

/// Countdown timer for short workouts (squats, planks, etc.) with sound + haptic on finish.
class ExerciseTimerScreen extends StatefulWidget {
  const ExerciseTimerScreen({super.key});

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  static const _presets = [15, 30, 45, 60, 90, 120];

  int _selectedSeconds = 30;
  int _remaining = 30;
  Timer? _timer;
  bool _running = false;
  bool _finished = false;
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _pickPreset(int seconds) {
    if (_running) return;
    setState(() {
      _selectedSeconds = seconds;
      _remaining = seconds;
      _finished = false;
    });
  }

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _finished = false;
      if (_remaining <= 0) _remaining = _selectedSeconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _pause() {
    _timer?.cancel();
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _finished = false;
      _remaining = _selectedSeconds;
    });
  }

  void _tick() {
    if (!mounted) return;
    if (_remaining <= 1) {
      _timer?.cancel();
      setState(() {
        _remaining = 0;
        _running = false;
        _finished = true;
      });
      _onComplete();
      return;
    }
    setState(() => _remaining -= 1);
  }

  Future<void> _onComplete() async {
    await _playAlarm();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded, size: 40),
        title: const Text("Time's up!"),
        content: const Text('Great work — take a breath and hydrate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            child: const Text('Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _playAlarm() async {
    HapticFeedback.heavyImpact();
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/timer_beep.wav'));
      // Stop looping after 3 seconds
      Future<void>.delayed(const Duration(seconds: 3), () {
        _player.stop();
      });
    } catch (e) {
      debugPrint('Audio play failed: $e');
      // Fallback: system beeps with haptic
      for (int i = 0; i < 3; i++) {
        await Future<void>.delayed(Duration(milliseconds: i * 350));
        HapticFeedback.heavyImpact();
        if (!kIsWeb) SystemSound.play(SystemSoundType.alert);
      }
    }
  }

  String _format(int total) {
    final m = total ~/ 60;
    final s = total % 60;
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
    return '$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _selectedSeconds > 0 ? 1 - (_remaining / _selectedSeconds) : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const GlowPageAppBar(title: Text('Workout timer')),
      body: AppBackdrop(
        child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  scheme.tertiary.withValues(alpha: 0.2),
                  scheme.primary.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Row(
              children: [
                const GlowieMascot(size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You got this! 💪',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick a time, move your body, and listen for the cute beep when you are done.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AnimatedGlassCard(
            index: 0,
            child: GlassCard(
              useBackdropBlur: false,
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: _finished ? 1 : progress.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: _finished ? scheme.tertiary : scheme.primary,
                          ),
                        ),
                        Text(
                          _format(_remaining),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_finished)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Finished!',
                        style: TextStyle(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _presets.map((sec) {
                      final selected = !_running && _selectedSeconds == sec && _remaining == sec;
                      return ChoiceChip(
                        label: Text(sec < 60 ? '${sec}s' : '${sec ~/ 60}m'),
                        selected: selected,
                        onSelected: _running ? null : (_) => _pickPreset(sec),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_running)
                        FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(_remaining == 0 || _finished ? 'Start' : 'Resume'),
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: _pause,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pause'),
                        ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
