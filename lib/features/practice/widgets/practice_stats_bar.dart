// Practice stats bar — environment, surface, location pills.
// Shown at the top of the practice queue screen.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';

class PracticeStatsBar extends StatelessWidget {
  final EnvironmentType? environmentType;
  final SurfaceType? surfaceType;
  final VoidCallback? onEnvironmentTap;
  final VoidCallback? onSurfaceTap;

  const PracticeStatsBar({
    super.key,
    this.environmentType,
    this.surfaceType,
    this.onEnvironmentTap,
    this.onSurfaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final envStyle = EnvironmentSurfaceStyles.environment(environmentType);
    final surfStyle = EnvironmentSurfaceStyles.surface(surfaceType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, 0,
      ),
      child: Row(
        children: [
          if (onEnvironmentTap != null)
            Expanded(
              child: ZxPillButton(
                label: envStyle.label,
                icon: envStyle.icon,
                size: ZxPillSize.sm,
                color: envStyle.color,
                expanded: true,
                centered: true,
                onTap: onEnvironmentTap,
              ),
            ),
          const SizedBox(width: SpacingTokens.xs),
          if (onSurfaceTap != null)
            Expanded(
              child: ZxPillButton(
                label: surfStyle.label,
                icon: surfStyle.icon,
                size: ZxPillSize.sm,
                color: surfStyle.color,
                backgroundColor: surfStyle.fillColor,
                borderColor: surfStyle.borderColor,
                expanded: true,
                centered: true,
                onTap: onSurfaceTap,
              ),
            ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: ZxPillButton(
              label: 'Location',
              icon: Icons.location_on_outlined,
              size: ZxPillSize.sm,
              variant: ZxPillVariant.tertiary,
              expanded: true,
              centered: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location picker coming soon')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
