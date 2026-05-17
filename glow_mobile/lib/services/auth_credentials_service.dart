import 'package:shared_preferences/shared_preferences.dart';

/// Remembers email/password on this device so sign-in fields are prefilled.
class AuthCredentialsService {
  AuthCredentialsService._();
  static final AuthCredentialsService instance = AuthCredentialsService._();

  static const _kEmail = 'glow_saved_email';
  static const _kPassword = 'glow_saved_password';
  static const _kRemember = 'glow_remember_credentials';

  Future<bool> rememberEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRemember) ?? true;
  }

  Future<void> setRemember(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, value);
    if (!value) {
      await p.remove(_kPassword);
    }
  }

  Future<({String? email, String? password})> load() async {
    final p = await SharedPreferences.getInstance();
    final email = p.getString(_kEmail);
    final remember = p.getBool(_kRemember) ?? true;
    final password = remember ? p.getString(_kPassword) : null;
    return (email: email, password: password);
  }

  Future<void> save({required String email, String? password}) async {
    final p = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    await p.setString(_kEmail, normalized);
    final remember = p.getBool(_kRemember) ?? true;
    if (remember && password != null) {
      await p.setString(_kPassword, password);
    }
  }

  Future<void> clearPassword() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPassword);
  }
}
