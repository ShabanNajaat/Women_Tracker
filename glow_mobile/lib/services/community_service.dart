import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'glow_local_db.dart';

class CommunityPost {
  final String id;
  final String authorName;
  final String title;
  final String body;
  final int commentCount;
  final int createdAtMs;
  final String? phaseRoom;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.body,
    required this.commentCount,
    required this.createdAtMs,
    this.phaseRoom,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> m) {
    final created = m['createdAt'];
    var ms = 0;
    if (created is String) {
      ms = DateTime.tryParse(created)?.millisecondsSinceEpoch ?? 0;
    } else if (created != null) {
      try {
        ms = DateTime.parse(created.toString()).millisecondsSinceEpoch;
      } catch (_) {}
    }
    final cc = m['commentCount'];
    return CommunityPost(
      id: m['id']?.toString() ?? '',
      authorName: m['authorName']?.toString() ?? 'Member',
      title: m['title']?.toString() ?? '',
      body: m['body']?.toString() ?? '',
      commentCount: cc is num ? cc.toInt() : int.tryParse('$cc') ?? 0,
      createdAtMs: ms,
      phaseRoom: m['phaseRoom'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'title': title,
        'body': body,
        'commentCount': commentCount,
        'createdAtMs': createdAtMs,
        'phaseRoom': phaseRoom,
      };
}

class CommunityComment {
  final String id;
  final String authorName;
  final String body;
  final int createdAtMs;

  CommunityComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAtMs,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> m) {
    final created = m['createdAt'];
    var ms = 0;
    if (created is String) {
      ms = DateTime.tryParse(created)?.millisecondsSinceEpoch ?? 0;
    } else if (created != null) {
      try {
        ms = DateTime.parse(created.toString()).millisecondsSinceEpoch;
      } catch (_) {}
    }
    return CommunityComment(
      id: m['id']?.toString() ?? '',
      authorName: m['authorName']?.toString() ?? 'Member',
      body: m['body']?.toString() ?? '',
      createdAtMs: ms,
    );
  }
}

class CommunityService {
  CommunityService._();
  static final CommunityService instance = CommunityService._();

  final ApiService _api = ApiService();
  static const _prefsPostsKey = 'glow_community_posts_v1';

  String _prefsPostsKeyFor(String? phaseRoom) =>
      phaseRoom == null || phaseRoom.isEmpty ? _prefsPostsKey : '${_prefsPostsKey}_$phaseRoom';

  String _prefsCommentsKey(String postId) => 'glow_comm_comments_${postId}_v1';

  Future<List<CommunityPost>> readCachedPosts({String? phaseRoom}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsPostsKeyFor(phaseRoom));
      if (raw == null || raw.isEmpty) return [];
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((p) => p.id.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
    final db = await GlowLocalDb.instance.database;
    final rows = phaseRoom != null
        ? await db.query(
            'community_posts_cache',
            where: 'phase_room = ?',
            whereArgs: [phaseRoom],
            orderBy: 'created_at_ms DESC',
          )
        : await db.query(
            'community_posts_cache',
            orderBy: 'created_at_ms DESC',
          );
    return rows.map((r) {
      return CommunityPost(
        id: r['post_id']! as String,
        authorName: (r['author_name'] as String?) ?? 'Member',
        title: r['title']! as String,
        body: r['body']! as String,
        commentCount: (r['comment_count'] as int?) ?? 0,
        createdAtMs: (r['created_at_ms'] as int?) ?? 0,
        phaseRoom: r['phase_room'] as String?,
      );
    }).toList();
  }

