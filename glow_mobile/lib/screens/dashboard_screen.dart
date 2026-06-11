import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/socket_service.dart';
import '../widgets/animated_glass_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/cycle_wheel.dart';
import '../widgets/glow_text.dart';
import '../widgets/mini_wellness_quiz_card.dart';
import '../widgets/mood_board.dart';
import '../widgets/skeleton_loader.dart';
import '../services/challenge_service.dart';
import '../services/cycle_service.dart';
import '../widgets/thirty_day_challenge_card.dart';
import '../widgets/wellness_insights_carousel.dart';
import '../widgets/beginner_tools_row.dart';
import 'friends_screen.dart';
import 'ai_forecast_screen.dart';
import 'health_insights_screen.dart';
import 'personalization_hub_screen.dart';
import 'settings_screen.dart';
import 'wellness_schedules_hub_screen.dart';
import '../models/wellness_schedule_type.dart';
import '../services/wellness_schedule_service.dart';
import '../services/health_log_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool _loadingHero = true;
  int _contentEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contentEpoch = DateTime.now().millisecondsSinceEpoch;
    CycleService.instance.ensureLoaded();
    WellnessScheduleService.instance.ensureLoaded();
    SocketService.instance.connect();
    ChallengeService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (mounted) setState(() => _loadingHero = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _contentEpoch++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CycleService.instance,
      builder: (context, _) {
        final cycle = CycleService.instance;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlowText(
                        _timeGreeting(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                        colors: [scheme.primary, scheme.tertiary],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Friends & Community',
                      icon: Icon(LucideIcons.users, color: scheme.onSurface),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const FriendsScreen()),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: Icon(Icons.settings_outlined, color: scheme.onSurface),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loadingHero) ...[
                  SkeletonLoader(width: double.infinity, height: 140, borderRadius: BorderRadius.circular(24)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: SkeletonLoader(width: double.infinity, height: 88, borderRadius: BorderRadius.circular(16))),
                      const SizedBox(width: 12),
                      Expanded(child: SkeletonLoader(width: double.infinity, height: 88, borderRadius: BorderRadius.circular(16))),
                    ],
                  ),
                ] else ...[
                  AnimatedGlassCard(
                    index: 0,
                    child: GlassCard(
                      useBackdropBlur: false,
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Builder(builder: (context) {
                            final log = HealthLogService.instance.logForDate(DateTime.now());
                            final score = HealthLogService.instance.weeklyGlowScore(days: 1);
                            final hasMood = log.mood > 0;
                            final hasEnergy = log.energy > 0;
                            final hasSleep = log.sleepHours > 0;
                            final hasWater = log.waterGlasses > 0;
                            final hasSymptoms = log.symptoms.isNotEmpty;
                            final hasAnyData = hasMood || hasEnergy || hasSleep || hasWater;

                            // Build dynamic insights
                            final insights = <String>[];
                            if (!hasMood) insights.add('• Log your mood to personalise your score');
                            if (!hasSleep) insights.add('• Add tonight\'s sleep to track rest patterns');
                            if (!hasWater) insights.add('• Log water intake to stay on top of hydration');
                            if (hasSleep && log.sleepHours < 6) insights.add('• You slept less than 6h — try an earlier bedtime tonight');
                            if (hasSleep && log.sleepHours >= 8) insights.add('• Great sleep last night! Your body is recovering well 🌙');
                            if (hasWater && log.waterGlasses < 4) insights.add('• Drink more water today — aim for 8 glasses');
                            if (hasWater && log.waterGlasses >= 8) insights.add('• Excellent hydration today! 💧');
                            if (hasMood && log.mood <= 2) insights.add('• Your mood is low — be gentle with yourself today 💕');
                            if (hasEnergy && log.energy <= 2) insights.add('• Energy is low — rest and nourishing food can help');
                            if (hasSymptoms) insights.add('• Symptoms logged: ${log.symptoms.take(3).join(", ")}');
                            if (insights.isEmpty) insights.add('• Everything looks great today! Keep glowing ✨');

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today\'s Wellness Score', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (score != null) ...[
                                      Text('$score', style: TextStyle(color: scheme.primary, fontSize: 44, fontWeight: FontWeight.w800)),
                                      Text('/100', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.w600)),
                                    ] else ...[
                                      Text('–', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 44, fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Log today\'s mood, sleep & water to see your score',
                                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (hasAnyData) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (hasMood)
                                        Text('😊 Mood: ${log.moodLabel ?? '${log.mood}/5'}',
                                            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                                      if (hasWater)
                                        Text('💧 ${log.waterGlasses} glasses',
                                            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                  if (hasSleep) ...[
                                    const SizedBox(height: 6),
                                    Text('😴 Sleep: ${log.sleepHours.toStringAsFixed(1)}h',
                                        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ],
                                const SizedBox(height: 16),
                                Text('Today\'s Insights', style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Text('Based on your cycle and today\'s logs:', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Text(insights.join('\n'), style: TextStyle(color: scheme.onSurface, height: 1.7, fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            );
                          }),
                        ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedGlassCard(
                    index: 1,
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reminders', style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildReminderChip(scheme, '📝', 'Log your symptoms', 0),
                                _buildReminderChip(scheme, '🩸', 'Cycle starts in 3 days', 1),
                                _buildReminderChip(scheme, '💖', 'Wellness check-in', 2),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedGlassCard(
                    index: 3,
                    child: DashboardHero(key: ValueKey(_contentEpoch)),
                  ),
                ],
                if (!_loadingHero) ...[
                  const BeginnerToolsRow(startIndex: 3),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 28),
                Center(
                  child: CycleWheel(
                    currentDay: cycle.demoDayInCycle,
                    totalDays: cycle.demoCycleLength,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_loadingHero)
                  AnimatedGlassCard(
                    index: 4,
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AiForecastScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.tertiary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.auto_awesome_rounded, color: scheme.tertiary, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI forecast',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cycle.hasCycleAnchor
                                          ? 'Next period, phases & mood trends — plus optional AI insight.'
                                          : 'Log your period to unlock personalized forecasts.',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!_loadingHero)
                  AnimatedGlassCard(
                    index: 5,
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PersonalizationHubScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.person_outline_rounded, color: scheme.primary, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'For you',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Buddy challenges, expert AMA, AI insights, tips & export.',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (!_loadingHero)
                  AnimatedGlassCard(
                    index: 6,
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HealthInsightsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.insights_rounded, color: scheme.primary, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Health insights',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Graphs for mood, energy, sleep & hydration — plus phase-aware tips.',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!_loadingHero)
                  ListenableBuilder(
                    listenable: WellnessScheduleService.instance,
                    builder: (context, _) {
                      final svc = WellnessScheduleService.instance;
                      final total = svc.reminders(WellnessScheduleType.meal).length +
                          svc.reminders(WellnessScheduleType.workout).length;
                      return AnimatedGlassCard(
                        index: 6,
                        child: GlassCard(
                          useBackdropBlur: false,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WellnessSchedulesHubScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: scheme.secondary.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.restaurant_menu_rounded, color: scheme.secondary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Meals & workouts',
                                          style: TextStyle(
                                            color: scheme.onSurface,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          total == 0
                                              ? 'Schedule nutrition and movement reminders.'
                                              : '$total scheduled · tap to manage',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 28),
                Text(
                  'Cycle overview',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Day ${cycle.demoDayInCycle} of ${cycle.demoCycleLength}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_loadingHero) const AnimatedGlassCard(index: 1, child: ThirtyDayChallengeCard()),
                const SizedBox(height: 16),
                if (!_loadingHero)
                  AnimatedGlassCard(
                    index: 4,
                    child: MiniWellnessQuizCard(key: ValueKey(_contentEpoch)),
                  ),
                const SizedBox(height: 20),
                if (!_loadingHero) const AnimatedGlassCard(index: 2, child: MoodBoard()),
                const SizedBox(height: 20),
                if (!_loadingHero) const WellnessInsightsCarousel(),
                const SizedBox(height: 24),
            Text(
              cycle.emphasizesFertility ? 'Cycle focus' : 'Next period (estimate)',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
                const SizedBox(height: 12),
                AnimatedGlassCard(
                  index: _loadingHero ? 0 : 3,
                  child: GlassCard(
                    useBackdropBlur: false,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AiForecastScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final c = CycleService.instance;
                                final summary = c.fertilityDashboardSummary();
                                final headline = summary.headline;
                                final sub = summary.sub;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      headline,
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (sub != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        sub,
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          Icon(Icons.calendar_today, color: scheme.primary, size: 28),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Glowie 🌸';
    if (hour < 17) return 'Good Afternoon, Glowie ☀️';
    return 'Good Evening, Glowie 🌙';
  }

  Widget _buildReminderChip(ColorScheme scheme, String emoji, String label, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
