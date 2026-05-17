import 'dart:math';

import 'package:flutter/material.dart';
import '../services/challenge_service.dart';
import '../services/wellness_score_service.dart';
import 'glass_card.dart';

class _QuizItem {
  const _QuizItem(this.question, this.options, this.correctIndex);
  final String question;
  final List<String> options;
  final int correctIndex;
}

/// Quick multiple-choice pool; a new item when the card is remounted (e.g. app resume / epoch key).
class MiniWellnessQuizCard extends StatefulWidget {
  const MiniWellnessQuizCard({super.key});

  static const List<_QuizItem> _bank = [
    _QuizItem(
      'Which habit supports iron balance during your period?',
      [
        'Pair iron-rich foods with vitamin C',
        'Skip meals to reduce bloating',
        'Only drink coffee for energy',
      ],
      0,
    ),
    _QuizItem(
      'What often helps menstrual cramps for many people (in addition to medical care when needed)?',
      [
        'Gentle heat on the lower belly',
        'Ignoring all fluid intake',
        'Very intense core workouts only',
      ],
      0,
    ),
    _QuizItem(
      'For steadier energy across the day, what is a helpful baseline?',
      [
        'Regular meals with protein and fiber when you can',
        'Replacing meals with only sugary drinks',
        'Avoiding water to reduce bathroom trips',
      ],
      0,
    ),
    _QuizItem(
      'If sleep has been rough, what is a realistic first step?',
      [
        'A calmer wind-down and a consistent wake time when possible',
        'Blue-light scrolling in bed until late',
        'Caffeine all evening to catch up',
      ],
      0,
    ),
    _QuizItem(
      'When stress feels high, what is a small nervous-system friendly tool?',
      [
        'A slow exhale longer than your inhale, a few times',
        'Holding your breath as long as possible',
        'Skipping meals to stay productive',
      ],
      0,
    ),
    _QuizItem(
      'Why might tracking your cycle be useful (not a diagnosis)?',
      [
        'It can help you notice patterns to discuss with a clinician',
        'It replaces seeing a doctor',
        'It guarantees predictions for everyone',
      ],
      0,
    ),
  ];

  @override
  State<MiniWellnessQuizCard> createState() => _MiniWellnessQuizCardState();
}

class _MiniWellnessQuizCardState extends State<MiniWellnessQuizCard> {
  int? _selected;
  bool _submitted = false;
  String _resultMessage = '';

  late final _QuizItem _item;

  @override
  void initState() {
    super.initState();
    _item = MiniWellnessQuizCard._bank[Random().nextInt(MiniWellnessQuizCard._bank.length)];
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    if (_selected == _item.correctIndex) {
      final awarded = await WellnessScoreService.instance.tryAwardQuizBonus();
      await ChallengeService.instance.recordTodayProgressIfNeeded();
      _resultMessage = awarded
          ? '+25 Glow points — nice work!'
          : 'Correct! You already earned quiz points today. Come back tomorrow.';
    } else {
      _resultMessage = 'Good try — tap a new question when you revisit Home after a break.';
    }
    if (mounted) {
      setState(() => _submitted = true);
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
            'Daily wellness quiz',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Glow score grows from check-ins, journal saves, and quizzes — not from empty numbers.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _item.question,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_item.options.length, (i) {
            final chosen = _selected == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: chosen
                    ? scheme.primary.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _submitted
                      ? null
                      : () => setState(() {
                            _selected = i;
                          }),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          chosen ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: scheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _item.options[i],
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (!_submitted) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _selected == null ? null : _submit,
              child: const Text('Submit answer'),
            ),
          ],
          if (_submitted && _resultMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _resultMessage,
              style: TextStyle(
                color: _selected == _item.correctIndex ? scheme.secondary : scheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
