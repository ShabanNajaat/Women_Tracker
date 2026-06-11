import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'privacy_consent_screen.dart';

class CreateUsernameScreen extends StatefulWidget {
  const CreateUsernameScreen({super.key});

  @override
  State<CreateUsernameScreen> createState() => _CreateUsernameScreenState();
}

class _CreateUsernameScreenState extends State<CreateUsernameScreen> {
  final _usernameController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters');
      return;
    }
    if (username.contains(' ')) {
      setState(() => _error = 'Username cannot contain spaces');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Re-init to make sure the auth token is loaded into memory
      final api = ApiService();
      await api.init();
      if (!api.isAuthenticated) {
        setState(() => _error = 'Not signed in. Please restart the app and log in again.');
        return;
      }
      final res = await api.post('/auth/set-username', body: {'username': username});
      if (res.statusCode == 200) {
        if (!mounted) return;
        // After picking a username, show the Privacy consent screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyConsentScreen()),
        );
      } else {
        String errMsg = 'Could not set username';
        try {
          final body = jsonDecode(res.body);
          errMsg = body['message'] ?? errMsg;
        } catch (_) {}
        setState(() => _error = errMsg);
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server. Check your connection and try again. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Username'),
        automaticallyImplyLeading: false, // User must set a username
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Glow! 🌸',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Pick a unique username so your friends can find you. '
                'This will be your identity in the Glow community.',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFFF8FC8)),
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF8FC8), width: 2),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8FC8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
