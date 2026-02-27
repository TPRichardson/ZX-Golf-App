import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S15 §15.8 — Card component.
// surface.primary bg, optional border, 8px radius, spacing.16 padding.
// On-press: darken ~4% (S15 §15.4).

class ZxCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool showBorder;
  final EdgeInsetsGeometry? padding;

  const ZxCard({
    super.key,
    required this.child,
    this.onTap,
    this.showBorder = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ??
          const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ColorTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: showBorder
            ? Border.all(color: ColorTokens.surfaceBorder)
            : null,
      ),
      child: child,
    );

    if (onTap == null) return cardContent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        highlightColor: ColorTokens.surfaceRaised,
        splashColor: Colors.transparent,
        child: cardContent,
      ),
    );
  }
}
