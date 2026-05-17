import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/phase_room.dart';
import '../services/api_service.dart';
import '../services/community_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';
import 'community_post_detail_screen.dart';

/// Posts and discussion for one cycle phase room.
class PhaseRoomScreen extends StatefulWidget {
  const PhaseRoomScreen({super.key, required this.room});

  final PhaseRoomInfo room;

  @override
  State<PhaseRoomScreen> createState() => _PhaseRoomScreenState();
}

class _PhaseRoomScreenState extends State<PhaseRoomScreen> {
  final CommunityService _svc = CommunityService.instance;
  List<CommunityPost> _posts = [];
  bool _loading = true;
  String? _error;

  String get _phaseApi => widget.room.apiValue;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final cached = await _svc.readCachedPosts(phaseRoom: _phaseApi);
    if (mounted && cached.isNotEmpty) {
      setState(() => _posts = List.of(cached));
    }
    final net = await _svc.fetchPostsNetwork(phaseRoom: _phaseApi);
    if (!mounted) return;
    if (net != null) {
      setState(() {
        _posts = net;
        _loading = false;
      });
      return;
    }
    if (cached.isEmpty) {
      setState(() {
        _error = 'Could not load this room. Check your connection.';
        _loading = false;
      });
    } else {
      setState(() {
        _posts = List.of(cached);
        _loading = false;
        _error = 'Showing saved posts — reconnect to refresh.';
      });
    }
  }

  String _ago(CommunityPost p) {
    final ms = p.createdAtMs;
    if (ms <= 0) return 'Recently';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 90) return '${diff.inMinutes.clamp(1, 89)}m ago';
    if (diff.inHours < 48) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(d);
  }

  Future<void> _openComposer() async {
    final api = ApiService();
    if (!api.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to post in this phase room.')),
      );
      return;
    }
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final pad = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: pad),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              useBackdropBlur: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Post in ${widget.room.title}',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.room.subtitle,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      minLines: 3,
                      maxLines: 6,
                      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        labelText: 'Share with this room',
                        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    try {
      if (ok != true || !mounted) return;
      final title = titleCtrl.text.trim();
      final body = bodyCtrl.text.trim();
      if (title.isEmpty || body.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Title and body are required.')),
          );
        }
        return;
      }
      final created = await _svc.createPost(
        title: title,
        body: body,
        phaseRoom: _phaseApi,
      );
      if (!mounted) return;
      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create post. Try again when online.')),
        );
        return;
      }
      await _load();
    } finally {
      titleCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final room = widget.room;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
                  ),
                  GlowHomeIconButton(color: scheme.onSurface),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.title,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${room.phase.displayName} phase room',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: Icon(LucideIcons.refreshCw, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(
                room.subtitle,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: _loading && _posts.isEmpty
                  ? Center(child: CircularProgressIndicator(color: scheme.primary))
                  : RefreshIndicator(
                      color: scheme.primary,
                      onRefresh: _load,
                      child: _posts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
                              children: [
                                Center(
                                  child: Text(
                                    'Be the first to start a conversation in this room.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                return _PhasePostCard(
                                  post: post,
                                  subtitle: _ago(post),
                                  scheme: scheme,
                                  onTap: () {
                                    Navigator.of(context)
                                        .push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) => CommunityPostDetailScreen(post: post),
                                          ),
                                        )
                                        .then((_) => _load());
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposer,
        backgroundColor: scheme.primary,
        child: Icon(LucideIcons.plus, color: scheme.onPrimary),
      ),
    );
  }
}

class _PhasePostCard extends StatelessWidget {
  const _PhasePostCard({
    required this.post,
    required this.subtitle,
    required this.scheme,
    required this.onTap,
  });

  final CommunityPost post;
  final String subtitle;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: GlassCard(
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
                            post.authorName,
                            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  post.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.messageSquare, color: scheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentCount}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
