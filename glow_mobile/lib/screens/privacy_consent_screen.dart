import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    final pinkColor = const Color(0xFFFF8FC8);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Privacy first',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        children: [
                          const TextSpan(text: 'I agree that Glow Wellness may process my personal data to provide me with its services, as described in the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog('Privacy Policy', 'Your health and wellness notes are yours alone. We do not sell or share your personal data with anyone. What you track in Glow stays private and secure.'),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog('Privacy Policy', 'Your health and wellness notes are yours alone. We do not sell or share your personal data with anyone.'),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog('Terms of Service', 'By using Glow Wellness, you agree to treat the community with respect and understand that Dr. Najaat is an AI assistant, not a substitute for professional medical advice.'),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'You may withdraw your consent at any time. However, if you do so, we will no longer be able to provide you with the Glow Wellness application services.',
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
              ),
              
              const SizedBox(height: 16),
              
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                  children: [
                    TextSpan(
                      text: 'Learn more',
                      style: TextStyle(color: pinkColor, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _showPolicyDialog('Learn More', 'If you decline the terms, you cannot use the app. You can uninstall the app to remove all local data.'),
                    ),
                    const TextSpan(text: ' about these options, and what you can do if you don\'t want to agree to the Terms.'),
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
                  child: const Text('Get started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
