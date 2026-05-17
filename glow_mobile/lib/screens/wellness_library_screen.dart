import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/glow_page_app_bar.dart';

/// Curated reads and media — story-style reassurance, music, motivation.
class WellnessLibraryScreen extends StatelessWidget {
  const WellnessLibraryScreen({super.key});

  Future<void> _open(BuildContext context, String label, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link for $label')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final stories = <_LibItem>[
      _LibItem(
        title: 'Understanding your cycle (plain language)',
        subtitle: 'NHS overview — phases, what’s normal, when to ask a clinician',
        icon: Icons.auto_stories_rounded,
        url: 'https://www.nhs.uk/conditions/periods/',
      ),
      _LibItem(
        title: 'PCOS — starter guide',
        subtitle: 'WHO fact sheet for context and next questions for your doctor',
        icon: Icons.menu_book_rounded,
        url: 'https://www.who.int/news-room/fact-sheets/detail/polycystic-ovary-syndrome',
      ),
      _LibItem(
        title: 'Mental health matters too',
        subtitle: 'Calm, practical grounding from Mind',
        icon: Icons.favorite_outline_rounded,
        url: 'https://www.mind.org.uk/information-support/types-of-mental-health-problems/',
      ),
    ];

    final audio = <_LibItem>[
      _LibItem(
        title: 'Soft instrumental — study & wind-down',
        subtitle: 'YouTube: “calming piano wellness” (external)',
        icon: Icons.library_music_rounded,
        url: 'https://www.youtube.com/results?search_query=calming+piano+wellness+instrumental',
      ),
      _LibItem(
        title: 'Gentle affirmations / motivation',
        subtitle: 'YouTube: “positive affirmation women wellness” (external)',
        icon: Icons.record_voice_over_rounded,
        url: 'https://www.youtube.com/results?search_query=positive+affirmation+women+wellness+morning',
      ),
      _LibItem(
        title: 'Body-doubling focus music',
        subtitle: 'YouTube search for focus playlists (external)',
        icon: Icons.headphones_rounded,
        url: 'https://www.youtube.com/results?search_query=lofi+focus+study+music+soft',
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: GlowPageAppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        title: Text(
          'Wellness library',
          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Stories, clarity & sound',
              style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick something gentle when you feel low—nothing here replaces medical advice. '
              'We’ll grow this library with more “storybook” reads and partner content over time.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 24),
            _sectionTitle(scheme, 'Short reads'),
            const SizedBox(height: 12),
            ...stories.map((e) => _tile(context, scheme, e)),
            const SizedBox(height: 28),
            _sectionTitle(scheme, 'Music & motivation'),
            const SizedBox(height: 12),
            ...audio.map((e) => _tile(context, scheme, e)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ColorScheme scheme, String t) {
    return Text(
      t,
      style: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _tile(BuildContext context, ColorScheme scheme, _LibItem e) {
    final isDark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context, e.title, e.url),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(e.icon, color: scheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.subtitle,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded, color: scheme.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;

  const _LibItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
  });
}
