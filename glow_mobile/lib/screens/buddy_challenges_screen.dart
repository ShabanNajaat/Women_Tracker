import 'package:flutter/material.dart';

import '../models/buddy_challenge_type.dart';
import '../services/buddy_challenge_service.dart';
import '../services/partner_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

/// Micro-challenges with friends — supportive, not competitive.
class BuddyChallengesScreen extends StatefulWidget {
  const BuddyChallengesScreen({super.key});

  @override
  State<BuddyChallengesScreen> createState() => _BuddyChallengesScreenState();
}

class _BuddyChallengesScreenState extends State<BuddyChallengesScreen> {
  @override
  void initState() {
    super.initState();
    BuddyChallengeService.instance.ensureLoaded();
    PartnerService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('Challenge buddies')),
      body: ValueListenableBuilder<int>(
        valueListenable: BuddyChallengeService.revision,
        builder: (context, _, __) {
          final svc = BuddyChallengeService.instance;
          final active = svc.activeChallenge;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Join a 7-day micro-challenge with a friend. No leaderboards — just gentle accountability '
                'for hydration, sleep, or yoga.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4),
              ),
              if (active != null) ...[
                const SizedBox(height: 20),
                GlassCard(
                  useBackdropBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(active.icon, color: scheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              active.title,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(active.encouragement, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 16),
                      Text(
                        '${svc.daysCompletedThisWeek} / 7 days',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: svc.weekProgress,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: svc.isDoneToday(active)
                                  ? null
                                  : () async {
                                      await svc.markTodayComplete();
                                      await svc.syncFromHealthLog();
                                      if (mounted) setState(() {});
                                    },
                              child: Text(svc.isDoneToday(active) ? 'Done today ✓' : 'Mark today complete'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final msg = await svc.cheerPartner();
                              if (mounted && msg != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            },
                            child: const Text('Cheer buddy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Pick a challenge',
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              for (final kind in BuddyChallengeKind.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    useBackdropBlur: false,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        child: Icon(kind.icon, color: scheme.primary),
                      ),
                      title: Text(kind.title, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      subtitle: Text(kind.subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      trailing: active == kind
                          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await svc.startChallenge(kind);
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
