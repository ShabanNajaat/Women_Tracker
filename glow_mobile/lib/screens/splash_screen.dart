import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/home_scaffold.dart';
import '../theme/glow_tokens.dart';
import 'login_screen.dart';

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
    await ApiService().init();
    var goHome = ApiService().isAuthenticated;
    if (goHome) {
      goHome = await ApiService().validateToken();
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final next = goHome ? const HomeScaffold() : const LoginScreen();
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
