import 'package:flutter/material.dart';
import '../navigation/home_tab_notifier.dart';
import '../services/phase_notification_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/glow_space_screen.dart';
import '../screens/her_cycle_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/community_screen.dart';
import '../screens/settings_screen.dart';
import 'bottom_nav.dart';
import 'left_sidebar.dart';
import 'app_backdrop.dart';
import '../services/user_data_scope.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    HomeTabNotifier.instance.tabIndex.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    HomeTabNotifier.instance.tabIndex.removeListener(_onExternalTabChange);
    super.dispose();
  }

  void _onExternalTabChange() {
    final next = HomeTabNotifier.instance.tabIndex.value;
    if (mounted && next != _selectedIndex) {
      setState(() => _selectedIndex = next);
    }
  }

  static const List<String> _titles = [
    'Home',
    'Calendar',
    'Glow Space',
    'Her Cycle',
    'Chat',
    'Camera',
    'Journal',
    'Community',
  ];

  List<Widget> _pagesForSession(int epoch) => [
        DashboardScreen(key: ValueKey('tab_home_$epoch')),
        CalendarScreen(key: ValueKey('tab_cal_$epoch')),
        GlowSpaceScreen(key: ValueKey('tab_glow_$epoch')),
        HerCycleScreen(key: ValueKey('tab_cycle_$epoch')),
        ChatScreen(key: ValueKey('tab_chat_$epoch')),
        CameraScreen(key: ValueKey('tab_camera_$epoch')),
        JournalScreen(key: ValueKey('tab_journal_$epoch')),
        CommunityScreen(key: ValueKey('tab_community_$epoch')),
      ];

  void _onItemTapped(int index) {
    if (index < 0 || index >= 8) return;
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    HomeTabNotifier.instance.tabIndex.value = index;
    PhaseNotificationService.instance.reschedule();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return ValueListenableBuilder<int>(
      valueListenable: UserDataScope.sessionEpoch,
      builder: (context, epoch, _) {
        final pages = _pagesForSession(epoch);
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: isWide
              ? null
              : AppBar(
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
                  surfaceTintColor: Colors.transparent,
                  systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
                  title: Text(_titles[_selectedIndex]),
                  actions: [
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: _openSettings,
                    ),
                  ],
                ),
          body: AppBackdrop(
            child: Row(
              children: [
                if (isWide)
                  LeftSidebar(
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : BottomNav(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
        );
      },
    );
  }
}