  Future<void> writePostsCache(List<CommunityPost> posts, {String? phaseRoom}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsPostsKeyFor(phaseRoom),
        jsonEncode(posts.map((e) => e.toJson()).toList()),
      );
      return;
    }
    final db = await GlowLocalDb.instance.database;
    final batch = db.batch();
    if (phaseRoom != null) {
      batch.delete('community_posts_cache', where: 'phase_room = ?', whereArgs: [phaseRoom]);
    } else {
      batch.delete('community_posts_cache');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in posts) {
      batch.insert('community_posts_cache', {
        'post_id': p.id,
        'author_name': p.authorName,
        'title': p.title,
        'body': p.body,
        'comment_count': p.commentCount,
        'created_at_ms': p.createdAtMs,
        'fetched_at_ms': now,
        'phase_room': p.phaseRoom,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Returns null if the network call failed; empty list means no posts.
  Future<List<CommunityPost>?> fetchPostsNetwork({String? phaseRoom}) async {
    final path = phaseRoom != null && phaseRoom.isNotEmpty
        ? '/community/posts?phase=$phaseRoom'
        : '/community/posts';
    final res = await _api.get(path);
    if (res.statusCode != 200) return null;
    try {
      final data = jsonDecode(res.body);
      if (data is! List) return null;
      final posts = data
          .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((p) => p.id.isNotEmpty)
          .toList();
      await writePostsCache(posts, phaseRoom: phaseRoom);
      return posts;
    } catch (_) {
      return null;
    }
  }

  Future<CommunityPost?> createPost({
    required String title,
    required String body,
    String? phaseRoom,
  }) async {
    final bodyMap = <String, dynamic>{'title': title, 'body': body};
    if (phaseRoom != null && phaseRoom.isNotEmpty) {
      bodyMap['phaseRoom'] = phaseRoom;
    }
    final res = await _api.post('/community/posts', body: bodyMap);
    if (res.statusCode != 201 && res.statusCode != 200) return null;
    try {
      final m = jsonDecode(res.body);
      if (m is! Map) return null;
      final post = CommunityPost.fromJson(Map<String, dynamic>.from(m));
      final existing = await readCachedPosts(phaseRoom: post.phaseRoom);
      await writePostsCache(
        [post, ...existing.where((p) => p.id != post.id)],
        phaseRoom: post.phaseRoom,
      );
      return post;
    } catch (_) {
      return null;
    }
  }

  Future<List<CommunityComment>?> fetchCommentsNetwork(String postId) async {
    final res = await _api.get('/community/posts/$postId/comments');
    if (res.statusCode != 200) return null;
    try {
      final data = jsonDecode(res.body);
      if (data is! List) return null;
      final comments = data
          .map((e) => CommunityComment.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((c) => c.id.isNotEmpty)
          .toList();
      await writeCommentsCache(postId, comments);
      return comments;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeCommentsCache(String postId, List<CommunityComment> comments) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsCommentsKey(postId),
        jsonEncode(comments
            .map((c) => {
                  'id': c.id,
                  'authorName': c.authorName,
                  'body': c.body,
                  'createdAtMs': c.createdAtMs,
                })
            .toList()),
      );
      return;
    }
    final db = await GlowLocalDb.instance.database;
    await db.delete('community_comments_cache', where: 'post_id = ?', whereArgs: [postId]);
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final c in comments) {
      batch.insert('community_comments_cache', {
        'post_id': postId,
        'server_comment_id': c.id,
        'author_name': c.authorName,
        'body': c.body,
        'created_at_ms': c.createdAtMs,
        'fetched_at_ms': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<CommunityComment>> readCommentsCache(String postId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsCommentsKey(postId));
      if (raw == null || raw.isEmpty) return [];
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return CommunityComment(
            id: m['id']?.toString() ?? '',
            authorName: m['authorName']?.toString() ?? 'Member',
            body: m['body']?.toString() ?? '',
            createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
          );
        }).where((c) => c.id.isNotEmpty).toList();
      } catch (_) {
        return [];
      }
    }
    final db = await GlowLocalDb.instance.database;
    final rows = await db.query(
      'community_comments_cache',
      columns: ['server_comment_id', 'author_name', 'body', 'created_at_ms'],
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'created_at_ms ASC',
    );
    return rows
        .map(
          (r) => CommunityComment(
            id: (r['server_comment_id'] as String?) ?? '',
            authorName: (r['author_name'] as String?) ?? 'Member',
            body: r['body']! as String,
            createdAtMs: (r['created_at_ms'] as int?) ?? 0,
          ),
        )
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  Future<CommunityComment?> addComment(String postId, String body) async {
    final res = await _api.post('/community/posts/$postId/comments', body: {'body': body});
    if (res.statusCode != 201 && res.statusCode != 200) return null;
    try {
      final m = jsonDecode(res.body);
      if (m is! Map) return null;
      final comment = CommunityComment.fromJson(Map<String, dynamic>.from(m));
      final existing = await readCommentsCache(postId);
      final merged = [...existing.where((c) => c.id != comment.id), comment];
      merged.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
      await writeCommentsCache(postId, merged);
      return comment;
    } catch (_) {
      return null;
    }
  }
}
