import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class DirectMessageScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const DirectMessageScreen({super.key, required this.friendId, required this.friendName});

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await ApiService().get('/messages/${widget.friendId}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['messages'] is List) {
          if (!mounted) return;
          setState(() {
            _messages.clear();
            for (var m in data['messages']) {
              _messages.add({
                'role': m['sender'] == widget.friendId ? 'friend' : 'me',
                'text': m['text'],
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    socket.on('receive_message', (data) {
      if (!mounted) return;
      if (data['sender'] == widget.friendId) {
        setState(() {
          _messages.add({'role': 'friend', 'text': data['text']});
        });
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final socket = SocketService.instance.socket;
    if (socket == null || !socket.connected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not connected to server')));
      return;
    }

    socket.emitWithAck('send_message', {
      'recipientId': widget.friendId,
      'text': text,
    }, ack: (response) {
      if (response['status'] == 'ok') {
        if (!mounted) return;
        setState(() {
          _messages.add({'role': 'me', 'text': text});
        });
        _textController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: ${response['error']}')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
        backgroundColor: scheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['role'] == 'me';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? scheme.primary : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(color: isMe ? scheme.onPrimary : scheme.onSurface),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(scheme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: scheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: scheme.primary,
            child: IconButton(
              icon: Icon(LucideIcons.send, color: scheme.onPrimary, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
