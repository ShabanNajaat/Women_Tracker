import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ama_models.dart';
import '../services/ama_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';
import 'expert_ama_session_screen.dart';

/// Lists expert AMA sessions (live, scheduled, ended).
class ExpertAmaScreen extends StatefulWidget {
  const ExpertAmaScreen({super.key});

  @override
  State<ExpertAmaScreen> createState() => _ExpertAmaScreenState();
}

class _ExpertAmaScreenState extends State<ExpertAmaScreen> {
  List<AmaSession> _sessions = [];
  bool _loading = true;
  String? _error;

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
    final list = await AmaService.instance.fetchSessions();
    if (!mounted) return;
    if (list == null) {
      setState(() {
        _error = 'Could not load AMA sessions. Is the server running?';
        _loading = false;
      });
      return;
    }
    setState(() {
      _sessions = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = _sessions.where((s) => s.isLive).toList();
    final other = _sessions.where((s) => !s.isLive).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: GlowPageAppBar(
        title: const Text('Expert AMA'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: scheme.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    'Anonymous Q&A and weekly-style expert sessions on fertility, PMS, PCOS, and hormonal acne. '
                    'Educational only — not diagnosis or emergency care.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
                  ],
                  if (live.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Live', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                    const SizedBox(height: 10),
                    ...live.map((s) => _SessionTile(session: s, scheme: scheme)),
                  ],
                  if (other.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Upcoming & past', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                    const SizedBox(height: 10),
                    ...other.map((s) => _SessionTile(session: s, scheme: scheme)),
                  ],
                  if (!_loading && _sessions.isEmpty && _error == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No AMA sessions yet.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.scheme});

  final AmaSession session;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final starts = session.startsAtMs > 0
        ? DateFormat.MMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(session.startsAtMs))
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ExpertAmaSessionScreen(sessionId: session.id),
              ),
            );
          },
          child: GlassCard(
            useBackdropBlur: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg(session.status, scheme),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(session.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _statusFg(session.status, scheme),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${session.answeredCount}/${session.questionCount} answered',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  session.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: scheme.onSurface,
                  ),
                ),
                if (session.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    session.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.35),
                  ),
                ],
                if (starts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(starts, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'live' => 'Live now',
        'ended' => 'Ended',
        _ => 'Scheduled',
      };

  static Color _statusBg(String status, ColorScheme scheme) => switch (status) {
        'live' => scheme.primaryContainer,
        'ended' => scheme.surfaceContainerHighest,
        _ => scheme.tertiary.withValues(alpha: 0.2),
      };

  static Color _statusFg(String status, ColorScheme scheme) => switch (status) {
        'live' => scheme.onPrimaryContainer,
        'ended' => scheme.onSurfaceVariant,
        _ => scheme.onSurface,
      };
}
