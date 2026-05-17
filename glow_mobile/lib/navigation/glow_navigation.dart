import 'package:flutter/material.dart';

import 'home_tab_notifier.dart';

abstract final class GlowNavigation {
  /// Pops all routes back to [HomeScaffold] and selects the dashboard tab.
  static void goToDashboard(BuildContext context) => goToTab(context, 0);

  /// Pops back to [HomeScaffold] and selects a main tab (0=Home … 6=Community).
  static void goToTab(BuildContext context, int index) {
    HomeTabNotifier.instance.goToTab(index);
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
  }
}
