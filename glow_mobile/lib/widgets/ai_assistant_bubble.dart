import 'package:flutter/material.dart';
import '../theme/glow_tokens.dart';

class AiAssistantBubble extends StatefulWidget {
  final String message;

  const AiAssistantBubble({super.key, required this.message});

  @override
  State<AiAssistantBubble> createState() => _AiAssistantBubbleState();
}

class _AiAssistantBubbleState extends State<AiAssistantBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GlowTokens.lavender.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GlowTokens.lavender.withValues(alpha: 0.38)),
          boxShadow: [
            BoxShadow(
              color: GlowTokens.lavender.withValues(alpha: 0.12),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.face, color: GlowTokens.lavender, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
