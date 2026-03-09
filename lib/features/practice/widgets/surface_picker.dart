import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

/// Shared style definitions for environment + surface display.
class EnvironmentSurfaceStyles {
  EnvironmentSurfaceStyles._();

  // -- Environment styles --
  static const indoorColor = ColorTokens.primaryDefault;
  static const indoorIcon = Icons.home;
  static const indoorLabel = 'Indoor';

  static const outdoorColor = Color(0xFFF5A623);
  static const outdoorIcon = Icons.wb_sunny;
  static const outdoorLabel = 'Outdoor';

  // -- Surface styles --
  static const grassColor = ColorTokens.successDefault;
  static const grassIcon = Icons.grass;
  static const grassLabel = 'Grass';

  static const matFillColor = Color(0xFF1A5C2A);
  static const matBorderColor = Color(0xFF2D7A3E);
  static const matTextColor = ColorTokens.textPrimary;
  static const matIcon = Icons.stop_rounded;
  static const matLabel = 'Mat';

  /// Returns (color, icon, label) for an environment type.
  static ({Color color, IconData icon, String label}) environment(
      EnvironmentType? env) {
    final isOutdoor = env == EnvironmentType.outdoor;
    return (
      color: isOutdoor ? outdoorColor : indoorColor,
      icon: isOutdoor ? outdoorIcon : indoorIcon,
      label: isOutdoor ? outdoorLabel : indoorLabel,
    );
  }

  /// Returns style props for a surface type.
  static ({Color color, IconData icon, double iconScale, String label, Color? fillColor, Color? borderColor})
      surface(SurfaceType? surface) {
    final isGrass = surface == SurfaceType.grass;
    return (
      color: isGrass ? grassColor : matTextColor,
      icon: isGrass ? grassIcon : matIcon,
      iconScale: isGrass ? 1.0 : 1.4,
      label: isGrass ? grassLabel : matLabel,
      fillColor: isGrass ? null : matFillColor,
      borderColor: isGrass ? null : matBorderColor,
    );
  }
}

/// Result of the environment/surface picker flow.
class EnvironmentSurfaceResult {
  final EnvironmentType environment;
  final SurfaceType surface;

  const EnvironmentSurfaceResult({
    required this.environment,
    required this.surface,
  });
}

/// Two-step picker: Indoor/Outdoor → Grass/Mat.
/// Returns null if dismissed.
Future<EnvironmentSurfaceResult?> showEnvironmentSurfacePicker(
  BuildContext context,
) async {
  final environment = await showEnvironmentPicker(context);
  if (environment == null || !context.mounted) return null;

  final surface = await showSurfacePicker(context);
  if (surface == null) return null;

  return EnvironmentSurfaceResult(
    environment: environment,
    surface: surface,
  );
}

/// Single-step picker: Indoor or Outdoor only.
Future<EnvironmentType?> showEnvironmentPicker(BuildContext context) {
  final indoor = EnvironmentSurfaceStyles.environment(EnvironmentType.indoor);
  final outdoor = EnvironmentSurfaceStyles.environment(EnvironmentType.outdoor);

  return showDialog<EnvironmentType>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Practice Environment',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerOption(
            label: outdoor.label,
            icon: outdoor.icon,
            color: outdoor.color,
            onTap: () => Navigator.pop(ctx, EnvironmentType.outdoor),
          ),
          const SizedBox(height: SpacingTokens.sm),
          _PickerOption(
            label: indoor.label,
            icon: indoor.icon,
            color: indoor.color,
            onTap: () => Navigator.pop(ctx, EnvironmentType.indoor),
          ),
        ],
      ),
    ),
  );
}

/// Single-step picker: Grass or Mat only.
Future<SurfaceType?> showSurfacePicker(BuildContext context) {
  final grass = EnvironmentSurfaceStyles.surface(SurfaceType.grass);
  final mat = EnvironmentSurfaceStyles.surface(SurfaceType.mat);

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
          _PickerOption(
            label: grass.label,
            icon: grass.icon,
            iconScale: grass.iconScale,
            color: grass.color,
            onTap: () => Navigator.pop(ctx, SurfaceType.grass),
          ),
          const SizedBox(height: SpacingTokens.sm),
          _PickerOption(
            label: mat.label,
            icon: mat.icon,
            iconScale: mat.iconScale * 0.8,
            color: mat.color,
            fillColor: mat.fillColor,
            borderColor: mat.borderColor,
            onTap: () => Navigator.pop(ctx, SurfaceType.mat),
          ),
        ],
      ),
    ),
  );
}

/// Picker option styled to match block tiles — filled background with colour.
class _PickerOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconScale;
  final Color color;
  final Color? fillColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _PickerOption({
    required this.label,
    required this.icon,
    this.iconScale = 1.0,
    required this.color,
    this.fillColor,
    this.borderColor,
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
          color: fillColor ?? color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: borderColor ?? color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Center(
                child: Icon(icon, color: color, size: 28 * iconScale),
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small tappable badges showing environment + surface.
class SurfaceBadge extends StatelessWidget {
  final SurfaceType? surfaceType;
  /// Explicit environment type. When null, derived from surface.
  final EnvironmentType? environmentType;
  final VoidCallback onTap;

  const SurfaceBadge({
    super.key,
    required this.surfaceType,
    this.environmentType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutdoor = environmentType != null
        ? environmentType == EnvironmentType.outdoor
        : surfaceType == SurfaceType.grass;
    final env = EnvironmentSurfaceStyles.environment(
        isOutdoor ? EnvironmentType.outdoor : EnvironmentType.indoor);
    final surf = EnvironmentSurfaceStyles.surface(surfaceType);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BadgePill(label: env.label, icon: env.icon, color: env.color),
          const SizedBox(width: SpacingTokens.xs),
          _BadgePill(
            label: surf.label,
            icon: surf.icon,
            iconScale: surf.iconScale,
            color: surf.color,
            fillColor: surf.fillColor,
            borderColor: surf.borderColor,
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconScale;
  final Color color;
  final Color? fillColor;
  final Color? borderColor;

  const _BadgePill({
    required this.label,
    required this.icon,
    this.iconScale = 1.0,
    required this.color,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: fillColor ?? color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
        border: Border.all(color: borderColor ?? color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * iconScale, color: color),
          const SizedBox(width: SpacingTokens.xs),
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
    );
  }
}
