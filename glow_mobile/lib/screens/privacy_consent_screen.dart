import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/home_scaffold.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _agreedToDataProcessing = false;
  bool _agreedToTerms = false;

  void _onGetStarted() async {
    if (_agreedToDataProcessing && _agreedToTerms) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_accepted', true);
      if (!mounted) return;
      // After accepting privacy, go directly to the dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScaffold()),
      );
    }
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _agreedToDataProcessing && _agreedToTerms;
    const pinkColor = Color(0xFFFF8FC8);
    final scheme = Theme.of(context).colorScheme;
    // Use dark text colors so text is visible in both light and dark mode
    final bodyColor = scheme.onSurface;
    final mutedColor = scheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Text('🌸', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Privacy first',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: bodyColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your health data belongs to you.',
                      style: TextStyle(color: mutedColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Checkbox 1
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToDataProcessing,
                      onChanged: (val) => setState(() => _agreedToDataProcessing = val ?? false),
                      activeColor: pinkColor,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
                        children: [
                          const TextSpan(text: 'I agree that Glow Wellness may process my personal data to provide me with its services, as described in the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog('Privacy Policy',
                                  'Your health and wellness notes are yours alone. We do not sell or share your personal data with anyone. What you track in Glow stays private and secure.'),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Checkbox 2
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                      activeColor: pinkColor,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog('Privacy Policy',
                                  'Your health and wellness notes are yours alone. We do not sell or share your personal data with anyone.'),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog('Terms of Service',
                                  'By using Glow Wellness, you agree to treat the community with respect and understand that Dr. Najaat is an AI assistant, not a substitute for professional medical advice.'),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'You may withdraw your consent at any time. However, if you do so, we will no longer be able to provide you with the Glow Wellness application services.',
                style: TextStyle(color: mutedColor, fontSize: 13, height: 1.5),
              ),

              const SizedBox(height: 16),

              RichText(
                text: TextSpan(
                  style: TextStyle(color: mutedColor, fontSize: 13, height: 1.5),
                  children: [
                    TextSpan(
                      text: 'Learn more',
                      style: const TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showPolicyDialog('Learn More',
                            'If you decline the terms, you cannot use the app. You can uninstall the app to remove all local data.'),
                    ),
                    TextSpan(
                      text: ' about these options, and what you can do if you don\'t want to agree to the Terms.',
                      style: TextStyle(color: mutedColor),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canContinue ? _onGetStarted : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pinkColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: pinkColor.withOpacity(0.3),
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('I agree — Get started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
