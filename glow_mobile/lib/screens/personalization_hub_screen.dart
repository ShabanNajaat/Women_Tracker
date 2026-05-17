import 'package:flutter/material.dart';

import '../services/adaptive_tips_service.dart';
import '../services/cycle_service.dart';
import '../services/health_log_service.dart';
import '../services/personalized_cycle_insights_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';
import 'ai_forecast_screen.dart';
import 'buddy_challenges_screen.dart';
import 'correlation_insights_screen.dart';
import 'expert_ama_screen.dart';
import 'health_insights_screen.dart';

/// Hyper-personalization hub: AI insights, patterns, tips, exports.
class PersonalizationHubScreen extends StatelessWidget {
  const PersonalizationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const GlowPageAppBar(title: Text('For you')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          HealthLogService.instance,
          CycleService.instance,
        ]),
        builder: (context, _) {
          final cycle = CycleService.instance;
          final health = HealthLogService.instance;
          final cycleInsights = PersonalizedCycleInsightsService.build(cycle: cycle, health: health);
          final tips = AdaptiveTipsService.generate(cycle: cycle, health: health);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Insights that evolve with your logs — wellness education only, not medical advice.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              _NavTile(
                scheme: scheme,
                icon: Icons.auto_awesome_rounded,
                title: 'AI cycle forecast',
                subtitle: 'Predictions + narrative tips for workouts & nutrition',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AiForecastScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _NavTile(
                scheme: scheme,
                icon: Icons.hub_outlined,
                title: 'Symptom patterns',
                subtitle: 'Correlations across phase, mood, pain & sleep',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CorrelationInsightsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _NavTile(
                scheme: scheme,
                icon: Icons.groups_2_outlined,
                title: 'Challenge buddies',
                subtitle: 'Hydration, sleep & yoga — supportive micro-challenges',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BuddyChallengesScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _NavTile(
                scheme: scheme,
                icon: Icons.school_outlined,
                title: 'Ask an expert',
                subtitle: 'AMA Q&A · fertility, PMS, PCOS, skin & more',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ExpertAmaScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _NavTile(
                scheme: scheme,
                icon: Icons.insights_outlined,
                title: 'Charts & export',
                subtitle: 'PDF report, CSV for doctors, symptom trends',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const HealthInsightsScreen()),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI-powered cycle insights',
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              for (final ins in cycleInsights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    useBackdropBlur: false,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ins.headline,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(ins.detail, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.35)),
                          const SizedBox(height: 8),
                          Text(
                            ins.actionHint,
                            style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Adaptive tips',
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              for (final tip in tips.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    useBackdropBlur: false,
                    child: ListTile(
                      dense: true,
                      title: Text(tip.title, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      subtitle: Text(tip.body, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
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

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.scheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ColorScheme scheme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBackdropBlur: false,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
