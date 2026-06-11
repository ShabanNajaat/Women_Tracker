import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import 'direct_message_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _friends = [];
  List<dynamic> _pendingIncoming = [];
  List<dynamic> _pendingOutgoing = [];
  List<dynamic> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/friends');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _friends = data['friends'] ?? [];
          _pendingIncoming = data['pendingIncoming'] ?? [];
          _pendingOutgoing = data['pendingOutgoing'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final res = await _api.get('/friends/search?q=${Uri.encodeComponent(query)}');
    if (res.statusCode == 200) {
      setState(() {
        _searchResults = jsonDecode(res.body);
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final res = await _api.post('/friends/request', body: {'targetUserId': userId});
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      _searchController.clear();
      _searchResults.clear();
      _fetchFriends();
    } else {
      final data = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error')));
    }
  }

  Future<void> _respondToRequest(String requestId, String action) async {
    final res = await _api.post('/friends/respond', body: {'requestId': requestId, 'action': action});
    if (res.statusCode == 200) {
      _fetchFriends();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(scheme),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Search Results', scheme),
                    ..._searchResults.map((u) => ListTile(
                      title: Text(u['username']),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.userPlus),
                        onPressed: () => _sendFriendRequest(u['_id']),
                      ),
                    )),
                  ],
                  if (_pendingIncoming.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Friend Requests', scheme),
                    ..._pendingIncoming.map((u) => ListTile(
                      title: Text(u['username']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.check, color: Colors.green),
                            onPressed: () => _respondToRequest(u['requestId'], 'accept'),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.red),
                            onPressed: () => _respondToRequest(u['requestId'], 'reject'),
                          ),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 16),
                  _buildSectionTitle('My Friends', scheme),
                  if (_friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No friends yet. Search for users above!'),
                    ),
                  ..._friends.map((f) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text(f['username'][0].toUpperCase(), style: TextStyle(color: scheme.onPrimaryContainer)),
                    ),
                    title: Text(f['username']),
                    trailing: const Icon(LucideIcons.messageCircle),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DirectMessageScreen(friendId: f['id'], friendName: f['username'])
                      ));
                    },
                  )),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar(ColorScheme scheme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search friends by username...',
        prefixIcon: const Icon(LucideIcons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      onChanged: (val) {
        if (val.length > 2) _searchUsers(val);
        else if (val.isEmpty) setState(() => _searchResults = []);
      },
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface),
      ),
    );
  }
}
