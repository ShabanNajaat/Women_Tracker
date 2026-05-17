import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../util/path_file_bytes.dart';

import '../services/api_service.dart';
import '../services/challenge_service.dart';
import '../services/chat_local_store.dart';
import '../models/phase_room.dart';
import '../services/community_service.dart';
import '../services/cycle_service.dart';
import '../services/server_llm_service.dart';
import '../services/user_data_scope.dart';
import '../services/wellness_score_service.dart';
import '../widgets/glass_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Map<String, dynamic> _welcome = {
    'role': 'assistant',
    'text':
        'Hello! I am Dr. Najaat. How can I help you with your wellness journey today? Ask a question below to get started.',
  };

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _inputFocus;
  final List<Map<String, dynamic>> _messages = [];
  final ServerLLMService _llmService = ServerLLMService();
  final ApiService _api = ApiService();
  AudioRecorder? _recorder;
  bool _bootstrapDone = false;
  bool _isTyping = false;
  bool _recording = false;
  String? _banner;
  bool _bannerIsError = true;

  @override
  void initState() {
    super.initState();
    _inputFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed) {
          _handleSend();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    if (!kIsWeb) _recorder = AudioRecorder();
    UserDataScope.sessionEpoch.addListener(_onUserSessionChanged);
    _bootstrap();
  }

  void _onUserSessionChanged() {
    if (!mounted) return;
    setState(() {
      _bootstrapDone = false;
      _messages.clear();
      _banner = null;
    });
    _bootstrap();
  }

  Future<void> _syncChatFromServer(String scope) async {
    if (!_api.isAuthenticated) return;
    final res = await _api.get('/chat');
    if (!mounted || res.statusCode != 200) return;
    try {
      final data = jsonDecode(res.body);
      if (data is! List) return;
      await ChatLocalStore.instance.mergeServerMessages(scope, data);
      final merged = await ChatLocalStore.instance.loadMessages(scope);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(merged.isEmpty ? [_welcome] : merged.map((e) => {'role': e.role, 'text': e.text}).toList());
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    await _api.init();
    final scope = await _api.userScope();
    final local = await ChatLocalStore.instance.loadMessages(scope);
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(local.isEmpty ? [_welcome] : local.map((e) => {'role': e.role, 'text': e.text}).toList());
      _bootstrapDone = true;
    });
    _scrollToBottom();
    if (_api.isAuthenticated) {
      await _syncChatFromServer(scope);
    }
  }

  Future<void> _shareScoresWithCommunity() async {
    await ChallengeService.instance.ensureLoaded();
    await WellnessScoreService.instance.ensureLoaded();
    await _api.init();
    final base = ChallengeService.instance.buildPartnerStreakMessage();
    final msg =
        '$base\n\nGlow score: ${WellnessScoreService.instance.points} pts (on this device).';

    if (!_api.isAuthenticated) {
      await Clipboard.setData(ClipboardData(text: msg));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to post to Community automatically — your update was copied to the clipboard.'),
        ),
      );
      return;
    }

    await CycleService.instance.ensureLoaded();
    final cycle = CycleService.instance;
    final phase = cycle.phaseForDay(
      cycle.currentDayInCycle,
      cycleLength: cycle.typicalCycleLength,
    );
    final room = PhaseRoomInfo.forPhase(phase);

    final post = await CommunityService.instance.createPost(
      title: 'My Glow progress',
      body: msg,
      phaseRoom: room?.apiValue,
    );
    if (!mounted) return;
    if (post != null) {
      await Clipboard.setData(ClipboardData(text: msg));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posted to Community — a copy is also on your clipboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await Clipboard.setData(ClipboardData(text: msg));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach Community — copied your update to the clipboard instead.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendUserText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final scope = await _api.userScope();
    await ChatLocalStore.instance.appendUserMessage(scope, trimmed);

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': trimmed});
      _isTyping = true;
      _banner = null;
      _bannerIsError = true;
    });
    _scrollToBottom();

    final LlmReply reply = await _llmService.getResponse(trimmed);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      if (reply.isError) {
        _banner = reply.text;
        _bannerIsError = true;
        const fallback =
            'Something blocked that reply. Check the note above—often it is network or sign-in.';
        _messages.add({'role': 'assistant', 'text': fallback});
        ChatLocalStore.instance.appendAssistantMessage(scope, fallback);
      } else {
        _banner = reply.infoNotice?.trim().isNotEmpty == true ? reply.infoNotice : null;
        _bannerIsError = false;
        _messages.add({'role': 'assistant', 'text': reply.text});
        ChatLocalStore.instance.appendAssistantMessage(scope, reply.text);
      }
    });
    _scrollToBottom();
    await _syncChatFromServer(scope);
  }

  Future<void> _handleSend() async {
    await _sendUserText(_textController.text);
  }

  Future<void> _toggleRecording() async {
    if (kIsWeb || _recorder == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice notes are available on iOS/Android builds.')),
        );
      }
      return;
    }
    final r = _recorder!;
    if (_recording) {
      final path = await r.stop();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path == null || path.isEmpty) return;
      try {
        final bytes = await readBytesFromPath(path);
        if (bytes.isEmpty) return;
        setState(() => _isTyping = true);
        final res = await _api.postMultipart(
          '/chat/transcribe',
          fieldName: 'audio',
          bytes: bytes,
          filename: 'voice.m4a',
        );
        if (!mounted) return;
        setState(() => _isTyping = false);
        if (res.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to send voice notes to the server.')),
          );
          return;
        }
        if (res.statusCode != 200) {
          String note = 'Could not transcribe that clip.';
          try {
            final m = jsonDecode(res.body);
            if (m is Map && m['message'] != null) note = m['message'].toString();
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(note)));
          return;
        }
        final data = jsonDecode(res.body);
        final text = data is Map ? (data['text']?.toString().trim() ?? '') : '';
        if (text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No words picked up — try again a little closer to the mic.')),
          );
          return;
        }
        await _sendUserText(
          'Here is what I said in my voice note — please respond with wellness ideas that fit: $text',
        );
      } catch (_) {
        if (mounted) {
          setState(() => _isTyping = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read that recording. Try again.')),
          );
        }
      }
      await deleteFileAtPath(path);
    } else {
      final ok = await r.hasPermission();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is needed for voice notes.')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/glow_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await r.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      if (!mounted) return;
      setState(() => _recording = true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    UserDataScope.sessionEpoch.removeListener(_onUserSessionChanged);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapDone) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_banner != null) _buildBanner(isError: _bannerIsError),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  final raw = msg['text'];
                  final content = raw == null ? '' : raw.toString();
                  return _buildChatBubble(content, isUser);
                },
              ),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.sparkles, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Najaat',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'AI wellness assistant',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Post score & challenge summary to Community (and copy to clipboard)',
            icon: Icon(Icons.ios_share_rounded, color: scheme.onSurface),
            onPressed: _shareScoresWithCommunity,
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({required bool isError}) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? Colors.orange.withValues(alpha: 0.18) : scheme.primary.withValues(alpha: 0.14);
    final icon = isError ? Icons.wifi_off_rounded : Icons.info_outline_rounded;
    final iconColor = isError ? Colors.orangeAccent : scheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _banner!,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    final scheme = Theme.of(context).colorScheme;
    final assistantBg = scheme.surfaceContainerHigh;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary.withValues(alpha: 0.32) : assistantBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: Border.all(
            color: isUser ? scheme.primary.withValues(alpha: 0.55) : scheme.outline.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Dr. Najaat is thinking…',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!kIsWeb) ...[
              Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: _recording ? scheme.error.withValues(alpha: 0.25) : scheme.surfaceContainerHigh,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isTyping ? null : _toggleRecording,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        _recording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _recording ? scheme.error : scheme.onSurface,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: GlassCard(
                useBackdropBlur: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _textController,
                  focusNode: _inputFocus,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your wellness…',
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _handleSend,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(LucideIcons.send, color: scheme.onPrimary, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
