import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/in_app_notification_service.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/glow_page_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _pink = Color(0xFFFF8FC8);

  @override
  void initState() {
    super.initState();
    // Mark all read when screen is opened
    InAppNotificationService.instance.markAllRead();
  }

  Future<void> _onRefresh() async {
    await InAppNotificationService.instance.refresh();
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  bool _isToday(String? iso) {
    if (iso == null) return false;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'friend_accepted':
        return LucideIcons.heart;
      case 'friend_request':
        return LucideIcons.userPlus;
      case 'streak_nudge':
        return LucideIcons.flame;
      case 'story_reaction':
        return LucideIcons.camera;
      default:
        return LucideIcons.bell;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlowPageAppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              InAppNotificationService.instance.markAllRead();
              setState(() {});
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: _pink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: AppBackdrop(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: InAppNotificationService.notifications,
          builder: (context, items, _) {
            if (items.isEmpty) {
              return _buildEmpty(scheme);
            }

            final today = items.where((n) => _isToday(n['createdAt']?.toString())).toList();
            final earlier = items.where((n) => !_isToday(n['createdAt']?.toString())).toList();

            return RefreshIndicator(
              color: _pink,
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  if (today.isNotEmpty) ...[
                    _sectionHeader('Today', scheme),
                    ...today.map((n) => _notificationTile(n, scheme)),
                    const SizedBox(height: 12),
                  ],
                  if (earlier.isNotEmpty) ...[
                    _sectionHeader('Earlier', scheme),
                    ...earlier.map((n) => _notificationTile(n, scheme)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_pink.withValues(alpha: 0.3), _pink.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(LucideIcons.bellOff, size: 36, color: _pink),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When your friends interact with you,\nyou\'ll see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _notificationTile(Map<String, dynamic> n, ColorScheme scheme) {
    final isRead = n['read'] == true;
    final sender = n['sender'] as Map<String, dynamic>? ?? {};
    final username = sender['username']?.toString() ?? 'Someone';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final message = n['message']?.toString() ?? '';
    final type = n['type']?.toString();
    final createdAt = n['createdAt']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : _pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? scheme.outline.withValues(alpha: 0.15)
              : _pink.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 14, right: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pink,
                ),
              )
            else
              const SizedBox(width: 16),

            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_pink, Color(0xFFFF5FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: username,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: ' ${message.replaceFirst(username, '').trim()}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Type icon
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                _typeIcon(type),
                size: 18,
                color: _pink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
