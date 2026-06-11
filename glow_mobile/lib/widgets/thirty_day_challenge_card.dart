import 'package:flutter/material.dart';

import '../models/partner_streak.dart';
import '../services/api_service.dart';
import '../services/challenge_service.dart';
import '../services/partner_service.dart';
import '../services/wellness_score_service.dart';
import 'glass_card.dart';
import 'partner_streak_sheet.dart';

class ThirtyDayChallengeCard extends StatefulWidget {
  const ThirtyDayChallengeCard({super.key});

  @override
  State<ThirtyDayChallengeCard> createState() => _ThirtyDayChallengeCardState();
}

class _ThirtyDayChallengeCardState extends State<ThirtyDayChallengeCard> {
  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    if (!ApiService().isAuthenticated) return;
    await PartnerService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: ChallengeService.revision,
      builder: (context, _, __) {
        return ValueListenableBuilder<int>(
          valueListenable: PartnerService.revision,
          builder: (context, _, __) {
            final ch = ChallengeService.instance;
            final day = ch.currentDayNumber;
            final done = ch.daysCompletedInChallenge;
            final progress = ch.progress01;
            final localStreak = ch.currentDailyStreak;
            final checkedToday = ch.checkedInToday;
            final partner = PartnerService.instance.snapshot;

            return GlassCard(
              useBackdropBlur: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '30-day wellness challenge',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check in daily (mood, journal, or quiz) to grow your streak and Glow score. '
                    'Share that streak with a partner so you both stay consistent.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Day $day',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'of ${ChallengeService.totalDays}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded, color: scheme.primary, size: 22),
                              const SizedBox(width: 4),
                              Text(
                                '$localStreak',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'day streak',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$done days in this challenge'
                    '${checkedToday ? ' · checked in today' : ' · check in today to keep your streak'}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PartnerStreakPanel(
                    scheme: scheme,
                    localStreak: localStreak,
                    partner: partner,
                    checkedToday: checkedToday,
                    onLinkPartner: () => showPartnerStreakSheet(context),
                    onRefresh: _loadPartner,
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: WellnessScoreService.pointsListenable,
                    builder: (context, pts, _) {
                      return Text(
                        'Total Glow points: $pts',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PartnerStreakPanel extends StatelessWidget {
  const _PartnerStreakPanel({
    required this.scheme,
    required this.localStreak,
    required this.partner,
    required this.checkedToday,
    required this.onLinkPartner,
    required this.onRefresh,
  });

  final ColorScheme scheme;
  final int localStreak;
  final PartnerStreakSnapshot? partner;
  final bool checkedToday;
  final VoidCallback onLinkPartner;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final snap = partner;
    final linked = snap?.linked == true;
    final partnerName = snap?.partnerName ?? 'Partner';
    final myStreak = snap?.myStreak ?? localStreak;
    final partnerStreak = snap?.partnerStreak ?? 0;
    final partnerChecked = snap?.partnerCheckedInToday == true;
    final bothDone = snap?.bothCheckedInToday == true;
    final nudgeFrom = snap?.pendingNudgeFrom;
    final nudgeMsg = snap?.pendingNudgeMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_outline_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Partner streak',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (nudgeFrom != null && nudgeMsg != null) ...[
            Material(
              color: scheme.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$nudgeFrom: $nudgeMsg',
                        style: TextStyle(color: scheme.onSurface, fontSize: 12, height: 1.35),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await PartnerService.instance.markNudgeAsRead();
                        await onRefresh();
                      },
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!ApiService().isAuthenticated)
            Text(
              'Sign in to sync daily streaks with a partner.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            )
          else if (!linked)
            Text(
              'Start a streak with a friend to see each other\'s progress and stay motivated together.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.35),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _StreakChip(label: 'You', streak: myStreak, active: checkedToday, scheme: scheme)),
                const SizedBox(width: 10),
                Expanded(
                  child: _StreakChip(
                    label: partnerName,
                    streak: partnerStreak,
                    active: partnerChecked,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bothDone
                  ? 'You both checked in today — streak team! 🎉'
                  : partnerChecked
                      ? '$partnerName checked in today. Your turn!'
                      : 'Waiting for $partnerName today — send a gentle nudge?',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!linked && ApiService().isAuthenticated)
                OutlinedButton.icon(
                  onPressed: onLinkPartner,
                  icon: Icon(Icons.local_fire_department_rounded, color: scheme.primary, size: 18),
                  label: Text('Start streak', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                ),
              if (linked && ApiService().isAuthenticated)
                FilledButton.icon(
                  onPressed: checkedToday
                      ? () async {
                          await PartnerService.instance.syncTodayCheckIn();
                          await onRefresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$partnerName can see your $myStreak-day streak — you showed up today!',
                                ),
                              ),
                            );
                          }
                        }
                      : () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check in with mood, journal, or quiz first — then share your streak.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.local_fire_department_rounded, size: 18),
                  label: Text(
                    checkedToday ? 'Share streak with partner' : 'Check in to share',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (linked && !partnerChecked && checkedToday)
                OutlinedButton(
                  onPressed: () async {
                    final msg = await PartnerService.instance.nudgePartner();
                    if (context.mounted && msg != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                  child: const Text('Nudge partner'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
    required this.label,
    required this.streak,
    required this.active,
    required this.scheme,
  });

  final String label;
  final int streak;
  final bool active;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? scheme.primary.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
