import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';
import '../services/story_service.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/glass_card.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const _pink = Color(0xFFFF8FC8);
  static const _darkPink = Color(0xFFE0569A);

  Uint8List? _imageBytes;
  String? _base64Image;
  bool _isSending = false;
  final _captionController = TextEditingController();

  List<dynamic> _friends = [];
  String? _selectedFriendId;

  static const _dailyTips = [
    {
      'title': '📖 Period Power',
      'author': 'Maisie Hill',
      'tip': 'Your menstrual cycle is your fifth vital sign. Understanding it gives you a superpower for planning your life.',
      'category': 'Book',
    },
    {
      'title': '🧠 The Female Brain',
      'author': 'Dr. Louann Brizendine',
      'tip': 'Hormonal fluctuations during the cycle affect mood, energy, and cognition. Track patterns to optimize your days.',
      'category': 'Book',
    },
    {
      'title': '🌸 Self-Care Tip',
      'author': 'Glow Wellness',
      'tip': 'During your luteal phase, magnesium-rich foods like dark chocolate and spinach can ease PMS symptoms naturally.',
      'category': 'Wellness',
    },
    {
      'title': '💪 Fitness Fact',
      'author': 'ROAR by Dr. Stacy Sims',
      'tip': 'Women perform best at high-intensity workouts during the follicular phase. Save gentler workouts for the luteal phase.',
      'category': 'Book',
    },
    {
      'title': '🍎 Nutrition Note',
      'author': 'Glow Wellness',
      'tip': 'Iron-rich foods are especially important during menstruation. Pair with vitamin C for better absorption!',
      'category': 'Wellness',
    },
    {
      'title': '📖 WomanCode',
      'author': 'Alisa Vitti',
      'tip': 'Cycle syncing your diet, exercise, and productivity can transform how you feel every day of the month.',
      'category': 'Book',
    },
    {
      'title': '💜 Mental Health',
      'author': 'Glow Wellness',
      'tip': 'Journaling for just 5 minutes during your cycle can reduce anxiety by 43%. Your feelings are valid — write them out.',
      'category': 'Wellness',
    },
    {
      'title': '📖 In the FLO',
      'author': 'Alisa Vitti',
      'tip': 'The infradian rhythm governs your 28-day cycle. Aligning with it boosts creativity, energy, and sleep quality.',
      'category': 'Book',
    },
    {
      'title': '🌿 Herbal Wisdom',
      'author': 'Glow Wellness',
      'tip': "Raspberry leaf tea has been used for centuries to support uterine health. It's rich in iron and B vitamins.",
      'category': 'Wellness',
    },
    {
      'title': '📖 Taking Charge',
      'author': 'Toni Weschler',
      'tip': 'Cervical mucus patterns can tell you exactly where you are in your cycle — knowledge is empowerment.',
      'category': 'Book',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    // Auto-open camera immediately when tab is tapped
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePhoto();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final res = await ApiService().get('/friends');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _friends = (data['friends'] as List?) ?? []);
      }
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.camera, maxWidth: 1080, maxHeight: 1920, imageQuality: 75,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (_) {
      _pickFromGallery();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1080, maxHeight: 1920, imageQuality: 75,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.red[400]),
      );
    }
  }

  Future<void> _sendAsStreak() async {
    if (_base64Image == null && _captionController.text.trim().isEmpty) return;
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add friends first to send streaks! 💕'), backgroundColor: _pink),
      );
      return;
    }
    // Show friend selector bottom sheet
    _showFriendSelectorSheet(
      imageData: _base64Image,
      caption: _captionController.text.trim().isEmpty ? '🔥 Streak!' : _captionController.text.trim(),
    );
  }

  void _showFriendSelectorSheet({String? imageData, required String caption}) {
    final selectedIds = <String>{};
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.grey.shade300)),
                const SizedBox(height: 16),
                const Text('Send streak to... 🔥', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Select friends to send your streak to', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 16),
                // Friends grid
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _friends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final friend = _friends[i];
                      final name = friend['username']?.toString() ?? 'Friend';
                      final fId = friend['_id']?.toString() ?? '';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                      final isSelected = selectedIds.contains(fId);
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          if (isSelected) { selectedIds.remove(fId); } else { selectedIds.add(fId); }
                        }),
                        child: Column(children: [
                          Stack(children: [
                            Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isSelected ? const LinearGradient(colors: [_pink, _darkPink]) : null,
                                color: isSelected ? null : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                                border: isSelected ? Border.all(color: _pink, width: 3) : Border.all(color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.2)),
                              ),
                              child: Center(child: Text(initial, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: isSelected ? Colors.white : Theme.of(ctx).colorScheme.onSurface))),
                            ),
                            if (isSelected)
                              Positioned(right: 0, bottom: 0, child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: _pink),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              )),
                          ]),
                          const SizedBox(height: 4),
                          Text(name.length > 8 ? '${name.substring(0, 8)}..' : name,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? _pink : Theme.of(ctx).colorScheme.onSurfaceVariant)),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Select all button
                Row(children: [
                  TextButton.icon(
                    onPressed: () => setSheetState(() {
                      if (selectedIds.length == _friends.length) {
                        selectedIds.clear();
                      } else {
                        for (final f in _friends) { selectedIds.add(f['_id']?.toString() ?? ''); }
                      }
                    }),
                    icon: Icon(selectedIds.length == _friends.length ? Icons.deselect : Icons.select_all, size: 18),
                    label: Text(selectedIds.length == _friends.length ? 'Deselect all' : 'Select all'),
                    style: TextButton.styleFrom(foregroundColor: _pink),
                  ),
                  const Spacer(),
                  Text('${selectedIds.length} selected', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13)),
                ]),
                const SizedBox(height: 12),
                // Send button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selectedIds.isEmpty ? null : () {
                      Navigator.pop(ctx);
                      _sendStreakToFriends(selectedIds.toList(), imageData: imageData, caption: caption);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _pink, foregroundColor: Colors.white,
                      disabledBackgroundColor: _pink.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(LucideIcons.send, size: 18),
                    label: Text('Send Streak 🔥 (${selectedIds.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _sendStreakToFriends(List<String> friendIds, {String? imageData, required String caption}) async {
    setState(() => _isSending = true);
    int sent = 0;
    for (final fId in friendIds) {
      try {
        final body = <String, dynamic>{'friendId': fId, 'caption': caption};
        if (imageData != null) body['imageData'] = imageData;
        final res = await ApiService().post('/streaks/send', body: body);
        if (res.statusCode == 200) sent++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (sent > 0) { _imageBytes = null; _base64Image = null; _captionController.clear(); }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent > 0 ? '🔥 Streak sent to $sent friend${sent > 1 ? 's' : ''}!' : 'Could not send streak'),
        backgroundColor: sent > 0 ? _pink : Colors.red[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> get _todayTip {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _dailyTips[dayOfYear % _dailyTips.length];
  }

  Future<void> _sendQuickStreak(String message) async {
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add friends first to send streaks! 💕'), backgroundColor: _pink),
      );
      return;
    }
    _showFriendSelectorSheet(caption: message);
  }

  void _shareTipAsStreak(Map<String, dynamic> tip) {
    final caption = '${tip['title']}\nby ${tip['author']}\n\n"${tip['tip']}"';
    _sendQuickStreak(caption);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tip = _todayTip;

    return AppBackdrop(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCameraCard(scheme),
              const SizedBox(height: 16),
              if (_imageBytes != null) ...[
                _buildFriendSelector(scheme),
                const SizedBox(height: 16),
              ],
              _buildDailyTipCard(scheme, tip),
              const SizedBox(height: 16),
              _buildQuickActions(scheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraCard(ColorScheme scheme) {
    return GlassCard(
      child: Column(
        children: [
          if (_imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.memory(_imageBytes!, width: double.infinity, height: 340, fit: BoxFit.cover),
                  Positioned(
                    top: 10, right: 10,
                    child: IconButton(
                      onPressed: () => setState(() { _imageBytes = null; _base64Image = null; }),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              maxLines: 2, minLines: 1,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Add a caption or message...',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _pink.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _pink)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(LucideIcons.penTool, color: _pink.withValues(alpha: 0.6), size: 18),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSending ? null : _sendAsStreak,
                style: FilledButton.styleFrom(
                  backgroundColor: _pink, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.send, size: 18),
                label: const Text('Send as Streak 🔥', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ] else ...[
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_pink.withValues(alpha: 0.08), _darkPink.withValues(alpha: 0.04)]),
                border: Border.all(color: _pink.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [_pink, _darkPink]),
                        boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)],
                      ),
                      child: const Icon(LucideIcons.camera, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 14),
                    Text('Snap a Streak 📸', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('Take a photo and send it to your friends!', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _takePhoto,
                    style: FilledButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(LucideIcons.camera, size: 18),
                    label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    style: OutlinedButton.styleFrom(foregroundColor: _pink, side: const BorderSide(color: _pink),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(LucideIcons.image, size: 18),
                    label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendSelector(ColorScheme scheme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.users, size: 20, color: _pink),
            const SizedBox(width: 8),
            Text('Send to a friend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.onSurface)),
          ]),
          const SizedBox(height: 12),
          if (_friends.isEmpty)
            Text('Add friends first to send them streaks! 💕', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14))
          else
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal, itemCount: _friends.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final friend = _friends[i];
                  final name = friend['username']?.toString() ?? 'Friend';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  final isSelected = friend['_id']?.toString() == _selectedFriendId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFriendId = friend['_id']?.toString()),
                    child: Column(children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected ? const LinearGradient(colors: [_pink, _darkPink]) : null,
                          color: isSelected ? null : scheme.surfaceContainerHighest,
                          border: isSelected ? null : Border.all(color: scheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: Center(child: Text(initial, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isSelected ? Colors.white : scheme.onSurface))),
                      ),
                      const SizedBox(height: 4),
                      Text(name.length > 6 ? '${name.substring(0, 6)}..' : name,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? _pink : scheme.onSurfaceVariant)),
                    ]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard(ColorScheme scheme, Map<String, dynamic> tip) {
    final isBook = tip['category'] == 'Book';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: isBook ? [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)] : [_pink, _darkPink])),
              child: Icon(isBook ? LucideIcons.bookOpen : LucideIcons.heart, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tip['title'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.onSurface)),
              Text(tip['author'] as String, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                color: isBook ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : _pink.withValues(alpha: 0.15)),
              child: Text(tip['category'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isBook ? const Color(0xFF8B5CF6) : _darkPink)),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4)),
            child: Text(tip['tip'] as String, style: TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.5)),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _shareTipAsStreak(tip),
              icon: const Icon(LucideIcons.share2, size: 16),
              label: const Text('Share as Streak'),
              style: TextButton.styleFrom(foregroundColor: _pink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('✨ Quick Streaks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface)),
        ),
        Row(children: [
          _QuickChip(emoji: '☀️', label: 'Good morning!', onTap: () => _sendQuickStreak('☀️ Good morning! Rise and glow! 🌸')),
          const SizedBox(width: 8),
          _QuickChip(emoji: '💧', label: 'Hydrate!', onTap: () => _sendQuickStreak('💧 Drink water queen! Stay hydrated 👑')),
          const SizedBox(width: 8),
          _QuickChip(emoji: '🧘', label: 'Self-care', onTap: () => _sendQuickStreak('🧘 Remember to take a break and breathe 🌿')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _QuickChip(emoji: '🔥', label: 'Streak!', onTap: () => _sendQuickStreak("🔥 Don't break the streak! Keep going 💪")),
          const SizedBox(width: 8),
          _QuickChip(emoji: '📖', label: 'Read today?', onTap: () => _sendQuickStreak('📖 Have you read something today? Knowledge is power! 🌟')),
        ]),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(color: const Color(0xFFFF8FC8).withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface))),
            ]),
          ),
        ),
      ),
    );
  }
}
