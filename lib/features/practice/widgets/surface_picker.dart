import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

/// Prompt user to select practice surface type (Grass/Mat).
/// Returns null if dismissed.
Future<SurfaceType?> showSurfacePicker(BuildContext context) async {
  return showDialog<SurfaceType>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Practice Surface',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SurfaceOption(
            label: 'Grass',
            icon: Icons.grass,
            color: ColorTokens.successDefault,
            onTap: () => Navigator.pop(ctx, SurfaceType.grass),
          ),
          const SizedBox(height: SpacingTokens.sm),
          _SurfaceOption(
            label: 'Mat',
            icon: Icons.rectangle_outlined,
            color: ColorTokens.primaryDefault,
            onTap: () => Navigator.pop(ctx, SurfaceType.mat),
          ),
        ],
      ),
    ),
  );
}

class _SurfaceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SurfaceOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: SpacingTokens.md),
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                fontWeight: FontWeight.w500,
                color: ColorTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small tappable badge showing current surface type.
class SurfaceBadge extends StatelessWidget {
  final SurfaceType? surfaceType;
  final VoidCallback onTap;

  const SurfaceBadge({
    super.key,
    required this.surfaceType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGrass = surfaceType == SurfaceType.grass;
    final label = surfaceType?.dbValue ?? 'Surface';
    final icon = isGrass ? Icons.grass : Icons.rectangle_outlined;
    final color = isGrass ? ColorTokens.successDefault : ColorTokens.primaryDefault;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
