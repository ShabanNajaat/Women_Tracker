import 'package:flutter/material.dart';
import '../services/dr_najaat_motivation.dart';
import '../theme/glow_tokens.dart';
import 'ai_assistant_bubble.dart';
import 'glow_text.dart';

class DashboardHero extends StatefulWidget {
  const DashboardHero({super.key});

  @override
  State<DashboardHero> createState() => _DashboardHeroState();
}

class _DashboardHeroState extends State<DashboardHero> {
  late String _message;

  @override
  void initState() {
    super.initState();
    _message = DrNajaatMotivation.randomLine();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: GlowTokens.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowText(
            "Today's Glow",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            colors: [Colors.white, Color(0xFFE8DEF8)],
          ),
          const SizedBox(height: 16),
          AiAssistantBubble(message: _message),
        ],
      ),
    );
  }
}
