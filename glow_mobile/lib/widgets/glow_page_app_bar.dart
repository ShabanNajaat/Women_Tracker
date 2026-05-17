import 'package:flutter/material.dart';

import '../navigation/glow_navigation.dart';

/// App bar for screens pushed on top of [HomeScaffold]: back + dashboard home.
class GlowPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlowPageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showHome = true,
    this.leading,
    this.automaticallyImplyLeading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool showHome;
  final Widget? leading;
  final bool? automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppBar(
      title: title,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      leading: leading ?? (canPop ? const BackButton() : null),
      automaticallyImplyLeading: automaticallyImplyLeading ?? (leading != null || canPop),
      actions: [
        if (showHome)
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => GlowNavigation.goToDashboard(context),
          ),
        ...?actions,
      ],
    );
  }
}

/// Home shortcut for custom headers (e.g. phase room).
class GlowHomeIconButton extends StatelessWidget {
  const GlowHomeIconButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Dashboard',
      icon: Icon(Icons.home_outlined, color: color),
      onPressed: () => GlowNavigation.goToDashboard(context),
    );
  }
}
