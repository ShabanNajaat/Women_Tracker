import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/phase_room.dart';
import '../services/cycle_service.dart';
import '../widgets/glass_card.dart';
import 'expert_ama_screen.dart';
import 'phase_room_screen.dart';

/// Hub for cycle-phase community rooms.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    CycleService.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: CycleService.instance,
      builder: (context, _) {
        final cycle = CycleService.instance;
        final currentPhase = cycle.phaseForDay(
          cycle.currentDayInCycle,
          cycleLength: cycle.typicalCycleLength,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Text(
                  'Glow Community',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phase rooms — connect with others in the same part of your cycle. Supportive peer space, not medical advice.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (cycle.lastPeriodStart != null) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    useBackdropBlur: false,
                    child: Row(
                      children: [
                        Icon(Icons.loop_rounded, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are in ${currentPhase.displayName} phase (day ${cycle.currentDayInCycle}) — your room is highlighted below.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    'Log your period on the calendar to highlight your current phase room.',
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ExpertAmaScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: GlassCard(
                      useBackdropBlur: false,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.secondary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.school_outlined, color: scheme.secondary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expert AMA',
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Live Q&A with wellness educators — ask, upvote, read answers.',
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
                const SizedBox(height: 24),
                Text(
                  'Phase rooms',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final room in PhaseRoomInfo.all) ...[
                  _PhaseRoomCard(
                    room: room,
                    scheme: scheme,
                    isCurrentPhase: room.phase == currentPhase,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PhaseRoomScreen(room: room),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                GlassCard(
                  useBackdropBlur: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.shield, color: scheme.onSurfaceVariant, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Be kind and protect your privacy. Do not share passwords, addresses, or personal health identifiers. Report concerns to your clinician when needed.',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhaseRoomCard extends StatelessWidget {
  const _PhaseRoomCard({
    required this.room,
    required this.scheme,
    required this.isCurrentPhase,
    required this.onTap,
  });

  final PhaseRoomInfo room;
  final ColorScheme scheme;
  final bool isCurrentPhase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          useBackdropBlur: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrentPhase
                      ? scheme.primary.withValues(alpha: 0.22)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrentPhase
                      ? Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: Icon(
                  room.icon,
                  color: isCurrentPhase ? scheme.primary : scheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrentPhase)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Your phase',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.phase.displayName,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room.subtitle,
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
    );
  }
}
