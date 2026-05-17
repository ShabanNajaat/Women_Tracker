import 'package:flutter/foundation.dart';

/// Keeps [HomeScaffold] tab index in sync when navigating home from pushed routes.
class HomeTabNotifier {
  HomeTabNotifier._();

  static final HomeTabNotifier instance = HomeTabNotifier._();

  final ValueNotifier<int> tabIndex = ValueNotifier(0);

  void goToDashboard() => goToTab(0);

  void goToTab(int index) {
    if (index < 0) return;
    tabIndex.value = index;
  }
}
