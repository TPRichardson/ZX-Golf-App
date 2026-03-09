// Practice stats bar — live clock, environment, surface, location.
// Shown at the top of the practice queue screen.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';

class PracticeStatsBar extends StatefulWidget {
  final DateTime startTimestamp;
  final EnvironmentType? environmentType;
  final SurfaceType? surfaceType;
  final VoidCallback? onEnvironmentTap;
  final VoidCallback? onSurfaceTap;

  const PracticeStatsBar({
    super.key,
    required this.startTimestamp,
    this.environmentType,
    this.surfaceType,
    this.onEnvironmentTap,
    this.onSurfaceTap,
  });

  @override
  State<PracticeStatsBar> createState() => _PracticeStatsBarState();
}

class _PracticeStatsBarState extends State<PracticeStatsBar> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTimestamp);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final envStyle = EnvironmentSurfaceStyles.environment(widget.environmentType);
    final surfStyle = EnvironmentSurfaceStyles.surface(widget.surfaceType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.sm, SpacingTokens.sm, SpacingTokens.sm, 0,
      ),
      child: Row(
        children: [
          // Live clock.
          Icon(Icons.timer_outlined, size: 14, color: ColorTokens.textTertiary),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            _formatElapsed(_elapsed),
            style: TextStyle(
              fontSize: TypographyTokens.microSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Environment, Surface, Location — equal width.
          if (widget.onEnvironmentTap != null)
            Expanded(
              child: GestureDetector(
                onTap: widget.onEnvironmentTap,
                child: _StatsPill(
                  label: envStyle.label,
                  icon: envStyle.icon,
                  color: envStyle.color,
                ),
              ),
            ),
          const SizedBox(width: SpacingTokens.xs),
          if (widget.onSurfaceTap != null)
            Expanded(
              child: GestureDetector(
                onTap: widget.onSurfaceTap,
                child: _StatsPill(
                  label: surfStyle.label,
                  icon: surfStyle.icon,
                  iconScale: surfStyle.iconScale,
                  color: surfStyle.color,
                  fillColor: surfStyle.fillColor,
                  borderColor: surfStyle.borderColor,
                ),
              ),
            ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location picker coming soon')),
                );
              },
              child: _StatsPill(
                label: 'Location',
                icon: Icons.location_on_outlined,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill badge used within the stats bar.
class _StatsPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconScale;
  final Color color;
  final Color? fillColor;
  final Color? borderColor;

  const _StatsPill({
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
        color: fillColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
        border: Border.all(
            color: borderColor ?? color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
