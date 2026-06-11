import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/home_scaffold.dart';
import '../theme/glow_tokens.dart';
import 'login_screen.dart';
import 'privacy_consent_screen.dart';
import 'create_username_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final privacyAccepted = prefs.getBool('privacy_accepted') ?? false;

    await ApiService().init();
    var isLoggedIn = ApiService().isAuthenticated;
    bool hasUsername = false;

    if (isLoggedIn) {
      isLoggedIn = await ApiService().validateToken();
      if (isLoggedIn) {
        final res = await ApiService().get('/auth/profile');
        if (res.statusCode == 200) {
          try {
            final data = jsonDecode(res.body);
            hasUsername = data['username'] != null && data['username'].toString().trim().isNotEmpty;
          } catch (_) {}
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Widget next;
    // New flow order: Login → Username → Privacy → Dashboard
    if (!isLoggedIn) {
      // Not logged in — go to login
      next = const LoginScreen();
    } else if (!hasUsername) {
      // Logged in but no username yet — pick one
      next = const CreateUsernameScreen();
    } else if (!privacyAccepted) {
      // Logged in + has username but hasn't accepted privacy yet — show consent
      next = const PrivacyConsentScreen();
    } else {
      // All good — go to dashboard
      next = const HomeScaffold();
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: GlassBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: GlowTokens.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.45),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                'GLOW',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
