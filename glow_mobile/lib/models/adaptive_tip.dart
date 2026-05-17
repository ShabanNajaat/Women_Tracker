/// A tip that adapts to logged symptoms, phase, and patterns.
class AdaptiveTip {
  const AdaptiveTip({
    required this.title,
    required this.body,
    required this.category,
    this.iconName = 'lightbulb',
  });

  final String title;
  final String body;
  final String category;
  final String iconName;
}
