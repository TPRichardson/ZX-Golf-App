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
      centerTitle: true,
      title: Text(title),
      leading: leading,
      actions: actions,
      backgroundColor: ColorTokens.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }
}

/// Shared styled tab bar — selected tab visually connects to the header above
/// via a cyan U-shaped border (left, bottom, right with rounded bottom corners).
/// The parent AppBar should use [connectedAppBarDecoration] on its bottom border
/// to complete the visual connection.
class ZxTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tab> tabs;

  const ZxTabBar({super.key, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  /// Decoration for the AppBar above this tab bar — adds a cyan bottom border
  /// so the selected tab's side borders connect into the header.
  static const connectedAppBarBottom = BorderSide(
    color: ColorTokens.primaryDefault,
    width: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.surfaceRaised,
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: ColorTokens.textPrimary,
        unselectedLabelColor: ColorTokens.textSecondary,
        indicator: _ConnectedTabIndicator(
          color: ColorTokens.surfacePrimary,
          borderColor: ColorTokens.primaryDefault,
          borderWidth: 2,
          radius: ShapeTokens.radiusCard,
        ),
        tabs: tabs,
      ),
    );
  }
}

/// Custom decoration that draws a U-shaped border (left + bottom + right)
/// with rounded bottom corners, connecting visually to the header above.
class _ConnectedTabIndicator extends Decoration {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  const _ConnectedTabIndicator({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.radius,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _ConnectedTabPainter(
      color: color,
      borderColor: borderColor,
      borderWidth: borderWidth,
      radius: radius,
    );
  }
}

class _ConnectedTabPainter extends BoxPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  _ConnectedTabPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    final rect = offset & size;

    // Tab background with rounded bottom corners.
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );

    // Fill.
    canvas.drawRRect(rrect, Paint()..color = color);

    // U-shaped border: left side, bottom, right side.
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path()
      ..moveTo(rect.left, rect.top) // top-left
      ..lineTo(rect.left, rect.bottom - radius) // left side down
      ..arcToPoint(
        Offset(rect.left + radius, rect.bottom),
        radius: Radius.circular(radius),
      ) // bottom-left corner
      ..lineTo(rect.right - radius, rect.bottom) // bottom edge
      ..arcToPoint(
        Offset(rect.right, rect.bottom - radius),
        radius: Radius.circular(radius),
      ) // bottom-right corner
      ..lineTo(rect.right, rect.top); // right side up

    canvas.drawPath(path, borderPaint);
  }
}
