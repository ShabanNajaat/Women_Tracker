import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'glow_local_db.dart';

/// Single persisted thread per [userScope] (Dr. Najaat). Web uses SharedPreferences JSON.
///
/// [migrateScope] moves rows from the logged-out guest scope to the signed-in user id.
class ChatLocalRow {
  final String role;
  final String text;

  const ChatLocalRow({required this.role, required this.text});
}

class ChatLocalStore {
  ChatLocalStore._();
  static final ChatLocalStore instance = ChatLocalStore._();

  static const _prefsPrefix = 'glow_chat_v1_';

  String _prefsKey(String userScope) => '$_prefsPrefix$userScope';

  Future<List<ChatLocalRow>> loadMessages(String userScope) async {
    if (kIsWeb) {
      final maps = await _readWebMaps(userScope);
      maps.sort((a, b) {
        final ca = (a['created_at_ms'] as num?)?.toInt() ?? 0;
        final cb = (b['created_at_ms'] as num?)?.toInt() ?? 0;
        return ca.compareTo(cb);
      });
      return maps
          .map((m) => ChatLocalRow(role: m['role']!.toString(), text: m['text']!.toString()))
          .toList();
    }
    final db = await GlowLocalDb.instance.database;
    final rows = await db.query(
      'chat_messages',
      where: 'user_scope = ?',
      whereArgs: [userScope],
      orderBy: 'created_at_ms ASC',
    );
    return rows
        .map((r) => ChatLocalRow(role: r['role']! as String, text: r['body']! as String))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _readWebMaps(String userScope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(userScope));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      final out = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v)));
        if (m['role'] != null && m['text'] != null) out.add(m);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Moves every message from [fromScope] to [toScope] (e.g. guest → user id after sign-in).
  Future<void> migrateScope(String fromScope, String toScope) async {
    if (fromScope.isEmpty || toScope.isEmpty || fromScope == toScope) return;
    if (kIsWeb) {
      final fromList = await _readWebMaps(fromScope);
      if (fromList.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final toRaw = prefs.getString(_prefsKey(toScope));
      List<Map<String, dynamic>> toList = [];
      if (toRaw != null && toRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(toRaw);
          if (decoded is List) {
            for (final e in decoded) {
              if (e is Map) {
                toList.add(Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v))));
              }
            }
          }
        } catch (_) {}
      }
      final seenServer = <String>{};
      for (final m in toList) {
        final sid = m['server_id']?.toString();
        if (sid != null && sid.isNotEmpty) seenServer.add(sid);
      }
      for (final m in fromList) {
        final sid = m['server_id']?.toString();
        if (sid != null && sid.isNotEmpty && seenServer.contains(sid)) continue;
        toList.add(m);
        if (sid != null && sid.isNotEmpty) seenServer.add(sid);
      }
      toList.sort((a, b) {
        final ca = (a['created_at_ms'] as num?)?.toInt() ?? 0;
        final cb = (b['created_at_ms'] as num?)?.toInt() ?? 0;
        return ca.compareTo(cb);
      });
      await prefs.setString(_prefsKey(toScope), jsonEncode(toList));
      await prefs.remove(_prefsKey(fromScope));
      return;
    }
    final db = await GlowLocalDb.instance.database;
    await db.rawUpdate(
      'UPDATE chat_messages SET user_scope = ? WHERE user_scope = ?',
      [toScope, fromScope],
    );
  }

  Future<void> appendUserMessage(String userScope, String text) async {
    await _append(userScope, 'user', text, null, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> appendAssistantMessage(String userScope, String text) async {
    await _append(userScope, 'assistant', text, null, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _append(String userScope, String role, String text, String? serverId, int createdAtMs) async {
    if (text.isEmpty) return;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = await _readWebMaps(userScope);
      list.add(<String, dynamic>{
        'role': role,
        'text': text,
        'created_at_ms': createdAtMs,
        if (serverId != null) 'server_id': serverId,
      });
      await prefs.setString(_prefsKey(userScope), jsonEncode(list));
      return;
    }
    final db = await GlowLocalDb.instance.database;
    await db.insert('chat_messages', {
      'user_scope': userScope,
      'role': role,
      'body': text,
      'created_at_ms': createdAtMs,
      'server_id': serverId,
    });
  }

  /// Upsert messages returned by [GET /api/chat].
  Future<void> mergeServerMessages(String userScope, List<dynamic> raw) async {
    for (final item in raw) {
      if (item is! Map) continue;
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final serverRole = item['role']?.toString() ?? 'ai';
      final uiRole = serverRole == 'user' ? 'user' : 'assistant';
      final text = item['text']?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      final ts = _parseTs(item['timestamp']);
      if (kIsWeb) {
        await _mergeWebRow(userScope, id, uiRole, text, ts);
        continue;
      }
      final db = await GlowLocalDb.instance.database;
      final exists = await db.query(
        'chat_messages',
        columns: ['local_id'],
        where: 'user_scope = ? AND server_id = ?',
        whereArgs: [userScope, id],
        limit: 1,
      );
      if (exists.isNotEmpty) continue;
      await _linkOrInsertLocalDupe(db, userScope, uiRole, text, ts, id);
    }
  }

  int _parseTs(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? DateTime.now().millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _mergeWebRow(String userScope, String serverId, String role, String text, int ts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(userScope));
    List<Map<String, dynamic>> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v))));
          }
        }
      } catch (_) {}
    }
    for (final m in list) {
      if (m['server_id']?.toString() == serverId) return;
    }
    for (var i = 0; i < list.length; i++) {
      if (list[i]['server_id'] != null) continue;
      if (list[i]['role'] == role && list[i]['text'] == text) {
        list[i]['server_id'] = serverId;
        list[i]['created_at_ms'] = ts;
        await prefs.setString(_prefsKey(userScope), jsonEncode(list));
        return;
      }
    }
    list.add(<String, dynamic>{
      'role': role,
      'text': text,
      'server_id': serverId,
      'created_at_ms': ts,
    });
    list.sort((a, b) {
      final ca = (a['created_at_ms'] as num?)?.toInt() ?? 0;
      final cb = (b['created_at_ms'] as num?)?.toInt() ?? 0;
      return ca.compareTo(cb);
    });
    await prefs.setString(_prefsKey(userScope), jsonEncode(list));
  }

  Future<void> _linkOrInsertLocalDupe(
    Database db,
    String userScope,
    String role,
    String text,
    int ts,
    String serverId,
  ) async {
    final loose = await db.query(
      'chat_messages',
      columns: ['local_id'],
      where: 'user_scope = ? AND role = ? AND body = ? AND server_id IS NULL AND abs(? - created_at_ms) < 120000',
      whereArgs: [userScope, role, text, ts],
      limit: 1,
    );
    if (loose.isNotEmpty) {
      await db.update(
        'chat_messages',
        {'server_id': serverId, 'created_at_ms': ts},
        where: 'local_id = ?',
        whereArgs: [loose.first['local_id']],
      );
      return;
    }
    await db.insert(
      'chat_messages',
      {
        'user_scope': userScope,
        'role': role,
        'body': text,
        'created_at_ms': ts,
        'server_id': serverId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
