import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/phase_room.dart';
import '../services/api_service.dart';
import '../services/community_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityPostDetailScreen({super.key, required this.post});

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final CommunityService _svc = CommunityService.instance;
  late CommunityPost _post;
  List<CommunityComment> _comments = [];
  bool _busy = true;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final cached = await _svc.readCommentsCache(_post.id);
    if (mounted && cached.isNotEmpty) {
      setState(() => _comments = List.of(cached));
    }
    final net = await _svc.fetchCommentsNetwork(_post.id);
    if (!mounted) return;
    if (net != null) {
      setState(() {
        _comments = net;
        _busy = false;
      });
    } else {
      setState(() {
        _comments = cached;
        _busy = false;
      });
    }
  }

  String _ago(int ms) {
    if (ms <= 0) return 'Recently';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 90) return '${diff.inMinutes.clamp(1, 89)}m ago';
    if (diff.inHours < 48) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(d);
  }

  Future<void> _sendComment() async {
    final api = ApiService();
    if (!api.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to comment.')),
      );
      return;
    }
    final body = _commentCtrl.text.trim();
    if (body.isEmpty) return;
    final c = await _svc.addComment(_post.id, body);
    if (!mounted) return;
    if (c == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not post comment.')),
      );
      return;
    }
    _commentCtrl.clear();
    setState(() {
      _comments = [..._comments, c];
      _post = CommunityPost(
        id: _post.id,
        authorName: _post.authorName,
        title: _post.title,
        body: _post.body,
        commentCount: _post.commentCount + 1,
        createdAtMs: _post.createdAtMs,
        phaseRoom: _post.phaseRoom,
      );
    });
    await _svc.fetchCommentsNetwork(_post.id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = _post.authorName.isNotEmpty ? _post.authorName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlowPageAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        title: Text('Discussion', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  GlassCard(
                    useBackdropBlur: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: scheme.primary.withValues(alpha: 0.28),
                              child: Text(
                                initial,
                                style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _post.authorName,
                                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _ago(_post.createdAtMs),
                                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_post.phaseRoom != null) ...[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final room = PhaseRoomInfo.fromApiValue(_post.phaseRoom);
                              if (room == null) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${room.phase.displayName} phase room',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          _post.title,
                          style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _post.body,
                          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Comments (${_comments.length})',
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (_busy && _comments.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: scheme.primary)))
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No comments yet — say hello below.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    ..._comments.map((c) {
                      final ci = c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GlassCard(
                          useBackdropBlur: false,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: scheme.secondary.withValues(alpha: 0.35),
                                child: Text(ci, style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.authorName,
                                          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _ago(c.createdAtMs),
                                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.body,
                                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: GlassCard(
                      useBackdropBlur: false,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: _commentCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Write a supportive comment…',
                          hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.9)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sendComment,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(LucideIcons.send, color: scheme.onPrimary, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
