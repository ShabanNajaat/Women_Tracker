import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fertility_intent.dart';
import '../services/cycle_service.dart';

/// Calendar hero cards: fertility-focused (TTC / avoid) or period-focused (track).
class FertilityPredictionCards extends StatelessWidget {
  const FertilityPredictionCards({
    super.key,
    required this.cycle,
    required this.scheme,
  });

  final CycleService cycle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (!cycle.hasCycleAnchor) {
      return Text(
        'Log when your period starts to see your next estimated date here.',
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    final showFertilityFirst = cycle.emphasizesFertility && cycle.approximateFertileWindow != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFertilityFirst) ...[
          _FertilityFocusCard(cycle: cycle, scheme: scheme),
          const SizedBox(height: 12),
          _PeriodEstimateCard(cycle: cycle, scheme: scheme, compact: true),
        ] else
          _PeriodEstimateCard(cycle: cycle, scheme: scheme, compact: false),
      ],
    );
  }
}

class _FertilityFocusCard extends StatelessWidget {
  const _FertilityFocusCard({required this.cycle, required this.scheme});

  final CycleService cycle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final intent = cycle.fertilityIntent;
    final ov = cycle.estimatedOvulationDate;
    final range = cycle.fertilityWindowRangeLabel;
    final inWindow = cycle.isInFertileWindowToday;

    final title = switch (intent) {
      FertilityIntent.ttc => 'Fertility focus (TTC)',
      FertilityIntent.avoidPregnancy => 'Higher-fertility awareness',
      FertilityIntent.track => 'Fertile window',
    };

    final icon = switch (intent) {
      FertilityIntent.ttc => Icons.favorite_rounded,
      FertilityIntent.avoidPregnancy => Icons.shield_outlined,
      FertilityIntent.track => Icons.spa_outlined,
    };

    String headline;
    if (inWindow) {
      headline = intent == FertilityIntent.ttc
          ? 'You may be in your fertile window now'
          : 'Estimated higher-fertility days now';
    } else if (ov != null && cycle.daysUntilOvulation != null) {
      final d = cycle.daysUntilOvulation!;
      headline = d == 0
          ? 'Estimated ovulation today'
          : d > 0
              ? 'Estimated ovulation in $d days'
              : 'Ovulation estimate passed this cycle';
    } else {
      headline = range != null ? 'Estimated window: $range' : 'Set your cycle anchor for estimates';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.tertiary.withValues(alpha: 0.5),
            scheme.tertiary.withValues(alpha: 0.22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: scheme.tertiary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.onTertiary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onTertiary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: TextStyle(
              color: scheme.onTertiary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          if (ov != null) ...[
            const SizedBox(height: 6),
            Text(
              'Ovulation (estimate): ${DateFormat('EEE, MMM d').format(ov)}',
              style: TextStyle(
                color: scheme.onTertiary.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (range != null) ...[
            const SizedBox(height: 4),
            Text(
              'Fertile window (estimate): $range',
              style: TextStyle(
                color: scheme.onTertiary.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            intent.calendarDisclaimer,
            style: TextStyle(
              color: scheme.onTertiary.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodEstimateCard extends StatelessWidget {
  const _PeriodEstimateCard({
    required this.cycle,
    required this.scheme,
    required this.compact,
  });

  final CycleService cycle;
  final ColorScheme scheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final next = cycle.predictedNextPeriodStart;
    if (next == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20, vertical: compact ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: compact ? 0.35 : 0.45),
            scheme.primary.withValues(alpha: compact ? 0.15 : 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: scheme.onPrimary, size: compact ? 22 : 26),
              const SizedBox(width: 10),
              Text(
                compact ? 'Next period' : 'Next period (estimate)',
                style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 13 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat(compact ? 'MMM d, y' : 'EEEE, MMMM d, y').format(next),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              cycle.daysUntilNextPeriod == 0
                  ? 'Estimated start is today — take it easy if you can.'
                  : cycle.daysUntilNextPeriod == 1
                      ? 'About 1 day from now (estimate).'
                      : 'About ${cycle.daysUntilNextPeriod} days from now (estimate).',
              style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            if (cycle.personalizedPredictionCaption != null) ...[
              const SizedBox(height: 8),
              Text(
                cycle.personalizedPredictionCaption!,
                style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
