import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/challenge_service.dart';
import '../services/health_log_service.dart';
import '../services/wellness_score_service.dart';
import 'glass_card.dart';

/// Lightweight mood tiles for dashboard check-ins (full journaling stays on Journal).
class MoodBoard extends StatefulWidget {
  const MoodBoard({super.key});

  @override
  State<MoodBoard> createState() => _MoodBoardState();
}

class _MoodBoardState extends State<MoodBoard> {
  static const List<String> _labels = [
    'Calm',
    'Energized',
    'Low',
    'Irritable',
    'Hopeful',
    'Drained',
  ];

  String? _selected;
  bool _saving = false;

  Future<void> _persistSelection(String label) async {
    setState(() {
      _selected = label;
      _saving = true;
    });
    await HealthLogService.instance.mergeMoodFromLabel(label);
    final api = ApiService();
    if (!api.isAuthenticated) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save mood check-ins to your account.')),
        );
      }
      return;
    }
    try {
      final res = await api.post('/tracking/logs', body: {
        'moods': [label],
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      if (!mounted) return;
      if (res.statusCode == 401) {
        await api.clearAuth();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Sign in again to save moods.')),
        );
      } else if (res.statusCode == 200) {
        await WellnessScoreService.instance.maybeAwardDailyCheckIn();
        await ChallengeService.instance.recordTodayProgressIfNeeded();
      } else if (res.statusCode != 200) {
        final msg = () {
          try {
            final m = jsonDecode(res.body);
            if (m is Map && m['msg'] != null) return m['msg'].toString();
          } catch (_) {}
          return null;
        }();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? 'Could not save mood (${res.statusCode})')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline or server unreachable — mood not saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      useBackdropBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood board',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap how you feel right now — no pressure to log a full journal entry.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              minHeight: 2,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _labels.map((label) {
              final selected = _selected == label;
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
                  ),
                ),
                selected: selected,
                onSelected: _saving ? null : (_) => _persistSelection(label),
                selectedColor: scheme.secondaryContainer,
                backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                side: BorderSide(
                  color: selected ? scheme.primary : scheme.outline.withValues(alpha: 0.35),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
