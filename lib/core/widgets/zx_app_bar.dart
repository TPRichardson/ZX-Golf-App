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
