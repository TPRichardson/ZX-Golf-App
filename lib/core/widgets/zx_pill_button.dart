import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S15 §15.8 — Pill button component. Five semantic variants with tinted
// background + border styling. Intended as the app-wide standard action button.

enum ZxPillVariant { progress, primary, secondary, tertiary, destructive }

enum ZxPillSize { sm, md, lg }

class ZxPillButton extends StatelessWidget {
  final String label;
  final ZxPillVariant variant;
  final ZxPillSize size;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool iconRight;
  final bool centered;
  final bool isLoading;
  final bool expanded;

  /// Optional color overrides — take precedence over variant colors.
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  const ZxPillButton({
    super.key,
    required this.label,
    this.variant = ZxPillVariant.primary,
    this.size = ZxPillSize.md,
    this.icon,
    required this.onTap,
    this.iconRight = false,
    this.centered = false,
    this.isLoading = false,
    this.expanded = false,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    final metrics = _resolveSize();

    final child = GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: metrics.verticalPadding,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: expanded || centered ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: centered
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: isLoading
              ? [
                  SizedBox(
                    width: metrics.iconSize,
                    height: metrics.iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.foreground,
                    ),
                  ),
                ]
              : _buildContent(colors.foreground, metrics),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }

  List<Widget> _buildContent(Color fg, _ZxPillMetrics metrics) {
    final iconWidget = icon != null
        ? Icon(icon, size: metrics.iconSize, color: fg)
        : null;
    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: metrics.fontSize,
        fontWeight: FontWeight.w500,
        color: fg,
        height: 1.0,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (iconWidget == null) return [Flexible(child: textWidget)];

    final gap = SizedBox(width: metrics.gap);
    return iconRight
        ? [Flexible(child: textWidget), gap, iconWidget]
        : [iconWidget, gap, Flexible(child: textWidget)];
  }

  _ZxPillMetrics _resolveSize() {
    return switch (size) {
      ZxPillSize.sm => const _ZxPillMetrics(
          fontSize: TypographyTokens.microSize,
          iconSize: 14,
          horizontalPadding: SpacingTokens.xs,
          verticalPadding: SpacingTokens.xs,
          gap: SpacingTokens.xs,
        ),
      ZxPillSize.md => const _ZxPillMetrics(
          fontSize: TypographyTokens.bodySize,
          iconSize: 16,
          horizontalPadding: SpacingTokens.md,
          verticalPadding: SpacingTokens.sm,
          gap: SpacingTokens.xs,
        ),
      ZxPillSize.lg => const _ZxPillMetrics(
          fontSize: TypographyTokens.bodyLgSize,
          iconSize: 20,
          horizontalPadding: SpacingTokens.xl,
          verticalPadding: SpacingTokens.md,
          gap: SpacingTokens.sm,
        ),
    };
  }

  ({Color foreground, Color background, Color border}) _resolveColors() {
    if (color != null) {
      return (
        foreground: color!,
        background: backgroundColor ?? color!.withValues(alpha: 0.1),
        border: borderColor ?? color!.withValues(alpha: 0.25),
      );
    }
    return switch (variant) {
      ZxPillVariant.progress => (
          foreground: ColorTokens.successDefault,
          background: ColorTokens.successDefault.withValues(alpha: 0.1),
          border: ColorTokens.successDefault.withValues(alpha: 0.25),
        ),
      ZxPillVariant.primary => (
          foreground: ColorTokens.textPrimary,
          background: ColorTokens.primaryDefault,
          border: ColorTokens.primaryDefault,
        ),
      ZxPillVariant.secondary => (
          foreground: ColorTokens.primaryDefault,
          background: Colors.transparent,
          border: ColorTokens.primaryDefault.withValues(alpha: 0.25),
        ),
      ZxPillVariant.tertiary => (
          foreground: ColorTokens.textTertiary,
          background: ColorTokens.textTertiary.withValues(alpha: 0.1),
          border: ColorTokens.textTertiary.withValues(alpha: 0.25),
        ),
      ZxPillVariant.destructive => (
          foreground: ColorTokens.errorDestructive,
          background: ColorTokens.errorDestructive.withValues(alpha: 0.1),
          border: ColorTokens.errorDestructive.withValues(alpha: 0.25),
        ),
    };
  }
}

class _ZxPillMetrics {
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double gap;

  const _ZxPillMetrics({
    required this.fontSize,
    required this.iconSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gap,
  });
}
