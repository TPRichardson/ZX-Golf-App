import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Live elapsed time shown in the app bar.
class ElapsedTimeBadge extends StatefulWidget {
  final DateTime startTimestamp;

  const ElapsedTimeBadge({super.key, required this.startTimestamp});

  @override
  State<ElapsedTimeBadge> createState() => _ElapsedTimeBadgeState();
}

class _ElapsedTimeBadgeState extends State<ElapsedTimeBadge> {
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 16, color: ColorTokens.textTertiary),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          _formatElapsed(_elapsed),
          style: TextStyle(
            fontSize: TypographyTokens.bodySize,
            fontWeight: FontWeight.w500,
            color: ColorTokens.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
