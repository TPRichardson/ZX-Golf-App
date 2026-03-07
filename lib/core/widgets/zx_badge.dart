import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// Shared badge widget used for skill area, drill type, status, and
// classification labels throughout the app.

class ZxBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ZxBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(ShapeTokens.radiusBadge),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
