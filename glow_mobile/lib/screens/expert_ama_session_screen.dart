import 'package:flutter/material.dart';

import '../models/ama_models.dart';
import '../services/ama_service.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_page_app_bar.dart';

class ExpertAmaSessionScreen extends StatefulWidget {
  const ExpertAmaSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<ExpertAmaSessionScreen> createState() => _ExpertAmaSessionScreenState();
}

class _ExpertAmaSessionScreenState extends State<ExpertAmaSessionScreen> {
  AmaSessionDetail? _detail;
  List<AmaQuestion> _questions = [];
  bool _loading = true;
  bool _recentSort = false;
  bool _askAnonymous = false;
  final _questionCtrl = TextEditingController();

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final detail = await AmaService.instance.fetchSession(widget.sessionId);
    final questions = await AmaService.instance.fetchQuestions(
      widget.sessionId,
      recent: _recentSort,
    );
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _questions = questions ?? [];
      _loading = false;
    });
  }

  Future<void> _submitQuestion() async {
    if (!ApiService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to ask a question.')),
      );
      return;
    }
    final body = _questionCtrl.text.trim();
    if (body.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question must be at least 8 characters.')),
      );
      return;
    }
    final session = _detail?.session;
    if (session?.isEnded == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This AMA has ended.')),
      );
      return;
    }
    final q = await AmaService.instance.askQuestion(
      sessionId: widget.sessionId,
      body: body,
      anonymous: _askAnonymous,
    );
    if (!mounted) return;
    if (q == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit — try again when online.')),
      );
      return;
    }
    _questionCtrl.clear();
    await _load();
  }

  Future<void> _upvote(AmaQuestion q) async {
    if (!ApiService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to upvote.')),
      );
      return;
    }
    final updated = await AmaService.instance.upvote(q.id);
    if (!mounted || updated == null) return;
    setState(() {
      _questions = _questions.map((x) => x.id == updated.id ? updated : x).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = _detail;
    final session = detail?.session;
    final expert = detail?.expert;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: GlowPageAppBar(title: Text(session?.title ?? 'AMA')),
      body: _loading && detail == null
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: scheme.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (expert != null)
                          GlassCard(
                            useBackdropBlur: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(Icons.school_outlined, color: scheme.onPrimaryContainer),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expert.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        expert.title,
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        expert.bio,
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Questions',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: false, label: Text('Top')),
                                ButtonSegment(value: true, label: Text('Recent')),
                              ],
                              selected: {_recentSort},
                              onSelectionChanged: (s) {
                                setState(() => _recentSort = s.first);
                                _load();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_questions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No questions yet — be the first to ask below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          )
                        else
                          ..._questions.map((q) => _QuestionCard(
                                question: q,
                                scheme: scheme,
                                onUpvote: () => _upvote(q),
                              )),
                      ],
                    ),
                  ),
                ),
                if (session != null && !session.isEnded)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Ask anonymously',
                              style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Your name won\'t appear on this question.',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                            ),
                            value: _askAnonymous,
                            onChanged: (v) => setState(() => _askAnonymous = v),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _questionCtrl,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Ask the expert…',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _submitQuestion,
                                child: const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.scheme,
    required this.onUpvote,
  });

  final AmaQuestion question;
  final ColorScheme scheme;
  final VoidCallback onUpvote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        useBackdropBlur: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.authorName,
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              question.body,
              style: TextStyle(color: scheme.onSurface, height: 1.45),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onUpvote,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: Text('${question.upvoteCount}'),
                ),
                if (question.isAnswered) ...[
                  const Spacer(),
                  Icon(Icons.verified_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Answered',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            if (question.isAnswered) ...[
              const Divider(height: 20),
              Text(
                'Expert answer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question.answer,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
