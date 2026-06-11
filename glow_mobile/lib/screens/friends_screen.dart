import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import 'direct_message_screen.dart';
import 'package:http/http.dart' as http;

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _friends = [];
  List<dynamic> _pendingIncoming = [];
  List<dynamic> _pendingOutgoing = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _suggested = [];
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.init();
      final res = await _api.get('/friends');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _friends = data['friends'] ?? [];
          _pendingIncoming = data['pendingIncoming'] ?? [];
          _pendingOutgoing = data['pendingOutgoing'] ?? [];
        });
      }
      final resSug = await _api.get('/friends/suggested');
      if (resSug.statusCode == 200) {
        setState(() {
          _suggested = jsonDecode(resSug.body);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final res =
        await _api.get('/friends/search?q=${Uri.encodeComponent(query)}');
    if (res.statusCode == 200) {
      setState(() {
        _searchResults = jsonDecode(res.body);
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final res =
        await _api.post('/friends/request', body: {'targetUserId': userId});
    if (!mounted) return;
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌸 Friend request sent!'),
          backgroundColor: Color(0xFFFF8FC8),
        ),
      );
      _searchController.clear();
      setState(() => _searchResults = []);
      _fetchFriends();
    } else {
      try {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? data['message'] ?? 'Error')));
      } catch (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not send request')));
      }
    }
  }

  Future<void> _respondToRequest(String requestId, String action) async {
    final res = await _api
        .post('/friends/respond', body: {'requestId': requestId, 'action': action});
    if (res.statusCode == 200) {
      _fetchFriends();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'accept'
              ? '🎉 You are now friends!'
              : 'Request declined'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pink = const Color(0xFFFF8FC8);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Friends',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _fetchFriends,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: pink,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: pink,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.users, size: 16),
                  const SizedBox(width: 6),
                  const Text('Friends'),
                  if (_pendingIncoming.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: pink, shape: BoxShape.circle),
                      child: Text(
                        '${_pendingIncoming.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.sparkles, size: 16),
                  SizedBox(width: 6),
                  Text('Discover'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.search, size: 16),
                  SizedBox(width: 6),
                  Text('Search'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(scheme, pink),
                _buildDiscoverTab(scheme, pink),
                _buildSearchTab(scheme, pink),
              ],
            ),
    );
  }

  // ──────────────────── FRIENDS TAB ────────────────────
  Widget _buildFriendsTab(ColorScheme scheme, Color pink) {
    return RefreshIndicator(
      onRefresh: _fetchFriends,
      color: pink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incoming requests banner
            if (_pendingIncoming.isNotEmpty) ...[
              _sectionHeader('Friend Requests 🌸', pink),
              const SizedBox(height: 8),
              ..._pendingIncoming.map((u) => _requestCard(u, scheme, pink)),
              const SizedBox(height: 24),
            ],
            // Outgoing
            if (_pendingOutgoing.isNotEmpty) ...[
              _sectionHeader('Pending — waiting for reply', scheme.onSurfaceVariant),
              const SizedBox(height: 8),
              ..._pendingOutgoing.map((u) => _outgoingCard(u, scheme)),
              const SizedBox(height: 24),
            ],
            _sectionHeader('My Friends (${_friends.length})', scheme.onSurface),
            const SizedBox(height: 8),
            if (_friends.isEmpty)
              _emptyState(
                icon: LucideIcons.users,
                title: 'No friends yet',
                subtitle: 'Go to Discover to find people on Glow!',
                scheme: scheme,
              )
            else
              ..._friends.map((f) => _friendCard(f, scheme, pink)),
          ],
        ),
      ),
    );
  }

  // ──────────────────── DISCOVER TAB ────────────────────
  Widget _buildDiscoverTab(ColorScheme scheme, Color pink) {
    return RefreshIndicator(
      onRefresh: _fetchFriends,
      color: pink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pink.withValues(alpha: 0.25), pink.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pink.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('People on Glow ✨',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    'Connect with others, share streaks, and support each other on your wellness journey.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_suggested.isEmpty)
              _emptyState(
                icon: LucideIcons.sparkles,
                title: 'No suggestions right now',
                subtitle: 'Come back later or search for friends by username.',
                scheme: scheme,
              )
            else ...[
              _sectionHeader('Suggested for you', scheme.onSurface),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.88,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _suggested.length,
                itemBuilder: (ctx, i) => _suggestedCard(_suggested[i], scheme, pink),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────── SEARCH TAB ────────────────────
  Widget _buildSearchTab(ColorScheme scheme, Color pink) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search by @username…',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: pink, width: 2),
              ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {}); // Update suffix icon
              if (val.length > 1) _searchUsers(val);
              else if (val.isEmpty) setState(() => _searchResults = []);
            },
          ),
          const SizedBox(height: 16),
          if (_searchResults.isEmpty && _searchController.text.isEmpty)
            Expanded(
              child: _emptyState(
                icon: LucideIcons.atSign,
                title: 'Find friends',
                subtitle: 'Type a username to search for people on Glow.',
                scheme: scheme,
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: _emptyState(
                icon: LucideIcons.searchX,
                title: 'No results',
                subtitle: 'Try a different username.',
                scheme: scheme,
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final u = _searchResults[i];
                  final username = u['username'] ?? '';
                  final id = u['_id']?.toString() ?? u['id']?.toString() ?? '';
                  return Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: _avatarCircle(username, 22, pink),
                      title: Text('@$username',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: _addButton(id, pink),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────── CARDS ────────────────────

  Widget _suggestedCard(dynamic u, ColorScheme scheme, Color pink) {
    final username = u['username'] ?? '';
    final id = u['_id']?.toString() ?? u['id']?.toString() ?? '';
    final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final colors = [
      [const Color(0xFFFF8FC8), const Color(0xFFFFB3D9)],
      [const Color(0xFFE0569A), const Color(0xFFFF8FC8)],
      [const Color(0xFFFFD6EC), const Color(0xFFFFECF5)],
    ];
    final colorPair = colors[username.hashCode.abs() % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pink.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colorPair,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('@$username',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: scheme.onSurface),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Glow member',
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: id.isNotEmpty ? () => _sendFriendRequest(id) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(LucideIcons.userPlus, size: 14),
            label: const Text('Add friend'),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(dynamic u, ColorScheme scheme, Color pink) {
    final username = u['username'] ?? '';
    final requestId = u['requestId']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pink.withValues(alpha: 0.12), pink.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pink.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _avatarCircle(username, 22, pink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$username',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Wants to be your friend',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    foregroundColor: Colors.green.shade700),
                icon: const Icon(LucideIcons.check, size: 18),
                onPressed: () => _respondToRequest(requestId, 'accept'),
                tooltip: 'Accept',
              ),
              const SizedBox(width: 4),
              IconButton(
                style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red.shade400),
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => _respondToRequest(requestId, 'reject'),
                tooltip: 'Decline',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _outgoingCard(dynamic u, ColorScheme scheme) {
    final username = u['username'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _avatarCircle(username, 20, scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('@$username',
              style: const TextStyle(fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Pending',
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _friendCard(dynamic f, ColorScheme scheme, Color pink) {
    final username = f['username'] ?? '';
    final id = f['id']?.toString() ?? f['_id']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: _avatarCircle(username, 22, pink),
        title: Text('@$username',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text('Glow friend',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(LucideIcons.messageCircle, color: pink),
              tooltip: 'Message',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DirectMessageScreen(
                          friendId: id, friendName: username))),
            ),
            IconButton(
              icon: Icon(LucideIcons.user, color: scheme.onSurfaceVariant),
              tooltip: 'View profile',
              onPressed: () => _showFriendProfile(id, username),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── HELPERS ────────────────────

  Widget _avatarCircle(String username, double radius, Color color) {
    final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(initials,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.85)),
    );
  }

  Widget _addButton(String id, Color pink) {
    return ElevatedButton(
      onPressed: id.isNotEmpty ? () => _sendFriendRequest(id) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: pink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: const Text('Add'),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Text(title,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: color));
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme scheme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: scheme.onSurfaceVariant, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _showFriendProfile(String friendId, String friendName) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return FutureBuilder<http.Response>(
          future: _api.get('/friends/shared/$friendId'),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.statusCode != 200) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: Text('Could not load profile')));
            }
            final data = jsonDecode(snapshot.data!.body);
            final int streak = data['dailyStreak'] ?? 0;
            final int points = data['glowPoints'] ?? 0;

            return Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8FC8), Color(0xFFE0569A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        friendName.isNotEmpty
                            ? friendName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 34,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('@$friendName',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Glow friend',
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn('🔥 Streak', '$streak days'),
                      Container(
                          width: 1,
                          height: 40,
                          color: Theme.of(ctx)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2)),
                      _statColumn('✨ Glow Points', '$points'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DirectMessageScreen(
                                    friendId: friendId,
                                    friendName: friendName)));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8FC8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(LucideIcons.messageCircle),
                      label: const Text('Send Message',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFFFF8FC8))),
      ],
    );
  }
}
