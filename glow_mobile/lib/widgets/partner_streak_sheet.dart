import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/partner_service.dart';

/// Pick a friend to start a daily streak with.
Future<void> showPartnerStreakSheet(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  const pink = Color(0xFFFF8FC8);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return _FriendStreakBody(
            scheme: scheme,
            pink: pink,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _FriendStreakBody extends StatefulWidget {
  const _FriendStreakBody({
    required this.scheme,
    required this.pink,
    required this.scrollController,
  });

  final ColorScheme scheme;
  final Color pink;
  final ScrollController scrollController;

  @override
  State<_FriendStreakBody> createState() => _FriendStreakBodyState();
}

class _FriendStreakBodyState extends State<_FriendStreakBody> {
  bool _loading = true;
  List<dynamic> _friends = [];
  String? _linkingId;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await api.get('/friends');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _friends = data['friends'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startStreak(String friendId, String friendName) async {
    setState(() => _linkingId = friendId);
    final err = await PartnerService.instance.joinPartner(friendId);
    if (!mounted) return;
    setState(() => _linkingId = null);
    if (err == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Streak started with $friendName — let\'s go! 🔥')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final pink = widget.pink;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: pink, size: 24),
              const SizedBox(width: 10),
              Text(
                'Start a streak with a friend',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a friend to share daily streaks with. You\'ll see each other\'s progress and stay motivated together.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (!ApiService().isAuthenticated)
            Text(
              'Sign in to start streaks with friends.',
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
            )
          else if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_friends.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 52,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No friends yet',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add friends first to start streaks! Go to Discover to find people on Glow.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: widget.scrollController,
                itemCount: _friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final f = _friends[i];
                  final username = f['username']?.toString() ?? '';
                  final id = f['id']?.toString() ?? f['_id']?.toString() ?? '';
                  final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';
                  final isLinking = _linkingId == id;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pink.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: pink.withValues(alpha: 0.2),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: pink,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$username',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Glow friend',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isLinking || id.isEmpty
                              ? null
                              : () => _startStreak(id, username),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: isLinking
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Start streak 🔥'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
