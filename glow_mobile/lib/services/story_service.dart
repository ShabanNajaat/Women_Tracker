import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class StoryService {
  StoryService._();
  static final StoryService instance = StoryService._();
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

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
      final res = await ApiService().get('/stories/feed');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List? ?? [];
        _feedStories = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        revision.value++;
      }
    } catch (_) {}
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
