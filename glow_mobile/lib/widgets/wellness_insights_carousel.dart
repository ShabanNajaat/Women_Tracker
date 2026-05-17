import 'package:flutter/material.dart';
import '../data/wellness_insights.dart';
import 'glass_card.dart';

/// Horizontal cards: facts, myths, encouragement (old-style “did you know” feed).
class WellnessInsightsCarousel extends StatefulWidget {
  const WellnessInsightsCarousel({super.key});

  @override
  State<WellnessInsightsCarousel> createState() => _WellnessInsightsCarouselState();
}

class _WellnessInsightsCarouselState extends State<WellnessInsightsCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accent(ColorScheme scheme, String type) {
    return switch (type) {
      'myth' => scheme.error.withValues(alpha: 0.85),
      'encourage' => scheme.secondary,
      _ => scheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = WellnessInsights.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facts · myths · encouragement',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quick reads — not a substitute for medical advice.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final m = items[i];
              final type = m['type'] ?? 'fact';
              final accent = _accent(scheme, type);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GlassCard(
                  useBackdropBlur: false,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            type == 'myth'
                                ? Icons.cancel_outlined
                                : type == 'encourage'
                                    ? Icons.favorite_border_rounded
                                    : Icons.lightbulb_outline_rounded,
                            size: 20,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            m['title'] ?? '',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: Text(
                          m['body'] ?? '',
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page ? scheme.primary : scheme.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
