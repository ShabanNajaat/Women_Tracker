import 'package:flutter/material.dart';

class CycleWheel extends StatelessWidget {
  final int currentDay;
  final int totalDays;

  const CycleWheel({
    super.key,
    required this.currentDay,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: currentDay / totalDays,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              color: scheme.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Day',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$currentDay',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                'of $totalDays',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
