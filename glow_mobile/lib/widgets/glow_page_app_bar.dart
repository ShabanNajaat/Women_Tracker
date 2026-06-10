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
    final scheme = Theme.of(context).colorScheme;
    final barTheme = Theme.of(context).appBarTheme;
    final fg = foregroundColor ?? barTheme.foregroundColor ?? scheme.onSurface;
    final bg = backgroundColor ?? barTheme.backgroundColor ??
        (scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHigh);

    return AppBar(
      title: DefaultTextStyle(
        style: barTheme.titleTextStyle ?? TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 20),
        child: title,
      ),
      backgroundColor: bg,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: barTheme.systemOverlayStyle,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
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
