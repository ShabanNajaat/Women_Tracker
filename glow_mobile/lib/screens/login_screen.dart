import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';
import '../services/auth_credentials_service.dart';
import '../theme/glow_tokens.dart';
import '../widgets/floating_bubbles_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/home_scaffold.dart';
import 'create_username_screen.dart';

/// Optional build-time override. Otherwise the app uses [GET /auth/public-config] (same ID as server `GOOGLE_CLIENT_ID`).
const _googleClientIdFromEnv = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  bool _rememberCredentials = true;
  /// From [GET /api/auth/public-config] — matches `GOOGLE_CLIENT_ID` on the server (OAuth Web client ID).
  String? _googleClientIdFromApi;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await _loadSavedCredentials();
      await _loadGooglePublicConfig();
    });
  }

  Future<void> _loadSavedCredentials() async {
    final creds = AuthCredentialsService.instance;
    final remember = await creds.rememberEnabled();
    final saved = await creds.load();
    if (!mounted) return;
    setState(() {
      _rememberCredentials = remember;
      if (saved.email != null && saved.email!.isNotEmpty) {
        _email.text = saved.email!;
      }
      if (remember && saved.password != null && saved.password!.isNotEmpty) {
        _password.text = saved.password!;
      }
    });
  }

  Future<void> _loadGooglePublicConfig() async {
    try {
      final res = await ApiService().get('/auth/public-config');
      if (!mounted || res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      if (data is Map && data['googleClientId'] != null) {
        final id = data['googleClientId'].toString().trim();
        if (id.isNotEmpty) setState(() => _googleClientIdFromApi = id);
      }
    } catch (_) {}
  }

  /// OAuth 2.0 **Web application** client ID (public). Server must list the same value in `GOOGLE_CLIENT_ID`.
  String get _effectiveGoogleClientId {
    final fromApi = _googleClientIdFromApi?.trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    return _googleClientIdFromEnv.trim();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String? _messageFromBody(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map) {
        if (m['message'] != null) return m['message'].toString();
        if (m['msg'] != null) return m['msg'].toString();
      }
    } catch (_) {}
    return null;
  }

  void _showPrivacyNote() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Privacy'),
        content: const Text(
          'Your health and wellness notes are yours alone. '
          'We do not sell or share your personal data with anyone.\n\n'
          'What you track in Glow stays private and secure. '
          'Only you can see your information.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showWhyGlow() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Why Glow Wellness?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your body goes through changes every day — your cycle, '
              'your mood, your energy, your sleep. It can be hard to '
              'keep track of it all.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 16),
            Text('Glow Wellness is your personal wellness companion. '
              'It helps you:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('🌸  Track your cycle and symptoms', style: TextStyle(fontSize: 14, height: 1.6)),
            Text('💬  Chat with Dr. Najaat, your AI wellness assistant', style: TextStyle(fontSize: 14, height: 1.6)),
            Text('📊  Understand your body\'s patterns', style: TextStyle(fontSize: 14, height: 1.6)),
            Text('📝  Keep a private wellness journal', style: TextStyle(fontSize: 14, height: 1.6)),
            SizedBox(height: 16),
            Text(
              'Everything is simple, private, and made just for you.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _submitEmailAuth() async {
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _toast('Enter email and password');
      return;
    }
    final name = _name.text.trim();
    if (_register) {
      if (name.isEmpty) {
        _toast('Enter your name');
        return;
      }
      if (password.length < 6) {
        _toast('Password must be at least 6 characters');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final api = ApiService();
      if (_register) {
        final res = await api.post('/auth/register', body: {
          'name': name,
          'email': email,
          'password': password,
        });

        if (res.statusCode == 201 || res.statusCode == 200) {
          await AuthCredentialsService.instance.setRemember(_rememberCredentials);
          await AuthCredentialsService.instance.save(
            email: email,
            password: _rememberCredentials ? password : null,
          );
          if (!mounted) return;
          setState(() {
            _register = false;
            _name.clear();
            _email.text = email;
            _password.text = password;
          });
          _toast(
            _messageFromBody(res.body) ??
                'Account created! Sign in with the same email and password.',
          );
          return;
        }
        _toast(_messageFromBody(res.body) ?? 'Could not create account (${res.statusCode})');
        return;
      }

      final res = await api.post('/auth/login', body: {'email': email, 'password': password});

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);
        if (raw is! Map) {
          _toast('Unexpected server response');
          return;
        }
        final token = raw['token']?.toString();
        if (token == null || token.isEmpty) {
          _toast('Server did not return a session');
          return;
        }
        await AuthCredentialsService.instance.setRemember(_rememberCredentials);
        await AuthCredentialsService.instance.save(
          email: email,
          password: _rememberCredentials ? password : null,
        );
        String? uid;
        final u = raw['user'];
        if (u is Map && u['id'] != null) uid = u['id'].toString();
        await api.persistToken(token, userId: uid);
        if (!mounted) return;
        final hasUsername = u['username'] != null && u['username'].toString().trim().isNotEmpty;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => hasUsername ? const HomeScaffold() : const CreateUsernameScreen()),
        );
        return;
      }
      final errMsg = _messageFromBody(res.body);
      if (res.statusCode == 401 && errMsg != null && errMsg.toLowerCase().contains('google')) {
        _toast(errMsg);
      } else {
        _toast(
          errMsg ??
              'Invalid email or password. If you just registered, use the exact same password. '
              'After a server restart you may need to register again.',
        );
      }
    } catch (_) {
      _toast('Could not reach the server. Check API_BASE_URL and that the API is running.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    var id = _effectiveGoogleClientId;
    if (id.isEmpty) {
      await _loadGooglePublicConfig();
      id = _effectiveGoogleClientId;
    }
    if (id.isEmpty) {
      _toast(
        'Set GOOGLE_CLIENT_ID in server/.env to your Google Cloud **Web application** client ID, restart the API, and ensure this app can reach it.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Email only — avoids Google Cloud "People API" requirement. Name/photo come from the ID token on the server.
      // Web: clientId only (serverClientId is not supported on web).
      final GoogleSignIn google = kIsWeb
          ? GoogleSignIn(
              scopes: const ['email', 'openid'],
              clientId: id,
            )
          : GoogleSignIn(
              scopes: const ['email', 'openid'],
              serverClientId: id,
            );
      await google.signOut();
      final account = await google.signIn();
      if (account == null) {
        return;
      }
      var auth = await account.authentication;
      var idToken = auth.idToken;
      var accessToken = auth.accessToken;

      // Web GIS often omits idToken; Bearer from authHeaders still works with the API.
      if (kIsWeb && (accessToken == null || accessToken.isEmpty)) {
        final headers = await account.authHeaders;
        final bearer = headers['Authorization'];
        if (bearer != null && bearer.startsWith('Bearer ')) {
          accessToken = bearer.substring(7).trim();
        }
      }
      if (kIsWeb && (idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        auth = await account.authentication;
        idToken = auth.idToken;
        accessToken = accessToken ?? auth.accessToken;
      }

      final Map<String, String> body;
      if (idToken != null && idToken.isNotEmpty) {
        body = {'idToken': idToken};
      } else if (kIsWeb && accessToken != null && accessToken.isNotEmpty) {
        body = {'accessToken': accessToken};
      } else {
        _toast(
          'No Google token. Add http://localhost:7357 under Google Cloud → Credentials → '
          'Authorized JavaScript origins. Open the app at that exact URL (not 127.0.0.1). '
          'GOOGLE_CLIENT_ID in server/.env must match web/index.html.',
        );
        return;
      }
      final api = ApiService();
      final res = await api.post('/auth/google', body: body);
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);
        if (raw is! Map) {
          _toast('Unexpected server response');
          return;
        }
        final token = raw['token']?.toString();
        if (token == null || token.isEmpty) {
          _toast('Server did not return a session');
          return;
        }
        String? uid;
        final u = raw['user'];
        if (u is Map && u['id'] != null) uid = u['id'].toString();
        await api.persistToken(token, userId: uid);
        if (!mounted) return;
        final hasUsername = u['username'] != null && u['username'].toString().trim().isNotEmpty;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => hasUsername ? const HomeScaffold() : const CreateUsernameScreen()),
        );
        return;
      }
      _toast(_messageFromBody(res.body) ?? 'Google sign-in failed (${res.statusCode})');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('People API') || msg.contains('people.googleapis.com')) {
        _toast(
          'Google Cloud: enable People API for your project, or hot-restart the app after updating (we now use email-only sign-in). '
          'Console: APIs & Services → enable People API.',
        );
      } else {
        _toast('Google sign-in error: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _darkAccent(ColorScheme scheme) => scheme.tertiary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = isLight ? scheme.primary : _darkAccent(scheme);

    return Scaffold(
      backgroundColor: isLight ? GlowTokens.creamSurface : scheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(isLight, scheme),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AbsorbPointer(
                absorbing: _busy,
                child: Opacity(
                  opacity: _busy ? 0.55 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        color: accent,
                        size: 48,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Glow',
                        style: TextStyle(
                          color: isLight ? GlowTokens.deepPlum : Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Designed for your clarity.',
                        style: TextStyle(
                          color: isLight ? scheme.onSurfaceVariant : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: _showWhyGlow,
                        child: Text(
                          'Why Glow Wellness?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLight ? scheme.onSurface : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showPrivacyNote,
                        child: Text(
                          'Health data stays private — how we treat your information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.lock, size: 14, color: isLight ? scheme.onSurfaceVariant : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Your wellness data is private and protected.',
                            style: TextStyle(
                              color: isLight ? scheme.onSurfaceVariant : Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        child: Column(
                          children: [
                            if (_register) ...[
                              _buildTextField(
                                label: 'Name',
                                icon: LucideIcons.user,
                                controller: _name,
                                isLight: isLight,
                              ),
                              const SizedBox(height: 20),
                            ],
                            _buildTextField(
                              label: 'Email',
                              icon: LucideIcons.mail,
                              controller: _email,
                              keyboard: TextInputType.emailAddress,
                              isLight: isLight,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Password',
                              icon: LucideIcons.lock,
                              controller: _password,
                              obscure: _obscure,
                              isLight: isLight,
                              trailing: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                                  color: isLight ? scheme.onSurfaceVariant : Colors.white38,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _rememberCredentials,
                              onChanged: _busy
                                  ? null
                                  : (v) async {
                                      if (v == null) return;
                                      setState(() => _rememberCredentials = v);
                                      await AuthCredentialsService.instance.setRemember(v);
                                    },
                              title: Text(
                                'Remember email & password on this device',
                                style: TextStyle(
                                  color: isLight ? scheme.onSurface : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _busy ? null : _submitEmailAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: isLight ? scheme.onPrimary : Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                _register ? 'Create account' : 'Sign in',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isLight ? scheme.outlineVariant.withValues(alpha: 0.55) : Colors.white10,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: isLight ? scheme.onSurfaceVariant : Colors.white38,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isLight ? scheme.outlineVariant.withValues(alpha: 0.55) : Colors.white10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _google,
                              icon: Icon(LucideIcons.chrome, size: 20, color: isLight ? scheme.onSurface : Colors.white),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isLight ? scheme.onSurface : Colors.white,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isLight ? scheme.onSurface : Colors.white,
                                side: BorderSide(
                                  color: isLight ? scheme.outline : GlowTokens.rose.withValues(alpha: 0.35),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _busy ? null : () => setState(() => _register = !_register),
                        child: Text(
                          _register ? 'Already have an account? Sign in' : 'Don\'t have an account? Create one',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_busy)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: accent,
                backgroundColor: isLight ? scheme.surfaceContainerHighest : Colors.black26,
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isLight, ColorScheme scheme) {
    return FloatingBubblesBackground(
      isLight: isLight,
      cute: true,
      opacityScale: isLight ? 0.85 : 0.75,
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isLight,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final border = isLight
        ? scheme.outline.withValues(alpha: 0.35)
        : GlowTokens.rose.withValues(alpha: 0.18);
    final fill = isLight
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.65)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);
    final primary = isLight ? scheme.onSurface : Colors.white;
    final secondary = isLight ? scheme.onSurfaceVariant : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: TextStyle(color: primary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: secondary),
          prefixIcon: Icon(icon, color: secondary, size: 20),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
