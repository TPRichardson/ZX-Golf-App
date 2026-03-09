// Practice stats bar — live clock, weather placeholder, location placeholder.
// Shown at the top of the practice queue screen below environment/surface tiles.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

class PracticeStatsBar extends StatefulWidget {
  final DateTime startTimestamp;
  final EnvironmentType? environmentType;

  const PracticeStatsBar({
    super.key,
    required this.startTimestamp,
    this.environmentType,
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
    final isOutdoor = widget.environmentType == EnvironmentType.outdoor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md, SpacingTokens.sm, SpacingTokens.md, 0,
      ),
      child: Row(
        children: [
          // Live clock.
          Icon(Icons.timer_outlined, size: 16, color: ColorTokens.textTertiary),
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
          const SizedBox(width: SpacingTokens.lg),
          // Weather placeholder (outdoor only).
          if (isOutdoor) ...[
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weather picker coming soon')),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_outlined, size: 16, color: ColorTokens.textTertiary),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    'Weather',
                    style: TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
          ],
          // Location placeholder.
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location picker coming soon')),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: ColorTokens.textTertiary),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
