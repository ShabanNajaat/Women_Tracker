import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _adminData;
  String? _error;

  Future<void> _login() async {
    final key = _passController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse('${ApiService().baseUrl}/admin/dashboard'),
        headers: {'x-admin-key': key},
      );

      if (res.statusCode == 200) {
        setState(() {
          _isAuthenticated = true;
          _adminData = jsonDecode(res.body);
        });
      } else {
        setState(() {
          _error = 'Invalid admin credentials';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      body: _isAuthenticated ? _buildDashboard(scheme) : _buildLogin(scheme),
    );
  }

  Widget _buildLogin(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64),
            const SizedBox(height: 24),
            Text(
              'Admin Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              FilledButton(
                onPressed: _login,
                child: const Text('Access Dashboard'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(ColorScheme scheme) {
    if (_adminData == null) return const Center(child: CircularProgressIndicator());

    final users = _adminData!['users'] as List;
    final ratings = _adminData!['ratings'] as List;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: scheme.surfaceContainerHighest,
            child: const TabBar(
              tabs: [
                Tab(text: 'Registered Users'),
                Tab(text: 'App Ratings'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(users),
                _buildRatingsList(ratings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final date = DateTime.tryParse(u['createdAt'] ?? '');
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(u['username'] ?? 'Unknown'),
          subtitle: Text(u['email'] ?? 'No email'),
          trailing: Text(date != null ? '${date.month}/${date.day}/${date.year}' : ''),
        );
      },
    );
  }

  Widget _buildRatingsList(List ratings) {
    if (ratings.isEmpty) {
      return const Center(child: Text('No ratings yet.'));
    }
    return ListView.builder(
      itemCount: ratings.length,
      itemBuilder: (context, index) {
        final r = ratings[index];
        final userObj = r['user'];
        String u = 'Unknown User';
        if (userObj is Map) {
          u = userObj['username']?.toString() ?? userObj['name']?.toString() ?? userObj['email']?.toString() ?? 'Unknown User';
        } else if (userObj is String && userObj.isNotEmpty) {
          u = userObj;
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Row(
              children: [
                Text(u, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < (r['stars'] ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(r['feedback'] ?? ''),
            ),
          ),
        );
      },
    );
  }
}
