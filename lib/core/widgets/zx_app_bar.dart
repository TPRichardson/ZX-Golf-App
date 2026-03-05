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

/// Shared styled tab bar — selected tab visually connects to the header above.
/// The selected tab has a U-shaped cyan border (left, bottom, right) with
/// rounded bottom corners. Unselected tabs show a cyan top border.
/// Parent AppBar should use [connectedHeaderShape] to add a matching cyan top border.
class ZxTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tab> tabs;

  const ZxTabBar({super.key, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  /// Shape for the parent AppBar — cyan top border on the header.
  static const connectedHeaderShape = Border(
    top: BorderSide(color: ColorTokens.primaryDefault, width: 2),
    left: BorderSide(color: ColorTokens.primaryDefault, width: 2),
    right: BorderSide(color: ColorTokens.primaryDefault, width: 2),
  );

  static const _borderWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    // Container has a cyan top border across the full width.
    // The selected tab indicator extends upward to cover that border,
    // so only unselected tabs show the cyan top line.
    return Container(
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: ColorTokens.primaryDefault,
            width: _borderWidth,
          ),
        ),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 2),
        labelColor: ColorTokens.textPrimary,
        unselectedLabelColor: ColorTokens.textSecondary,
        dividerHeight: 0,
        indicator: _ConnectedTabIndicator(
          color: ColorTokens.surfacePrimary,
          borderColor: ColorTokens.primaryDefault,
          borderWidth: _borderWidth,
          radius: ShapeTokens.radiusCard,
        ),
        tabs: tabs,
      ),
    );
  }
}

/// Custom decoration that draws a U-shaped border (left + bottom + right)
/// with rounded bottom corners. Extends upward by [borderWidth] to cover
/// the container's top cyan border, connecting the tab to the header.
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
    final r = radius;
    final bw = borderWidth;

    // Extend upward by borderWidth to cover the container's cyan top border.
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy - bw,
      size.width,
      size.height + bw,
    );

    // Fill path with convex (outward-curving) bottom corners.
    final fillPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.left + r, rect.bottom),
        radius: Radius.circular(r),
        clockwise: false, // convex: curves outward
      )
      ..lineTo(rect.right - r, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - r),
        radius: Radius.circular(r),
        clockwise: false, // convex: curves outward
      )
      ..lineTo(rect.right, rect.top)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = color);

    // U-shaped border (left + bottom + right) with convex corners.
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = bw;

    final borderPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.left + r, rect.bottom),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(rect.right - r, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(rect.right, rect.top);

    canvas.drawPath(borderPath, borderPaint);
  }
}
