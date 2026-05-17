/// Hyper-personal cycle insight (on-device, wellness-only).
class PersonalizedCycleInsight {
  const PersonalizedCycleInsight({
    required this.headline,
    required this.detail,
    required this.actionHint,
  });

  final String headline;
  final String detail;
  final String actionHint;
}
