import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// In-app notification service that polls for notifications and tracks unread count.
class InAppNotificationService {
  InAppNotificationService._();
  static final InAppNotificationService instance = InAppNotificationService._();

  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static final ValueNotifier<List<Map<String, dynamic>>> notifications =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  Timer? _pollTimer;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  void dispose() {
    _pollTimer?.cancel();
    _initialized = false;
  }

  Future<void> refresh() async {
    if (!ApiService().isAuthenticated) return;
    try {
      final res = await ApiService().get('/notifications');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['notifications'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        notifications.value = list;
        unreadCount.value = data['unreadCount'] as int? ?? 0;
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiService().post('/notifications/read', body: {});
      unreadCount.value = 0;
      final updated = notifications.value
          .map((n) => {...n, 'read': true})
          .toList();
      notifications.value = updated;
    } catch (_) {}
  }
}
