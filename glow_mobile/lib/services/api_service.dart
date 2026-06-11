import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_local_store.dart';
import 'partner_service.dart';
import 'user_data_scope.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _prefUserId = 'glow-user-id';
  /// Stable on-device chat scope while logged out (per install). Migrates to user id on sign-in.
  static const String _prefGuestChatScope = 'glow-guest-chat-scope';

  /// Build with `--dart-define=API_BASE_URL=https://your.host/api`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  String get baseUrl {
    final fromEnv = _envBaseUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8081/api';
      }
      // If hosted on Netlify or GitHub Pages, API lives on Render
      if (host.contains('netlify.app') || host.contains('github.io')) {
        return 'https://women-tracker-1.onrender.com/api';
      }
      // Same host as API (e.g. Render serves build/web + /api together).
      return '$origin/api';
    }
    return 'https://women-tracker-1.onrender.com/api';
  }


  String? _token;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('x-auth-token');
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('x-auth-token');
    if (_token != null && _token!.trim().isNotEmpty) {
      final uid = prefs.getString(_prefUserId);
      if (uid == null || uid.isEmpty) {
        await _refreshUserIdFromProfile(prefs);
      }
    }
  }

  /// Stable scope for on-device chat rows: signed-in user id, or a persistent guest id.
  Future<String> userScope() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefUserId);
    if (id != null && id.isNotEmpty) return id;
    var guest = prefs.getString(_prefGuestChatScope);
    if (guest == null || guest.isEmpty) {
      // Stable bucket matching older app versions; persisted in prefs for the install.
      guest = 'local_anonymous';
      await prefs.setString(_prefGuestChatScope, guest);
    }
    return guest;
  }

  Future<String> _guestScopeForMigrate(SharedPreferences prefs) async {
    var guest = prefs.getString(_prefGuestChatScope);
    if (guest == null || guest.isEmpty) {
      guest = 'local_anonymous';
      await prefs.setString(_prefGuestChatScope, guest);
    }
    return guest;
  }

  Future<void> _refreshUserIdFromProfile(SharedPreferences prefs) async {
    try {
      final res = await get('/auth/profile');
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      if (data is Map && data['id'] != null) {
        final uid = data['id'].toString();
        final previous = prefs.getString(_prefUserId);
        final guest = await _guestScopeForMigrate(prefs);
        final wasGuest = previous == null || previous.isEmpty;
        if (wasGuest && guest.isNotEmpty && uid.isNotEmpty && guest != uid) {
          await ChatLocalStore.instance.migrateScope(guest, uid);
        }
        await prefs.setString(_prefUserId, uid);
        if (previous != uid) {
          await _notifySessionChanged();
        }
      }
    } catch (_) {}
  }

  Future<void> persistToken(String token, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final previousUserId = prefs.getString(_prefUserId);
    final guest = await _guestScopeForMigrate(prefs);
    await prefs.setString('x-auth-token', token);
    _token = token;

    String? newUserId = userId;
    if (newUserId != null && newUserId.isNotEmpty) {
      final wasGuest = previousUserId == null || previousUserId.isEmpty;
      if (wasGuest && guest.isNotEmpty && guest != newUserId) {
        await ChatLocalStore.instance.migrateScope(guest, newUserId);
      }
      await prefs.setString(_prefUserId, newUserId);
    } else {
      await _refreshUserIdFromProfile(prefs);
      newUserId = prefs.getString(_prefUserId);
    }

    if (previousUserId != newUserId) {
      await _notifySessionChanged();
    }
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final hadUser = prefs.getString(_prefUserId);
    await prefs.remove('x-auth-token');
    await prefs.remove(_prefUserId);
    _token = null;
    await prefs.setString(
      _prefGuestChatScope,
      'guest_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (hadUser != null && hadUser.isNotEmpty) {
      await _notifySessionChanged();
    }
  }

  Future<void> _notifySessionChanged() async {
    await UserDataScope.notifySessionChanged();
    if (isAuthenticated) {
      try {
        await PartnerService.instance.refresh();
      } catch (_) {}
    }
  }

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'x-auth-token': _token!,
      };

  Future<http.Response> get(String endpoint) async {
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );
  }

  /// Multipart upload (e.g. voice note for transcription). Does not set JSON Content-Type.
  Future<http.Response> postMultipart(
    String endpoint, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final req = http.MultipartRequest('POST', uri);
    final t = _token;
    if (t != null && t.trim().isNotEmpty) {
      req.headers['x-auth-token'] = t;
    }
    req.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }

  bool get isAuthenticated => _token != null && _token!.trim().isNotEmpty;

  /// Returns true if the saved token is accepted by [GET /auth/profile].
  Future<bool> validateToken() async {
    if (!isAuthenticated) return false;
    final res = await get('/auth/profile');
    if (res.statusCode == 200) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final previous = prefs.getString(_prefUserId);
        final guest = await _guestScopeForMigrate(prefs);
        final data = jsonDecode(res.body);
        if (data is Map && data['id'] != null) {
          final uid = data['id'].toString();
          final wasGuest = previous == null || previous.isEmpty;
          if (wasGuest && guest.isNotEmpty && uid.isNotEmpty && guest != uid) {
            await ChatLocalStore.instance.migrateScope(guest, uid);
          }
          await prefs.setString(_prefUserId, uid);
          if (previous != uid) {
            await _notifySessionChanged();
          }
        }
      } catch (_) {}
      return true;
    }
    if (res.statusCode == 401) await clearAuth();
    return false;
  }
}
