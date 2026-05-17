import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Scrollable bottom bar — reliable with 7 tabs on narrow web layouts.
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? surfaceTint;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.surfaceTint,
  });

  static const _items = [
    (LucideIcons.home, 'Home'),
    (LucideIcons.calendar, 'Calendar'),
    (LucideIcons.sparkles, 'Glow'),
    (LucideIcons.refreshCw, 'Cycle'),
    (LucideIcons.messageCircle, 'Chat'),
    (LucideIcons.edit3, 'Journal'),
    (LucideIcons.users, 'Community'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = surfaceTint ?? scheme.surfaceContainerHigh;

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: barColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: 0.25), width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final (icon, label) = _items[index];
                final selected = index == currentIndex;
                final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
                final bg = selected ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent;

                return Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 22, color: fg),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
