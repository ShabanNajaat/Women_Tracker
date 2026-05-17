import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/glow_effects_service.dart';
import '../screens/settings_screen.dart';

class LeftSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LeftSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.selected,
      backgroundColor: isDark ? scheme.surface : scheme.surfaceContainerHigh,
      selectedIconTheme: IconThemeData(color: scheme.primary, size: 26),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: GlowEffectsService.instance.enabled,
              builder: (context, on, _) {
                return Tooltip(
                  message: on ? 'Glass effects on' : 'Glass effects off',
                  child: SizedBox(
                    height: 34,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Switch(
                        value: on,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeThumbColor: scheme.primary,
                        activeTrackColor: scheme.primary.withValues(alpha: 0.45),
                        inactiveThumbColor: scheme.onSurfaceVariant,
                        inactiveTrackColor: scheme.outline.withValues(alpha: 0.35),
                        onChanged: (value) => GlowEffectsService.instance.setEnabled(value),
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Settings',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: Icon(
                Icons.settings_outlined,
                color: scheme.onSurface,
                size: 22,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(LucideIcons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.calendar),
          label: Text('Calendar'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.sparkles),
          label: Text('Glow Space'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.refreshCw),
          label: Text('Her Cycle'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.messageCircle),
          label: Text('Chat'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.edit3),
          label: Text('Journal'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.users),
          label: Text('Community'),
        ),
      ],
    );
  }
}
