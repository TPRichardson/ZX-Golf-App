import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
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
          ZxPillButton(
            label: outdoor.label,
            icon: outdoor.icon,
            color: outdoor.color,
            size: ZxPillSize.lg,
            expanded: true,
            onTap: () => Navigator.pop(ctx, EnvironmentType.outdoor),
          ),
          const SizedBox(height: SpacingTokens.sm),
          ZxPillButton(
            label: indoor.label,
            icon: indoor.icon,
            color: indoor.color,
            size: ZxPillSize.lg,
            expanded: true,
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
          ZxPillButton(
            label: grass.label,
            icon: grass.icon,
            color: grass.color,
            size: ZxPillSize.lg,
            expanded: true,
            onTap: () => Navigator.pop(ctx, SurfaceType.grass),
          ),
          const SizedBox(height: SpacingTokens.sm),
          ZxPillButton(
            label: mat.label,
            icon: mat.icon,
            color: mat.color,
            backgroundColor: mat.fillColor,
            borderColor: mat.borderColor,
            size: ZxPillSize.lg,
            expanded: true,
            onTap: () => Navigator.pop(ctx, SurfaceType.mat),
          ),
        ],
      ),
    ),
  );
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
          ZxPillButton(
            label: env.label,
            icon: env.icon,
            color: env.color,
            size: ZxPillSize.sm,
            onTap: onTap,
          ),
          const SizedBox(width: SpacingTokens.xs),
          ZxPillButton(
            label: surf.label,
            icon: surf.icon,
            color: surf.color,
            backgroundColor: surf.fillColor,
            borderColor: surf.borderColor,
            size: ZxPillSize.sm,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

