import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class StoryService {
  StoryService._();
  static final StoryService instance = StoryService._();
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  List<Map<String, dynamic>> _feedStories = [];
  List<Map<String, dynamic>> get feedStories => _feedStories;

  /// Grouped by user: { userId, username, photo, stories: [...] }
  List<Map<String, dynamic>> get groupedFeed {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final story in _feedStories) {
      final user = story['user'];
      if (user == null) continue;
      final uid = user['_id']?.toString() ?? user['id']?.toString() ?? '';
      if (uid.isEmpty) continue;
      if (!grouped.containsKey(uid)) {
        grouped[uid] = {
          'userId': uid,
          'username': user['username'] ?? '',
          'photo': user['photo'],
          'stories': <Map<String, dynamic>>[],
        };
      }
      (grouped[uid]!['stories'] as List).add(story);
    }
    return grouped.values.toList();
  }

  Future<void> refreshFeed() async {
    if (!ApiService().isAuthenticated) return;
    try {
      // Load current user ID
      if (_currentUserId == null) {
        final prefs = await SharedPreferences.getInstance();
        _currentUserId = prefs.getString('glow-user-id');
      }
      final res = await ApiService().get('/stories/feed');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List? ?? [];
        _feedStories = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        revision.value++;
      }
    } catch (_) {}
  }

  /// Stories by the current user only
  List<Map<String, dynamic>> get myStories {
    if (_currentUserId == null) return [];
    return _feedStories.where((s) {
      final user = s['user'];
      if (user == null) return false;
      final uid = user['_id']?.toString() ?? user['id']?.toString() ?? '';
      return uid == _currentUserId;
    }).toList();
  }

  /// Grouped feed excluding the current user's stories
  List<Map<String, dynamic>> get friendGroupedFeed {
    return groupedFeed.where((g) => g['userId'] != _currentUserId).toList();
  }

  Future<String?> createStory(String imageData, String caption) async {
    try {
      final res = await ApiService().post('/stories', body: {
        'imageData': imageData,
        'caption': caption,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await refreshFeed();
        return null;
      }
      final data = jsonDecode(res.body);
      return data['error']?.toString() ?? 'Could not post story';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<String?> createTextStory(String text) async {
    try {
      final res = await ApiService().post('/stories', body: {
        'caption': text,
        'textOnly': true,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        await refreshFeed();
        return null;
      }
      final data = jsonDecode(res.body);
      return data['error']?.toString() ?? 'Could not post story';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<void> reactToStory(String storyId, String emoji) async {
    try {
      await ApiService().post('/stories/$storyId/react', body: {'emoji': emoji});
    } catch (_) {}
  }

  Future<void> markViewed(String storyId) async {
    try {
      await ApiService().post('/stories/$storyId/view', body: {});
    } catch (_) {}
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await ApiService().delete('/stories/$storyId');
      await refreshFeed();
    } catch (_) {}
  }
}
