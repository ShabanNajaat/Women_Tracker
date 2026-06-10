import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../navigation/glow_navigation.dart';
import '../services/glow_web_links.dart';
import '../widgets/animated_glass_card.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';
import '../widgets/glowie_mascot.dart';
import 'ai_forecast_screen.dart';
import 'buddy_challenges_screen.dart';
import 'correlation_insights_screen.dart';
import 'exercise_timer_screen.dart';
import 'expert_ama_screen.dart';
import 'health_insights_screen.dart';
import 'personalization_hub_screen.dart';
import 'wellness_library_screen.dart';
import 'wellness_schedules_hub_screen.dart';

/// Friendly, cute walkthrough for beginners — every major Glow feature explained.
class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  static final _categories = <_GuideCategory>[
    _GuideCategory(
      emoji: '🌷',
      title: 'Start here',
      tint: Color(0xFFFFE4F0),
      sections: [
        _GuideSection(
          emoji: '✨',
          title: 'Welcome, glow friend!',
          body:
              'Glow Wellness is your cozy space to track your cycle, mood, and habits — and learn in plain language. '
              'We are here to support you, not replace your doctor. 💗',
        ),
        _GuideSection(
          emoji: '💡',
          title: 'Tips for your first week',
          body:
              '① Log when your period started on the Calendar.\n'
              '② Add mood or sleep a few days each week.\n'
              '③ Peek at AI forecast once you have a little data.\n'
              '④ Say hi in Community when you feel ready.',
        ),
        _GuideSection(
          emoji: '📲',
          title: 'Install on your phone (free)',
          body:
              'No app store fee — add Glow to your home screen from the website. '
              'Android: Chrome → Install app. iPhone: Safari → Share → Add to Home Screen.',
          action: _GuideAction.installPage(),
        ),
      ],
    ),
    _GuideCategory(
      emoji: '🏠',
      title: 'Main tabs',
      tint: Color(0xFFE8F4FF),
      sections: [
        _GuideSection(
          emoji: '🏡',
          title: 'Home dashboard',
          body:
              'Your daily hello: cycle wheel, glow points, mood board, mini quiz, and cards that open AI forecast, health insights, “For you”, meals, and schedules.',
          action: _GuideAction.tab(0),
        ),
        _GuideSection(
          emoji: '🎨',
          title: 'Mood board',
          body:
              'On Home — pick how you feel today with cute mood tiles. It feeds your wellness score and helps AI spot patterns over time.',
          action: _GuideAction.tab(0),
        ),
        _GuideSection(
          emoji: '🧠',
          title: 'Mini wellness quiz',
          body:
              'A quick question on Home for extra glow points. Fun facts about cycle care — one bonus per day when you answer right.',
          action: _GuideAction.tab(0),
        ),
        _GuideSection(
          emoji: '📅',
          title: 'Calendar',
          body:
              'Tap a day to log period flow, cramps, mood, sleep, and notes. More logs = smarter predictions later.',
          action: _GuideAction.tab(1),
        ),
        _GuideSection(
          emoji: '🌙',
          title: 'Glow Space',
          body:
              'A softer, lavender-lit corner for calm focus and your exercise timer.',
          action: _GuideAction.tab(2),
        ),
        _GuideSection(
          emoji: '📚',
          title: 'Wellness library',
          body:
              'Short reads and tips in Glow Space — cycle phases, self-care, and gentle habit ideas when you want to learn without chatting.',
          action: _GuideAction.screen((_) => const WellnessLibraryScreen()),
        ),
        _GuideSection(
          emoji: '🔄',
          title: 'Her Cycle',
          body:
              'See your phase today — menstrual, follicular, ovulatory, or luteal — plus gentle phase tips and fertility tools in Settings.',
          action: _GuideAction.tab(3),
        ),
        _GuideSection(
          emoji: '💬',
          title: 'Chat — Dr. Najaat',
          body:
              'Your friendly AI wellness companion. Ask about cycles, PMS, sleep, or nutrition. Educational only — not an emergency line.',
          action: _GuideAction.tab(4),
        ),
        _GuideSection(
          emoji: '📔',
          title: 'Journal',
          body:
              'Private thoughts and voice notes, saved to your account. Only you see them when signed in.',
          action: _GuideAction.tab(5),
        ),
        _GuideSection(
          emoji: '👭',
          title: 'Community',
          body:
              'Supportive posts and kind comments. A warm place to share wins — not for emergencies.',
          action: _GuideAction.tab(6),
        ),
        _GuideSection(
          emoji: '🚪',
          title: 'Phase rooms',
          body:
              'Inside Community — join menstrual, follicular, ovulatory, or luteal rooms so conversations match where you are in your cycle.',
          action: _GuideAction.tab(6),
        ),
        _GuideSection(
          emoji: '⚙️',
          title: 'Settings & profile',
          body:
              'Gear icon (top right): theme, name, photo, medication reminders, partner mode, notifications, and sign out. Each login keeps its own data.',
        ),
      ],
    ),
    _GuideCategory(
      emoji: '🤖',
      title: 'Smart insights (AI & charts)',
      tint: Color(0xFFF3E8FF),
      sections: [
        _GuideSection(
          emoji: '🗺️',
          title: 'Where is everything?',
          body:
              'On Home look for “AI forecast” and “Health insights” cards. Open “For you” for the full menu — buddies, expert AMA, patterns, and export.',
        ),
        _GuideSection(
          emoji: '🎯',
          title: '“For you” hub',
          body:
              'Your personalization home — the cute menu that lists AI forecast, symptom patterns, challenge buddies, ask an expert, and charts/export in one place.',
          action: _GuideAction.screen((_) => const PersonalizationHubScreen()),
        ),
        _GuideSection(
          emoji: '🔮',
          title: 'AI cycle forecast',
          body:
              'Predicts your next period window, phase timeline, and mood trends. Optional AI story for workouts & nutrition — log your period on the Calendar first for the best magic.',
          action: _GuideAction.screen((_) => const AiForecastScreen()),
        ),
        _GuideSection(
          emoji: '🌈',
          title: 'AI forecast (from Home)',
          body:
              'Same feature as above — tap the “AI forecast” card on your dashboard when you want a quick peek without opening “For you” first.',
          action: _GuideAction.screen((_) => const AiForecastScreen()),
        ),
        _GuideSection(
          emoji: '📊',
          title: 'Health insights',
          body:
              'Line and bar charts for mood, energy, sleep, and hydration. See what is trending up or down across your cycle phases.',
          action: _GuideAction.screen((_) => const HealthInsightsScreen()),
        ),
        _GuideSection(
          emoji: '💎',
          title: 'Health insights (from Home)',
          body:
              'Same charts — use the “Health insights” card on Home for one-tap access to graphs and phase-aware tips.',
          action: _GuideAction.screen((_) => const HealthInsightsScreen()),
        ),
        _GuideSection(
          emoji: '🧩',
          title: 'Symptom patterns (AI correlations)',
          body:
              'Finds links in your logs — e.g. more cramps in luteal week or better sleep after movement — so you can plan ahead kindly.',
          action: _GuideAction.screen((_) => const CorrelationInsightsScreen()),
        ),
        _GuideSection(
          emoji: '🌸',
          title: 'AI cycle insights cards',
          body:
              'Scroll down in “For you” — headline cards that update as you log, written for your current phase (educational, not a diagnosis).',
          action: _GuideAction.screen((_) => const PersonalizationHubScreen()),
        ),
        _GuideSection(
          emoji: '💫',
          title: 'Adaptive daily tips',
          body:
              'Also in “For you” — small friendly nudges (water, stretch, rest) that change when your mood and sleep logs change.',
          action: _GuideAction.screen((_) => const PersonalizationHubScreen()),
        ),
      ],
    ),
    _GuideCategory(
      emoji: '🎓',
      title: 'Experts & buddies',
      tint: Color(0xFFE8FFF4),
      sections: [
        _GuideSection(
          emoji: '👩‍⚕️',
          title: 'Ask an expert (AMA)',
          body:
              'Expert AMA Q&A with Dr. Najaat — live and upcoming sessions on fertility, PMS, PCOS, skin, and cycle mood. Ask anonymously; upvote questions you love.',
          action: _GuideAction.screen((_) => const ExpertAmaScreen()),
        ),
        _GuideSection(
          emoji: '💌',
          title: 'Partner mode',
          body:
              'Settings → share your invite code so a partner can send encouragement and see streak-friendly nudges (you control what you share).',
        ),
        _GuideSection(
          emoji: '🤝',
          title: 'Challenge buddies',
          body:
              'Cute micro-challenges with friends: hydration, sleep, or yoga streaks. Cheer each other on — no pressure, just gentle accountability.',
          action: _GuideAction.screen((_) => const BuddyChallengesScreen()),
        ),
        _GuideSection(
          emoji: '🏆',
          title: '30-day glow challenge',
          body:
              'On Home: earn glow points for daily check-ins. A fun way to build a logging habit.',
          action: _GuideAction.tab(0),
        ),
      ],
    ),
    _GuideCategory(
      emoji: '🧘',
      title: 'Wellness tools',
      tint: Color(0xFFFFF4E8),
      sections: [
        _GuideSection(
          emoji: '⏱️',
          title: 'Exercise timer',
          body:
              'Pick 15s–2min, hit Start, move (squats, plank, stretches). Ding! — sound + celebration when you are done.',
          action: _GuideAction.timer(),
        ),
        _GuideSection(
          emoji: '🍽️',
          title: 'Meals & workout schedules',
          body:
              'Remind yourself to eat well or move — set recurring meal and workout nudges from Home or Settings.',
          action: _GuideAction.screen((_) => const WellnessSchedulesHubScreen()),
        ),
        _GuideSection(
          emoji: '💊',
          title: 'Medication reminders',
          body:
              'Settings → build a gentle pill or supplement schedule with notifications on this device.',
        ),
        _GuideSection(
          emoji: '❤️‍🩹',
          title: 'Body pain map',
          body:
              'From health logging: tap where you feel discomfort to track patterns over your cycle.',
        ),
        _GuideSection(
          emoji: '⌚',
          title: 'Wearables (optional)',
          body:
              'Settings → connect health data when available for richer sleep and activity context.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var cardIndex = 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const GlowPageAppBar(title: Text('Glow guide')),
      body: AppBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            _CuteGuideHeader(scheme: scheme),
            const SizedBox(height: 24),
            for (final cat in _categories) ...[
              _CategoryLabel(cat: cat, scheme: scheme),
              const SizedBox(height: 10),
              for (final s in cat.sections) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedGlassCard(
                    index: cardIndex++,
                    child: _CuteGuideTile(
                      section: s,
                      tint: cat.tint,
                      scheme: scheme,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CuteGuideHeader extends StatelessWidget {
  const _CuteGuideHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.22),
            scheme.tertiary.withValues(alpha: 0.18),
            scheme.secondary.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowieMascot(size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, I am Glowie! 🌸',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap any card below — I will explain what each feature does and take you there if you want.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.cat, required this.scheme});

  final _GuideCategory cat;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(cat.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          cat.title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CuteGuideTile extends StatelessWidget {
  const _CuteGuideTile({
    required this.section,
    required this.tint,
    required this.scheme,
  });

  final _GuideSection section;
  final Color tint;
  final ColorScheme scheme;

  Future<void> _runAction(BuildContext context) async {
    final a = section.action;
    if (a == null) return;
    switch (a.kind) {
      case _GuideActionKind.tab:
        GlowNavigation.goToTab(context, a.tabIndex!);
      case _GuideActionKind.timer:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ExerciseTimerScreen()),
        );
      case _GuideActionKind.screen:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: a.screenBuilder!),
        );
      case _GuideActionKind.installPage:
        final uri = Uri.parse(GlowWebLinks.installPage);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = section.action != null;

    return GlassCard(
      useBackdropBlur: false,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(section.emoji, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: hasAction
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tap to read · then jump in',
                    style: TextStyle(
                      color: scheme.primary.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          children: [
            Text(
              section.body,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            if (hasAction) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _runAction(context),
                icon: Icon(
                  section.action!.kind == _GuideActionKind.tab
                      ? Icons.rocket_launch_rounded
                      : section.action!.kind == _GuideActionKind.installPage
                          ? Icons.install_mobile_outlined
                          : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(_actionLabel(section.action!)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(_GuideAction action) {
    return switch (action.kind) {
      _GuideActionKind.tab => "Let's go! 💕",
      _GuideActionKind.timer => 'Start timer ⏱️',
      _GuideActionKind.screen => 'Open it ✨',
      _GuideActionKind.installPage => 'Install guide 📲',
    };
  }
}

class _GuideCategory {
  const _GuideCategory({
    required this.emoji,
    required this.title,
    required this.tint,
    required this.sections,
  });

  final String emoji;
  final String title;
  final Color tint;
  final List<_GuideSection> sections;
}

class _GuideSection {
  const _GuideSection({
    required this.emoji,
    required this.title,
    required this.body,
    this.action,
  });

  final String emoji;
  final String title;
  final String body;
  final _GuideAction? action;
}

enum _GuideActionKind { tab, timer, screen, installPage }

class _GuideAction {
  const _GuideAction._(this.kind, {this.tabIndex, this.screenBuilder});

  factory _GuideAction.tab(int index) => _GuideAction._(_GuideActionKind.tab, tabIndex: index);
  factory _GuideAction.timer() => const _GuideAction._(_GuideActionKind.timer);
  factory _GuideAction.screen(WidgetBuilder screenBuilder) =>
      _GuideAction._(_GuideActionKind.screen, screenBuilder: screenBuilder);
  factory _GuideAction.installPage() => const _GuideAction._(_GuideActionKind.installPage);

  final _GuideActionKind kind;
  final int? tabIndex;
  final WidgetBuilder? screenBuilder;
}
