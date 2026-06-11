import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/user_data_scope.dart';
import '../widgets/app_backdrop.dart';
import '../services/glow_effects_service.dart';
import '../services/glow_notification_service.dart';
import '../services/phase_notification_service.dart';
import '../services/theme_service.dart';
import '../services/wearable_health_service.dart';
import '../screens/medication_reminders_screen.dart';
import '../screens/wellness_schedules_hub_screen.dart';
import '../services/medication_reminder_service.dart';
import '../services/wellness_schedule_service.dart';
import '../models/wellness_schedule_type.dart';
import '../navigation/glow_navigation.dart';
import '../widgets/fertility_mode_section.dart';
import '../widgets/glow_page_app_bar.dart';
import '../widgets/wearable_settings_section.dart';
import 'login_screen.dart';
import 'app_guide_screen.dart';
import 'exercise_timer_screen.dart';
import '../services/glow_web_links.dart';
import 'admin_dashboard_screen.dart';
import '../widgets/rate_app_dialog.dart';

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

/// Desktop-style settings: narrow sidebar + detail pane (similar to WhatsApp / system prefs).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.tune_rounded,
      title: 'General',
      subtitle: 'Theme, display & startup look',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      title: 'Profile',
      subtitle: 'Name & photo synced with your account',
    ),
    _NavItem(
      icon: Icons.key_outlined,
      title: 'Account',
      subtitle: 'Session & sign out',
    ),
    _NavItem(
      icon: Icons.lock_outline_rounded,
      title: 'Privacy',
      subtitle: 'How we treat your health notes',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Wellness & AI',
      subtitle: 'Dr. Najaat & your server',
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      subtitle: 'Daily wellness reminder on this device',
    ),
    _NavItem(
      icon: Icons.help_outline_rounded,
      title: 'Help & feedback',
      subtitle: 'About Glow, get support',
    ),
  ];

  int _section = 0;
  bool _mobileDetail = false;
  final TextEditingController _profileNameCtrl = TextEditingController();
  String? _profileEmail;
  int? _profileGlowPoints;
  String? _profilePhotoDataUrl;
  bool _profileLoading = false;
  bool _profileLoadRequested = false;
  bool _profileSaving = false;
  bool _clearPhotoOnSave = false;
  bool? _notifEnabled;
  bool? _phaseHydration;
  bool? _phaseStretch;
  bool? _phaseRest;

  static const double _breakpoint = 760;

  @override
  void initState() {
    super.initState();
    UserDataScope.sessionEpoch.addListener(_onUserSessionChanged);
    _loadNotifPref();
    _loadPhaseNotifPrefs();
    WearableHealthService.instance.ensureLoaded();
    MedicationReminderService.instance.ensureLoaded();
    WellnessScheduleService.instance.ensureLoaded();
  }

  @override
  void dispose() {
    UserDataScope.sessionEpoch.removeListener(_onUserSessionChanged);
    _profileNameCtrl.dispose();
    super.dispose();
  }

  void _onUserSessionChanged() {
    if (!mounted) return;
    _resetProfileState();
    setState(() {});
  }

  void _resetProfileState() {
    _profileLoadRequested = false;
    _profileEmail = null;
    _profileGlowPoints = null;
    _profileNameCtrl.clear();
    _profilePhotoDataUrl = null;
    _clearPhotoOnSave = false;
  }

  Future<void> _loadNotifPref() async {
    final v = await GlowNotificationService.instance.getEnabled();
    if (mounted) setState(() => _notifEnabled = v);
  }

  Future<void> _loadPhaseNotifPrefs() async {
    final p = PhaseNotificationService.instance;
    final h = await p.hydrationEnabled();
    final s = await p.stretchEnabled();
    final r = await p.restEnabled();
    if (mounted) {
      setState(() {
        _phaseHydration = h;
        _phaseStretch = s;
        _phaseRest = r;
      });
    }
  }

  Future<void> _ensureProfileLoaded() async {
    if (_profileLoadRequested) return;
    _profileLoadRequested = true;
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) {
      if (mounted) setState(() => _profileLoading = false);
      return;
    }
    if (mounted) setState(() => _profileLoading = true);
    final res = await api.get('/auth/profile');
    if (!mounted) return;
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final name = data['name']?.toString() ?? '';
          final email = data['email']?.toString() ?? '';
          final photo = data['photo']?.toString();
          final points = data['glowPoints'];
          setState(() {
            _profileNameCtrl.text = name;
            _profileEmail = email.isNotEmpty ? email : null;
            _profileGlowPoints = points is int ? points : int.tryParse('$points');
            _profilePhotoDataUrl = photo != null && photo.isNotEmpty ? photo : null;
            _clearPhotoOnSave = false;
            _profileLoading = false;
          });
          return;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _profileLoading = false);
  }

  Future<void> _pickProfilePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 82,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (bytes.length > 380000) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That image is still too large after shrinking — try another photo.')),
        );
      }
      return;
    }
    final b64 = base64Encode(bytes);
    setState(() {
      _profilePhotoDataUrl = 'data:image/jpeg;base64,$b64';
      _clearPhotoOnSave = false;
    });
  }

  Future<void> _saveProfile(BuildContext context) async {
    final api = ApiService();
    await api.init();
    if (!api.isAuthenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save profile changes.')),
        );
      }
      return;
    }
    setState(() => _profileSaving = true);
    final body = <String, dynamic>{
      'name': _profileNameCtrl.text.trim(),
    };
    if (_clearPhotoOnSave) {
      body['photo'] = '';
    } else if (_profilePhotoDataUrl != null && _profilePhotoDataUrl!.startsWith('data:image')) {
      body['photo'] = _profilePhotoDataUrl;
    }
    final res = await api.post('/auth/profile', body: body);
    if (!mounted) return;
    setState(() => _profileSaving = false);
    if (res.statusCode == 200) {
      if (mounted) {
        setState(() => _clearPhotoOnSave = false);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } else {
      var msg = 'Could not save profile.';
      try {
        final m = jsonDecode(res.body);
        if (m is Map && m['message'] != null) msg = m['message'].toString();
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Widget _profileInfoCard(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar(ColorScheme scheme) {
    final p = _profilePhotoDataUrl;
    if (p != null && p.startsWith('data:image') && !_clearPhotoOnSave) {
      final idx = p.indexOf(',');
      if (idx > 0) {
        try {
          final raw = base64Decode(p.substring(idx + 1));
          return CircleAvatar(
            radius: 48,
            backgroundImage: MemoryImage(raw),
          );
        } catch (_) {}
      }
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: scheme.primary.withValues(alpha: 0.22),
      child: Icon(Icons.face_rounded, size: 46, color: scheme.primary),
    );
  }

  void _privacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy summary'),
        content: const Text(
          'Health and wellness notes you add in Glow are meant to stay private—we do not sell your personal '
          'wellness data.\n\n'
          'Use HTTPS between the app and your API in production. '
          'We are not claiming extra “military-grade” encryption beyond what TLS and your host provide.\n\n'
          'A full privacy policy will be published before a public launch.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await ApiService().clearAuth();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= _breakpoint;
    final isDark = scheme.brightness == Brightness.dark;

    final sidebarBg = isDark ? scheme.surface : scheme.surfaceContainerHigh;
    final paneBg = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final border = scheme.outline.withValues(alpha: isDark ? 0.12 : 0.18);

    if (!wide) {
      if (_mobileDetail) {
        return Scaffold(
          backgroundColor: paneBg,
          appBar: GlowPageAppBar(
            backgroundColor: sidebarBg,
            foregroundColor: scheme.onSurface,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => setState(() => _mobileDetail = false),
            ),
            title: Text(_items[_section].title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: AppBackdrop(child: _buildDetailPane(context, scheme, paneBg)),
        );
      }
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlowPageAppBar(
          backgroundColor: sidebarBg,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: AppBackdrop(
          child: _buildSidebarList(context, scheme, sidebarBg, border, wide: false),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackdrop(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 300,
            child: _buildSidebarList(context, scheme, sidebarBg, border, wide: true),
          ),
          Container(width: 1, color: border),
          Expanded(
            child: ColoredBox(
              color: paneBg,
              child: _buildDetailPane(context, scheme, paneBg),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSidebarList(
    BuildContext context,
    ColorScheme scheme,
    Color bg,
    Color border, {
    required bool wide,
  }) {
    return ColoredBox(
      color: bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12, wide ? 20 : 8, 12, 24),
        children: [
          _SidebarTile(
            item: const _NavItem(
              icon: Icons.home_outlined,
              title: 'Home',
              subtitle: 'Back to dashboard',
            ),
            selected: false,
            scheme: scheme,
            onTap: () => GlowNavigation.goToDashboard(context),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _items.length; i++)
            _SidebarTile(
              item: _items[i],
              selected: _section == i,
              scheme: scheme,
              onTap: () {
                setState(() {
                  _section = i;
                  if (i == 1) _profileLoadRequested = false;
                  if (!wide) _mobileDetail = true;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(BuildContext context, ColorScheme scheme, Color paneBg) {
    return ColoredBox(
      color: paneBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
        child: switch (_section) {
          0 => _buildGeneral(context, scheme),
          1 => _buildProfile(context, scheme),
          2 => _buildAccount(context, scheme),
          3 => _buildPrivacy(context, scheme),
          4 => _buildWellnessAi(scheme),
          5 => _buildNotifications(context, scheme),
          _ => _buildHelp(context, scheme),
        },
      ),
    );
  }

  Widget _buildGeneral(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose how Glow feels when you open it — warm Glow (light) or calm Dusk (dark).',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 28),
        Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _BigModeTile(
                icon: Icons.light_mode_rounded,
                label: 'Glow',
                subtitle: 'Light',
                scheme: scheme,
                onTap: () => ThemeService.setTheme(ThemeMode.light),
              ),
              _BigModeTile(
                icon: Icons.dark_mode_rounded,
                label: 'Dusk',
                subtitle: 'Dark',
                scheme: scheme,
                onTap: () => ThemeService.setTheme(ThemeMode.dark),
              ),
              _BigModeTile(
                icon: Icons.brightness_auto_rounded,
                label: 'System',
                subtitle: 'Match device',
                scheme: scheme,
                onTap: () => ThemeService.setTheme(ThemeMode.system),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Fine-tune',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeMode,
          builder: (context, mode, _) {
            return SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Glow'), icon: Icon(Icons.wb_sunny_outlined, size: 18)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dusk'), icon: Icon(Icons.nightlight_round, size: 18)),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.settings_suggest_outlined, size: 18)),
              ],
              selected: {mode},
              onSelectionChanged: (s) => ThemeService.setTheme(s.first),
            );
          },
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<bool>(
          valueListenable: GlowEffectsService.instance.enabled,
          builder: (context, glassOn, _) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Glass blur effects', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Turn off for sharper text on web and dense screens.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              value: glassOn,
              onChanged: (v) => GlowEffectsService.instance.setEnabled(v),
            );
          },
        ),
        const SizedBox(height: 32),
        Divider(color: scheme.outline.withValues(alpha: 0.25)),
        const SizedBox(height: 24),
        Text(
          'Fertility mode',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how Glow highlights your calendar and dashboard — tracking, TTC, or pregnancy awareness.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        FertilityModeSection(scheme: scheme),
        const SizedBox(height: 32),
        Divider(color: scheme.outline.withValues(alpha: 0.25)),
        const SizedBox(height: 24),
        Text(
          'Wearables & Apple Health',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        WearableSettingsSection(scheme: scheme),
      ],
    );
  }

  Widget _buildProfile(BuildContext context, ColorScheme scheme) {
    if (!_profileLoadRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProfileLoaded());
    }
    final api = ApiService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Your name and photo are stored with your Glow account. Photos are cropped and compressed before upload.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 24),
        if (!api.isAuthenticated)
          Text(
            'Sign in to edit your profile on this device.',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
          )
        else if (_profileLoading)
          const LinearProgressIndicator()
        else ...[
          Center(child: _profileAvatar(scheme)),
          const SizedBox(height: 20),
          if (_profileEmail != null && _profileEmail!.isNotEmpty)
            _profileInfoCard(
              scheme,
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: _profileEmail!,
            ),
          if (_profileGlowPoints != null) ...[
            const SizedBox(height: 10),
            _profileInfoCard(
              scheme,
              icon: Icons.auto_awesome_rounded,
              label: 'Glow points',
              value: '${_profileGlowPoints!} pts',
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _pickProfilePhoto(context),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose photo'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _clearPhotoOnSave = true;
                  _profilePhotoDataUrl = null;
                }),
                child: const Text('Remove photo'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _profileNameCtrl,
            decoration: InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _profileSaving ? null : () => _saveProfile(context),
            icon: _profileSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_profileSaving ? 'Saving…' : 'Save profile', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _buildAccount(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'You’re signed in on this device. Sign out clears the saved session token.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildPrivacy(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'We design Glow so your wellness notes stay yours. Read the summary, then a full policy will ship before public launch.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => _privacyDialog(context),
          icon: const Icon(Icons.policy_outlined),
          label: const Text('Open privacy summary'),
        ),
      ],
    );
  }

  Widget _buildWellnessAi(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wellness & AI', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Dr. Najaat replies from your Node server. In server/.env use the exact variable name:',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 8),
        SelectableText(
          'OPENAI_API_KEY',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'in server/.env (not OPEN_API_KEY). Restart npm after changes. Optionally set GEMINI_API_KEY instead.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Glow can nudge you once a day on this device (local scheduling — not a cloud push service). '
          'On Android 13+ you may be asked to allow notifications.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Daily wellness reminder', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Around 9:00 local time — a gentle check-in prompt.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          value: _notifEnabled ?? false,
          onChanged: (_notifEnabled == null)
              ? null
              : (v) async {
                  await GlowNotificationService.instance.setEnabled(v);
                  if (context.mounted) setState(() => _notifEnabled = v);
                },
        ),
        const SizedBox(height: 20),
        Text(
          'Phase-aware care',
          style: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Extra local nudges based on your current cycle phase (updates when you open the app).',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Hydration on flow & PMS days', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
          subtitle: Text('Menstrual & luteal · ~11:00', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          value: _phaseHydration ?? false,
          onChanged: (_phaseHydration == null)
              ? null
              : (v) async {
                  await PhaseNotificationService.instance.setHydration(v);
                  if (context.mounted) setState(() => _phaseHydration = v);
                },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Stretch & relax (PMS)', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
          subtitle: Text('Luteal phase · ~18:00', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          value: _phaseStretch ?? false,
          onChanged: (_phaseStretch == null)
              ? null
              : (v) async {
                  await PhaseNotificationService.instance.setStretch(v);
                  if (context.mounted) setState(() => _phaseStretch = v);
                },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Wind down on period days', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
          subtitle: Text('Menstrual phase · ~21:00', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          value: _phaseRest ?? false,
          onChanged: (_phaseRest == null)
              ? null
              : (v) async {
                  await PhaseNotificationService.instance.setRest(v);
                  if (context.mounted) setState(() => _phaseRest = v);
                },
        ),
        const SizedBox(height: 24),
        Text(
          'Medication & supplements',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Daily reminders for birth control, pain relief, vitamins, or anything you take on a schedule.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: MedicationReminderService.instance,
          builder: (context, _) {
            final count = MedicationReminderService.instance.reminders.length;
            final active = MedicationReminderService.instance.reminders.where((r) => r.enabled).length;
            return OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MedicationRemindersScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.medication_outlined),
              label: Text(
                count == 0
                    ? 'Set up medication reminders'
                    : '$active active · $count total',
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Meals & workouts',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Schedule breakfast, lunch, yoga, walks, and other daily nutrition or movement nudges.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: WellnessScheduleService.instance,
          builder: (context, _) {
            final svc = WellnessScheduleService.instance;
            final mealA = svc.activeCount(WellnessScheduleType.meal);
            final mealT = svc.reminders(WellnessScheduleType.meal).length;
            final woA = svc.activeCount(WellnessScheduleType.workout);
            final woT = svc.reminders(WellnessScheduleType.workout).length;
            return OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WellnessSchedulesHubScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                mealT + woT == 0
                    ? 'Set up meal & workout schedules'
                    : 'Meals $mealA/$mealT · Workouts $woA/$woT',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHelp(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Help & feedback', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Glow Wellness helps you track and learn — not a substitute for a clinician.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AppGuideScreen()),
            );
          },
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text('Open Glow guide (meet Glowie)'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse(GlowWebLinks.installPage);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.install_mobile_outlined),
          label: const Text('How to install on your phone'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ExerciseTimerScreen()),
            );
          },
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Exercise timer'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => const RateAppDialog(),
            );
          },
          icon: const Icon(Icons.star_rate_rounded),
          label: const Text('Rate Glow Wellness'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 28),
        AboutListTile(
          icon: Icon(Icons.info_outline_rounded, color: scheme.primary),
          applicationName: 'Glow Wellness',
          applicationVersion: '1.0.0',
          applicationLegalese: 'For wellness tracking and education only — not a medical device.',
        ),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    final hi = selected
        ? (isDark ? Colors.white.withValues(alpha: 0.08) : scheme.primary.withValues(alpha: 0.12))
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: hi,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 22, color: scheme.onSurface.withValues(alpha: 0.9)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigModeTile extends StatelessWidget {
  const _BigModeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.scheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    final box = Color(0xFF2A2A2A).withValues(alpha: isDark ? 1 : 0.08);
    if (!isDark) {
      return Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 128,
            height: 128,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: scheme.primary),
                const SizedBox(height: 10),
                Text(label, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800)),
                Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: box,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 128,
          height: 128,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.92)),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
