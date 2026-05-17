/// Educational self-care copy after a journal save — not medical advice.
class JournalWellnessNote {
  JournalWellnessNote._();

  static String build({required String mood, required List<String> symptoms}) {
    final lines = <String>[
      'Here are a few gentle ideas based on what you logged. This is general wellness support, not a diagnosis — '
          'reach out to a clinician if symptoms are new, severe, or worrying for you.',
      '',
    ];

    if (mood == 'Happy') {
      lines.add('• You noticed something good — savor a small moment today (tea, music, or a thank-you to yourself).');
    } else if (mood == 'Calm') {
      lines.add('• Calm days are a gift: a short walk or one line in your journal about what feels steady can anchor it.');
    } else if (mood == 'Tired') {
      lines.add('• Low energy: steady water, a snack with protein when you can, and rest without judging yourself.');
    } else if (mood == 'Sad') {
      lines.add('• Heavy mood: soften the day — lower the bar, connect with someone kind, or get a bit of daylight.');
    } else if (mood == 'Anxious') {
      lines.add('• Uneasy mind: slow exhale longer than inhale for a minute, or name 5 things you see and 3 you hear.');
    } else {
      lines.add('• However you feel, one small kind action (water, food, fresh air) still counts.');
    }

    if (symptoms.isNotEmpty) {
      lines.add('');
      for (final s in symptoms) {
        if (s == 'Cramps') {
          lines.add('• Cramps: heat on the lower belly, gentle movement, and hydration help many people between visits.');
        } else if (s == 'Headache') {
          lines.add('• Headache: quiet dim space, steady fluids, and rest when you can — seek care if severe or sudden.');
        } else if (s == 'Bloating') {
          lines.add('• Bloating: smaller meals, fewer carbonated drinks if they bother you, and light walking.');
        } else if (s == 'Acne') {
          lines.add('• Skin flares: gentle cleansing, avoid picking, and note cycle timing for your clinician if needed.');
        } else if (s == 'Nausea') {
          lines.add('• Nausea: small sips of water, bland snacks if tolerated, and medical help if it persists.');
        } else {
          lines.add('• For $s: track what seems to trigger or ease it so you can share patterns with a healthcare provider.');
        }
      }
    }

    lines.add('');
    lines.add('You can open Chat anytime for educational support from Dr. Najaat.');

    return lines.join('\n');
  }
}
