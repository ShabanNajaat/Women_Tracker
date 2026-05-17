import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/partner_streak.dart';
import 'api_service.dart';

/// Partner link + daily streak accountability (replaces generic “share with club”).
class PartnerService {
  PartnerService._();
  static final PartnerService instance = PartnerService._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  PartnerStreakSnapshot? _snapshot;
  bool _loading = false;

  PartnerStreakSnapshot? get snapshot => _snapshot;
  bool get isLoading => _loading;

  void _notify() {
    revision.value = revision.value + 1;
  }

  Future<PartnerStreakSnapshot?> refresh() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) {
      _snapshot = null;
      _notify();
      return null;
    }

    _loading = true;
    _notify();

    try {
      final res = await api.get('/partner/streak');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          _snapshot = PartnerStreakSnapshot.fromJson(data);
        }
      }
    } catch (_) {}

    _loading = false;
    _notify();
    return _snapshot;
  }

  Future<String?> fetchInviteCode() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) return null;
    try {
      final res = await api.get('/partner/invite-code');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['inviteCode'] != null) {
          return data['inviteCode'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> joinPartner(String code) async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) return 'Sign in to link a partner.';
    try {
      final res = await api.post('/partner/join', body: {'code': code.trim()});
      if (res.statusCode == 200) {
        await refresh();
        return null;
      }
      try {
        final m = jsonDecode(res.body);
        if (m is Map && m['msg'] != null) return m['msg'].toString();
      } catch (_) {}
      return 'Could not link partner.';
    } catch (_) {
      return 'Could not reach server.';
    }
  }

  /// Sync today’s wellness check-in to server streak + partner visibility.
  Future<void> syncTodayCheckIn() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) return;
    try {
      final res = await api.post('/partner/streak/check-in', body: {});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final prev = _snapshot;
          _snapshot = PartnerStreakSnapshot(
            linked: prev?.linked ?? (data['partner'] != null),
            inviteCode: prev?.inviteCode,
            partnerName: prev?.partnerName ??
                (data['partner'] is Map ? (data['partner'] as Map)['name']?.toString() : null),
            myStreak: (data['me'] is Map ? (data['me'] as Map)['streak'] as num? : null)?.toInt() ??
                prev?.myStreak ??
                0,
            myLongest:
                (data['me'] is Map ? (data['me'] as Map)['longest'] as num? : null)?.toInt() ??
                    prev?.myLongest ??
                    0,
            myCheckedInToday: data['me'] is Map ? (data['me'] as Map)['checkedInToday'] == true : true,
            partnerStreak: (data['partner'] is Map
                    ? (data['partner'] as Map)['streak'] as num?
                    : null)
                ?.toInt() ??
                prev?.partnerStreak ??
                0,
            partnerLongest: (data['partner'] is Map
                    ? (data['partner'] as Map)['longest'] as num?
                    : null)
                ?.toInt() ??
                prev?.partnerLongest ??
                0,
            partnerCheckedInToday: data['partner'] is Map
                ? (data['partner'] as Map)['checkedInToday'] == true
                : false,
            bothCheckedInToday: data['bothCheckedInToday'] == true,
            pendingNudgeFrom: prev?.pendingNudgeFrom,
            pendingNudgeMessage: prev?.pendingNudgeMessage,
          );
          _notify();
        }
      }
    } catch (_) {}
  }

  Future<String?> nudgePartner() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) return 'Sign in to nudge your partner.';
    if (_snapshot?.linked != true) return 'Link a partner first.';
    try {
      final res = await api.post('/partner/send-nudge', body: {});
      if (res.statusCode == 200) {
        try {
          final m = jsonDecode(res.body);
          if (m is Map && m['msg'] != null) return m['msg'].toString();
        } catch (_) {}
        return 'Nudge sent!';
      }
      return 'Could not send nudge.';
    } catch (_) {
      return 'Could not reach server.';
    }
  }

  Future<void> markNudgeAsRead() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) return;
    try {
      await api.post('/partner/nudge/read', body: {});
      if (_snapshot != null) {
        _snapshot = PartnerStreakSnapshot(
          linked: _snapshot!.linked,
          inviteCode: _snapshot!.inviteCode,
          partnerName: _snapshot!.partnerName,
          myStreak: _snapshot!.myStreak,
          myLongest: _snapshot!.myLongest,
          myCheckedInToday: _snapshot!.myCheckedInToday,
          partnerStreak: _snapshot!.partnerStreak,
          partnerLongest: _snapshot!.partnerLongest,
          partnerCheckedInToday: _snapshot!.partnerCheckedInToday,
          bothCheckedInToday: _snapshot!.bothCheckedInToday,
        );
        _notify();
      }
    } catch (_) {}
  }

  Future<void> leavePartner() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) return;
    try {
      await api.post('/partner/leave', body: {});
      await refresh();
    } catch (_) {}
  }
}
