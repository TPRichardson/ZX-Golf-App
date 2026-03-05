import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S15 §15.8 — Custom app bar matching dark theme.

class ZxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const ZxAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      backgroundColor: ColorTokens.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }
}

/// Shared styled tab bar — selected tab matches title bar colour,
/// unselected tab slightly raised for visual separation.
class ZxTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tab> tabs;

  const ZxTabBar({super.key, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.surfaceRaised,
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: ColorTokens.textPrimary,
        unselectedLabelColor: ColorTokens.textSecondary,
        indicator: BoxDecoration(
          color: ColorTokens.surfacePrimary,
          border: const Border(
            bottom: BorderSide(
              color: ColorTokens.primaryDefault,
              width: 3,
            ),
          ),
        ),
        tabs: tabs,
      ),
    );
  }
}
